# Utilidades para normalizar nombres de selecciones de forma centralizada.
# Los nombres que no aparecen en el mapeo se conservan sin cambios.

columnas_equipos <- c(
  "home_team", "away_team", "winning_team", "losing_team",
  "winner", "second", "third", "fourth"
)

cargar_mapeo_equipos <- function(
    ruta = file.path("data", "reference", "team_name_mapping.csv")) {
  if (!file.exists(ruta)) {
    stop("No se encontró el archivo de equivalencias: ", ruta, call. = FALSE)
  }

  mapeo <- read.csv(
    ruta,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    check.names = FALSE
  )

  requeridas <- c("source_name", "standardized_name", "justification")
  faltantes <- setdiff(requeridas, names(mapeo))
  if (length(faltantes) > 0L) {
    stop(
      "Faltan columnas obligatorias en el mapeo: ",
      paste(faltantes, collapse = ", "),
      call. = FALSE
    )
  }

  mapeo$source_name <- trimws(mapeo$source_name)
  mapeo$standardized_name <- trimws(mapeo$standardized_name)

  if (anyNA(mapeo$source_name) || any(mapeo$source_name == "")) {
    stop("El mapeo contiene nombres de origen vacíos.", call. = FALSE)
  }
  if (anyNA(mapeo$standardized_name) || any(mapeo$standardized_name == "")) {
    stop("El mapeo contiene nombres normalizados vacíos.", call. = FALSE)
  }
  if (anyDuplicated(mapeo$source_name)) {
    duplicados <- unique(mapeo$source_name[duplicated(mapeo$source_name)])
    stop(
      "El mapeo contiene nombres de origen duplicados: ",
      paste(duplicados, collapse = ", "),
      call. = FALSE
    )
  }

  mapeo
}

normalizar_nombre_equipo <- function(nombre, mapeo, advertir_desconocidos = FALSE) {
  if (!is.character(nombre)) {
    nombre <- as.character(nombre)
  }

  limpio <- trimws(nombre)
  posiciones <- match(limpio, mapeo$source_name)
  resultado <- limpio
  encontrados <- !is.na(posiciones) & !is.na(limpio)
  resultado[encontrados] <- mapeo$standardized_name[posiciones[encontrados]]

  if (isTRUE(advertir_desconocidos)) {
    desconocidos <- sort(unique(limpio[!encontrados & !is.na(limpio) & limpio != ""]))
    if (length(desconocidos) > 0L) {
      warning(
        "Nombres sin equivalencia; se conservaron sin cambios: ",
        paste(desconocidos, collapse = ", "),
        call. = FALSE
      )
    }
  }

  resultado[is.na(nombre)] <- NA_character_
  resultado
}

normalizar_columnas_equipos <- function(
    datos,
    mapeo,
    columnas = columnas_equipos,
    advertir_desconocidos = FALSE) {
  if (!is.data.frame(datos)) {
    stop("'datos' debe ser un data.frame.", call. = FALSE)
  }

  presentes <- intersect(columnas, names(datos))
  for (columna in presentes) {
    datos[[columna]] <- normalizar_nombre_equipo(
      datos[[columna]],
      mapeo,
      advertir_desconocidos = advertir_desconocidos
    )
  }

  datos
}
