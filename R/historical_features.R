# Predictores construidos exclusivamente con partidos de fechas anteriores.
# El suavizado usa cuatro partidos neutrales y no consulta resultados futuros.

columnas_predictoras_historicas <- c(
  "home_previous_matches", "home_win_rate", "home_draw_rate",
  "home_loss_rate", "home_avg_goals_for", "home_avg_goals_against",
  "home_avg_goal_difference", "home_role_performance",
  "home_stage_performance", "home_h2h_matches", "home_head_to_head",
  "home_recent_form", "away_previous_matches", "away_win_rate",
  "away_draw_rate", "away_loss_rate", "away_avg_goals_for",
  "away_avg_goals_against", "away_avg_goal_difference",
  "away_role_performance", "away_stage_performance", "away_h2h_matches",
  "away_head_to_head", "away_recent_form", "diff_win_rate",
  "diff_draw_rate", "diff_goal_difference", "diff_recent_form",
  "diff_stage_performance", "diff_head_to_head"
)

parametros_suavizado <- list(
  partidos = 4,
  victorias = 1.5,
  empates = 1,
  derrotas = 1.5,
  goles_favor = 1.3,
  goles_contra = 1.3,
  puntos_por_partido = 1.25
)

validar_partidos_para_features <- function(partidos) {
  requeridas <- c(
    "year", "stage", "home_team", "away_team", "home_score",
    "away_score", "outcome", "date"
  )
  faltantes <- setdiff(requeridas, names(partidos))
  if (length(faltantes) > 0L) {
    stop(
      "Faltan columnas para calcular estadísticas históricas: ",
      paste(faltantes, collapse = ", "),
      call. = FALSE
    )
  }
  if (anyNA(partidos[requeridas])) {
    stop("Existen campos obligatorios vacíos en los partidos.", call. = FALSE)
  }
  if (any(!partidos$outcome %in% c("H", "D", "A"))) {
    stop("outcome solo puede contener H, D o A.", call. = FALSE)
  }
  invisible(partidos)
}

resultado_desde_equipo <- function(partidos, equipo) {
  es_local <- partidos$home_team == equipo
  ifelse(
    partidos$outcome == "D", "D",
    ifelse(
      (es_local & partidos$outcome == "H") |
        (!es_local & partidos$outcome == "A"),
      "W", "L"
    )
  )
}

goles_desde_equipo <- function(partidos, equipo) {
  es_local <- partidos$home_team == equipo
  list(
    favor = ifelse(es_local, partidos$home_score, partidos$away_score),
    contra = ifelse(es_local, partidos$away_score, partidos$home_score)
  )
}

filtrar_partidos_equipo <- function(
    historial, equipo, rol = NULL, fase = NULL, rival = NULL) {
  seleccion <- historial$home_team == equipo | historial$away_team == equipo
  if (!is.null(rol)) {
    if (rol == "home") {
      seleccion <- seleccion & historial$home_team == equipo
    } else if (rol == "away") {
      seleccion <- seleccion & historial$away_team == equipo
    } else {
      stop("rol debe ser 'home', 'away' o NULL.", call. = FALSE)
    }
  }
  if (!is.null(fase)) {
    seleccion <- seleccion & historial$stage == fase
  }
  if (!is.null(rival)) {
    seleccion <- seleccion & (
      historial$home_team == rival | historial$away_team == rival
    )
  }
  historial[seleccion, , drop = FALSE]
}

resumir_rendimiento <- function(partidos, equipo, suavizado = parametros_suavizado) {
  n <- nrow(partidos)
  if (n > 0L) {
    resultados <- resultado_desde_equipo(partidos, equipo)
    goles <- goles_desde_equipo(partidos, equipo)
    victorias <- sum(resultados == "W")
    empates <- sum(resultados == "D")
    derrotas <- sum(resultados == "L")
    goles_favor <- sum(goles$favor)
    goles_contra <- sum(goles$contra)
    puntos <- 3 * victorias + empates
  } else {
    victorias <- empates <- derrotas <- 0
    goles_favor <- goles_contra <- puntos <- 0
  }

  denominador <- n + suavizado$partidos
  list(
    matches = n,
    win_rate = (victorias + suavizado$victorias) / denominador,
    draw_rate = (empates + suavizado$empates) / denominador,
    loss_rate = (derrotas + suavizado$derrotas) / denominador,
    avg_goals_for = (
      goles_favor + suavizado$partidos * suavizado$goles_favor
    ) / denominador,
    avg_goals_against = (
      goles_contra + suavizado$partidos * suavizado$goles_contra
    ) / denominador,
    performance = (
      puntos + suavizado$partidos * suavizado$puntos_por_partido
    ) / (3 * denominador)
  )
}

