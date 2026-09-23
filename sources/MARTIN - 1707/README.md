# MARTIN - 1707

Ce dossier contient les scripts qui produisent les fichiers MARTIN présents dans [complete-Bible](/complete-Bible), à partir de la source téléchargée sur le [martin1707 website](https://sites.google.com/view/martin1707) (voir [step1/1.getting_the_translation/README.md](step1/1.getting_the_translation/README.md)).

Deux fichiers en découlent :

- [`complete-Bible/MARTIN - 1707 (KJV).txt`](/complete-Bible/MARTIN%20-%201707%20(KJV).txt) — le texte dans la versification de la KJV / 1551, annoté des marqueurs `⋄` et `⌇` qui enregistrent le découpage d'origine de la traduction ;
- [`complete-Bible/MARTIN.txt`](/complete-Bible/MARTIN.txt) — le même texte dans le **découpage (versification) d'origine** de la traduction, obtenu à partir du précédent.

[`complete-Bible/MARTIN - 1707.txt`](/complete-Bible/MARTIN%20-%201707.txt) est un état intermédiaire de cette bascule : son AT est déjà dans la versification d'origine, seul le NT est encore dans celle de la KJV.

## Les étapes

| Étape | Rôle | Produit |
| --- | --- | --- |
| [step1/1.getting_the_translation](step1/1.getting_the_translation/README.md) | extraire la traduction de la source, au format `bbcccvvv` | `output.txt` |
| [step1/2.fixing_versification](step1/2.fixing_versification/README.md) | rétablir le découpage d'origine à partir des notes `(c:v)` de la source | `output3.txt` |
| [step1/3.kjv_versification](step1/3.kjv_versification/README.md) | rediviser la traduction selon la KJV / 1551 en convertissant les notes en marqueurs `⋄` | `MARTIN - 1707 (KJV).txt` |
| `step2/1.verisifying_manually` | vérifier les marqueurs à la main | — |
| [step2/2.checking_with_AI](step2/2.checking_with_AI/README.md) | vérifier les marqueurs à l'aide d'une IA | — |
| [step2/3. checking the file integrity](step2/3.%20checking%20the%20file%20integrity/README.md) | reconstruire la versification d'origine à partir des seuls marqueurs, et la comparer à la référence | `MARTIN.txt` |

## Pour mémoire : la chaîne depuis `source.html`

La versification d'origine de la traduction a d'abord été obtenue directement depuis la source, qui présente le texte dans la versification de la KJV et note en `(c:v)` la référence d'origine de certains versets :

```
source.html
  └─ step1/1.getting_the_translation/format_martin.awk   → output.txt    (bbcccvvv, notes (c:v) incluses)
     └─ step1/2.fixing_versification/step1/step1.sh      → output1.txt   (notes (c:v) "vers l'avant")
        └─ step1/2.fixing_versification/step2/*.sh       → output2-3.txt (retire les notes redondantes (cc:vv))
           └─ step1/2.fixing_versification/step3/step3.sh
                                                          → output3.txt   (découpage d'origine)
```

Ces scripts (et leurs sorties, committées) restent dans le dépôt ; `step1/2.fixing_versification/step3/output3.txt` est identique à `complete-Bible/MARTIN.txt` et sert de référence à [step2/3. checking the file integrity](step2/3.%20checking%20the%20file%20integrity/README.md).
