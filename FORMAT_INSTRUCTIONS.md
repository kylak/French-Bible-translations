# Guide de formatage des traductions bibliques

## Vue d'ensemble

Ce guide décrit le processus pour convertir n'importe quelle traduction biblique (HTML, CSV, texte, etc.) vers un format standardisé compatible avec le système du CNTR.

**Format cible :** `bbcccvvv texte`
- `bb` = Numéro du livre (01-66)
- `ccc` = Numéro du chapitre
- `vvv` = Numéro du verset
- Suivi d'un espace puis du texte du verset

**Exemple :** `01001001 Au commencement Dieu créa les cieux et la terre.`

---

## Numérotation des livres (ordre protestant)

### Ancien Testament (01-39)

```
01 Genèse          11 I Rois          21 Ecclésiaste     31 Abdias
02 Exode           12 II Rois         22 Cantique        32 Jonas
03 Lévitique       13 I Chroniques    23 Ésaïe           33 Michée
04 Nombres         14 II Chroniques   24 Jérémie         34 Nahum
05 Deutéronome     15 Esdras          25 Lamentations    35 Habacuc
06 Josué           16 Néhémie         26 Ézéchiel        36 Sophonie
07 Juges           17 Esther          27 Daniel          37 Aggée
08 Ruth            18 Job             28 Osée            38 Zacharie
09 I Samuel        19 Psaumes         29 Joël            39 Malachie
10 II Samuel       20 Proverbes       30 Amos
```

### Nouveau Testament (40-66)

```
40 Matthieu        48 Galates         56 Tite            64 III Jean
41 Marc            49 Éphésiens       57 Philémon        65 Jude
42 Luc             50 Philippiens     58 Hébreux         66 Apocalypse
43 Jean            51 Colossiens      59 Jacques
44 Actes           52 I Thessaloniciens  60 I Pierre
45 Romains         53 II Thessaloniciens 61 II Pierre
46 I Corinthiens   54 I Timothée      62 I Jean
47 II Corinthiens  55 II Timothée     63 II Jean
```

---

## Processus de formatage

### Étape 1 : Analyser la source

Identifier le format du fichier source et sa structure :

**Formats courants :**
- **HTML** : balises `<p>`, `<div>`, `<span>` contenant les versets
- **CSV** : colonnes livre, chapitre, verset, texte
- **Texte** : format libre avec références (ex: "Gn 1:1")
- **Fichiers multiples** : un fichier par livre ou chapitre

**Questions à se poser :**
- Comment les références sont-elles indiquées ? (ex: "Gn 1:1", "Mt 5:3")
- Le texte contient-il des balises HTML à nettoyer ?
- Y a-t-il des notes de bas de page à supprimer ?
- Quel est l'encodage du fichier ? (UTF-8 recommandé)

### Étape 2 : Créer la table de correspondance

Mapper les abréviations source vers les numéros de livres (01-66).

