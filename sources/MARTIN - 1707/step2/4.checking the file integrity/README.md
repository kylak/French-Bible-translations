# 3. checking the file integrity

`check_file_integrity.sh` vérifie l'intégrité de [`complete-Bible/MARTIN - 1707 (KJV).txt`](/complete-Bible/MARTIN%20-%201707%20(KJV).txt) : si les marqueurs `⋄` / `⌇` placés au step2 sont bien placés, ils encodent à eux seuls la versification d'origine de la traduction, et la reconstruire doit redonner — à la lettre près — les 31 171 versets de [`complete-Bible/MARTIN.txt`](/complete-Bible/MARTIN.txt). Le script produit ce fichier au passage, et le confronte à la référence obtenue par la chaîne historique (voir [step1/2.fixing_versification](/sources/MARTIN%20-%201707/step1/2.fixing_versification/README.md)).

```
complete-Bible/MARTIN - 1707 (KJV).txt
  └─ check_file_integrity.sh → complete-Bible/MARTIN.txt
```

## Entrée

`complete-Bible/MARTIN - 1707 (KJV).txt` : le texte de la MARTIN dans la versification de la KJV / 1551 (produit par [step1/3.kjv_versification](../../step1/3.kjv_versification/README.md)), annoté des marqueurs qui indiquent où la traduction plaçait ses propres frontières de versets.

| Marqueur | Signification |
| --- | --- |
| `⋄N` | la frontière du verset `N` de la versification d'origine tombe ici, dans le même chapitre |
| `⋄c:N` | idem, mais la frontière tombe dans un autre chapitre (même livre) |
| `⋄-` | pas de frontière à cet endroit : le texte reste rattaché au verset d'origine précédent |
| `⌇ … ⌇` | paire encadrant une frontière où l'ordre des mots s'entrecroise ; purement indicative, elle est retirée |
| *(aucun)* | la frontière du verset d'origine coïncide avec celle du verset KJV / 1551 de même numéro |

[`complete-Bible/MARTIN - 1707.txt`](/complete-Bible/MARTIN%20-%201707.txt) est un état intermédiaire de la bascule (son AT est déjà dans la versification d'origine, seul le NT est encore dans celle de la KJV) ; le script l'accepte aussi en entrée et donne exactement le même résultat.

## Algorithme

1. Chaque verset est découpé en fragments autour des marqueurs, qui sont retirés du texte.
2. On dresse la liste des frontières de la versification d'origine. Chaque frontière a une **position** dans le texte concaténé et une **étiquette `(chapitre, verset)`** :
   - un marqueur `⋄N` / `⋄c:N` étiquette la frontière `(chapitre visé, N)` à sa position ;
   - la frontière **par défaut** d'un verset KJV / 1551 — au début de ce verset, étiquetée `(chapitre, son numéro)` — est supprimée dès qu'un marqueur du chapitre porte ce numéro, ou qu'un `⋄-` ouvre le verset.

   Deux frontières à la même position fusionnent, et le marqueur l'emporte alors sur la frontière par défaut : c'est ce qui permet à une frontière de changer de chapitre (Nb 12:16 → 13:1, Job 40:1-5 → 39:34-38) et aux séries de marqueurs de propager un décalage (Rm 3, Rm 8, Ac 24).
3. Chaque fragment est rattaché à la dernière frontière qui le précède, et les fragments d'un même verset d'origine sont recollés dans l'ordre.

## Usage

```sh
./check_file_integrity.sh            # régénère et écrit complete-Bible/MARTIN.txt
./check_file_integrity.sh --check    # vérifie tout, n'écrit rien
```

## Garde-fous

Le script échoue si :

- l'entrée ou la sortie contient une ligne hors du format `bbcccvvv texte` ;
- des marqueurs `⋄` / `⌇` subsistent dans la sortie ;
- la numérotation des versets n'est pas contiguë (`1`, `2`, `3`, …) dans un chapitre — ce qui arrive si un marqueur mal placé laisse un verset vide ;
- en mode `--check`, `complete-Bible/MARTIN.txt` est absent ou périmé.

Il signale par ailleurs, sans échouer, une différence éventuelle avec `sources/MARTIN - 1707/step1/2.fixing_versification/step3/output3.txt`, la référence de la versification d'origine.

## Prérequis

- `gawk` (et `sh`, `grep`, `awk`, `diff`, `mktemp`)
- `complete-Bible/MARTIN - 1707 (KJV).txt`

## Résultat

`complete-Bible/MARTIN.txt` : 31 171 versets (23 213 AT + 7 958 NT), une ligne par verset au format `bbcccvvv texte`, dans l'ordre d'origine des versets de la traduction. Le fichier est actuellement identique à `sources/MARTIN - 1707/step1/2.fixing_versification/step3/output3.txt`.
