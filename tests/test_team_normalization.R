source(file.path("R", "team_normalization.R"))

mapeo <- cargar_mapeo_equipos()

# Los datasets crudos del pipeline deben tener todos sus equipos declarados.
historicos <- read.csv(
  file.path("data", "raw", "wcmatches.csv"),
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)
mundiales <- read.csv(
  file.path("data", "raw", "worldcups.csv"),
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)
if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Falta el paquete 'readxl' para validar el dataset crudo reciente.", call. = FALSE)
}
recientes <- as.data.frame(readxl::read_excel(
  file.path("data", "raw", "datos 2022 y 2026.xlsx"),
  sheet = "Partidos 2022 y 2026", na = c("", "NA")
), stringsAsFactors = FALSE)
stopifnot(isTRUE(validar_nombres_mapeados(
  list(historicos = historicos, mundiales = mundiales, recientes = recientes),
  mapeo,
  ruta_reporte = tempfile(fileext = ".csv")
)))

# Una entrada sin equivalencia genera el CSV y detiene el proceso.
ruta_reporte <- tempfile(fileext = ".csv")
error_no_mapeado <- try(validar_nombres_mapeados(
  list(prueba = data.frame(home_team = "Equipo desconocido", stringsAsFactors = FALSE)),
  mapeo,
  ruta_reporte = ruta_reporte
), silent = TRUE)
stopifnot(inherits(error_no_mapeado, "try-error"))
stopifnot(file.exists(ruta_reporte))
reporte <- read.csv(ruta_reporte, stringsAsFactors = FALSE)
stopifnot(identical(reporte$nombre_no_mapeado, "Equipo desconocido"))

cat("OK: todos los equipos crudos están mapeados y los no mapeados detienen el pipeline.\n")
