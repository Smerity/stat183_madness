library(rPython)
library(glmnet)
#
# Creates temp/[train|test]_mixer.csv
#python.load("extract_feats.py")
#
print("Reading in data...")
games <- read.csv("temp/train.csv")
rownames(games) <- games$match
games$match <- NULL
#
print("Training prediction model...")
#
library(glmnet)
f <- as.formula(AWins ~ .)
x <- model.matrix(f, games)
y <- as.matrix(games$AWins, ncol=1)
model <- cv.glmnet(x, y, alpha=1, family="binomial")
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
test$AWinGuess <- 0.1 + test$AWinGuess * 0.8
#
write.table(test[, c('AWinGuess'), drop=FALSE], file="temp/final.csv", sep=",", quote=FALSE)
