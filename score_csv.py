import csv
import numpy as np
import sys

print 'Marking {} against {}'.format(sys.argv[1], sys.argv[2])

# Open the files
fA = open(sys.argv[1], 'rb')
fB = open(sys.argv[2], 'rb')

error, total = 0, 0
# Put the lines of the two files next to each other
lines = zip(enumerate(csv.reader(fA)), enumerate(csv.reader(fB)))
for (i, gold), (j, rowB) in lines:
  # Skip the header
  if i == 0:
    continue
  assert gold[0] == rowB[0], "Not comparing same teams"
  correct, guess = int(gold[1]), float(rowB[1])
  if correct != -1:
    error += correct * np.log(guess) + (1 - correct) * np.log(1 - guess)
    total += 1
print 'Log loss: {}'.format(-error / total)
print 'Total: {} (should be 315)'.format(total)
