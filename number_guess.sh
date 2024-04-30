#!/bin/bash

# Generate Random Number
RNUM=$((1 + $RANDOM % 1000))

# Connections to database
# PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
PSQL="psql --username=freecodecamp --dbname=number_guess -t -c"

# Initial prompt & read USERNAME 
echo -e "Enter your username:"
read USERNAME

# Check if user exists in database:
PLAYER_ID=$($PSQL "SELECT player_id FROM players WHERE username='$USERNAME'")

if [[ -z $PLAYER_ID ]] # player does not exist
then # add to database & welcome msg
  ADD_PLAYER=$($PSQL "INSERT INTO players(username) VALUES('$USERNAME')")
  PLAYER_ID=$($PSQL "SELECT player_id FROM players WHERE username='$USERNAME'")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else # print player stats
  PLAYER_STATS=$($PSQL "SELECT games_played,best_game FROM players WHERE username='$USERNAME'")
  echo $PLAYER_STATS | while read GAMES_PLAYED BAR BEST_GAME
  do 
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# Instruction prompt:
PARSE_GUESS() {
  #echo -e "Target Number is: $RNUM, Guess Was: $1"
  if [[ ! $1 =~ ^[0-9]+$ ]] # not a digit
  then
    echo "That is not an integer, guess again:"
    read NEXT_GUESS
    PARSE_GUESS $NEXT_GUESS
  else
    if [[ ! $1 =~ $RNUM ]]
    then
      NUMBER_OF_GUESSES=$[ $NUMBER_OF_GUESSES+1 ]
      if [[ $1 > $RNUM ]]
      then
        echo "It's lower than that, guess again:"
      else
        echo "It's higher than that, guess again:"
      fi
      read NEXT_GUESS
      PARSE_GUESS $NEXT_GUESS
    else
      echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RNUM. Nice job!"
      # Incriment Games Played
      GAMES_PLAYED=$($PSQL "SELECT games_played FROM players WHERE username='$USERNAME'")
      GAMES_PLAYED=$[ $GAMES_PLAYED+1 ]
      UPDATE_GAMES_PLAYED=$($PSQL "UPDATE players SET games_played='$GAMES_PLAYED' WHERE username='$USERNAME'")
      
      # Update Best Game (if needed) 
      BEST_GAME=$($PSQL "SELECT best_game FROM players WHERE username='$USERNAME'")
      #echo $BEST_GAME
      if [[ $BEST_GAME =~ 0 ]]
      then
        #echo "TRUE CONDITION"
        #echo "$BEST_GAME !=0 : $[ ! $BEST_GAME ]"
        UPDATE_BEST_GAME=$($PSQL "UPDATE players SET best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME'")
      fi

      if [[ $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
      then
        #echo "TRUE CONDITION"
        #echo "$NUMBER_OF_GUESSES < $BEST_GAME : $[ $NUMBER_OF_GUESSES < $BEST_GAME ]"
        UPDATE_BEST_GAME=$($PSQL "UPDATE players SET best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME'")
      fi

    fi
  fi
}


NUMBER_OF_GUESSES=1 # Initialise counter  
echo -e "Guess the secret number between 1 and 1000:"
read GUESS
PARSE_GUESS $GUESS