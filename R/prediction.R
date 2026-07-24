source(file.path("R", "team_normalization.R"))
source(file.path("R", "historical_features.R"))

validar_fecha_prediccion <- function(fecha_partido) {
  if (length(fecha_partido) != 1L) {
    stop("fecha_partido debe contener una sola fecha.", call. = FALSE)
  }
  fecha <- suppressWarnings(as.Date(fecha_partido))
  if (is.na(fecha)) {
    stop("fecha_partido no es una fecha válida.", call. = FALSE)
  }
  fecha
}

predecir_partido <- function(
    equipo_local,
    equipo_visitante,
    fase,
    fecha_partido,
    ruta_modelo = file.path("data", "processed", "modelo_prediccion.rds"),
    ruta_partidos = file.path("data", "processed", "wcmatches.rds"),
    ruta_mapeo = file.path("data", "reference", "team_name_mapping.csv")) {
  if (!requireNamespace("nnet", quietly = TRUE)) {
    stop("Falta el paquete 'nnet'. Instálelo antes de predecir.", call. = FALSE)
  }
  if (!file.exists(ruta_modelo)) {
    stop("No existe el modelo. Ejecute: Rscript R/modeling.R", call. = FALSE)
  }
  if (!file.exists(ruta_partidos)) {
    stop("No existen los partidos procesados. Ejecute: Rscript R/clean.R", call. = FALSE)
  }

  fecha <- validar_fecha_prediccion(fecha_partido)
  mapeo <- cargar_mapeo_equipos(ruta_mapeo)
  local <- normalizar_nombre_equipo(as.character(equipo_local), mapeo)
  visitante <- normalizar_nombre_equipo(as.character(equipo_visitante), mapeo)
  if (length(local) != 1L || is.na(local) || trimws(local) == "") {
    stop("equipo_local debe contener un nombre válido.", call. = FALSE)
  }
  if (length(visitante) != 1L || is.na(visitante) || trimws(visitante) == "") {
    stop("equipo_visitante debe contener un nombre válido.", call. = FALSE)
  }
  if (identical(local, visitante)) {
    stop("Los equipos local y visitante deben ser diferentes.", call. = FALSE)
  }
  if (length(fase) != 1L || is.na(fase) || trimws(fase) == "") {
    stop("fase debe contener un valor válido.", call. = FALSE)
  }

  partidos <- readRDS(ruta_partidos)
  partidos$date <- as.Date(partidos$date)
  historial <- partidos[partidos$date < fecha, , drop = FALSE]
  equipos_conocidos <- unique(c(historial$home_team, historial$away_team))
  if (!local %in% equipos_conocidos) {
    stop("No existen antecedentes anteriores para el equipo local: ", local, call. = FALSE)
  }
  if (!visitante %in% equipos_conocidos) {
    stop(
      "No existen antecedentes anteriores para el equipo visitante: ",
      visitante,
      call. = FALSE
    )
  }
  fases_conocidas <- sort(unique(historial$stage))
  if (!fase %in% fases_conocidas) {
    stop(
      "Fase desconocida. Valores disponibles: ",
      paste(fases_conocidas, collapse = ", "),
      call. = FALSE
    )
  }

  bundle <- readRDS(ruta_modelo)
  predictores <- crear_predictores_partido(
    partidos, local, visitante, fase, fecha
  )
  predictores <- predictores[, bundle$predictores, drop = FALSE]
  probabilidades <- predict(bundle$modelo, newdata = predictores, type = "probs")
  if (is.matrix(probabilidades)) {
    probabilidades <- probabilidades[1, ]
  }

  completas <- setNames(rep(0, 3), c("H", "D", "A"))
  completas[names(probabilidades)] <- as.numeric(probabilidades)
  completas <- completas / sum(completas)

  resultado <- list(
    equipo_local = local,
    equipo_visitante = visitante,
    fase = as.character(fase),
    fecha = fecha,
    probabilidades = c(
      victoria_local = 100 * completas[["H"]],
      empate = 100 * completas[["D"]],
      victoria_visitante = 100 * completas[["A"]]
    ),
    mensaje = "Estimación basada en datos históricos; no garantiza el resultado."
  )
  class(resultado) <- "prediccion_partido"
  resultado
}

print.prediccion_partido <- function(x, ...) {
  cat("Equipo local:", x$equipo_local, "\n")
  cat("Equipo visitante:", x$equipo_visitante, "\n")
  cat("Fase:", x$fase, "\n")
  cat("Fecha evaluada:", format(x$fecha), "\n\n")
  cat("Victoria local:", sprintf("%.2f%%", x$probabilidades[["victoria_local"]]), "\n")
  cat("Empate:", sprintf("%.2f%%", x$probabilidades[["empate"]]), "\n")
  cat(
    "Victoria visitante:",
    sprintf("%.2f%%", x$probabilidades[["victoria_visitante"]]),
    "\n\n"
  )
  cat(x$mensaje, "\n")
  invisible(x)
}
