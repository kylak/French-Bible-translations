step3 traite les marqueurs (X:Y) "vers l'arrière" — c'est-à-dire ceux où X:Y est inférieur au c:v de l'ID courant.

step1 ne réécrit l'ID que pour un marqueur strictement supérieur. step2 retire ensuite les marqueurs redondants. Il reste alors une centaine de versets dont le marqueur pointe en arrière, par exemple :

- Job 40:1 marqué (39:34), Isaïe 9:1 marqué (8:23), Romains 3:24 marqué (3:23) — versets entiers à renommer.
- Marc 12:15 contient (12:14) ... (12:15), 1 Pierre 2:8 contient (2:7) ... (2:8), Apoc 13:1 contient (12:18) ... (13:1) — versets à découper.

step3.sh applique le même algorithme que step1 avec la règle assouplie (marqueur ≠ courant), fusionne les lignes consécutives partageant un même ID après réécriture (par ex. MARTIN 3:23 + MARTIN 3:24 marqué (3:23) → 45003023), et retire toute occurrence d'un marqueur qui correspond à l'ID après fusion.

Entrée : `step2/output2-3.txt`
Sortie : `step3/output3.txt`
