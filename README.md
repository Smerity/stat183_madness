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
+ `python feat_ext.py`
+ This generates train.csv and test.csv in the temp folder
+ `Rscript predict.R`
+ `python score_csv.py temp/correct.csv temp/guess.csv`
