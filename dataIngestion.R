######### Handles data ingestion and translation into standard format #############

# Set source location
setwd("~/Documents/Harvard/Stats/Stat 183/March Madness/stat183_madness")

# Parse data for regular seasons and for tourneys
tourney.data <- ParseTourneyTeamData("teams.csv", "tourney_seeds.csv", "tourney_results.csv")
season.data <- ParseSeasonTeamData("teams.csv", "regular_season_results.csv")

save(season.data, tourney.data, file="./data/teamData.RData")


# Parse metrics data for chessmetrics and rpi
metric.data <- ParseTeamMetricsData("teams.csv", "chessmetrics.csv", "rpi.csv")

save(metric.data, file="./data/metricData.RData")


# Parse ordinal metrics
coreord.data <- ParseCoreOrdMetricsData("teams.csv", "ordinal_ranks_core_33.csv")
noncoreord.data <- ParseNonCoreOrdMetricsData("teams.csv", "ordinal_ranks_non_core.csv")

save(coreord.data, noncoreord.data, file="./data/ordmetricData.RData")


# Parse school stats from sportsreference
school.stats <- ParseSchoolStats(c("1997-98.csv", "1998-99.csv", "1999-00.csv", "2000-01.csv", # File list must be given in order
                                   "2001-02.csv", "2002-03.csv", "2003-04.csv", "2004-05.csv",
                                   "2005-06.csv", "2006-07.csv", "2007-08.csv", "2008-09.csv",
                                   "2009-10.csv", "2010-11.csv", "2011-12.csv", "2012-13.csv",
                                   "2013-14.csv"), "teams.csv")

save(school.stats, file="./data/schoolstatsData.RData")


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
                                            w.id, levels(teams$name)[wname.ind], 0, game$lscore,
                                            game$wscore, ifelse(game$wloc == "A", "H", "A"), 
                                            game$numot)
  }
  
  # Convert columns to numeric
  season.data$id <- as.numeric(season.data$id)
  season.data$season.id <- as.numeric(season.data$season.id)
  season.data$daynum <- as.numeric(season.data$daynum)
  season.data$win <- as.numeric(season.data$win)
  season.data$score <- as.numeric(season.data$score)
  season.data$opp.score <- as.numeric(season.data$opp.score)
  
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
  
  # Convert columns to numeric
  tourney.data$id <- as.numeric(tourney.data$id)
  tourney.data$season.id <- as.numeric(tourney.data$season.id)
  tourney.data$daynum <- as.numeric(tourney.data$daynum)
  tourney.data$win <- as.numeric(tourney.data$win)
  tourney.data$score <- as.numeric(tourney.data$score)
  tourney.data$opp.score <- as.numeric(tourney.data$opp.score)
  
  # Order the data frame by id, season, daynum
  attach(tourney.data)
  tourney.data <- tourney.data[order(id, season, daynum), ]
  
  tourney.data
}


## Parses team metrics from csv files
ParseTeamMetricsData <- function(teamsFile, chessmetricFile, rpiFile) {
  
  teams <- read.csv(paste("./data", teamsFile, sep="/"))
  chessmetric <- read.csv(paste("./data", chessmetricFile, sep="/"))
  rpi <- read.csv(paste("./data", rpiFile, sep="/"))
  
  # Order chess and rpi data frame so that rows match
  attach(chessmetric)
  chessmetric <- chessmetric[order(team, season, rating_day_num), ]
  attach(rpi)
  rpi <- rpi[order(team, season, rating_day_num), ]
  
  # Check if row correspond
  print("Rows match checking...")
  rows.match <- (chessmetric$team == rpi$team) && (chessmetric$season == rpi$season) &&
    (chessmetric$rating_day_num == rpi$rating_day_num) 
  print(rows.match)
  
  # Compute additional columns
  id <- chessmetric$team
  seasons.id <- as.numeric(chessmetric$season) # Season index (A=1)
  seasons <- levels(chessmetric$season)[seasons.id]
  colnames(teams) <- c("team", "name")
  chessmetric <- merge(chessmetric, teams)
  
  # Combine relevant columns
  metric.data <- data.frame(id=id, name=levels(teams$name)[chessmetric$name], # Find team name
                                  season=seasons, season.id=seasons.id,
                                  daynum=chessmetric$rating_day_num, chess.orank=chessmetric$orank, 
                                  WP=rpi$WP, OWP=rpi$OWP, OOWP=rpi$OOWP, 
                                  RPI=rpi$RPI, SOS=rpi$SOS, RPI_orank=rpi$RPI_orank,
                                  SOS_orank=rpi$SOS_orank)
  
  metric.data
}


