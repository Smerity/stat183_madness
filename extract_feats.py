from collections import defaultdict
import csv

# List of files and the set of columns to extract from them
# We assume each file has a column called "season" and "team"
data = [
    (
        "data/atr_core.csv",
        ['AP', 'BOB', 'CNG', 'COL', 'DES', 'DOL', 'MOORE', 'MOR', 'RPI', 'RTH', 'SAG', 'USA', 'WLK', 'WOL']
        + ["Pyth.x", "AdjO.x", "AdjD.x", "AdjT.x", "Luck.x", "OppPyth.x", "OppO.x", "OppD.x", "NCOppPyth.x"]
    ),
    ("data/chessmetrics.csv", ["rating"]),
    ("temp/conffeatures_data.csv", ["conf.score"]),
    ("temp/statsfeatures_data.csv", ["SRS", "SOS", "FG.", "X3P.", "FT.", "ORB", "TRB", "STL", "BLK", "TOV"]),
    # Can't use features_data as it is all the features from the season they're playing. Putting in "mean_tourn.win" for example makes it "win"
    #("temp/features_data.csv", ["mean_seas.score", "mean_seas.opp.score", "mean_tourn.opp.score", "grad_chess.orank", "grad_RPI_orank"]),
    # Can't use "mean_tourn.win", "mean_tourn.score"
    ("temp/features_data.csv", ["grad_chess.orank", "grad_RPI_orank"]),
]
FEATURES = sorted(reduce(lambda x, y: x + y, [f for _, f in data]))

###
# Compile the list of team features
all_teams = set()
team_features = defaultdict(lambda: defaultdict(dict))

for fn, features in data:
  print 'Processing {}'.format(fn)
  reader = csv.DictReader(open(fn))
  for line, row in enumerate(reader):
    season, team = row['season'], row['team']
    all_teams.add(team)
    for feat in features:
      data = row[feat]
      try:
        data = float(row[feat])
      except ValueError:
        if data == 'NA':
          data = 0
      team_features[season][team][feat] = data

seasons = sorted(team_features.keys())
teams = sorted(all_teams)

print 'Loaded in seasons {}'.format(', '.join(seasons))

###
# Compile the win-lose pairs

win_pairs = defaultdict(lambda: defaultdict(lambda: -1))
rows = 0
if False:
  # Regular season data seems to only impair the results
  for row in csv.DictReader(open("data/regular_season_results.csv")):
    season = row['season']
    lteam, wteam = row['lteam'], row['wteam']
    # Predict 1 if the first team wins, else 0
    key = tuple(sorted([lteam, wteam]))
    win_pairs[season][key] = 1 if wteam == key[0] else 0
    rows += 1
for row in csv.DictReader(open("data/tourney_results.csv")):
  season = row['season']
  lteam, wteam = row['lteam'], row['wteam']
  # Predict 1 if the first team wins, else 0
  key = tuple(sorted([lteam, wteam]))
  win_pairs[season][key] = 1 if wteam == key[0] else 0
  rows += 1
print 'Loaded in {} win-lose pairs'.format(rows)

###
# Create the training / testing CSV files

#train_seasons = 'ABCDEFGHIJKLM'
train_seasons = 'HIJKLM'
test_seasons = 'NOPQR'
#train_seasons = 'HIJKLNOP'
#test_seasons = 'QR'

# Work out which teams are versing each other, create the team-team match features, write the result
only_teams = defaultdict(set)
for row in csv.DictReader(open("data/sample_submission.csv")):
  season, t1, t2 = row['id'].split("_")
  only_teams[season].add((t1, t2))


def match_features(season, teamA, teamB):
  fA = team_features[season][teamA]
  fB = team_features[season][teamB]
  feats = {}
  for f in FEATURES:
    feats[f] = fA[f] - fB[f]
  return feats
  """
  for k, v in fA.items():
    feats['A.' + k] = v
  for k, v in fB.items():
    feats['B.' + k] = v
  """
  return feats

###
# Create train.csv

row_names = ['match', 'AWins'] + FEATURES
#row_names = ['match', 'AWins'] + ['A.' + x for x in FEATURES] + ['B.' + x for x in FEATURES]
writer = csv.DictWriter(open('temp/train.csv', 'w'), row_names)
writer.writeheader()
for season in train_seasons:
  for tA, tB in sorted(win_pairs[season]):
    feats = match_features(season, tA, tB)
    feats['match'] = '{}_{}_{}'.format(season, tA, tB)
    feats['AWins'] = win_pairs[season][(tA, tB)]
    writer.writerow(feats)
    # Also provide for training the opposite orientation
    feats = match_features(season, tB, tA)
    feats['match'] = '{}_{}_{}'.format(season, tB, tA)
    feats['AWins'] = 0 if win_pairs[season][(tA, tB)] == 1 else 1
    writer.writerow(feats)

###
# Create test.csv

writer = csv.DictWriter(open('temp/test.csv', 'w'), row_names)
writer.writeheader()
for season in test_seasons:
  for tA, tB in sorted(only_teams[season]):
    feats = match_features(season, tA, tB)
    feats['match'] = '{}_{}_{}'.format(season, tA, tB)
    feats['AWins'] = win_pairs[season][(tA, tB)]
    writer.writerow(feats)
