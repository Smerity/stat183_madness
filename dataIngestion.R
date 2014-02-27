######### Handles data ingestion and translation into standard format #############

# Set source location
setwd("~/Documents/Harvard/Stats/Stat 183/March Madness/stat183_madness")

parseTeam <- function(teamsFile, seedsFile, tourneyResultsFile, seasonResultsFile) {
  teams <- read.csv(paste("./data",teamsFile, sep="/"))
  tourney.seeds <- read.csv(paste("./data",seedsFile, sep="/"))
  tourney.results <- read.csv(paste("./data",tourneyResultsFile, sep="/"))
  season.results <- read.csv(paste("./data",seasonResultsFile, sep="/"))
}
