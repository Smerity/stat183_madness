# This creates the train.csv and test.csv files in the temp folder
library(rPython)
#python.load("feat_mixer.py")
#
games <- read.csv("temp/train.csv")
rownames(games) <- games$match
games$match <- NULL
#
print("Beginning of data...")
head(games)
#
print("Summary of data...")
summary(games)
#
print("Training prediction model...")
#model <- glm(AWins ~
#    ChessAB + RPIAB +
#    CPR + WLK + DOL + CPA + DCI + COL + BOB + SAG + RTH + PGH + AP + DUN + MOR
#  , data=games, family="binomial")
#model <- glm(AWins ~
#  grad_RPI_orank.A + grad_RPI_orank.B + grad_chess.orank.A + grad_chess.orank.B + max_RPI_orank.A + max_RPI_orank.B + max_chess.orank.A +
#  max_chess.orank.B + mean_seas.opp.score.A + mean_seas.opp.score.B + mean_seas.score.A + mean_seas.score.B + mean_seas.win.A +
#  mean_seas.win.B + mean_tourn.opp.score.A + mean_tourn.opp.score.B + mean_tourn.score.A + mean_tourn.score.B + mean_tourn.win.A +
#  mean_tourn.win.B +
#  ChessA + ChessAB + ChessB + DOL + RTH + WLK,
#  data=games, family="binomial")
#
# Just these guys = 0.458507987079 / 0.507276824178 versus all ords = 0.457489416823 / 0.50215094726
#model <- glm(AWins ~ ChessA + ChessAB + ChessB + DOL + RTH + WLK,
#  data=games, family="binomial")
#
model <- glm(AWins ~ .,
  data=games, family="binomial")
summary(model)
games$AWinGuess <- predict(model, games, type="response")
#
#library(glmnet)
#f <- as.formula(AWins ~ .)
#x <- model.matrix(f, games)
#y <- as.matrix(games$AWins, ncol=1)
#model <- glmnet(x, y, family="binomial")
#print(coef(model))
#games$AWinGuess <- predict(model, x, type="response")
#
write.table(games[, c('AWinGuess'), drop=FALSE], file="temp/guess.csv", sep=",", quote=FALSE)
write.table(games[, c('AWins'), drop=FALSE], file="temp/correct.csv", sep=",", quote=FALSE)
#
#
print("Running over test data...")
test <- read.csv("temp/test.csv")
rownames(test) <- test$match
test$match <- NULL
#
test$AWinGuess <- predict(model, test, type="response")
write.table(test[, c('AWinGuess'), drop=FALSE], file="temp/final.csv", sep=",", quote=FALSE)
