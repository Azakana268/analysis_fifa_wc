library(dplyr)
library(tidyverse)

worldcups <- read.csv("data/raw/worldcups.csv")
wcmatches <- read.csv("data/raw/wcmatches.csv")

source(file.path("R", "team_normalization.R"))
mapeo_equipos <- cargar_mapeo_equipos()
worldcups <- normalizar_columnas_equipos(worldcups, mapeo_equipos)
wcmatches <- normalizar_columnas_equipos(wcmatches, mapeo_equipos)

head(worldcups)

worldcups <- worldcups %>% mutate(
  goals_per_game = goals_scored / games,
  attendance_per_game = attendance / games
)

#wcmatches[wcmatches$outcome == "D", ]

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

saveRDS(worldcups, "data/processed/worldcups.rds")
saveRDS(wcmatches, "data/processed/wcmatches.rds")
