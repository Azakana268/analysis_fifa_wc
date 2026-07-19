# Funciones para validar e incorporar partidos recientes sin modificar el CSV original.

columnas_partidos <- c(
  "year", "country", "city", "stage", "home_team", "away_team",
  "home_score", "away_score", "outcome", "win_conditions",
  "winning_team", "losing_team", "date", "month", "dayofweek"
)

preparar_tipos_partidos <- function(datos) {
  enteras <- c("year", "home_score", "away_score")
  texto <- setdiff(columnas_partidos, c(enteras, "date"))

  for (columna in enteras) {
    datos[[columna]] <- as.integer(datos[[columna]])
  }
  for (columna in texto) {
    datos[[columna]] <- as.character(datos[[columna]])
    vacios <- !is.na(datos[[columna]]) & trimws(datos[[columna]]) == ""
    datos[[columna]][vacios] <- NA_character_
  }
  datos$date <- as.Date(datos$date)
  datos
}

validar_partidos_recientes <- function(datos) {
  faltantes <- setdiff(columnas_partidos, names(datos))
  adicionales <- setdiff(names(datos), columnas_partidos)
  if (length(faltantes) > 0L || length(adicionales) > 0L) {
    stop(
      "Las columnas del Excel no coinciden con wcmatches.csv. Faltantes: ",
      paste(faltantes, collapse = ", "), "; adicionales: ",
      paste(adicionales, collapse = ", "),
      call. = FALSE
    )
  }

  obligatorias <- c(
    "year", "country", "city", "stage", "home_team", "away_team",
    "home_score", "away_score", "outcome", "date", "month", "dayofweek"
  )
  if (anyNA(datos[obligatorias])) {
    stop("Hay partidos con campos obligatorios vacíos.", call. = FALSE)
  }
  if (any(datos$home_score < 0L | datos$away_score < 0L)) {
    stop("Los marcadores no pueden ser negativos.", call. = FALSE)
  }
  if (any(!datos$outcome %in% c("H", "D", "A"))) {
    stop("outcome solo puede contener H, D o A.", call. = FALSE)
  }
  if (any(datos$home_team == datos$away_team)) {
    stop("Un partido no puede tener el mismo equipo como local y visitante.", call. = FALSE)
  }

  sin_penales <- is.na(datos$win_conditions)
  esperado <- ifelse(
    datos$home_score > datos$away_score, "H",
    ifelse(datos$home_score < datos$away_score, "A", "D")
  )
  incoherentes <- sin_penales & datos$outcome != esperado
  if (any(incoherentes)) {
    stop("Hay marcadores incompatibles con outcome.", call. = FALSE)
  }

  claves <- paste(datos$date, datos$home_team, datos$away_team, sep = "|")
  if (anyDuplicated(claves)) {
    stop("El Excel contiene partidos duplicados.", call. = FALSE)
  }

  meses <- format(datos$date, "%b")
  dias <- format(datos$date, "%A")
  locale_anterior <- Sys.getlocale("LC_TIME")
  locale_ingles <- try(Sys.setlocale("LC_TIME", "English"), silent = TRUE)
  if (!inherits(locale_ingles, "try-error")) {
    meses <- format(datos$date, "%b")
    dias <- format(datos$date, "%A")
    try(Sys.setlocale("LC_TIME", locale_anterior), silent = TRUE)
    if (any(datos$month != meses) || any(datos$dayofweek != dias)) {
      stop("month o dayofweek no coincide con date.", call. = FALSE)
    }
  }

  invisible(datos)
}

cargar_partidos_recientes <- function(
    ruta = file.path("data", "raw", "datos 2022 y 2026.xlsx"),
    hoja = "Partidos 2022 y 2026") {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop(
      "Falta el paquete 'readxl'. Instálelo con install.packages('readxl').",
      call. = FALSE
    )
  }
  if (!file.exists(ruta)) {
    stop("No se encontró el archivo de partidos recientes: ", ruta, call. = FALSE)
  }

  datos <- as.data.frame(
    readxl::read_excel(ruta, sheet = hoja, na = c("", "NA")),
    stringsAsFactors = FALSE
  )
  faltantes <- setdiff(columnas_partidos, names(datos))
  adicionales <- setdiff(names(datos), columnas_partidos)
  if (length(faltantes) > 0L || length(adicionales) > 0L) {
    stop(
      "Las columnas del Excel no coinciden con wcmatches.csv. Faltantes: ",
      paste(faltantes, collapse = ", "), "; adicionales: ",
      paste(adicionales, collapse = ", "),
      call. = FALSE
    )
  }
  datos <- datos[, columnas_partidos, drop = FALSE]
  datos <- preparar_tipos_partidos(datos)
  validar_partidos_recientes(datos)
  datos
}

combinar_partidos <- function(historicos, recientes) {
  faltantes_historicos <- setdiff(columnas_partidos, names(historicos))
  if (length(faltantes_historicos) > 0L) {
    stop(
      "Al CSV histórico le faltan columnas: ",
      paste(faltantes_historicos, collapse = ", "),
      call. = FALSE
    )
  }

  historicos <- preparar_tipos_partidos(
    historicos[, columnas_partidos, drop = FALSE]
  )
  recientes <- preparar_tipos_partidos(
    recientes[, columnas_partidos, drop = FALSE]
  )

  clave_historica <- paste(
    historicos$date, historicos$home_team, historicos$away_team, sep = "|"
  )
  clave_reciente <- paste(
    recientes$date, recientes$home_team, recientes$away_team, sep = "|"
  )
  repetidos <- intersect(clave_historica, clave_reciente)
  if (length(repetidos) > 0L) {
    stop(
      "Los datos recientes repiten partidos del CSV histórico: ",
      paste(head(repetidos, 5L), collapse = ", "),
      call. = FALSE
    )
  }

  resultado <- rbind(historicos, recientes)
  resultado <- resultado[order(resultado$date), , drop = FALSE]
  rownames(resultado) <- NULL
  resultado
}
