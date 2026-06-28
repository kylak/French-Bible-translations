#!/bin/sh
# Script shell pour extraire les lignes de MARTIN.txt contenant des références (cc:vv)

grep -E '\([0-9]{1,3}:[0-9]{1,3}\)' "$1"
