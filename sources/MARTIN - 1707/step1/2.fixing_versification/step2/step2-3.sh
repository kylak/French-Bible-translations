#!/usr/bin/env bash
# $1 : fichier avec les bbcccvvv cibles
# $2 : fichier à nettoyer

declare -A targeted_ids
while IFS= read -r line; do
    id="${line:0:8}"
    targeted_ids["$id"]=1
done < "$1"

while IFS= read -r line; do
    id="${line:0:8}"
    if [[ -n "${targeted_ids[$id]}" ]]; then
        ccc="${id:2:3}"
        vvv="${id:5:3}"
        c=$((10#$ccc))
        v=$((10#$vvv))
        # Capture le PREMIER marqueur (X:Y) après l'ID
        if [[ "$line" =~ ^${id}[[:space:]]*\(([0-9]+):([0-9]+)\) ]]; then
            found_c="${BASH_REMATCH[1]}"
            found_v="${BASH_REMATCH[2]}"
            # Vérifie que ce marqueur correspond à c et v de l'ID
            if [[ "$found_c" == "$c" && "$found_v" == "$v" ]]; then
                line=$(echo "$line" | sed "s/ *($found_c:$found_v) */ /g; s/  */ /g")
            fi
        fi
    fi
    echo "$line"
done < "$2"
