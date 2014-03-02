from __future__ import division

import csv
from collections import defaultdict


def get_features_for_seasons():
  # Create features for training and testing data
  def create_feats(season, teamA, teamB):
    f = {}
    if played[season][teamA] == 0:
      played[season][teamA] = 1
    if played[season][teamB] == 0:
      played[season][teamB] = 1
    f['WinA'] = wins[season][teamA] / played[season][teamA]
    f['WinB'] = wins[season][teamB] / played[season][teamB]
    AvgA = sum(totalscore[season][teamA]) / played[season][teamA]
    AvgB = sum(totalscore[season][teamB]) / played[season][teamB]
    f['AvgA.AvgB'] = AvgA - AvgB
    f['AWins'] = win_pairs[season][teamA, teamB]
    #
    f['ChessA.ChessB'] = chessmetrics[season][teamA] - chessmetrics[season][teamB]
    #
    f['WPA.WPB'] = WP_scores[season][teamA] - WP_scores[season][teamB]
    f['OWPA.OWPB'] = OWP_scores[season][teamA] - OWP_scores[season][teamB]
    f['OOWPA.OOWPB'] = OOWP_scores[season][teamA] - OOWP_scores[season][teamB]
    return f

  # Populate totalscore, won games, and played games
  all_teams = defaultdict(set)
  totalscore = defaultdict(lambda: defaultdict(list))
  wins = defaultdict(lambda: defaultdict(int))
  played = defaultdict(lambda: defaultdict(int))
  win_pairs = defaultdict(lambda: defaultdict(lambda: -1))
  for season, daynum, wteam, wscore, lteam, lscore, wloc, numot in csv.reader(open("data/regular_season_results.csv")):
    # Skip the naming row
    if season == 'season':
      continue
    wscore, lscore = int(wscore), int(lscore)
    wins[season][wteam] += 1
    played[season][wteam] += 1
    played[season][lteam] += 1
    totalscore[season][wteam].append(wscore)
    totalscore[season][lteam].append(lscore)
    # Predict 1 if the first team wins, else 0
    key = tuple(sorted([lteam, wteam]))
    win_pairs[season][key] = 1 if wteam == key[0] else 0
    #
    all_teams[season].add(wteam)
    all_teams[season].add(lteam)
  #
  chessmetrics = defaultdict(lambda: defaultdict(float))
  for season, rating_day_num, team, rating, orank in csv.reader(open("data/chessmetrics.csv")):
    # Skip the naming row
    if season == 'season':
      continue
    chessmetrics[season][team] = float(rating)
  #
  WP_scores = defaultdict(lambda: defaultdict(float))
  OWP_scores = defaultdict(lambda: defaultdict(float))
  OOWP_scores = defaultdict(lambda: defaultdict(float))
  for season, rating_day_num, team, WP, OWP, OOWP, RPI, SOS, RPI_orank, SOS_orank in csv.reader(open("data/rpi.csv")):
    # Skip the naming row
    if season == 'season':
      continue
    WP_scores[season][team] = float(WP)
    OWP_scores[season][team] = float(OWP)
    OOWP_scores[season][team] = float(OOWP)
  #
  seasons = sorted(wins.keys())
  teams = sorted(wins[seasons[0]].keys())
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
  return all_teams, features


def add_prefix(s, f):
  d = {}
  for k, v in f.items():
    d['{}_{}'.format(s, k)] = v
  return d


def get_final_winning_feats():
  print 'Retrieving features...'
  all_teams, sfeats = get_features_for_seasons()
  letters = 'ABCDEFGHIJKLMNOPQR'
  train_seasons = 'EFGHIJKL'
  test_seasons = 'NOPQR'
  #

  def produce_csv(fn, season_list, ONLY_TRAINING):
    f = open(fn, 'w')
    rownum = 0
    FEATURES = None
    for s in season_list:
      for k in sorted(sfeats[s]):
        teamA, teamB = k
        # Skip if the team didn't play against each other
        if ONLY_TRAINING and sfeats[s][k]['AWins'] == -1:
          continue
        # Populate the features
        ## AWins is so we can check our test set, Chessmetrics as we're ensembling
        feats = {
            'AWins': sfeats[s][k]['AWins'],
            'ChessA.ChessB': sfeats[s][k]['ChessA.ChessB'],
        }
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
  produce_csv('temp/test.csv', test_seasons, ONLY_TRAINING=False)


get_final_winning_feats()
