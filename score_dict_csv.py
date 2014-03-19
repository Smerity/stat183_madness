import csv
import numpy as np
import sys

print 'Marking {} against {}'.format(sys.argv[1], sys.argv[2])

# Open the files
fA = open(sys.argv[1], 'rb')
fB = open(sys.argv[2], 'rb')

result = {}
for i, row in enumerate(csv.reader(fA)):
  if i == 0:
    continue
  match, wins = row
  wins = int(wins)
  result[match] = wins

team = {}
for row in csv.DictReader(open('data/teams.csv')):
  team[row['id']] = row['name']

error, total = 0, 0
# Put the lines of the two files next to each other
for i, rowB in enumerate(csv.reader(fB)):
  # Skip the header
  if i == 0:
    continue
  match, guess = rowB[0], float(rowB[1])
  if match in result:
    correct = result[match]
    err = correct * np.log(guess) + (1 - correct) * np.log(1 - guess)
    error += err
    _, t1, t2 = match.split('_')
    print 'Error for match {} vs {} ({}) = {}'.format(team[t1], team[t2], match, err)
    total += 1
print '{}/{}'.format(-error, total)
print 'Log loss: {}'.format(-error / total)
print 'Total: {} (should be 315)'.format(total)
