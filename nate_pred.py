from collections import defaultdict
import csv
import re

# Convert Nate's prediction into prediction checker

teams_in_s = defaultdict(set)
seeds_in_s = defaultdict(lambda: 0)
for row in csv.DictReader(open("data/tourney_seeds.csv")):
	if row['season'] == 'S':
  		teams_in_s[row['season']].add(row['team'])
  		seeds_in_s[row['seed']] = row['team']
only_teams = defaultdict(set)
for season in sorted(teams_in_s):
  for t1 in sorted(teams_in_s[season]):
    for t2 in sorted(teams_in_s[season]):
      if t1 < t2:
        only_teams[season].add((t1, t2))

#print only_teams
# print seeds_in_s

regions = ['Midwest', 'East', 'West', 'South']
regions_letter = {'Midwest': "Y", 'East': "W", 'West': "Z", 'South': "X"}

game_prob = defaultdict(dict)
sec_prob = defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: 0)))
with open("data/nate_prediction.csv", 'rb') as csvfile:
	pred_reader = csv.reader(csvfile, delimiter=',', quotechar='"')
	for region, seed, team, sec, third, sixt, eight, four, champ, win in pred_reader:
		if region == "region":
			continue
		if len(seed) == 1:
			seed = str(0) + seed
		reg_lett = regions_letter[region]
		id = seeds_in_s[reg_lett + seed]
		game_prob[id] = {'third': 0.01 * float(re.sub("\D", "", third)), 'sixt': 0.01 * float(re.sub("\D", "", sixt)), 
		'eight': 0.01 * float(re.sub("\D", "", eight)), 'four': 0.01 * float(re.sub("\D", "", four)), 'champ': 0.01 * float(re.sub("\D", "", champ)), 'win': 0.01 * float(re.sub("\D", "", win))}
		if sec != '-1':
			fin_seed = seed[:-1]
			sec_prob[reg_lett][fin_seed][id] = 0.01 * float(re.sub("\D", "", sec))

tourney_win = defaultdict(lambda: -1)
# Solve 2nd round games
for region in regions_letter.values():
	for fin_seed in sec_prob[region].keys():
		if sec_prob[region][fin_seed].values()!= []:
			if sec_prob[region][fin_seed].values()[0] < sec_prob[region][fin_seed].values()[1]:
				id1 = sec_prob[region][fin_seed].keys()[1]
				id0 = sec_prob[region][fin_seed].keys()[0]
				seeds_in_s[fin_seed] = sec_prob[region][fin_seed].keys()[1]
				if id1 < id0:
					tourney_win[(id1, id0)] = 1
				else:
					tourney_win[(id0, id1)] = 0
			else:
				id1 = sec_prob[region][fin_seed].keys()[1]
				id0 = sec_prob[region][fin_seed].keys()[0]
				seeds_in_s[fin_seed] = sec_prob[region][fin_seed].keys()[0]
				if id1 < id0:
					tourney_win[(id1, id0)] = 0
				else:
					tourney_win[(id0, id1)] = 1

seeds_in_s['Y12'] = '695' # Weird bug
seeds_in_s['Y11'] = '790'

