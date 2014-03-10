import csv
import sys


def merge_csv(fnA, fnB, outfn):
  sys.stderr.write('Merging {} with {}\n'.format(fnA, fnB))

  # Open the files
  fA = open(fnA, 'rb')
  fB = open(fnB, 'rb')
  out = open(outfn, 'w')

  error, total = 0, 0
  # Put the lines of the two files next to each other
  lines = zip(enumerate(csv.reader(fA)), enumerate(csv.reader(fB)))
  for (i, rowA), (j, rowB) in lines:
    rowA = [x.strip(' "') for x in rowA]
    rowB = [x.strip(' "') for x in rowB]
    assert rowA[0] == rowB[0], 'Not merging same IDs'
    out.write(', '.join(rowA + rowB[2:]) + '\n')

merge_csv("temp/train_mixer.csv", "temp/train_game.csv", "temp/train.csv")
merge_csv("temp/test_mixer.csv", "temp/test_game.csv", "temp/test.csv")
