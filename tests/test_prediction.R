archivos_requeridos <- c(
  file.path("data", "processed", "wcmatches.rds"),
  file.path("data", "processed", "match_features.rds"),
  file.path("data", "processed", "modelo_prediccion.rds")
)
if (any(!file.exists(archivos_requeridos))) {
  stop(
    "Faltan archivos procesados. Ejecute Rscript R/clean.R y Rscript R/modeling.R.",
    call. = FALSE
  )
}

source(file.path("R", "prediction.R"))

resultado <- predecir_partido(
  equipo_local = "Spain",
  equipo_visitante = "Argentina",
  fase = "Final",
  fecha_partido = as.Date("2026-07-19")
)

stopifnot(inherits(resultado, "prediccion_partido"))
stopifnot(length(resultado$probabilidades) == 3L)
stopifnot(all(is.finite(resultado$probabilidades)))
stopifnot(all(resultado$probabilidades >= 0))
stopifnot(all(resultado$probabilidades <= 100))
stopifnot(abs(sum(resultado$probabilidades) - 100) < 1e-6)

error_iguales <- try(
  predecir_partido("Spain", "Spain", "Final", as.Date("2026-07-19")),
  silent = TRUE
)
stopifnot(inherits(error_iguales, "try-error"))

error_fecha <- try(
  predecir_partido("Spain", "Argentina", "Final", "fecha-invalida"),
  silent = TRUE
)
stopifnot(inherits(error_fecha, "try-error"))

error_equipo <- try(
  predecir_partido("Equipo inexistente", "Argentina", "Final", as.Date("2026-07-19")),
  silent = TRUE
)
stopifnot(inherits(error_equipo, "try-error"))

print(resultado)
cat("OK: predicción validada con tres probabilidades que suman 100%.\n")
