# Instructions pour formater une traduction biblique

## Format cible : `bbcccvvv texte`

Chaque verset doit être sur une ligne unique avec le format suivant :
- `bb` : Numéro du livre (2 chiffres avec zéros initiaux)
- `ccc` : Numéro du chapitre (3 chiffres avec zéros initiaux)
- `vvv` : Numéro du verset (3 chiffres avec zéros initiaux)
- Un espace
- Le texte du verset

**Exemple :** `01001001 Au commencement Dieu créa les cieux et la terre.`

---

## Numérotation des livres

### Ordre Protestant (STANDARD)

**Ancien Testament (01-39) :**
```
01 Genèse          14 II Chroniques   27 Daniel
02 Exode           15 Esdras          28 Osée
03 Lévitique       16 Néhémie         29 Joël
04 Nombres         17 Esther          30 Amos
05 Deutéronome     18 Job             31 Abdias
06 Josué           19 Psaumes         32 Jonas
07 Juges           20 Proverbes       33 Michée
08 Ruth            21 Ecclésiaste     34 Nahum
09 I Samuel        22 Cantique        35 Habacuc
10 II Samuel       23 Ésaïe           36 Sophonie
11 I Rois          24 Jérémie         37 Aggée
12 II Rois         25 Lamentations    38 Zacharie
13 I Chroniques    26 Ézéchiel        39 Malachie
```

**Nouveau Testament (40-66) :**
```
40 Matthieu        50 Philippiens     60 I Pierre
41 Marc            51 Colossiens      61 II Pierre
42 Luc             52 I Thessaloniciens  62 I Jean
43 Jean            53 II Thessaloniciens 63 II Jean
44 Actes           54 I Timothée      64 III Jean
45 Romains         55 II Timothée     65 Jude
46 I Corinthiens   56 Tite            66 Apocalypse
47 II Corinthiens  57 Philémon
48 Galates         58 Hébreux
49 Éphésiens       59 Jacques
```

---

## Processus de formatage

### 1. IDENTIFIER LA SOURCE

Déterminer le format source de la traduction :

**a) Fichier HTML :**
- Identifier les balises contenant les versets (ex: `<p>`, `<div>`, etc.)
- Repérer le pattern de référence (ex: "Gn 1:1", "Mt 5:3", etc.)
- Identifier les balises à nettoyer

**b) Fichier CSV :**
- Identifier les colonnes : livre, chapitre, verset, texte
- Vérifier le délimiteur (virgule, point-virgule, tabulation)
- Vérifier si les champs sont entre guillemets

**c) Fichier texte structuré :**
- Identifier le pattern de référence
- Repérer les séparateurs entre les champs

**d) Fichiers multiples :**
- Un fichier par livre ou par chapitre
- Identifier la structure des noms de fichiers

### 2. CRÉER LA TABLE DE CORRESPONDANCE

Mapper les références source vers les numéros de livres :

```awk
# Exemple pour l'Ancien Testament
BOOK_MAP["Gn"] = 1
BOOK_MAP["Ex"] = 2
BOOK_MAP["Lv"] = 3
# ... etc.

# Exemple pour le Nouveau Testament
BOOK_MAP["Mt"] = 40
BOOK_MAP["Mc"] = 41
# ... etc.
```

**Important :** Vérifier toutes les variantes possibles :
- Abréviations : "Gn", "Gen", "Ge"
- Numéros : "1S", "1 S", "I S", "I Samuel"
- Accents : "Esaïe", "Ésaïe", "Isaïe"

### 3. EXTRAIRE ET PARSER

#### Pour HTML :

```awk
BEGIN {
    # Tables de correspondance
}

# Identifier le livre actuel
/<a id="at01"\/>/ {
    current_book = 1  # Genèse
}

# Identifier le chapitre actuel
/<a id="at01_05"\/>/ {
    current_chapter = 5
}

# Extraire les versets
/<p class="paragraph">/ {
    # Pattern : <p>XX Y:Z Texte</p>
    if (match($0, /<p[^>]*>([A-Za-z0-9]+) ([0-9]+):([0-9]+) (.+)<\/p>/, arr)) {
        book_abbrev = arr[1]
        chapter = arr[2]
        verse = arr[3]
        text = arr[4]

        # Nettoyer les balises HTML
        gsub(/<[^>]+>/, "", text)
        gsub(/&nbsp;/, " ", text)
        gsub(/&[a-z]+;/, "", text)
        gsub(/^[ \t]+/, "", text)
        gsub(/[ \t]+$/, "", text)

        # Mapper au numéro de livre
        if (book_abbrev in BOOK_MAP) {
            book = BOOK_MAP[book_abbrev]
            ref = sprintf("%02d%03d%03d", book, chapter, verse)
            print ref " " text
        }
    }
}
```

#### Pour CSV :

