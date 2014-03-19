from collections import defaultdict
import csv

# List of files and the set of columns to extract from them
# We assume each file has a column called "season" and "team"
data = [
    (
        "data/atr_core.csv",
        ['AP', 'BOB', 'CNG', 'COL', 'DES', 'DOL', 'MOORE', 'MOR', 'RPI', 'RTH', 'SAG', 'USA', 'WLK', 'WOL']
        + ["Pyth", "AdjO", "AdjD", "AdjT", "Luck", "OppPyth", "OppO", "OppD", "NCOppPyth"]
    ),
    ("data/agg_S.csv", ["AP", "BOB", "CNG", "COL", "DES", "DOL", "MOR", "Pyth", "AdjO", "AdjD", "AdjT", "Luck", "OppPyth", "OppO", "OppD", "NCOppPyth", "RPI", "RTH", "SAG", "USA", "WLK", "WOL", "MOORE"]),
    #("data/chessmetrics.csv", ["rating"]),
    ("temp/conffeatures_data.csv", ["conf.score"]),
    ("temp/statsfeatures_data.csv", ["SRS", "SOS", "FG.", "X3P.", "FT.", "ORB", "TRB", "STL", "BLK", "TOV"]),
    # Can't use features_data as it is all the features from the season they're playing. Putting in "mean_tourn.win" for example makes it "win"
    #("temp/features_data.csv", ["mean_seas.score", "mean_seas.opp.score", "mean_tourn.opp.score", "grad_chess.orank", "grad_RPI_orank"]),
    # Can't use "mean_tourn.win", "mean_tourn.score"
    #("temp/features_data.csv", ["grad_chess.orank", "grad_RPI_orank"]),
]
FEATURES = sorted(reduce(lambda x, y: x + y, [f for _, f in data]))

train_seasons = 'HIJKLMNOPQR'
test_seasons = 'S'

###
# Compile the list of team features
all_teams = set()
team_features = defaultdict(lambda: defaultdict(dict))
missing = defaultdict(lambda: defaultdict(int))

for fn, features in data:
  print 'Processing {}'.format(fn)
  reader = csv.DictReader(open(fn))
  for line, row in enumerate(reader):
    season, team = row['season'], row['team']
    if season not in train_seasons + test_seasons:
      continue
    all_teams.add(team)
    for feat in features:
      data = row[feat]
      try:
        data = float(row[feat])
      except ValueError:
        if data == 'NA':
          missing[season][feat] += 1
          data = 0
        else:
          print data
          missing[season][feat] += 1
          data = 0
      team_features[season][team][feat] = data

# Ensure all the data is there
for season in train_seasons + test_seasons:
  missed = defaultdict(int)
  for team in team_features[season]:
    for feat in FEATURES:
      if feat not in team_features[season][team]:
        missed[feat] += 1
  if missed:
    print '{} not in {}-{}'.format(sorted(missed.items()), season, team)

for season in sorted(missing):
  print season, missing[season]

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

# Work out which teams are versing each other, create the team-team match features, write the result
teams_in_s = defaultdict(set)
for row in csv.DictReader(open("data/tourney_seeds.csv")):
  teams_in_s[row['season']].add(row['team'])
only_teams = defaultdict(set)
for season in sorted(teams_in_s):
  for t1 in sorted(teams_in_s[season]):
    for t2 in sorted(teams_in_s[season]):
      if t1 < t2:
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
