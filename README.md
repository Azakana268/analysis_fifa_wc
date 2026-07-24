# FIFA World Cup Analysis (1930–2026)

Análisis exploratorio y modelo predictivo de partidos de la Copa Mundial FIFA. El
proyecto combina los datos históricos de 1930–2018 con los 64 partidos de 2022 y los
104 partidos finalizados de 2026.

## Datos

- Histórico 1930–2018: [FIFA World Cup en Kaggle](https://www.kaggle.com/datasets/evangower/fifa-world-cup).
- Resultados 2022 y 2026: FIFA y `openfootball/worldcup.json`.
- Final 2026: España 1–0 Argentina después de tiempo extra, verificada con el informe
  oficial de FIFA del 19-07-2026.

Archivos de entrada:

- `data/raw/worldcups.csv`
- `data/raw/wcmatches.csv`
- `data/raw/datos 2022 y 2026.xlsx`

El Excel contiene 168 partidos: 64 de 2022 y 104 de 2026. Sus hojas `Resumen`,
`Fuentes` y `Diccionario` documentan cobertura, procedencia y transformaciones. El CSV
histórico se conserva intacto; `R/recent_data.R` valida y combina los registros en
memoria.

## Normalización de selecciones

`R/team_normalization.R` aplica equivalencias centralizadas a las columnas de equipos
que existan. El archivo `data/reference/team_name_mapping.csv` mantiene cada nombre
alternativo, nombre canónico y justificación. Los nombres desconocidos se conservan en
vez de convertirse silenciosamente en `NA`.

Entre las equivalencias documentadas se incluyen `USA` → `United States`, `IR Iran` →
`Iran`, `Korea Republic` → `South Korea` y `Germany FR` → `Germany`. Las continuidades
históricas discutibles se identifican como simplificaciones estadísticas y no como
equivalencias políticas.

## Corrección de fuga de información

El modelo anterior utilizaba `home_score`, `away_score` y `goals_per_match` del mismo
encuentro y dividía los datos aleatoriamente. Eso permitía conocer información producida
después del partido.

`R/historical_features.R` corrige el problema usando únicamente encuentros con:

```r
date < fecha_partido
```

Los predictores incluyen partidos anteriores, tasas suavizadas de victoria/empate/
derrota, goles a favor y en contra, diferencia de goles, rendimiento por localía,
rendimiento por fase, enfrentamientos directos y forma de los últimos cinco partidos.
También se calculan diferencias entre el equipo local y el visitante.

Para selecciones con pocos antecedentes se aplican cuatro partidos neutrales de
suavizado. Estos valores son fijos y no utilizan resultados futuros.

## Modelo predictivo

`R/modeling.R` entrena una regresión logística multinomial para predecir:

- `H`: victoria local.
- `D`: empate.
- `A`: victoria visitante.

La evaluación es cronológica: las primeras fechas se destinan al entrenamiento y las
últimas a prueba. El modelo no utiliza marcadores, ganador, perdedor ni outcome del
partido evaluado como predictores.

## Requisitos

- R >= 4.1.0
- GNU Make, opcional
- Paquetes: `tidyverse`, `readxl`, `nnet`, `MASS`, `glmnet`, `caret`, `rmarkdown`

```r
install.packages(c(
  "tidyverse", "readxl", "nnet", "MASS", "glmnet", "caret", "rmarkdown"
))
```

## Ejecución

Pipeline completo:

```bash
make all
```

Pruebas completas:

```bash
make test
```

Ejemplo de predicción:

```bash
make predict
```

Sin Make:

```bash
Rscript R/clean.R
Rscript R/modeling.R
Rscript -e "source('R/prediction.R'); print(predecir_partido('Spain', 'Argentina', 'Final', as.Date('2026-07-19')))"
```

Desde R:

```r
source("R/clean.R")
source("R/modeling.R")
source("R/prediction.R")

predecir_partido(
  equipo_local = "Spain",
  equipo_visitante = "Argentina",
  fase = "Final",
  fecha_partido = as.Date("2026-07-19")
)
```

La salida muestra los nombres normalizados, fase, fecha y probabilidades porcentuales
de `H`, `D` y `A`. Las tres probabilidades suman aproximadamente 100%. Es una estimación
basada en datos históricos y no garantiza el resultado real.

## Pruebas

Las pruebas verifican:

- Normalización y conservación de nombres desconocidos.
- Incorporación de 168 partidos sin duplicados y presencia de la final 2026.
- Exclusión del propio partido y de partidos de la misma fecha.
- Ausencia de marcadores finales entre los predictores.
- Estadísticas históricas y diferencias local–visitante.
- Equipos inexistentes, equipos iguales y fechas inválidas.
- Tres probabilidades finitas, entre 0 y 100, cuya suma es 100%.
- Ejecución de España contra Argentina.

## Targets de Make

| Target | Descripción |
|---|---|
| `make all` | Ejecuta carga, limpieza, EDA, modelo e informe |
| `make load` | Inspecciona los datos crudos |
| `make clean` | Valida, combina, normaliza y genera archivos procesados |
| `make eda` | Genera gráficos exploratorios |
| `make model` | Entrena y evalúa cronológicamente el modelo |
| `make report` | Renderiza el informe HTML |
| `make test` | Ejecuta todas las pruebas reproducibles |
| `make predict` | Ejecuta el ejemplo España–Argentina |

## Limitaciones

- Los mundiales tienen pocos partidos comparados con ligas regulares.
- Las plantillas, lesiones, entrenadores y condiciones del día no están modelados.
- Las equivalencias históricas simplifican cambios geopolíticos complejos.
- Los antecedentes más antiguos pueden representar estilos de juego diferentes.
- Una probabilidad alta no asegura que el resultado ocurra.

## Uso de inteligencia artificial

Se utilizó inteligencia artificial como apoyo para revisión, depuración, explicación y
documentación. El estudiante revisó los archivos, debe ejecutar las pruebas, comprender
los cambios y poder justificar todas las decisiones entregadas.
