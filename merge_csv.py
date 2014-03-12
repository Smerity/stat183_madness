import csv
import sys


def merge_csv(filenames, outfn):
  sys.stderr.write('Merging files: {}\n'.format(filenames))

  # Open the files
  out = open(outfn, 'w')

  error, total = 0, 0
  # Put the lines of the two files next to each other
  files = [csv.reader(open(fn, 'rb')) for fn in filenames]
  lines = zip(*files)
  for rows in lines:
    rows = [[x.strip(' "') for x in r] for r in rows]
    rows = [rows[0]] + [r[2:] for r in rows[1:]]
    assert len(set([r[0] for r in rows])), 'Not merging same IDs'
    out.write(', '.join(reduce(lambda x, y: x + y, rows)) + '\n')


merge_csv(["temp/train_mixer.csv", "temp/train_game.csv", "temp/train_gamestats.csv", "temp/train_gameconf.csv"], "temp/train.csv")
merge_csv(["temp/test_mixer.csv", "temp/test_game.csv", "temp/test_gamestats.csv", "temp/test_gameconf.csv"], "temp/test.csv")
