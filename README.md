STAT183: March Madness
===============

+ Data ingestion
+ Feature extraction
  + Team[Winning percentage]
  + Team[Avg score] => TeamA[Avg score] - TeamB[Avg score]
  + Chessmetrics
+ Training
+ Ensembling
+ Validation

Starting from a blank slate...

+ Create a directory called 'temp'
+ `python feat_mixer.py`
+ This generates train.csv and test.csv in the temp folder
+ `Rscript predict.R`
+ To evaluate against the training set (TODO: cross validation / held-out): `python score_csv.py temp/correct.csv temp/guess.csv`
+ To evaluate against final test set (don't do this!): `python score_csv.py given/gold.csv temp/final.csv`
+ To submit, fix the first line of `temp/final.csv` ("id,pred") and you're good
