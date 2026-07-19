source(file.path("R", "recent_data.R"))

recientes <- cargar_partidos_recientes()
historicos <- read.csv(
  file.path("data", "raw", "wcmatches.csv"),
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)
combinados <- combinar_partidos(historicos, recientes)

stopifnot(nrow(recientes) == 167L)
stopifnot(sum(recientes$year == 2022L) == 64L)
stopifnot(sum(recientes$year == 2026L) == 103L)
stopifnot(nrow(combinados) == nrow(historicos) + 167L)
stopifnot(!anyDuplicated(paste(
  combinados$date, combinados$home_team, combinados$away_team, sep = "|"
)))
stopifnot(max(recientes$date) == as.Date("2026-07-18"))
stopifnot(!any(
  recientes$date == as.Date("2026-07-19") &
    recientes$home_team == "Spain" &
    recientes$away_team == "Argentina"
))

cat("OK: 167 partidos recientes validados e incorporados sin duplicados.\n")
