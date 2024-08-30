#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.
csv_files="games.csv"
TEMP_FILE=$(mktemp)
echo -e "\nstarting insertion of teams table\n"

awk -F, 'NR >1 {print $3; print $4}' "$csv_files" | sort | uniq > "$TEMP_FILE"
while IFS= read -r team_name; do
$PSQL \ "INSERT INTO teams (name) VALUES ('$team_name') ON CONFLICT (name) DO NOTHING;"
done < "$TEMP_FILE"

rm "$TEMP_FILE"

#insert the games data
echo -e "\n starting insertion of games table\n"

tail -n +2 "$csv_files" | while IFS=',' read -r year round winner opponent winner_goals opponent_goals;do
#gather the correct winner_id and opponent_id from the teams table
winner_id=$($PSQL \ "SELECT team_id FROM teams WHERE name='$winner'")  
opponent_id=$($PSQL \ "SELECT team_id FROM teams WHERE name='$opponent'")  

  if [[ -z $winner_id || -z $opponent_id ]]; then
    echo "Warning: One of the teams ('$winner' or '$opponent') was not found in the database. Winner ID: $winner_id, Opponent ID: $opponent_id."
    continue
  fi

#insering the data now
$PSQL "INSERT INTO games (year, round, winner_goals, opponent_goals, winner_id, opponent_id) VALUES ($year, '$round', $winner_goals, $opponent_goals, $winner_id, $opponent_id);"
done <$csv_files