```awk
BEGIN {
    FS = ","  # ou ";" ou "\t"
}

NR > 1 {  # Skip header
    # Enlever les guillemets
    gsub(/"/, "", $1)
    gsub(/"/, "", $2)
    gsub(/"/, "", $3)
    gsub(/"/, "", $4)

    book_number = $1
    chapter = $2
    verse = $3
    text = $4

    # Mapper au numéro protestant si nécessaire
    if (book_number in BOOK_MAP) {
        book = BOOK_MAP[book_number]
    } else {
        book = book_number
    }

    ref = sprintf("%02d%03d%03d", book, chapter, verse)
    print ref " " text
}
```

### 4. NETTOYER LE TEXTE

Règles de nettoyage :

```awk
# Supprimer les balises HTML
gsub(/<[^>]+>/, "", text)

# Convertir les entités HTML
gsub(/&nbsp;/, " ", text)
gsub(/&amp;/, "&", text)
gsub(/&lt;/, "<", text)
gsub(/&gt;/, ">", text)
gsub(/&quot;/, "\"", text)
gsub(/&[a-z]+;/, "", text)  # Autres entités

# Nettoyer les espaces
gsub(/^[ \t]+/, "", text)  # Début
gsub(/[ \t]+$/, "", text)  # Fin
gsub(/  +/, " ", text)     # Multiples espaces

# Garder la ponctuation et les crochets [texte] utilisés dans certaines traductions
# NE PAS supprimer : . , ; : ! ? " ' [ ] ( ) -
```

### 5. TRIER ET FUSIONNER

```bash
# Trier numériquement par référence
sort -n fichier_brut.txt > fichier_trie.txt

# Pour fusionner AT et NT
cat ancien_testament.txt nouveau_testament.txt | sort -n > bible_complete.txt
```

### 6. VÉRIFICATIONS DE QUALITÉ

**a) Compter les versets attendus :**
```bash
# AT : environ 23,000 versets
grep "^[0-3][0-9]" fichier.txt | wc -l

# NT : environ 7,957 versets
grep "^[4-6][0-9]" fichier.txt | wc -l
```

**b) Vérifier la continuité :**
```bash
# Tous les livres sont présents
for i in $(seq -f "%02g" 1 66); do
    count=$(grep "^$i" fichier.txt | wc -l)
    echo "Livre $i : $count versets"
done
```

**c) Vérifier les premiers et derniers versets :**
```bash
# Premier verset : Genèse 1:1
head -1 fichier.txt

# Dernier verset AT : Malachie 3:24
grep "^39" fichier.txt | tail -1

# Dernier verset NT : Apocalypse 22:21
tail -1 fichier.txt
```

**d) Détecter les anomalies :**
```bash
# Lignes sans texte (référence seule)
grep "^[0-9]\{8\}$" fichier.txt

# Lignes avec format incorrect
grep -v "^[0-9]\{8\} " fichier.txt

# Doublons
sort fichier.txt | uniq -d
```

---

## GESTION DES CAS PARTICULIERS

### 1. Versets manquants

Certaines traductions omettent des versets. Options :

**a) Ligne vide avec référence seule :**
```
42007029
```

**b) Note explicative :**
```
42007029 [Verset omis dans cette traduction]
```

**c) Pas de ligne (référence absente)**

### 2. Numérotation différente des Psaumes

Les Psaumes ont des numérotations différentes selon les traditions :
- Hébraïque (protestante) : Psaumes 1-150
- Septante (catholique) : décalage d'un numéro pour Ps 10-146

**Solution :** Toujours utiliser la numérotation protestante (hébraïque).

### 3. Divisions de chapitres différentes

Exemple : Lévitique 6 a 23 versets dans certaines traductions, 30 dans d'autres.

**Solution :** Conserver la numérotation de la traduction source.

### 4. Versets longs

Si un verset est très long (>1000 caractères), vérifier qu'il n'y a pas eu de fusion accidentelle de plusieurs versets.

### 5. Caractères spéciaux

- **Garder** : accents (é, è, à, etc.), guillemets (« »), tirets (—), crochets []
- **Supprimer** : notes de bas de page (*,**,***), numéros de notes (¹,²,³)
- **Convertir** : entités HTML, caractères Unicode mal encodés

---

## EXEMPLE COMPLET (BASH + AWK)

