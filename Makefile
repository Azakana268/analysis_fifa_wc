.PHONY: all load clean eda model report test predict

all: load clean eda model report

load:
	Rscript R/load.R

clean:
	Rscript R/clean.R

eda:
	Rscript R/eda.R

model:
	Rscript R/modeling.R

report:
	Rscript -e "rmarkdown::render('report/mini-proyecto.Rmd')"

test:
	Rscript tests/test_team_normalization.R
	Rscript tests/test_recent_data.R
	Rscript R/clean.R
	Rscript tests/test_historical_features.R
	Rscript R/modeling.R
	Rscript tests/test_prediction.R

predict:
	Rscript R/clean.R
	Rscript R/modeling.R
	Rscript -e "source('R/prediction.R'); print(predecir_partido('Spain', 'Argentina', 'Final', as.Date('2026-07-19')))"
