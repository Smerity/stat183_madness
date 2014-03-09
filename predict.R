# This creates the train.csv and test.csv files in the temp folder
library(rPython)
#python.load("feat_mixer.py")
#
games <- read.csv("temp/train.csv")
rownames(games) <- games$match
games$match <- NULL
#
print("Beginning of data...")
#head(games)
#
print("Summary of data...")
#summary(games)
#
print("Training prediction model...")
#
library(glmnet)
f <- as.formula(AWins ~ ChessAB + RPIAB + CPR + WLK + DOL + CPA + DCI + COL + BOB + SAG + RTH + PGH + AP + DUN + MOR)
#                mean_seas.win.A.B + mean_seas.score.A.B + mean_tourn.score.A.B + mean_tourn.win.A.B)
x <- model.matrix(f, games)
y <- as.matrix(games$AWins, ncol=1)
model <- cv.glmnet(x, y, alpha=0, family="binomial")
games$AWinGuess <- predict(model, x, type="response")
#
print(coef(model))
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
x <- model.matrix(f, test)
y <- as.matrix(test$AWins, ncol=1)
test$AWinGuess <- predict(model, x, type="response")
#
write.table(test[, c('AWinGuess'), drop=FALSE], file="temp/final.csv", sep=",", quote=FALSE)
