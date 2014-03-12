################# Performs feature extraction from data ###################

# Set source location
#setwd("")

# Load season and tourney data, chessmetrics/RPI data and ordinal data
load("./data/teamData.RData")
load("./data/metricData.RData")
# load("./data/ordmetricData.RData") # Data not used for now
load("./data/schoolstatsData.RData")

######################### Useful functions ############################

## Compute gradient of a column
Gradient <- function(col) {
  n <- length(col)
  col[n] - col[1]
}

################## Create comprehensive feat.data dataframe with feature ######################

# Season aggregates by teams and seasons
season.mean <- aggregate(cbind(win, score, opp.score) ~ id + season,
                         season.data, FUN=mean)
colnames(season.mean) <- c("id", "season", "mean_seas.win", "mean_seas.score", "mean_seas.opp.score")

# Tourney aggregates by teams and seasons
tourney.mean <- aggregate(cbind(win, score, opp.score) ~ id + season,
                          tourney.data, FUN=mean)
colnames(tourney.mean) <- c("id", "season", "mean_tourn.win", "mean_tourn.score", "mean_tourn.opp.score")

feat.data <- merge(season.mean, tourney.mean, all=TRUE)
rm(season.mean)
rm(tourney.mean)
rm(season.data)
rm(tourney.data)

# Chessmetircs/RPI metric aggregates by teams and seasons
metric.mean <- aggregate(cbind(chess.orank, WP, OWP, OOWP, RPI, SOS, RPI_orank, SOS_orank) ~ id + 
                          season, metric.data, FUN=mean)
colnames(metric.mean) <- c("id", "season", "mean_chess.orank", "mean_WP", "mean_OWP",
                           "mean_OOWP", "mean_WPI", "mean_SOS", "mean_RPI_orank", "mean_SOS_orank")
# feat.data<-merge(feat.data, metric.mean, all=TRUE)
rm(metric.mean)

metric.min <- aggregate(cbind(chess.orank, WP, OWP, OOWP, RPI, SOS, RPI_orank, SOS_orank) ~ id +
                          season, metric.data, FUN=min)
colnames(metric.min) <- c("id", "season", "min_chess.orank", "min_WP", "min_OWP",
                           "min_OOWP", "min_WPI", "min_SOS", "min_RPI_orank", "min_SOS_orank")
# feat.data<-merge(feat.data, metric.min, all=TRUE)

metric.max <- aggregate(cbind(chess.orank, WP, OWP, OOWP, RPI, SOS, RPI_orank, SOS_orank) ~ id +
                          season, metric.data, FUN=max)
colnames(metric.max) <- c("id", "season", "max_chess.orank", "max_WP", "max_OWP",
                           "max_OOWP", "max_WPI", "max_SOS", "max_RPI_orank", "max_SOS_orank")
keep.max <- c("id", "season", "max_chess.orank", "max_RPI_orank")
feat.data<-merge(feat.data, metric.max[, ((names(metric.max) %in% keep.max))], all=TRUE)

metric.var <- data.frame(cbind(metric.max[, 1:2], metric.max[, 3:10] - metric.min[, 3:10]))
colnames(metric.var) <- c("id", "season", "var_chess.orank", "var_WP", "var_OWP",
                           "var_OOWP", "var_WPI", "var_SOS", "var_RPI_orank", "var_SOS_orank")
# feat.data<-merge(feat.data, metric.var, all=TRUE)
rm(metric.min)
rm(metric.max)
rm(metric.var)

metric.grad <- aggregate(cbind(chess.orank, WP, OWP, OOWP, RPI, SOS, RPI_orank, SOS_orank) ~ id + 
                           season, metric.data, FUN=Gradient)
colnames(metric.grad) <- c("id", "season", "grad_chess.orank", "grad_WP", "grad_OWP",
                           "grad_OOWP", "grad_WPI", "grad_SOS", "grad_RPI_orank", "grad_SOS_orank")
keep.grad <- c("id", "season", "grad_chess.orank", "grad_RPI_orank")
feat.data <-merge(feat.data, metric.grad[, ((names(metric.grad) %in% keep.grad))], all=TRUE)
rm(metric.grad)
rm(metric.data)


################ Write features_data.csv file and compute training/set set for games in python ###############

feat.data[is.na(feat.data)] <- -1 # Replace NA by -1
## Write features data to csv to be assembled in training set in python
write.csv(feat.data, file="./temp/features_data.csv", row.names=FALSE)


# Keep only some potentially useful school stats data
statskeep <- c("id", "season", "SRS", "SOS", "FG.", "X3P.", "FT.", "ORB", "TRB", "STL", "BLK", "TOV")
statsfeat.data <- school.stats[, names(school.stats) %in% statskeep]
attach(statsfeat.data)
statsfeat.data <- statsfeat.data[order(id, season), ]
## Write statsfeatures data to csv to be assembled in training set in python
write.csv(statsfeat.data, file="./temp/statsfeatures_data.csv", row.names=FALSE)


