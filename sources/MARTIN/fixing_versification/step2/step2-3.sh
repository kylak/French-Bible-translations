#!/nix/store/lfbzxs5wyqd2122mpbj5azkxhxspw9cd-bash-interactive-5.3p3/bin/bash
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
        if [[ "$line" =~ "^${id} *\($c:$v\)" ]]; then
            line=$(echo "$line" | sed "s/ *($c:$v) */ /g; s/  */ /g")
        fi
    fi
    echo "$line"
done < "$2"
