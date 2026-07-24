source(file.path("R", "historical_features.R"))

partidos <- data.frame(
  year = c(2020L, 2020L, 2020L, 2020L),
  stage = c("Group A", "Group A", "Group A", "Final"),
  home_team = c("A", "C", "A", "B"),
  away_team = c("B", "A", "C", "A"),
  home_score = c(2L, 0L, 1L, 0L),
  away_score = c(0L, 1L, 1L, 3L),
  outcome = c("H", "A", "D", "A"),
  date = as.Date(c("2020-01-01", "2020-01-01", "2020-01-02", "2020-01-10")),
  stringsAsFactors = FALSE
)

features <- crear_estadisticas_historicas(partidos)

# Los dos partidos de la misma fecha no pueden utilizarse entre sí.
stopifnot(features$home_previous_matches[[1]] == 0L)
stopifnot(features$away_previous_matches[[1]] == 0L)
stopifnot(features$home_previous_matches[[2]] == 0L)
stopifnot(features$away_previous_matches[[2]] == 0L)

# En la fecha siguiente, A sí tiene sus dos partidos anteriores disponibles.
stopifnot(features$home_previous_matches[[3]] == 2L)
stopifnot(features$away_previous_matches[[3]] == 1L)

# Cambiar el marcador y resultado del propio partido no cambia sus predictores.
alterados <- partidos
alterados$home_score[[3]] <- 8L
alterados$away_score[[3]] <- 0L
alterados$outcome[[3]] <- "H"
features_alterados <- crear_estadisticas_historicas(alterados)
stopifnot(isTRUE(all.equal(
  features[3, columnas_predictoras_historicas],
  features_alterados[3, columnas_predictoras_historicas],
  check.attributes = FALSE
)))

# Las diferencias deben ser local menos visitante.
stopifnot(isTRUE(all.equal(
  features$diff_win_rate,
  features$home_win_rate - features$away_win_rate
)))
stopifnot(isTRUE(all.equal(
  features$diff_goal_difference,
  features$home_avg_goal_difference - features$away_avg_goal_difference
)))

prohibidas <- c(
  "home_score", "away_score", "goals_per_match",
  "winning_team", "losing_team", "outcome"
)
stopifnot(!any(columnas_predictoras_historicas %in% prohibidas))

numericas <- vapply(features, is.numeric, logical(1))
stopifnot(!anyNA(features[, numericas, drop = FALSE]))
stopifnot(all(vapply(
  features[, numericas, drop = FALSE],
  function(x) all(is.finite(x)),
  logical(1)
)))
stopifnot(all(diff(features$date) >= 0))

cat("OK: estadísticas históricas calculadas sin fuga de información.\n")