```bash
#!/bin/bash

SOURCE_FILE="bible_source.html"
OUTPUT_FILE="MA_TRADUCTION.txt"

# Créer le script AWK
cat > /tmp/parse.awk << 'EOF'
BEGIN {
    # Tables de correspondance
    BOOK_MAP["Gn"] = 1
    BOOK_MAP["Ex"] = 2
    # ... (compléter pour tous les livres)
}

# Parser selon le format source
/<p class="verset">/ {
    if (match($0, /pattern_regex/, arr)) {
        book = BOOK_MAP[arr[1]]
        chapter = arr[2]
        verse = arr[3]
        text = arr[4]

        # Nettoyer
        gsub(/<[^>]+>/, "", text)
        gsub(/&[a-z]+;/, "", text)
        gsub(/^[ \t]+/, "", text)
        gsub(/[ \t]+$/, "", text)

        # Formater et afficher
        ref = sprintf("%02d%03d%03d", book, chapter, verse)
        print ref " " text
    }
}
EOF

# Extraire et formater
awk -f /tmp/parse.awk "$SOURCE_FILE" | sort -n > "$OUTPUT_FILE"

# Vérifications
echo "Versets extraits : $(wc -l < $OUTPUT_FILE)"
echo "Premier verset :"
head -1 "$OUTPUT_FILE"
echo "Dernier verset :"
tail -1 "$OUTPUT_FILE"

# Statistiques par testament
echo "AT : $(grep "^[0-3][0-9]" $OUTPUT_FILE | wc -l) versets"
echo "NT : $(grep "^[4-6][0-9]" $OUTPUT_FILE | wc -l) versets"
```

---

## CHECKLIST FINALE

- [ ] Tous les livres sont présents (1-39 pour AT, 40-66 pour AT+NT)
- [ ] Format correct : `bbcccvvv texte` (8 chiffres + espace + texte)
- [ ] Pas de balises HTML résiduelles
- [ ] Pas d'entités HTML non converties (&nbsp;, etc.)
- [ ] Nombre de versets cohérent (~23,000 AT, ~8,000 NT)
- [ ] Fichier trié numériquement par référence
- [ ] Premier verset = 01001001 (Genèse 1:1)
- [ ] Dernier verset AT = 39... (Malachie)
- [ ] Dernier verset NT = 66022021 (Apocalypse 22:21)
- [ ] Encodage UTF-8
- [ ] Fins de ligne Unix (LF, pas CRLF)
- [ ] Pas de lignes vides parasites
- [ ] Pas de caractères de contrôle

---

## RESSOURCES

**Nombre de versets attendus par livre (ordre protestant) :**

| Livre | Versets | Livre | Versets | Livre | Versets |
|-------|---------|-------|---------|-------|---------|
| 01 Gn | ~1530   | 23 És | ~1290   | 45 Rm | 433     |
| 02 Ex | ~1210   | 24 Jr | ~1360   | 46 1Co| 437     |
| 03 Lv | ~860    | 25 Lm | ~150    | 47 2Co| 257     |
| 04 Nb | ~1290   | 26 Éz | ~1270   | 48 Ga | 149     |
| 05 Dt | ~960    | 27 Dn | ~360    | 49 Ép | 155     |
| 06 Jos| ~660    | 28 Os | ~200    | 50 Ph | 104     |
| 07 Jg | ~620    | 29 Jl | ~70     | 51 Col| 95      |
| 08 Rt | 85      | 30 Am | ~150    | 52 1Th| 89      |
| 09 1S | ~810    | 31 Ab | 21      | 53 2Th| 47      |
| 10 2S | ~695    | 32 Jon| 48      | 54 1Ti| 113     |
| 11 1R | ~820    | 33 Mi | ~105    | 55 2Ti| 83      |
| 12 2R | ~720    | 34 Na | ~50     | 56 Tt | 46      |
| 13 1Ch| ~940    | 35 Ha | ~55     | 57 Phm| 25      |
| 14 2Ch| ~820    | 36 So | ~55     | 58 Hé | 303     |
| 15 Esd| ~280    | 37 Ag | ~40     | 59 Jc | 108     |
| 16 Né | ~405    | 38 Za | ~210    | 60 1P | 105     |
| 17 Est| ~170    | 39 Ml | ~55     | 61 2P | 61      |
| 18 Job| ~1070   | 40 Mt | 1071    | 62 1Jn| 105     |
| 19 Ps | ~2530   | 41 Mc | 678     | 63 2Jn| 13      |
| 20 Pr | ~915    | 42 Lc | 1151    | 64 3Jn| 14      |
| 21 Ec | ~220    | 43 Jn | 879     | 65 Jude| 25     |
| 22 Ct | ~120    | 44 Ac | 1007    | 66 Ap | 404     |

**Total AT :** ~23,000 versets
**Total NT :** ~7,957 versets
**Total Bible :** ~31,000 versets

---

## NOTES IMPORTANTES

1. **Préserver l'exactitude** : Ne jamais modifier le texte des versets
2. **Documenter les choix** : Si numérotation ou découpage différent, le noter
3. **Tester progressivement** : Commencer par un livre, valider, puis continuer
4. **Sauvegarder** : Garder les fichiers intermédiaires et sources
5. **Comparer** : Si possible, comparer avec d'autres traductions formatées
