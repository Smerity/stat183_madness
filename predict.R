library(rPython)
#
# Creates temp/[train|test]_mixer.csv
python.load("feat_mixer.py")
# Creates temp/[train|test]_game.csv
python.load("game_feats.py")
# Creates temp/[train|test]_gamestats.csv
python.load("gamestats_feats.py")
# Merges the two files to create temp/train.csv and temp/test.csv
python.load("merge_csv.py")
#
print("Reading in data...")
games <- read.csv("temp/train.csv")
rownames(games) <- games$match
games$match <- NULL
#
print("Training prediction model...")
#
library(glmnet)
f <- as.formula(AWins ~ ChessAB + RPIAB + CPR + WLK + DOL + CPA + DCI + COL + BOB + SAG + RTH + PGH + AP + DUN + MOR)
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