**Variantes possibles à considérer :**
- Abréviations : "Gn" / "Gen" / "Ge" / "Genèse"
- Numéros : "1S" / "1 S" / "I S" / "I Samuel"
- Accents : "Esaïe" / "Ésaïe" / "Isaïe"
- Encodage : "Hé" / "He" (problème fréquent avec l'encodage UTF-8)

### Étape 3 : Extraire et nettoyer

**Nettoyage du texte :**
```awk
# Supprimer les balises HTML
gsub(/<[^>]+>/, "", text)

# Convertir les entités HTML
gsub(/&nbsp;/, " ", text)
gsub(/&amp;/, "&", text)
gsub(/&lt;/, "<", text)
gsub(/&gt;/, ">", text)
gsub(/&quot;/, "\"", text)

# Nettoyer les espaces
gsub(/^[ \t]+/, "", text)   # Début
gsub(/[ \t]+$/, "", text)   # Fin
gsub(/  +/, " ", text)      # Espaces multiples
```

**À conserver :**
- Accents : é, è, à, ç, ô, etc.
- Guillemets : « », ", '
- Ponctuation : . , ; : ! ? - —
- Crochets : [ ] (utilisés dans certaines traductions)

**À supprimer :**
- Notes de bas de page : *, **, ***, ¹, ², ³
- Numéros de Strong : <0123>
- Balises HTML
- Caractères de contrôle

### Étape 4 : Formater et trier

```bash
# Formater avec AWK
awk -f parse_script.awk source.html > output_brut.txt

# Trier numériquement
sort -n output_brut.txt > MA_TRADUCTION.txt

# Fusionner AT et NT si séparés
cat ancien_testament.txt nouveau_testament.txt | sort -n > bible_complete.txt
```

### Étape 5 : Gérer les versets manquants

**RÈGLE IMPORTANTE :** Si un verset est absent de la traduction source, le fichier final **doit** contenir une ligne avec la référence seule (sans texte).

**Exemple :**
```
42007028 Ils lui répondirent: Jean le Baptiseur; les autres, Élie...
42007029
42007030 Et il leur demanda: Et vous, qui dites-vous que je suis?
```

Le verset Luc 7:29 est manquant → ligne vide avec référence uniquement.

---

## Tables de versification de référence

### Volumes totaux

| Testament | Livres | Versets |
|-----------|--------|---------|
| Ancien Testament | 01-39 | ~23,000 |
| Nouveau Testament | 40-66 | 7,957 |
| **Total Bible** | **1-66** | **~31,000** |

### Nouveau Testament

#### MATTHIEU (40) - 28 chapitres, 1071 versets
```
Ch.  1:25   2:23   3:17   4:25   5:48   6:34   7:29
Ch.  8:34   9:38  10:42  11:30  12:50  13:58  14:36
Ch. 15:39  16:28  17:27  18:35  19:30  20:34  21:46
Ch. 22:46  23:39  24:51  25:46  26:75  27:66  28:20
```

#### MARC (41) - 16 chapitres, 678 versets
```
Ch. 1:45   2:28   3:35   4:41   5:43   6:56   7:37   8:38
Ch. 9:50  10:52  11:33  12:44  13:37  14:72  15:47  16:20
```

#### LUC (42) - 24 chapitres, 1151 versets
```
Ch.  1:80   2:52   3:38   4:44   5:39   6:49   7:50   8:56
Ch.  9:62  10:42  11:54  12:59  13:35  14:35  15:32  16:31
Ch. 17:37  18:43  19:48  20:47  21:38  22:71  23:56  24:53
```

#### JEAN (43) - 21 chapitres, 879 versets
```
Ch.  1:51   2:25   3:36   4:54   5:47   6:71   7:53   8:59
Ch.  9:41  10:42  11:57  12:50  13:38  14:31  15:27  16:33
Ch. 17:26  18:40  19:42  20:31  21:25
```

#### ACTES (44) - 28 chapitres, 1007 versets
```
Ch.  1:26   2:47   3:26   4:37   5:42   6:15   7:60   8:40
Ch.  9:43  10:48  11:30  12:25  13:52  14:28  15:41  16:40
Ch. 17:34  18:28  19:41  20:38  21:40  22:30  23:35  24:27
Ch. 25:27  26:32  27:44  28:31
```

#### ROMAINS (45) - 16 chapitres, 433 versets
```
Ch.  1:32   2:29   3:31   4:25   5:21   6:23   7:25   8:39
Ch.  9:33  10:21  11:36  12:21  13:14  14:23  15:33  16:27
```

#### I CORINTHIENS (46) - 16 chapitres, 437 versets
```
Ch.  1:31   2:16   3:23   4:21   5:13   6:20   7:40   8:13
Ch.  9:27  10:33  11:34  12:31  13:13  14:40  15:58  16:24
```

#### II CORINTHIENS (47) - 13 chapitres, 257 versets
```
Ch.  1:24   2:17   3:18   4:18   5:21   6:18   7:16
Ch.  8:24   9:15  10:18  11:33  12:21  13:14
```

#### GALATES (48) - 6 chapitres, 149 versets
```
Ch. 1:24   2:21   3:29   4:31   5:26   6:18
```

#### ÉPHÉSIENS (49) - 6 chapitres, 155 versets
```
Ch. 1:23   2:22   3:21   4:32   5:33   6:24
```

#### PHILIPPIENS (50) - 4 chapitres, 104 versets
```
Ch. 1:30   2:30   3:21   4:23
```

#### COLOSSIENS (51) - 4 chapitres, 95 versets
```
Ch. 1:29   2:23   3:25   4:18
```

#### I THESSALONICIENS (52) - 5 chapitres, 89 versets
```
Ch. 1:10   2:20   3:13   4:18   5:28
```

#### II THESSALONICIENS (53) - 3 chapitres, 47 versets
```
Ch. 1:12   2:17   3:18
```

#### I TIMOTHÉE (54) - 6 chapitres, 113 versets
```
Ch. 1:20   2:15   3:16   4:16   5:25   6:21
```

#### II TIMOTHÉE (55) - 4 chapitres, 83 versets
```
Ch. 1:18   2:26   3:17   4:22
```

#### TITE (56) - 3 chapitres, 46 versets
```
Ch. 1:16   2:15   3:15
```

#### PHILÉMON (57) - 1 chapitre, 25 versets
```
Ch. 1:25
```

#### HÉBREUX (58) - 13 chapitres, 303 versets
```
Ch.  1:14   2:18   3:19   4:16   5:14   6:20   7:28
Ch.  8:13   9:28  10:39  11:40  12:29  13:25
```

#### JACQUES (59) - 5 chapitres, 108 versets
```
Ch. 1:27   2:26   3:18   4:17   5:20
```

#### I PIERRE (60) - 5 chapitres, 105 versets
```
Ch. 1:25   2:25   3:22   4:19   5:14
```

#### II PIERRE (61) - 3 chapitres, 61 versets
```
Ch. 1:21   2:22   3:18
```

#### I JEAN (62) - 5 chapitres, 105 versets
```
Ch. 1:10   2:29   3:24   4:21   5:21
```

#### II JEAN (63) - 1 chapitre, 13 versets
```
Ch. 1:13
```

#### III JEAN (64) - 1 chapitre, 14 versets
```
Ch. 1:14
```

#### JUDE (65) - 1 chapitre, 25 versets
```
Ch. 1:25
```

#### APOCALYPSE (66) - 22 chapitres, 404 versets
```
Ch.  1:20   2:29   3:22   4:11   5:14   6:17   7:17   8:13
Ch.  9:21  10:11  11:19  12:18  13:18  14:20  15:8   16:21
Ch. 17:18  18:24  19:21  20:15  21:27  22:21
```

---

## Scripts et exemples de code

### Script AWK complet pour HTML

```awk
#!/usr/bin/awk -f

BEGIN {
    # Table de correspondance des abréviations
    # Ancien Testament
    BOOK["Gn"] = 1;   BOOK["Ex"] = 2;   BOOK["Lv"] = 3;   BOOK["Nm"] = 4
    BOOK["Dt"] = 5;   BOOK["Js"] = 6;   BOOK["Jg"] = 7;   BOOK["Rt"] = 8
    BOOK["1S"] = 9;   BOOK["2S"] = 10;  BOOK["1R"] = 11;  BOOK["2R"] = 12
    BOOK["1Ch"] = 13; BOOK["2Ch"] = 14; BOOK["Esd"] = 15; BOOK["Ne"] = 16
    BOOK["Est"] = 17; BOOK["Jb"] = 18;  BOOK["Ps"] = 19;  BOOK["Pr"] = 20
    BOOK["Ec"] = 21;  BOOK["Ct"] = 22;  BOOK["Es"] = 23;  BOOK["Jr"] = 24
    BOOK["La"] = 25;  BOOK["Ez"] = 26;  BOOK["Dn"] = 27;  BOOK["Os"] = 28
    BOOK["Jl"] = 29;  BOOK["Am"] = 30;  BOOK["Ab"] = 31;  BOOK["Jon"] = 32
    BOOK["Mi"] = 33;  BOOK["Na"] = 34;  BOOK["Ha"] = 35;  BOOK["So"] = 36
    BOOK["Ag"] = 37;  BOOK["Za"] = 38;  BOOK["Ma"] = 39

    # Nouveau Testament
    BOOK["Mt"] = 40;  BOOK["Mc"] = 41;  BOOK["Lc"] = 42;  BOOK["Jn"] = 43
    BOOK["Ac"] = 44;  BOOK["Rm"] = 45;  BOOK["1Co"] = 46; BOOK["2Co"] = 47
    BOOK["Gal"] = 48; BOOK["Eph"] = 49; BOOK["Ph"] = 50;  BOOK["Col"] = 51
    BOOK["1Th"] = 52; BOOK["2Th"] = 53; BOOK["1Ti"] = 54; BOOK["2Ti"] = 55
    BOOK["Tt"] = 56;  BOOK["Phm"] = 57; BOOK["Hé"] = 58;  BOOK["Jc"] = 59
    BOOK["1P"] = 60;  BOOK["2P"] = 61;  BOOK["1Jn"] = 62; BOOK["2Jn"] = 63
    BOOK["3Jn"] = 64; BOOK["Jd"] = 65;  BOOK["Ap"] = 66
}

# Extraction des versets
/<p class="paragraph">/ {
    # Pattern: <p class="paragraph">AB C:D Texte...</p>
    if (match($0, /<p[^>]*>([A-Za-z0-9]+) ([0-9]+):([0-9]+) (.+)<\/p>/, arr)) {
        abbrev = arr[1]
        chapter = arr[2]
        verse = arr[3]
        text = arr[4]

        # Nettoyer le texte
        gsub(/<[^>]+>/, "", text)        # Balises HTML
        gsub(/&nbsp;/, " ", text)        # Espaces insécables
        gsub(/&amp;/, "\\&", text)       # Esperluettes
        gsub(/&lt;/, "<", text)          # Chevrons
        gsub(/&gt;/, ">", text)
        gsub(/&quot;/, "\"", text)       # Guillemets
        gsub(/&[a-z]+;/, "", text)       # Autres entités
        gsub(/^[ \t]+/, "", text)        # Espaces début
        gsub(/[ \t]+$/, "", text)        # Espaces fin

        # Vérifier et formater
        if (abbrev in BOOK && text != "") {
            book_num = BOOK[abbrev]
            ref = sprintf("%02d%03d%03d", book_num, chapter, verse)
            print ref " " text
        }
    }
}
```

### Script AWK pour CSV

```awk
#!/usr/bin/awk -f

BEGIN {
    FS = ","  # Délimiteur (peut être ";" ou "\t")
    # Table de correspondance si nécessaire
}

NR > 1 {  # Ignorer la ligne d'en-tête
    # Nettoyer les guillemets
    for (i = 1; i <= NF; i++) {
        gsub(/^"/, "", $i)
        gsub(/"$/, "", $i)
    }

    book = $1
    chapter = $2
    verse = $3
    text = $4

    # Formater
    ref = sprintf("%02d%03d%03d", book, chapter, verse)
    print ref " " text
}
```

### Script Bash de vérification

```bash
#!/bin/bash

FICHIER="MA_TRADUCTION.txt"

echo "=== VÉRIFICATION DU FICHIER $FICHIER ==="
echo ""

# Compter les versets
total=$(wc -l < "$FICHIER")
at=$(grep -c "^[0-3][0-9]" "$FICHIER")
nt=$(grep -c "^[4-6][0-9]" "$FICHIER")

echo "Versets totaux : $total"
echo "Ancien Testament : $at"
echo "Nouveau Testament : $nt"
echo ""

# Premier et dernier verset
echo "Premier verset :"
head -1 "$FICHIER"
echo ""
echo "Dernier verset :"
tail -1 "$FICHIER"
echo ""

# Compter par livre
echo "=== VERSETS PAR LIVRE ==="
for i in $(seq -f "%02g" 1 66); do
    count=$(grep -c "^$i" "$FICHIER")
    if [ $count -gt 0 ]; then
        echo "Livre $i : $count versets"
    fi
done
echo ""

# Détecter les anomalies
echo "=== ANOMALIES ==="
echo "Lignes sans texte (versets manquants) :"
grep -c "^[0-9]\{8\}$" "$FICHIER"

echo "Lignes avec format incorrect :"
grep -cv "^[0-9]\{8\} " "$FICHIER"

echo "Doublons :"
sort "$FICHIER" | uniq -d | wc -l
```

### Script de détection des versets manquants

```bash
#!/bin/bash

SOURCE="/tmp/nt_versification.txt"
TRADUCTION="MA_TRADUCTION.txt"
OUTPUT="versets_manquants.txt"

> "$OUTPUT"  # Vider le fichier

while read -r line; do
    ref=$(echo "$line" | awk '{print $1}')
    count=$(echo "$line" | awk '{print $2}')

    book=$(echo "$ref" | cut -c1-2)
    chapter=$(echo "$ref" | cut -c3-5)

    for v in $(seq 1 $count); do
        verse_ref=$(printf "%02d%03d%03d" $book $chapter $v)
        if ! grep -q "^$verse_ref" "$TRADUCTION"; then
            echo "$verse_ref" >> "$OUTPUT"
        fi
    done
done < "$SOURCE"

# Ajouter les versets manquants au fichier
if [ -s "$OUTPUT" ]; then
    echo "$(wc -l < $OUTPUT) versets manquants détectés"
    cat "$TRADUCTION" "$OUTPUT" | sort -n > "${TRADUCTION}.complete"
    mv "${TRADUCTION}.complete" "$TRADUCTION"
    echo "Versets manquants ajoutés"
else
    echo "Aucun verset manquant"
fi
```

---

## Contrôle qualité

### Vérifications automatiques

**1. Format des références**
```bash
# Toutes les lignes doivent commencer par 8 chiffres + espace (ou juste 8 chiffres)
grep -nv "^[0-9]\{8\}\( \|$\)" fichier.txt
```

**2. Continuité des versets**
```bash
# Vérifier qu'il n'y a pas de sauts de versets dans un chapitre
awk '{
    ref = substr($1, 1, 5)
    verse = substr($1, 6, 3) + 0
    if (ref == prev_ref && verse != prev_verse + 1) {
        print "Saut détecté : " prev_ref prev_verse " -> " ref verse
    }
    prev_ref = ref
    prev_verse = verse
}' fichier.txt
```

**3. Balises HTML résiduelles**
```bash
grep -n "<[^>]*>" fichier.txt
```

**4. Entités HTML non converties**
```bash
grep -n "&[a-z]\+;" fichier.txt
```

**5. Volumes attendus**

| Livre | Code | Versets attendus |
|-------|------|------------------|
| Genèse | 01 | ~1,530 |
| Matthieu | 40 | 1,071 |
| Romains | 45 | 433 |
| Apocalypse | 66 | 404 |

### Vérifications manuelles

- [ ] Vérifier les 10 premiers versets (01001001 à 01001010)
- [ ] Vérifier le dernier verset de l'AT (livre 39)
- [ ] Vérifier le premier verset du NT (40001001)
- [ ] Vérifier le dernier verset du NT (66022021)
- [ ] Lire quelques versets connus pour valider le contenu
- [ ] Vérifier les livres à un seul chapitre (Abdias, Philémon, II-III Jean, Jude)

---

## Cas particuliers

### 1. Versets manquants

**Problème :** Certaines traductions omettent des versets (variantes textuelles).

**Solution :** Ajouter une ligne avec la référence seule (sans texte).

**Exemples de versets souvent absents :**
- Matthieu 17:21, 18:11, 23:14
- Marc 7:16, 9:44, 9:46, 11:26, 15:28
- Luc 17:36, 23:17
- Jean 5:4
- Actes 8:37, 15:34, 24:7, 28:29
- Romains 16:24

### 2. Numérotation des Psaumes

**Problème :** Décalage entre tradition hébraïque (protestante) et Septante (catholique).

**Solution :** Toujours utiliser la numérotation hébraïque (protestante).

| Protestant | Catholique |
|------------|------------|
| Ps 1-8 | Ps 1-8 |
| Ps 9-10 | Ps 9 |
| Ps 11-113 | Ps 10-112 |
| Ps 114-115 | Ps 113 |
| Ps 116 | Ps 114-115 |
| Ps 117-146 | Ps 116-145 |
| Ps 147 | Ps 146-147 |
| Ps 148-150 | Ps 148-150 |

### 3. Divisions de chapitres

**Problème :** Certains chapitres ont une numérotation différente selon les éditions.

**Solution :** Conserver la numérotation de la traduction source. Documenter les différences.

**Exemple :** Lévitique 5-6
- Certaines éditions : Lv 5:1-19, Lv 6:1-23
- Autres éditions : Lv 5:1-26, Lv 6:1-16

### 4. Encodage des caractères

**Problème fréquent :** Le caractère "é" dans "Hé" (Hébreux) peut causer des problèmes d'encodage.

**Solutions :**
```bash
# Vérifier l'encodage
file -i fichier.html

# Convertir en UTF-8 si nécessaire
iconv -f ISO-8859-1 -t UTF-8 fichier.html > fichier_utf8.html

# Pour Hébreux, variantes possibles
BOOK["Hé"] = 58
BOOK["He"] = 58
BOOK["Hébreux"] = 58
BOOK["Hebreux"] = 58
```

### 5. Versets très longs

**Problème :** Versets >1000 caractères peuvent indiquer une fusion accidentelle.

**Solution :** Vérifier manuellement les versets longs.

```bash
# Détecter les versets >1000 caractères
awk 'length > 1008 {print substr($1,1,8) " - " length " caractères"}' fichier.txt
```

### 6. Texte entre crochets

**Problème :** Certaines traductions utilisent [texte] pour indiquer des ajouts.

**Solution :** CONSERVER les crochets (font partie du texte de la traduction).

---

## Checklist finale

### Format et structure
- [ ] Toutes les lignes suivent le format `bbcccvvv texte` ou `bbcccvvv` (verset manquant)
- [ ] Les références sont sur 8 chiffres exactement
- [ ] Un seul espace sépare la référence du texte
- [ ] Le fichier est trié numériquement par référence
- [ ] Encodage UTF-8
- [ ] Fins de ligne Unix (LF, pas CRLF)

### Contenu
- [ ] 66 livres présents (01-39 AT, 40-66 NT pour Bible complète)
- [ ] Volume cohérent : ~23,000 versets AT, ~7,957 versets NT
- [ ] Premier verset : 01001001 (Genèse 1:1)
- [ ] Dernier verset AT : livre 39 (Malachie)
- [ ] Dernier verset NT : 66022021 (Apocalypse 22:21)

### Nettoyage
- [ ] Aucune balise HTML résiduelle (`<p>`, `<span>`, etc.)
- [ ] Aucune entité HTML non convertie (`&nbsp;`, `&amp;`, etc.)
- [ ] Pas d'espaces multiples consécutifs
- [ ] Pas d'espaces en début/fin de ligne
- [ ] Pas de lignes vides parasites
- [ ] Pas de caractères de contrôle

### Qualité
- [ ] Versets manquants identifiés et ajoutés (référence seule)
- [ ] Pas de doublons (même référence deux fois)
- [ ] Pas de sauts de numérotation dans les chapitres
- [ ] Accents et caractères spéciaux préservés
- [ ] Ponctuation correcte
- [ ] Comparaison avec table de versification (si disponible)

---

## Ressources complémentaires

### Nombre de versets par livre

| Livre | Versets | Livre | Versets | Livre | Versets |
|-------|---------|-------|---------|-------|---------|
| 01 Genèse | ~1530 | 23 Ésaïe | ~1290 | 45 Romains | 433 |
| 02 Exode | ~1210 | 24 Jérémie | ~1360 | 46 I Cor | 437 |
| 03 Lévitique | ~860 | 25 Lament. | ~150 | 47 II Cor | 257 |
| 04 Nombres | ~1290 | 26 Ézéchiel | ~1270 | 48 Galates | 149 |
| 05 Deutéronome | ~960 | 27 Daniel | ~360 | 49 Éphésiens | 155 |
| 06 Josué | ~660 | 28 Osée | ~200 | 50 Philippiens | 104 |
| 07 Juges | ~620 | 29 Joël | ~70 | 51 Colossiens | 95 |
| 08 Ruth | 85 | 30 Amos | ~150 | 52 I Thess | 89 |
| 09 I Samuel | ~810 | 31 Abdias | 21 | 53 II Thess | 47 |
| 10 II Samuel | ~695 | 32 Jonas | 48 | 54 I Tim | 113 |
| 11 I Rois | ~820 | 33 Michée | ~105 | 55 II Tim | 83 |
| 12 II Rois | ~720 | 34 Nahum | ~50 | 56 Tite | 46 |
| 13 I Chroniques | ~940 | 35 Habacuc | ~55 | 57 Philémon | 25 |
| 14 II Chroniques | ~820 | 36 Sophonie | ~55 | 58 Hébreux | 303 |
| 15 Esdras | ~280 | 37 Aggée | ~40 | 59 Jacques | 108 |
| 16 Néhémie | ~405 | 38 Zacharie | ~210 | 60 I Pierre | 105 |
| 17 Esther | ~170 | 39 Malachie | ~55 | 61 II Pierre | 61 |
| 18 Job | ~1070 | 40 Matthieu | 1071 | 62 I Jean | 105 |
| 19 Psaumes | ~2530 | 41 Marc | 678 | 63 II Jean | 13 |
| 20 Proverbes | ~915 | 42 Luc | 1151 | 64 III Jean | 14 |
| 21 Ecclésiaste | ~220 | 43 Jean | 879 | 65 Jude | 25 |
| 22 Cantique | ~120 | 44 Actes | 1007 | 66 Apocalypse | 404 |

---

**Version du guide :** 2.0
**Dernière mise à jour :** 2026-04-05
