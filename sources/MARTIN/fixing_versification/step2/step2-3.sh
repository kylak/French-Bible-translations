#!/bin/sh
while IFS= read -r line; do
  ccc="${line:2:3}"
  vvv="${line:5:3}"
  chapter=$((10#$ccc))
  verse=$((10#$vvv))
  echo "$line" | sed "s/ *($chapter:$verse) */ /g; s/  */ /g"
done < "$1"