############# Not used metrics
# Ordinal data aggreagates by teams and seasons
#coreord.mean <- aggregate(orank ~ id + name + season + season.id + sys.name, coreord.data, FUN=mean)
#coreord.min <- aggregate(orank ~ id + name + season + season.id + sys.name, coreord.data, FUN=min)
#coreord.max <- aggregate(orank ~ id + name + season + season.id + sys.name, coreord.data, FUN=max)
#coreord.var <- data.frame(cbind(coreord.max[, 1:5], coreord.max[, 6] - coreord.min[, 6]))
#coreord.grad <- aggregate(orank ~ id + name + season + season.id + sys.name, coreord.data, FUN=Gradient)

#noncoreord.mean <- aggregate(orank ~ id + name + season + season.id + sys.name, noncoreord.data, FUN=mean)
#noncoreord.min <- aggregate(orank ~ id + name + season + season.id + sys.name, noncoreord.data, FUN=min)
#noncoreord.max <- aggregate(orank ~ id + name + season + season.id + sys.name, noncoreord.data, FUN=max)
#noncoreord.var <- data.frame(cbind(noncoreord.max[, 1:5], noncoreord.max[, 6] - noncoreord.min[, 6]))
#noncoreord.grad <- aggregate(orank ~ id + name + season + season.id + sys.name, noncoreord.data, FUN=Gradient)


#corelist <- c('CPR', 'WLK', 'DOL', 'CPA', 'DCI', 'COL', 'BOB', 'SAG', 'RTH', 'PGH', 'AP', 'DUN', 'MOR')
#for (i in 1:length(corelist)) { # Add core ord metric means
#  rank.name <- corelist[i]
#  drops <- c("sys.name") # Column to drop
#  rank.mean <- coreord.mean[coreord.mean$sys.name == rank.name, ]
#  rank.mean <- coreord.mean[, !((names(coreord.mean) %in% drops))]
#  rank.mean <- rank.mean[rank.mean$sys.name == rank.name, ]
#  colnames(rank.mean) <- c("id", "name", "season", "season.id", paste("mean", rank.name, sep="_"))
#  feat.data <- merge(feat.data, rank.mean, all=TRUE)
#}
#rm(rank.mean)
#rm(coreord.mean)

#for (i in 1:length(corelist)) { # Add core ord metric mins
#  rank.name <- corelist[i]
#  drops <- c("sys.name") # Column to drop
#  rank.min <- coreord.min[coreord.min$sys.name == rank.name, ]
#  rank.min <- coreord.min[, !((names(coreord.min) %in% drops))]
#  colnames(rank.min) <- c("id", "name", "season", "season.id", paste("min", rank.name, sep="_"))
#  feat.data <- merge(feat.data, rank.min, all=TRUE)
#}
#rm(rank.min)
#rm(coreord.min)

#for (i in 1:length(corelist)) { # Add core ord metric maxs
#  rank.name <- corelist[i]
#  drops <- c("sys.name") # Column to drop
#  rank.max <- coreord.max[coreord.max$sys.name == rank.name, ]
#  rank.max <- coreord.max[, !((names(coreord.max) %in% drops))]
#  colnames(rank.max) <- c("id", "name", "season", "season.id", paste("max", rank.name, sep="_"))
#  feat.data <- merge(feat.data, rank.max, all=TRUE)
#}
#rm(rank.max)
#rm(coreord.max)

#for (i in 1:length(corelist)) { # Add core ord metric maxs
#  rank.name <- corelist[i]
#  drops <- c("sys.name") # Column to drop
#  rank.var <- coreord.var[coreord.var$sys.name == rank.name, ]
#  rank.var <- coreord.var[, !((names(coreord.var) %in% drops))]
#  colnames(rank.var) <- c("id", "name", "season", "season.id", paste("var", rank.name, sep="_"))
#  feat.data <- merge(feat.data, rank.var, all=TRUE)
#}
#rm(rank.var)
#rm(coreord.var)

#for (i in 1:length(corelist)) { # Add core ord metric maxs
#  rank.name <- corelist[i]
#  drops <- c("sys.name") # Column to drop
#  rank.var <- coreord.var[coreord.var$sys.name == rank.name, ]
#  rank.grad <- coreord.grad[, !((names(coreord.grad) %in% drops))]
#  colnames(rank.grad) <- c("id", "name", "season", "season.id", paste("grad", rank.name, sep="_"))
#  feat.data <- merge(feat.data, rank.grad, all=TRUE)
#}
#rm(rank.grad)
#rm(coreord.grad)
#rm(coreord.data)

