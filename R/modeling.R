library(nnet)

source(file.path("R", "historical_features.R"))

ruta_features <- file.path("data", "processed", "match_features.rds")
if (!file.exists(ruta_features)) {
  stop(
    "No existe match_features.rds. Ejecute primero: Rscript R/clean.R",
    call. = FALSE
  )
}

features <- readRDS(ruta_features)
features$date <- as.Date(features$date)
features <- features[order(features$date, features$match_id), , drop = FALSE]

prohibidas <- c(
  "home_score", "away_score", "goals_per_match",
  "winning_team", "losing_team", "outcome"
)
if (any(columnas_predictoras_historicas %in% prohibidas)) {
  stop("La lista de predictores contiene información posterior al partido.", call. = FALSE)
}

fechas <- sort(unique(features$date))
if (length(fechas) < 2L) {
  stop("No hay suficientes fechas para una división temporal.", call. = FALSE)
}
indice_corte <- max(1L, floor(0.8 * length(fechas)))
fecha_corte <- fechas[[indice_corte]]

train <- features[features$date <= fecha_corte, , drop = FALSE]
test <- features[features$date > fecha_corte, , drop = FALSE]
if (nrow(test) == 0L) {
  stop("La división temporal dejó el conjunto de prueba vacío.", call. = FALSE)
}

predictores_activos <- columnas_predictoras_historicas[vapply(
  train[, columnas_predictoras_historicas, drop = FALSE],
  function(x) length(unique(x)) > 1L,
  logical(1)
)]

x_train <- train[, predictores_activos, drop = FALSE]
x_test <- test[, predictores_activos, drop = FALSE]
y_train <- factor(train$outcome, levels = c("H", "D", "A"))
y_test <- factor(test$outcome, levels = c("H", "D", "A"))

if (anyNA(y_train) || length(unique(y_train)) < 3L) {
  stop("El entrenamiento necesita ejemplos de H, D y A.", call. = FALSE)
}

datos_train <- data.frame(outcome = y_train, x_train, check.names = FALSE)
set.seed(123)
modelo <- nnet::multinom(
  outcome ~ .,
  data = datos_train,
  trace = FALSE,
  maxit = 1000,
  MaxNWts = 10000
)

predicciones <- predict(modelo, newdata = x_test, type = "class")
accuracy <- mean(predicciones == y_test)

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
saveRDS(
  list(
    modelo = modelo,
    predictores = predictores_activos,
    niveles_resultado = c("H", "D", "A"),
    fecha_corte = fecha_corte,
    fecha_maxima_entrenamiento = max(train$date),
    filas_entrenamiento = nrow(train),
    filas_prueba = nrow(test),
    accuracy_prueba = accuracy
  ),
  file.path("data", "processed", "modelo_prediccion.rds")
)

cat("División temporal\n")
cat("Entrenamiento hasta:", format(max(train$date)), "\n")
cat("Prueba desde:", format(min(test$date)), "\n")
cat("Filas de entrenamiento:", nrow(train), "\n")
cat("Filas de prueba:", nrow(test), "\n")
cat("Accuracy temporal:", sprintf("%.2f%%", 100 * accuracy), "\n")
