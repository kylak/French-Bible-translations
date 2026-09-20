Produit `complete-Bible/MARTIN - 1707 (KJV).txt` : la MARTIN - 1707 avec le découpage (versification) de la KJV.

- L'AT (01-39) vient de `../1.getting_the_translation/output.txt`, qui est la MARTIN dans la versification de la KJV. Les notes `(c:v)` de la source, qui donnent la référence du verset dans la versification d'origine de la MARTIN, sont converties en marqueurs `⋄` (comme ceux du NT) ; une note en tête de verset qui redonne la référence du verset lui-même est supprimée puisqu'elle est redondante. Voir `versification_kjv.sh`.
- Le NT (40-66) est repris tel quel de `complete-Bible/MARTIN - 1707.txt`, déjà dans la versification de la KJV (marqueurs `⋄`/`⌇` issus du `step2`).

`⋄N` (même chapitre) ou `⋄c:N` (chapitre différent) marque l'endroit où la versification d'origine de la MARTIN plaçait la frontière de son verset.