## Parses core ordinal metrics from csv files
ParseCoreOrdMetricsData <- function(teamsFile, coreFile) {
  
  teams <- read.csv(paste("./data", teamsFile, sep="/"))
  core <- read.csv(paste("./data", coreFile, sep="/"))
  
  colnames(teams) <- c("team", "name")
  core <- merge(core, teams)
  seasons.id <- as.numeric(core$season) + 7 # Season index (A=1)
  seasons <- levels(core$season)[seasons.id]
  
  # Create ordinal metrics data frame
  core.data <- data.frame(id=core$team, name=levels(teams$name)[core$name], 
                          season=seasons, 
                                season.id=seasons.id, daynum=core$rating_day_num, 
                                sys.name=core$sys_name, orank=core$orank)
  
  # Order the data frame by id, season, daynum
  attach(core.data)
  core.data <- core.data[order(id, season, sys.name, daynum), ]
  
  core.data
}


## Parses noncore ordinal metrics from csv files
ParseNonCoreOrdMetricsData <- function(teamsFile, noncoreFile) {
  
  teams <- read.csv(paste("./data", teamsFile, sep="/"))
  noncore <- read.csv(paste("./data", noncoreFile, sep="/"))
  
  colnames(teams) <- c("team", "name")
  noncore <- merge(noncore, teams)
  seasons.id <- as.numeric(noncore$season) + 7 # Season index (A=1)
  seasons <- levels(noncore$season)[seasons.id]
  
  # Create ordinal metrics data frame
  noncore.data <- data.frame(id=noncore$team, name=levels(teams$name)[noncore$name], 
                          season=seasons, 
                          season.id=seasons.id, daynum=noncore$rating_day_num, 
                          sys.name=noncore$sys_name, orank=noncore$orank)
  
  # Order the data frame by id, season, daynum
  attach(noncore.data)
  noncore.data <- noncore.data[order(id, season, sys.name, daynum), ]
  
  noncore.data
}



## Parses School stats from sports-reference.com
ParseSchoolStats <- function(fileList, teamFile) {
  
  seasons <- c("C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q",
               "R", "S")
  
  teams <- read.csv(paste("./data", teamsFile, sep="/"))
  
  school.stats <- NULL
  for (i in 1:length(fileList)) {
    file.name <- fileList[i]
    season.stats <- read.csv(paste("./data/School Stats", file.name, sep="/"))
    season.stats <- season.stats[season.stats$School %in% teams$sportsref_name, ]
    season.stats$season <- as.character(season.stats$season) # Correct a weird bug on season display
    
    season.stats <- data.frame(season.stats, id=numeric(dim(season.stats)[1]))
    for (j in 1:dim(season.stats)[1]) { # Retrieve teams' names
      season.stats$id[j] <- (teams[as.character(teams$sportsref_name) == as.character(season.stats$School[j]), ][1])[[1]]
    }
    teams.id <- data.frame(id=teams$id)
    season.stats <- merge(teams.id, season.stats, all=TRUE) # Incoporate missing ids
    for (k in 1:length(season.stats$season)) { # Incorporate season name
      season.stats$season[k] <- seasons[i]
    }
    ms <- melt(season.stats, id.vars=c("id", "season", "Rk", "School"))
    drop <- c("Rk", "School") # Drop useless columns
    ms <- ms[, !(names(ms) %in% drop)]
    ms$value <- as.numeric(ms$value)
    # Replace missing values by mean of variable
    ms <- ddply(ms, .(variable), function(df) {df$value[is.na(df$value)] <- mean(df$value, na.rm=TRUE); return(df)})
    season.stats <- dcast(ms, id + season ~ variable)
    
    print(dim(season.stats)[1])
    school.stats <- rbind(school.stats, season.stats) # Update stats file
  }
  
  # Replace missing columns by next year's values
  for (i in (length(seasons) - 1):1) { # Last year has all data
    print(i)
    curr.seas <- school.stats[school.stats$season == seasons[i], ]
    next.seas <- school.stats[school.stats$season == seasons[i + 1], ]
    
    for (feat in colnames(curr.seas)) {
      if (all(curr.seas[feat] == "NaN")) {
        curr.seas[feat] <- next.seas[feat]
      }
    }
    school.stats[school.stats$season == seasons[i], ] <- curr.seas
  }
  
  school.stats 
}
