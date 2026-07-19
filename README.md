# FIFA World Cup Analysis (1930–2026)

Análisis exploratorio y modelado predictivo sobre datos históricos de la Copa del
Mundo FIFA.

## Dataset

- Datos históricos 1930–2018: [FIFA World Cup, Kaggle](https://www.kaggle.com/datasets/evangower/fifa-world-cup).
- Resultados 2022: FIFA y `openfootball/worldcup.json`.
- Resultados 2026 disponibles: FIFA y `openfootball/worldcup.json`.
- Archivos: `worldcups.csv`, `wcmatches.csv` y `datos 2022 y 2026.xlsx`.

El Excel incorpora 64 partidos de 2022 y 103 partidos finalizados de 2026 hasta el
18-07-2026. La final del 19-07-2026 no se incluye porque no tenía resultado final al
preparar el archivo. Las fuentes, cobertura y transformaciones están documentadas
dentro del propio libro.

`wcmatches.csv` conserva intactos los datos originales. Durante la limpieza,
`R/recent_data.R` valida las 15 columnas del Excel, rechaza duplicados o resultados
incoherentes y combina los 167 registros nuevos en memoria. El resultado consolidado
se guarda en `data/processed/wcmatches.rds`.

## Requisitos

- R (>= 4.1.0)
- Paquetes: `tidyverse`, `readxl`, `nnet`, `MASS`, `glmnet`, `caret`

```r
install.packages(c("tidyverse", "readxl", "nnet", "MASS", "glmnet", "caret"))
```

## Estructura del proyecto

```text
fifa-worldcup-analysis/
├── R/
│   ├── load.R
│   ├── clean.R
│   ├── recent_data.R
│   ├── team_normalization.R
│   ├── eda.R
│   ├── modeling.R
│   └── utils.R
├── data/
│   ├── raw/
│   │   └── datos 2022 y 2026.xlsx
│   ├── reference/
│   └── processed/
├── tests/
│   ├── test_team_normalization.R
│   └── test_recent_data.R
├── output/plots/
├── report/
├── Makefile
├── README.md
└── .gitignore
```

## Uso

Instalar las dependencias una vez y ejecutar:

```bash
make all
```

En Windows, si `make` no está disponible, la incorporación de datos puede probarse
directamente con:

```bash
Rscript tests/test_recent_data.R
Rscript R/clean.R
```

### Targets disponibles

| Target | Descripción |
|---|---|
| `make all` | Ejecuta el pipeline completo |
| `make load` | Carga datos |
| `make clean` | Limpia, incorpora y guarda datos procesados |
| `make eda` | Ejecuta el análisis exploratorio |
| `make model` | Ejecuta el modelado |
| `make report` | Renderiza el informe |

El reporte se almacena en el directorio `report` con formato HTML.