construir_fila_historica <- function(partido, historial, match_id) {
  local <- partido$home_team[[1]]
  visitante <- partido$away_team[[1]]
  fase <- partido$stage[[1]]

  hist_local <- filtrar_partidos_equipo(historial, local)
  hist_visitante <- filtrar_partidos_equipo(historial, visitante)
  general_local <- resumir_rendimiento(hist_local, local)
  general_visitante <- resumir_rendimiento(hist_visitante, visitante)

  rol_local <- resumir_rendimiento(
    filtrar_partidos_equipo(historial, local, rol = "home"), local
  )
  rol_visitante <- resumir_rendimiento(
    filtrar_partidos_equipo(historial, visitante, rol = "away"), visitante
  )
  fase_local <- resumir_rendimiento(
    filtrar_partidos_equipo(historial, local, fase = fase), local
  )
  fase_visitante <- resumir_rendimiento(
    filtrar_partidos_equipo(historial, visitante, fase = fase), visitante
  )

  h2h_local_partidos <- filtrar_partidos_equipo(
    historial, local, rival = visitante
  )
  h2h_local <- resumir_rendimiento(h2h_local_partidos, local)
  h2h_visitante <- resumir_rendimiento(h2h_local_partidos, visitante)

  recientes_local <- tail(hist_local[order(hist_local$date), , drop = FALSE], 5L)
  recientes_visitante <- tail(
    hist_visitante[order(hist_visitante$date), , drop = FALSE], 5L
  )
  forma_local <- resumir_rendimiento(recientes_local, local)
  forma_visitante <- resumir_rendimiento(recientes_visitante, visitante)

  diferencia_goles_local <-
    general_local$avg_goals_for - general_local$avg_goals_against
  diferencia_goles_visitante <-
    general_visitante$avg_goals_for - general_visitante$avg_goals_against

  data.frame(
    match_id = match_id,
    year = as.integer(partido$year[[1]]),
    date = as.Date(partido$date[[1]]),
    stage = as.character(fase),
    home_team = as.character(local),
    away_team = as.character(visitante),
    outcome = as.character(partido$outcome[[1]]),
    home_previous_matches = general_local$matches,
    home_win_rate = general_local$win_rate,
    home_draw_rate = general_local$draw_rate,
    home_loss_rate = general_local$loss_rate,
    home_avg_goals_for = general_local$avg_goals_for,
    home_avg_goals_against = general_local$avg_goals_against,
    home_avg_goal_difference = diferencia_goles_local,
    home_role_performance = rol_local$performance,
    home_stage_performance = fase_local$performance,
    home_h2h_matches = h2h_local$matches,
    home_head_to_head = h2h_local$performance,
    home_recent_form = forma_local$performance,
    away_previous_matches = general_visitante$matches,
    away_win_rate = general_visitante$win_rate,
    away_draw_rate = general_visitante$draw_rate,
    away_loss_rate = general_visitante$loss_rate,
    away_avg_goals_for = general_visitante$avg_goals_for,
    away_avg_goals_against = general_visitante$avg_goals_against,
    away_avg_goal_difference = diferencia_goles_visitante,
    away_role_performance = rol_visitante$performance,
    away_stage_performance = fase_visitante$performance,
    away_h2h_matches = h2h_visitante$matches,
    away_head_to_head = h2h_visitante$performance,
    away_recent_form = forma_visitante$performance,
    diff_win_rate = general_local$win_rate - general_visitante$win_rate,
    diff_draw_rate = general_local$draw_rate - general_visitante$draw_rate,
    diff_goal_difference =
      diferencia_goles_local - diferencia_goles_visitante,
    diff_recent_form = forma_local$performance - forma_visitante$performance,
    diff_stage_performance =
      fase_local$performance - fase_visitante$performance,
    diff_head_to_head = h2h_local$performance - h2h_visitante$performance,
    stringsAsFactors = FALSE
  )
}

crear_estadisticas_historicas <- function(partidos) {
  validar_partidos_para_features(partidos)
  partidos <- as.data.frame(partidos, stringsAsFactors = FALSE)
  partidos$date <- as.Date(partidos$date)
  orden <- order(partidos$date, seq_len(nrow(partidos)))
  partidos <- partidos[orden, , drop = FALSE]
  rownames(partidos) <- NULL

  filas <- vector("list", nrow(partidos))
  for (i in seq_len(nrow(partidos))) {
    # La comparación estricta impide usar el partido actual o partidos del mismo día.
    historial <- partidos[partidos$date < partidos$date[[i]], , drop = FALSE]
    filas[[i]] <- construir_fila_historica(
      partidos[i, , drop = FALSE], historial, match_id = i
    )
  }

  resultado <- do.call(rbind, filas)
  rownames(resultado) <- NULL
  resultado
}

crear_predictores_partido <- function(
    historial, equipo_local, equipo_visitante, fase, fecha_partido) {
  validar_partidos_para_features(historial)
  fecha_partido <- as.Date(fecha_partido)
  historial$date <- as.Date(historial$date)
  historial_previo <- historial[historial$date < fecha_partido, , drop = FALSE]

  partido <- data.frame(
    year = as.integer(format(fecha_partido, "%Y")),
    stage = as.character(fase),
    home_team = as.character(equipo_local),
    away_team = as.character(equipo_visitante),
    home_score = 0L,
    away_score = 0L,
    outcome = "D",
    date = fecha_partido,
    stringsAsFactors = FALSE
  )

  fila <- construir_fila_historica(partido, historial_previo, match_id = NA_integer_)
  fila[, columnas_predictoras_historicas, drop = FALSE]
}
