import csv
from collections import defaultdict

all_teams = set()

with open('temp/features_data.csv', 'rb') as feature_file:
	features_csv = csv.reader(feature_file, delimiter=',', quotechar='|')
	row_index = 0
	features_list = []
	features = defaultdict(lambda: defaultdict(lambda: defaultdict(float)))
	for row in features_csv:
	  if (row_index == 0):
	    features_list = row
	  else:
	    team = row[0]
	    season = row[2]
	    all_teams.add(team)
	    for i in range(4,len(row)):
	      feature = row[i]
	      feature_name = features_list[i]
	      features[season][team][feature_name] = feature
	  row_index = row_index + 1 # Update row index

print all_teams