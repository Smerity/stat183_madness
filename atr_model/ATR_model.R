### The glmnet library has many functions for fitting regularized general linear models
library(glmnet)

### Change this as necessary
#home.dir = "~/Dropbox/Stat 183 NCAA/submit_week2/"
#setwd(home.dir)

### cmp(df, seas, fst, snd)
### Calculates difference in ability between
### two teams.
### --------------
### df -
### a dataframe describing each team's ability
### in each season; needs columns "season", "team"
###
### seas, fst, snd -
### desired season and team
### (when inputted to mdl, will predict prob
###  that fst beats snd)
cmp <- function(df, seas, fst, snd){
  # Grab stats
  fst.data <- subset(df, subset = (season == seas & team == fst))[1,]
  snd.data <- subset(df, subset = (season == seas & team == snd))[1,]

  # Scratch non-numeric data...
  fst.data$X <- NULL; fst.data$season <- NULL; fst.data$team <- NULL;
  snd.data$X <- NULL; snd.data$season <- NULL; snd.data$team <- NULL;

  # ...so that we can compute the difference.
  cmb.data <- fst.data - snd.data

  # Re-add in the season
  cmb.data$season <- seas

  return(cmb.data)
}

### Calculate log.loss of predictions
log.loss <- function(y, fitted){
  return( -1 * mean(y * log(fitted) + (1 - y) * log(1 - fitted)) )
}

### First, read in the team stats (i.e., rankings, POM stats, etc.)

### Read in main data file
df     <- read.csv('data/agg_core.csv', header = TRUE)

### Eliminate rankings incomlete in seasons I-N
all.df <- df[,!(names(df) %in% c("BPI", "CPA", "CPR", "DC", "DCI", "DOK", "DUN", "LMC", "MB",
                                 "NOL", "PGH", "PIG", "REW", "RTB", "RTR", "SE","SPW", "STH",
                                 "WIL", "D1A"))]

### Remove any rows with NAs (there aren't too many, thankfully)
all.df <- na.omit(all.df)

# --------------------------------------------
# Next, read in the games we want to examine
# --------------------------------------------

### Read in all tournament games
tourney.results = read.csv('data/tourney_results.csv', header = TRUE)

### Finally, compute (team 1 stats - team 2 stats) for each team

### Wrapper function for cmp that allows us to use it in an "apply"
### We also randomly flip games so that we look at "lteam,wteam"
### rather than "wteam,lteam" (this way, not all y's are equal to 1)
### (Remember that cmp assumes first team inputted wins)
cur.cmp.2 <- function(row){
  cmb.data <- cmp(all.df, row['season'], row['wteam'], row['lteam'])
  seas <- cmb.data$season; cmb.data$season <- NULL;

  # Randomly flip to give us a legit data set
  if(rbinom(1,1,0.5)){
    cmb.data$Y <- 1
  }else{ cmb.data$Y <- 0; cmb.data <- -1 * cmb.data; }

  # Add the season back in
  cmb.data$season <- seas
  return( cmb.data )
}

### Compute diff in team stats for every game in tourney
all.feat <- do.call(rbind, apply(tourney.results, 1, cur.cmp.2))
all.feat <- na.omit(all.feat)

### Load games needed for submission & fix column names
games <- read.csv('data/submit_games.csv', header = TRUE)
names(games)[2:3] <- c('wteam', 'lteam'); games$result <- NULL

### Wrapper for apply; no need to flip results here since this is test data
cmp.test <- function(row){
  cmb.data <- cmp(all.df, row['season'], row['wteam'], row['lteam'])
  return( cmb.data )
}

### Compute features
test.feat <- do.call(rbind, apply(games, 1, cmp.test))

final = array(0, c(0,1)) # Create container for submissions

### Iterating across the seasons described in the submission set...
for(seas in levels(factor(test.feat$season))){
  ### Grab the leave-one-out training data, and seperate x's & y's
  train.x = subset(all.feat, subset = (season != seas))
  train.y = train.x$Y; train.x$Y <- NULL; train.x$season = NULL

  ### Grab test x's for given season; elim season column
  test.x  = subset(test.feat, subset = (season == seas)); test.x$season = NULL

  ### Make sure data is correctly scaled
  train.x <- scale(train.x); train.x[is.nan(train.x)] <- 0;
  test.x  <- scale(test.x) ; test.x[is.nan(test.x)] <- 0;

  ### Perform cross-validation on training set to determine correct regularization
  ### parameter for the lasso-reg'd logistic regression
  cv.result <- cv.glmnet(t(t(train.x)), t(train.y), family = "binomial", alpha = 0.8)

  ### Predict results for games based on the features test.x.
  ### Predicting with the cv.result object automatically uses model for
  ### the "1 standard deviation above min" lambda! (how nice!)
  results <- predict(cv.result, test.x, type = "response")

  ### Compile results
  final = rbind(final, results)
}

submit <- data.frame(
  id = apply(games, 1, function(x){
    return(paste(x['season'], x['wteam'], x['lteam'], sep = '_'))}),
  pred = final)

names(submit) <- c('id', 'pred')

write.csv(submit, file = 'Amanda_Tony_Randall_week2.csv', row.names = FALSE)

cv.err = c()
for(seas in levels(factor(all.feat$season))){
  train.x = subset(all.feat, subset = (season != seas))
  test.x  = subset(all.feat, subset = (season == seas))

  train.y = train.x$Y; train.x$Y <- NULL; train.x$season = NULL
  test.y  = test.x$Y;  test.x$Y  <- NULL; test.x$season = NULL

  train.x <- scale(train.x); train.x[is.nan(train.x)] <- 0;
  test.x  <- scale(test.x) ; test.x[is.nan(test.x)] <- 0;

  cv.result <- cv.glmnet(t(t(train.x)), t(train.y), family = "binomial", alpha = 0.8)
  results <- predict(cv.result, test.x, type = "response")

  cv.err <- c(cv.err, log.loss(test.y, results))
}

print( paste('Mean CV Log Loss:', mean(cv.err[6:10])) )
print( cbind(levels(factor(all.feat$season)), cv.err) )
