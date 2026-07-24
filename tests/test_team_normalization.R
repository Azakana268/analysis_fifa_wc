source(file.path("R", "team_normalization.R"))

mapeo <- cargar_mapeo_equipos()

entrada <- c(" USA ", "IR Iran", "Korea Republic", "Equipo desconocido", NA)
esperado <- c("United States", "Iran", "South Korea", "Equipo desconocido", NA)
resultado <- normalizar_nombre_equipo(entrada, mapeo)
stopifnot(identical(resultado, esperado))

datos <- data.frame(
  home_team = c("USA", "Côte d'Ivoire"),
  away_team = c("Germany FR", "Equipo desconocido"),
  winning_team = c("USA", NA),
  otra_columna = c(1, 2),
  stringsAsFactors = FALSE
)

normalizados <- normalizar_columnas_equipos(datos, mapeo)
stopifnot(identical(normalizados$home_team, c("United States", "Ivory Coast")))
stopifnot(identical(normalizados$away_team, c("Germany", "Equipo desconocido")))
stopifnot(identical(normalizados$winning_team, c("United States", NA_character_)))
stopifnot(identical(normalizados$otra_columna, datos$otra_columna))

cat("OK: todas las pruebas de normalización pasaron.\n")
