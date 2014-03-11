import csv
import os
from collections import defaultdict


def get_gamestatsfeats_for_seasons():
  all_teams = set()

  # Create features for training and testing data
  def create_gamestatsfeats(season, teamA, teamB):
    f = {}
    f['AWins'] = win_pairs[season][teamA, teamB]
    #
    for i in range(2, len(features_list)):
      feature_name = features_list[i]
      #f[feature_name + '.A'] = features[season][teamA][feature_name]
      #f[feature_name + '.B'] = features[season][teamB][feature_name]
      f[feature_name + '.A.B'] = float(features[season][teamA][feature_name]) - float(features[season][teamB][feature_name])
    return f

  # Get the record of games between teams
  win_pairs = defaultdict(lambda: defaultdict(lambda: -1))
  for season, daynum, wteam, wscore, lteam, lscore, wloc, numot in csv.reader(open("data/regular_season_results.csv")):
    # Skip the naming row
    if season == 'season':
      continue
    # Predict 1 if the first team wins, else 0
    key = tuple(sorted([lteam, wteam]))
    win_pairs[season][key] = 1 if wteam == key[0] else 0

  # Get features for each team
  features_list = []
  features = defaultdict(lambda: defaultdict(lambda: defaultdict(float)))
  # Parse through the csv to obtain features for each teams
  with open('temp/statsfeatures_data.csv', 'rb') as feature_file:
    features_csv = csv.reader(feature_file, delimiter=',', quotechar='"')
    row_index = 0
    for row in features_csv:
      if (row_index == 0):
        features_list = row
      else:
        team = row[0]
        season = row[1]
        all_teams.add(team)
        for i in range(2, len(row)):
          feature = row[i]
          feature_name = features_list[i]
          features[season][team][feature_name] = feature
      row_index = row_index + 1  # Update row index
  #
  seasons = sorted(features.keys())
  teams = sorted(all_teams)
  #
  gamestats_features = {}
  for season in seasons:
    print "Season " + season
    gamestatsfeats = {}
    #
    for i in xrange(len(teams) - 1):
      teamA = teams[i]
      for j in xrange(i + 1, len(teams)):
        teamB = teams[j]
        gamestatsfeats[(teamA, teamB)] = create_gamestatsfeats(season, teamA, teamB)
    #
    gamestats_features[season] = gamestatsfeats
  return gamestats_features


def add_prefix(s, f):
  d = {}
  for k, v in f.items():
    d['{}_{}'.format(s, k)] = v
  return d


def get_gamestatsfeats():
  print 'Retrieving features...'
  sgamestatsfeats = get_gamestatsfeats_for_seasons()
  #letters = 'ABCDEFGHIJKLMNOPQR'
  train_seasons = 'CDEFGHIJKL'
  train_seasons = 'HIJKL'
  test_seasons = 'NOPQR'
  #

  def produce_csv(fn, season_list, ONLY_TRAINING, ONLY_TEAMS=None):
    f = open(fn, 'w')
    rownum = 0
    FEATURES = None
    for s in season_list:
      s = s
      for k in sorted(sgamestatsfeats[s]):
        teamA, teamB = k
        if ONLY_TEAMS and k not in ONLY_TEAMS[s]:
          continue
        # Skip if the team didn't play against each other
        if ONLY_TRAINING and sgamestatsfeats[s][k]['AWins'] == -1:
          continue
        # Populate the features
        ## AWins is so we can check our test set, Chessmetrics as we're ensembling
        gamestatsfeats = sgamestatsfeats[s][k].copy()
        # Add all features from the last 4 previous seasons
        #for p in xrange(1, 4):
        #  prev_season = letters[letters.find(s) - p]
        #  featset.update(add_prefix('P{}'.format(p), featsets[prev_season][k]))
        #
        if rownum == 0:
          FEATURES = sorted(gamestatsfeats.keys())
          HEADER = ['match'] + FEATURES
          f.write(', '.join('"' + str(h) + '"' for h in HEADER) + '\n')
        name = '{}_{}_{}'.format('"' + s, teamA, teamB + '"')
        fline = ', '.join('"' + str(gamestatsfeats[f]) + '"' for f in FEATURES)
        f.write('{}, {}\n'.format(name, fline))
        rownum += 1
    f.close()
  #
  print 'Creating train.csv...'
  produce_csv('temp/train_gamestats.csv', train_seasons, ONLY_TRAINING=True)
  print 'Creating test.csv...'
  only_teams = defaultdict(set)
  for tids, pred in csv.reader(open("data/sample_submission.csv")):
    if tids == 'id':
      continue
    season, t1, t2 = tids.split("_")
    only_teams[season].add((t1, t2))
  produce_csv('temp/test_gamestats.csv', test_seasons, ONLY_TRAINING=False, ONLY_TEAMS=only_teams)

if not os.path.exists("./temp/"):
  os.makedirs("./temp/")

get_gamestatsfeats()