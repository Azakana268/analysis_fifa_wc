library(dplyr)
library(tidyverse)

worldcups <- read.csv("data/raw/worldcups.csv")
wcmatches_historicos <- read.csv(
  "data/raw/wcmatches.csv",
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)

source(file.path("R", "recent_data.R"))
wcmatches_recientes <- cargar_partidos_recientes()
wcmatches <- combinar_partidos(wcmatches_historicos, wcmatches_recientes)

source(file.path("R", "team_normalization.R"))
mapeo_equipos <- cargar_mapeo_equipos()
validar_nombres_mapeados(
  list(
    worldcups_raw = worldcups,
    wcmatches_historicos_raw = wcmatches_historicos,
    wcmatches_recientes_raw = wcmatches_recientes
  ),
  mapeo_equipos
)
worldcups <- normalizar_columnas_equipos(worldcups, mapeo_equipos)
wcmatches <- normalizar_columnas_equipos(wcmatches, mapeo_equipos)

source(file.path("R", "historical_features.R"))
match_features <- crear_estadisticas_historicas(wcmatches)

head(worldcups)

worldcups <- worldcups %>% mutate(
  goals_per_game = goals_scored / games,
  attendance_per_game = attendance / games
)

wcmatches <- wcmatches %>% mutate(
  goals_per_match = home_score + away_score,
  empate = outcome == "D",
  win_conditions = ifelse(
    is.na(win_conditions), "Regular", win_conditions
  ),
  stage_type = case_when(
    grepl("Group", stage) ~ "Group Stage",
    stage == "Final" ~ "Final",
    TRUE ~ "Knockout"
  )
)

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
saveRDS(worldcups, "data/processed/worldcups.rds")
saveRDS(wcmatches, "data/processed/wcmatches.rds")
saveRDS(match_features, "data/processed/match_features.rds")
