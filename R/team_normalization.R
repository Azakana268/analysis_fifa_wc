# Utilidades para normalizar nombres de selecciones de forma centralizada.
# Todo nombre no vacío debe existir en el mapeo antes de continuar el pipeline.

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

obtener_nombres_no_mapeados <- function(
    datos,
    mapeo,
    columnas = columnas_equipos,
    origen = NA_character_) {
  if (!is.data.frame(datos)) {
    stop("'datos' debe ser un data.frame.", call. = FALSE)
  }

  presentes <- intersect(columnas, names(datos))
  hallazgos <- lapply(presentes, function(columna) {
    valores <- trimws(as.character(datos[[columna]]))
    valores <- sort(unique(valores[!is.na(valores) & valores != ""]))
    desconocidos <- setdiff(valores, mapeo$source_name)
    if (length(desconocidos) == 0L) {
      return(NULL)
    }
    data.frame(
      origen = origen,
      columna = columna,
      nombre_no_mapeado = desconocidos,
      stringsAsFactors = FALSE
    )
  })

  hallazgos <- Filter(Negate(is.null), hallazgos)
  if (length(hallazgos) == 0L) {
    return(data.frame(
      origen = character(), columna = character(),
      nombre_no_mapeado = character(), stringsAsFactors = FALSE
    ))
  }
  unique(do.call(rbind, hallazgos))
}

validar_nombres_mapeados <- function(
    conjuntos,
    mapeo,
    ruta_reporte = file.path("output", "unmapped_team_names.csv"),
    columnas = columnas_equipos) {
  if (!is.list(conjuntos) || length(conjuntos) == 0L) {
    stop("'conjuntos' debe ser una lista no vacía de data.frames.", call. = FALSE)
  }
  if (is.null(names(conjuntos)) || any(names(conjuntos) == "")) {
    names(conjuntos) <- paste0("dataset_", seq_along(conjuntos))
  }

  no_mapeados <- Map(
    function(datos, origen) obtener_nombres_no_mapeados(
      datos, mapeo, columnas = columnas, origen = origen
    ),
    conjuntos, names(conjuntos)
  )
  no_mapeados <- Filter(function(x) nrow(x) > 0L, no_mapeados)

  if (length(no_mapeados) == 0L) {
    if (file.exists(ruta_reporte)) {
      unlink(ruta_reporte)
    }
    return(invisible(TRUE))
  }

  reporte <- unique(do.call(rbind, no_mapeados))
  reporte <- reporte[order(reporte$origen, reporte$columna, reporte$nombre_no_mapeado), ]
  directorio <- dirname(ruta_reporte)
  if (!dir.exists(directorio)) {
    dir.create(directorio, recursive = TRUE)
  }
  write.csv(reporte, ruta_reporte, row.names = FALSE, fileEncoding = "UTF-8")

  stop(
    "Se encontraron nombres de equipos sin mapear. Se escribió el reporte en: ",
    ruta_reporte,
    ". Corrija data/reference/team_name_mapping.csv antes de continuar.",
    call. = FALSE
  )
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

