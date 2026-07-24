source(file.path("R", "recent_data.R"))

recientes <- cargar_partidos_recientes()
historicos <- read.csv(
  file.path("data", "raw", "wcmatches.csv"),
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)
combinados <- combinar_partidos(historicos, recientes)

stopifnot(nrow(recientes) == 168L)
stopifnot(sum(recientes$year == 2022L) == 64L)
stopifnot(sum(recientes$year == 2026L) == 104L)
stopifnot(nrow(combinados) == nrow(historicos) + 168L)
stopifnot(!anyDuplicated(paste(
  combinados$date, combinados$home_team, combinados$away_team, sep = "|"
)))
stopifnot(max(recientes$date) == as.Date("2026-07-19"))

final <- recientes[
  recientes$date == as.Date("2026-07-19") &
    recientes$home_team == "Spain" &
    recientes$away_team == "Argentina",
  ,
  drop = FALSE
]
stopifnot(nrow(final) == 1L)
stopifnot(final$home_score[[1]] == 1L)
stopifnot(final$away_score[[1]] == 0L)
stopifnot(final$outcome[[1]] == "H")
stopifnot(final$winning_team[[1]] == "Spain")
stopifnot(final$losing_team[[1]] == "Argentina")
stopifnot(grepl("extra time", final$win_conditions[[1]], fixed = TRUE))

cat("OK: 168 partidos recientes, incluida la final 2026, validados sin duplicados.\n")
