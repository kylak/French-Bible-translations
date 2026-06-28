#!/bin/sh
# Conserve les lignes où le marqueur (C:V) correspond à ccc et vvv
while IFS= read -r line; do
  ccc="${line:2:3}"  # positions 3-5
  vvv="${line:5:3}"  # positions 6-8
  chapter=$((10#$ccc))
  verse=$((10#$vvv))
  [[ "$line" =~ \($chapter:$verse\) ]] && echo "$line"
done < "$1"
