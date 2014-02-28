######### Handles data ingestion and translation into standard format #############

# Set source location
setwd("~/Documents/Harvard/Stats/Stat 183/March Madness/stat183_madness")

# Parse data for regular seasons and for tourneys
season.data <- ParseSeasonTeamData("teams.csv", "regular_season_results.csv")
tourney.data <- ParseTourneyTeamData("teams.csv", "tourney_seeds.csv", "tourney_results.csv")

save(season.data, tourney.data, file="./data/teamData.RData")

## Parses season data for a team given .csv files
ParseSeasonTeamData <- function(teamsFile, seasonResultsFile) {
  teams <- read.csv(paste("./data", teamsFile, sep="/"))
  season.results <- read.csv(paste("./data", seasonResultsFile, sep="/"))
  
  n.games <- dim(season.results)[1]
  n.row <- n.games * 2
  
  season.data <- data.frame(id=numeric(n.row), name=numeric(n.row), season=numeric(n.row), 
                            season.id=numeric(n.row), daynum=numeric(n.row), 
                            opp.team=numeric(n.row), opp.name=numeric(n.row), 
                            win=numeric(n.row), score=numeric(n.row), opp.score=numeric(n.row), 
                            loc=numeric(n.row), numot=numeric(n.row))
  
  # Parse the season.results file to fill the rows
  for (i in 1:n.games) {
    print(i)
   
    game <- season.results[i, ] # Current game row
    
    w.id <- game$wteam  # Win team id
    wname.ind <- as.numeric(teams[teams[, 1] == w.id, ][2]) # Index of the team name in the factor
    l.id <- game$lteam  # Lose team id
    lname.ind <- as.numeric(teams[teams[, 1] == l.id, ][2]) # Index of the team name in the factor
    
    season.id <- as.numeric(game$season) # Season index (A=1)
    
    # Winner info
    season.data[2 * (i - 1) + 1, ] <- cbind(w.id, levels(teams$name)[wname.ind], # Find team name
                                            levels(game$season)[season.id], season.id, game$daynum, 
                                            l.id, levels(teams$name)[lname.ind], 1, game$wscore, 
                                            game$lscore, ifelse(game$wloc == "H", "H", "A"), 
                                            game$numot)
    # Loser info
    season.data[2 * i, ] <- cbind(l.id, levels(teams$name)[lname.ind], # Find team name
                                            levels(game$season)[season.id], season.id, game$daynum, 
                                            w.id, levels(teams$name)[wname.ind],0, game$lscore,
                                            game$wscore, ifelse(game$wloc == "A", "H", "A"), 
                                            game$numot)
  }
  
  # Order the data frame by id, season, daynum
  attach(season.data)
  season.data <- season.data[order(id, season, daynum), ]
  
  season.data
}


## Parses tourney data for a team given .csv files
ParseTourneyTeamData <- function(teamsFile, seedsFile, tourneyResultsFile) {
  teams <- read.csv(paste("./data", teamsFile, sep="/"))
  seeds <- read.csv(paste("./data", seedsFile, sep="/"))
  tourney.results <- read.csv(paste("./data", tourneyResultsFile, sep="/"))
  
  n.games <- dim(tourney.results)[1]
  n.row <- n.games * 2
  
  tourney.data <- data.frame(id=numeric(n.row), name=numeric(n.row), season=numeric(n.row), 
                            season.id=numeric(n.row), seed=numeric(n.row), daynum=numeric(n.row), 
                            opp.team=numeric(n.row), opp.name=numeric(n.row), 
                            win=numeric(n.row), score=numeric(n.row), opp.score=numeric(n.row), 
                            numot=numeric(n.row))
  
  # Parse the season.results file to fill the rows
  for (i in 1:n.games) {
    print(i)
    
    game <- tourney.results[i, ] # Current game row
    
    w.id <- game$wteam  # Win team id
    wname.ind <- as.numeric(teams[teams[, 1] == w.id, ][2]) # Index of the team name in the factor
    l.id <- game$lteam  # Lose team id
    lname.ind <- as.numeric(teams[teams[, 1] == l.id, ][2]) # Index of the team name in the factor
    
    season.id <- as.numeric(game$season) # Season index (A=1)
    
    wseed.ind <- as.numeric(seeds[seeds$team == w.id & seeds$season == game$season, ][2])
    w.seed <- levels(seeds$seed)[wseed.ind]
    lseed.ind <- as.numeric(seeds[seeds$team == l.id & seeds$season == game$season, ][2])
    l.seed <- levels(seeds$seed)[lseed.ind]
    
    # Winner info
    tourney.data[2 * (i - 1) + 1, ] <- cbind(w.id, levels(teams$name)[wname.ind], # Find team name
                                            levels(game$season)[season.id], season.id, w.seed, 
                                            game$daynum, l.id, levels(teams$name)[lname.ind], 1, 
                                            game$wscore, game$lscore, game$numot)
    # Loser info
    tourney.data[2 * i, ] <- cbind(l.id, levels(teams$name)[lname.ind], # Find team name
                                            levels(game$season)[season.id], season.id, l.seed, 
                                            game$daynum, w.id, levels(teams$name)[wname.ind], 0, 
                                            game$lscore, game$wscore, game$numot)
  }
  
  # Order the data frame by id, season, daynum
  attach(tourney.data)
  tourney.data <- tourney.data[order(id, season, daynum), ]
  
  tourney.data
}
