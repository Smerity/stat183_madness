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
model <- glm(AWins ~
    ChessAB + RPIAB +
    CPR + WLK + DOL + CPA + DCI + COL + BOB + SAG + RTH + PGH + AP + DUN + MOR
  , data=games, family="binomial")
#
summary(model)
#
games$AWinGuess <- predict(model, games, type="response")
games$AWinGuess <- 0.1 + (games$AWinGuess - 0.1) * 0.9
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
test$AWinGuess <- 0.1 + (test$AWinGuess - 0.1) * 0.9
write.table(test[, c('AWinGuess'), drop=FALSE], file="temp/final.csv", sep=",", quote=FALSE)
