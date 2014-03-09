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
#
library(glmnet)
f <- as.formula(AWins ~ .)
x <- model.matrix(f, games)
y <- as.matrix(games$AWins, ncol=1)
model <- glmnet(x, y, family="binomial")
print(coef(model))
games$AWinGuess <- predict(model, x, type="response")
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
