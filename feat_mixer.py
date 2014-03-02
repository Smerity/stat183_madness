from __future__ import division

import csv
import math
from collections import defaultdict


def get_features_for_seasons():
  all_teams = set()

  # Create features for training and testing data
  def create_feats(season, teamA, teamB):
    f = {}
    f['AWins'] = win_pairs[season][teamA, teamB]
    #
    f['ChessA'] = chessmetrics[season][teamA]
    f['ChessB'] = chessmetrics[season][teamB]
    #
    f['RPIA'] = RPI_score[season][teamA]
    f['RPIB'] = RPI_score[season][teamA]
    #
    for sys_name in ['CPR', 'WLK', 'DOL', 'CPA', 'DCI']:
      rankA = ordinal[season][teamA][sys_name]
      f[sys_name + 'A'] = 100 - 4 * math.log(rankA + 1) - rankA / 22
      rankB = ordinal[season][teamB][sys_name]
      f[sys_name + 'B'] = 100 - 4 * math.log(rankB + 1) - rankB / 22
    return f
  #
  win_pairs = defaultdict(lambda: defaultdict(lambda: -1))
  for season, daynum, wteam, wscore, lteam, lscore, wloc, numot in csv.reader(open("data/regular_season_results.csv")):
    # Skip the naming row
    if season == 'season':
      continue
    # Predict 1 if the first team wins, else 0
    key = tuple(sorted([lteam, wteam]))
    win_pairs[season][key] = 1 if wteam == key[0] else 0
    all_teams.add(wteam)
    all_teams.add(lteam)
  #
  chessmetrics = defaultdict(lambda: defaultdict(float))
  for season, rating_day_num, team, rating, orank in csv.reader(open("data/chessmetrics.csv")):
    # Skip the naming row
    if season == 'season':
      continue
    chessmetrics[season][team] = float(rating)
  #
  RPI_score = defaultdict(lambda: defaultdict(float))
  for season, rating_day_num, team, WP, OWP, OOWP, RPI, SOS, RPI_orank, SOS_orank in csv.reader(open("data/rpi.csv")):
    # Skip the naming row
    if season == 'season':
      continue
    RPI_score[season][team] = float(RPI)
  #
  ordinal = defaultdict(lambda: defaultdict(lambda: defaultdict(float)))
  for season, rating_day_num, sys_name, team, orank in csv.reader(open("data/ordinal_ranks_core_33.csv")):
    # Skip the naming row
    if season == 'season':
      continue
    ordinal[season][team][sys_name] = float(orank)
  #
  seasons = sorted(chessmetrics.keys())
  teams = sorted(all_teams)
  #
  features = {}
  for season in seasons:
    feats = {}
    #
    for i in xrange(len(teams) - 1):
      teamA = teams[i]
      for j in xrange(i + 1, len(teams)):
        teamB = teams[j]
        feats[(teamA, teamB)] = create_feats(season, teamA, teamB)
    #
    features[season] = feats
  return features


def add_prefix(s, f):
  d = {}
  for k, v in f.items():
    d['{}_{}'.format(s, k)] = v
  return d


def get_final_winning_feats():
  print 'Retrieving features...'
  sfeats = get_features_for_seasons()
  letters = 'ABCDEFGHIJKLMNOPQR'
  train_seasons = 'EFGHIJKL'
  test_seasons = 'NOPQR'
  #

  def produce_csv(fn, season_list, ONLY_TRAINING, ONLY_TEAMS=None):
    f = open(fn, 'w')
    rownum = 0
    FEATURES = None
    for s in season_list:
      for k in sorted(sfeats[s]):
        teamA, teamB = k
        if ONLY_TEAMS and k not in ONLY_TEAMS[s]:
          continue
        # Skip if the team didn't play against each other
        if ONLY_TRAINING and sfeats[s][k]['AWins'] == -1:
          continue
        # Populate the features
        ## AWins is so we can check our test set, Chessmetrics as we're ensembling
        feats = sfeats[s][k].copy()
        # Add all features from the last 4 previous seasons
        for p in xrange(1, 4):
          prev_season = letters[letters.find(s) - p]
          feats.update(add_prefix('P{}'.format(p), sfeats[prev_season][k]))
        #
        if rownum == 0:
          FEATURES = sorted(feats.keys())
          f.write(', '.join(['match'] + FEATURES) + '\n')
        name = '{}_{}_{}'.format(s, teamA, teamB)
        fline = ', '.join(str(feats[f]) for f in FEATURES)
        f.write('{}, {}\n'.format(name, fline))
        rownum += 1
    f.close()
  #
  print 'Creating train.csv...'
  produce_csv('temp/train.csv', train_seasons, ONLY_TRAINING=True)
  print 'Creating test.csv...'
  only_teams = defaultdict(set)
  for tids, pred in csv.reader(open("data/sample_submission.csv")):
    if tids == 'id':
      continue
    season, t1, t2 = tids.split("_")
    only_teams[season].add((t1, t2))
  produce_csv('temp/test.csv', test_seasons, ONLY_TRAINING=False, ONLY_TEAMS=only_teams)


get_final_winning_feats()