# Compute games outcome
win_4 = {} # Outcome for region finals
for region in regions_letter.values():
	games_3 = []
	for i in range(8):
		seed0 = ("0" + str(i + 1)) if (len(str(i + 1)) == 1) else str(i + 1)
		seed1 = ("0" + str(16 - (i + 1))) if (len(str(16 - (i + 1))) == 1) else str(16 - (i + 1))
		id0 = seeds_in_s[region + seed0]
		id1 = seeds_in_s[region + seed1]
		games_3.append((id0, id1))
	print games_3
	win_3 = []
	for match in games_3:
		id0 = match[0]
		id1 = match[1]
		if game_prob[id0]['third'] > game_prob[id1]['third']:
			win_3.append(id0)
			if id0 < id1:
					tourney_win[(id0, id1)] = 1
			else:
					tourney_win[(id1, id0)] = 0
		else:
			win_3.append(id1)
			if id0 < id1:
					tourney_win[(id0, id1)] = 0
			else:
					tourney_win[(id1, id0)] = 1

	
	games_16 = []
	for i in range(len(win_3) / 2):
		games_16.append((win_3[2 * i], win_3[2 * i + 1]))
	win_16 = []
	for match in games_16:
		id0 = match[0]
		id1 = match[1]
		if game_prob[id0]['sixt'] / game_prob[id0]['third'] > game_prob[id0]['sixt'] / game_prob[id1]['third']:
			win_16.append(id0)
			if id0 < id1:
					tourney_win[(id0, id1)] = 1
			else:
					tourney_win[(id1, id0)] = 0
		else:
			win_16.append(id1)
			if id0 < id1:
					tourney_win[(id0, id1)] = 0
			else:
					tourney_win[(id1, id0)] = 1
	print win_16
	games_8 = []
	for i in range(len(win_16) / 2):
		games_8.append((win_16[2 * i], win_16[2 * i + 1]))
	win_8 = []
	for match in games_8:
		id0 = match[0]
		id1 = match[1]
		if game_prob[id0]['eight'] / game_prob[id0]['sixt'] > game_prob[id0]['eight'] / game_prob[id1]['sixt']:
			win_8.append(id0)
			if id0 < id1:
					tourney_win[(id0, id1)] = 1
			else:
					tourney_win[(id1, id0)] = 0
		else:
			win_8.append(id1)
			if id0 < id1:
					tourney_win[(id0, id1)] = 0
			else:
					tourney_win[(id1, id0)] = 1

	games_4 = []
	for i in range(len(win_8) / 2):
		games_4.append((win_8[2 * i], win_8[2 * i + 1]))
	for match in games_4:
		id0 = match[0]
		id1 = match[1]
		if game_prob[id0]['four'] / game_prob[id0]['eight'] > game_prob[id0]['four'] / game_prob[id1]['eight']:
			win_4[region] = id0
			if id0 < id1:
					tourney_win[(id0, id1)] = 1
			else:
					tourney_win[(id1, id0)] = 0
		else:
			win_4[region] = id1
			if id0 < id1:
					tourney_win[(id0, id1)] = 0
			else:
					tourney_win[(id1, id0)] = 1

print win_4
# Compute semi-final
final = []
id0 = win_4['X']
id1 = win_4['W']
if game_prob[id0]['champ'] / game_prob[id0]['four'] > game_prob[id0]['champ'] / game_prob[id1]['four']:
	final.append(id0)
	if id0 < id1:
			tourney_win[(id0, id1)] = 1
	else:
			tourney_win[(id1, id0)] = 0
else:
	final.append(id1)
	if id0 < id1:
			tourney_win[(id0, id1)] = 0
	else:
			tourney_win[(id1, id0)] = 1
#
id0 = win_4['Z']
id1 = win_4['Y']
if game_prob[id0]['champ'] / game_prob[id0]['four'] > game_prob[id0]['champ'] / game_prob[id1]['four']:
	final.append(id0)
	if id0 < id1:
			tourney_win[(id0, id1)] = 1
	else:
			tourney_win[(id1, id0)] = 0
else:
	final.append(id1)
	if id0 < id1:
			tourney_win[(id0, id1)] = 0
	else:
			tourney_win[(id1, id0)] = 1

# Compute final
id0 = final[0]
id1 = final[1]
if game_prob[id0]['win'] / game_prob[id0]['champ'] > game_prob[id0]['win'] / game_prob[id1]['champ']:
	if id0 < id1:
			tourney_win[(id0, id1)] = 1
	else:
			tourney_win[(id1, id0)] = 0
else:
	if id0 < id1:
			tourney_win[(id0, id1)] = 0
	else:
			tourney_win[(id1, id0)] = 1

print tourney_win
row_names = ['match', 'AWins']
writer = csv.DictWriter(open('temp/nate_checker.csv', 'w'), row_names)
writer.writeheader()
for match in tourney_win.keys():
    game = {}
    game['match'] = '{}_{}_{}'.format("S", match[0], match[1])
    game['AWins'] = tourney_win[match]
    writer.writerow(game)