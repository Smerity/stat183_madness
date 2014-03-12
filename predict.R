library(rPython)
library(glmnet)
#
# Creates temp/[train|test]_mixer.csv
python.load("feat_mixer.py")
# Creates temp/[train|test]_game.csv
python.load("game_feats.py")
# Creates temp/[train|test]_gamestats.csv
python.load("game_stats_feats.py")
# Creates temp/[train|test]_conf.csv
python.load("conf_feats.py")
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
f <- as.formula(AWins ~ ChessAB + RPIAB + CPR + WLK + DOL + CPA + DCI + COL + BOB + SAG + RTH + PGH + AP + DUN + MOR +
                grad_RPI_orank.A.B + grad_chess.orank.A.B + max_RPI_orank.A.B + max_chess.orank.A.B + mean_seas.opp.score.A.B + 
                mean_seas.score.A.B + mean_seas.win.A.B + BLK.A.B + FG..A.B + FT..A.B + ORB.A.B + SOS.A.B + SRS.A.B + STL.A.B +
                TOV.A.B + TRB.A.B + X3P..A.B + conf.score.A + conf.score.B)
x <- model.matrix(f, games)
y <- as.matrix(games$AWins, ncol=1)
model <- cv.glmnet(x, y, alpha=0.5, family="binomial")
summary(model)
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
