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
#mylogit <- glm(AWins ~ ChessA.ChessB + AvgA.AvgB + WinA + WinB, data=games, family="binomial")
#mylogit <- glm(AWins ~ ChessA.ChessB + P1_AvgA.AvgB + P1_ChessA.ChessB + P1_WinA + P1_WinB + P2_AvgA.AvgB + P2_ChessA.ChessB + P2_WinA + P2_WinB + P3_AvgA.AvgB + P3_ChessA.ChessB + P3_WinA + P3_WinB, data=games, family="binomial")
#mylogit <- glm(AWins ~ ChessA.ChessB + P1_ChessA.ChessB + P2_ChessA.ChessB + P3_ChessA.ChessB
#    + P1_AvgA.AvgB +  P1_WinA + P1_WinB + P1_WPA.WPB + P1_OWPA.OWPB + P1_OOWPA.OOWPB
#    + P2_AvgA.AvgB + P2_WinA + P2_WinB + P2_WPA.WPB + P2_OWPA.OWPB + P2_OOWPA.OOWPB
#    + P3_AvgA.AvgB + P3_WinA + P3_WinB + P3_WPA.WPB + P3_OWPA.OWPB + P3_OOWPA.OOWPB
#  , data=games, family="binomial")
#mylogit <- glm(AWins ~ ChessA.ChessB, data=games, family="binomial")
model <- glm(AWins ~ ChessA + ChessB
    + RPIA + RPIB
    + CPRA + CPRB
    + WLKA + WLKB
    + DOLA + DOLB
    + CPAA + CPAB
    + DCIA + DCIB
  , data=games, family="binomial")
#
#library(randomForest)
#model <- randomForest(AWins ~ ChessA + ChessB
#    + RPIA + RPIB
#    + CPRA + CPRB
#    + WLKA + WLKB
#    + DOLA + DOLB
#    + CPAA + CPAB
#    + DCIA + DCIB
#  , data=games, ntree=100, nodesize=10)
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
