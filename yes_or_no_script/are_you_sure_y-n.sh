#!/bin/bash

# For those of you with indecisions...

read -p "Are you sure you want to continue? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
  echo You chose $prompt.
else
  echo You chose $prompt.
  exit 0
fi