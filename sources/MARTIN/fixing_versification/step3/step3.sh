#!/bin/sh
# ===============================================================================
# step3 : traite les marqueurs (X:Y) "vers l'arrière".
#
# step1 ne traite qu'un marqueur strictement supérieur au c:v courant ; les
# marqueurs inférieurs sont laissés tels quels. Après step2 (qui retire les
# marqueurs redondants où X:Y == c:v de l'ID), il reste des lignes avec un
# marqueur (X:Y) < c:v actuel — par ex. Job 40:1 marqué (39:34), Romains 3:24
# marqué (3:23), Isaïe 9:1 marqué (8:23), etc.
#
# step3 applique le même algorithme que step1 mais en autorisant les marqueurs
# dans les deux sens (X:Y != c:v courant), puis fusionne les lignes consécutives
# ayant le même ID, puis retire le marqueur de tête qui correspond désormais à
# l'ID — comme step2 le ferait.
#
# Entrée : sortie de step2-3 (output2-3.txt).
# Sortie : verses propres, sans marqueur résiduel quand celui-ci correspond à
#          l'ID après réécriture.
# ===============================================================================

[ -z "$1" ] || [ ! -f "$1" ] && { echo "Usage: $0 <fichier>" >&2; exit 1; }

TMP=$(mktemp)
PRE=$(mktemp)
trap "rm -f $TMP $PRE" EXIT

# Pass 0 (pré-traitement) : MARTIN_1707.txt contient parfois des versets
# insérés par découpe d'un verset original. Quand le marqueur arrière sur
# un verset K fait partie d'une SÉRIE (le verset K+1 a lui aussi un
# marqueur arrière), c'est le motif typique d'un décalage de versification
# où le verset K est standalone et la fusion a eu lieu AVANT la série,
# entre deux versets non-marqués. On recule alors l'ID du verset K-1 d'une
# unité pour qu'il fusionne (passe 2) avec le verset K-2.
#
# Si le marqueur arrière est isolé (un seul, pas de série), on ne fait rien
# de spécial : la fusion par même-ID naturelle absorbera le verset K dans
# son prédécesseur immédiat (cas 1 Co 3:23, 2 Co 13:14, ...).
#
# Exemples :
#   Rm 3:24 (3:23) avec Rm 3:25 (3:24) aussi marqué → série → on recule
#   Rm 3:23 vers Rm 3:22.
#   1 Co 3:23 (3:22) avec 1 Co 4:1 sans marqueur → isolé → pas de pushback,
#   1 Co 3:22 + 3:23 fusionneront naturellement sur l'ID 46003022.
cat > $PRE << 'PREEND'
{
    lines[NR] = $0
}
END {
    n = NR
    # Première passe : repérer les marqueurs arrière.
    for (i = 1; i <= n; i++) {
        is_back[i] = 0
        line = lines[i]
        id = substr(line, 1, 8)
        if (id !~ /^[0-9]{8}$/) continue
        text = substr(line, 9)
        sub(/^[ \t]+/, "", text)
        if (match(text, /^\(([0-9]+):([0-9]+)\)/, arr)) {
            c = int(substr(id, 3, 3))
            v = int(substr(id, 6, 3))
            mc = int(arr[1]); mv = int(arr[2])
            if (mc < c || (mc == c && mv < v)) {
                is_back[i] = 1
                mc_a[i] = mc
                mv_a[i] = mv
            }
        }
    }

    # Deuxième passe : appliquer le pushback uniquement aux débuts de série
    # (lignes arrière dont la suivante est aussi arrière).
    for (i = 1; i <= n; i++) {
        if (!is_back[i] || !is_back[i+1] || i == 1) continue
        cur_id = substr(lines[i], 1, 8)
        new_id = sprintf("%s%03d%03d", substr(cur_id, 1, 2), mc_a[i], mv_a[i])
        prev_id = substr(lines[i-1], 1, 8)
        prev_text = substr(lines[i-1], 9)
        sub(/^[ \t]+/, "", prev_text)
        # Pré-requis : le précédent partage l'ID-cible et n'a pas de marqueur.
        if (prev_id != new_id) continue
        if (prev_text ~ /^\([0-9]+:[0-9]+\)/) continue
        pc = int(substr(prev_id, 3, 3))
        pv = int(substr(prev_id, 6, 3))
        if (pv <= 1) continue
        pv -= 1
        lines[i-1] = sprintf("%s%03d%03d %s", substr(prev_id, 1, 2), pc, pv, prev_text)
    }

    for (i = 1; i <= n; i++) print lines[i]
}
PREEND

# Pass 1 : réécriture/découpe selon les marqueurs (toute direction sauf égalité).
cat > $TMP << 'AWKEND'
{
    if (NF == 0) { print ""; next }

    line = $0
    id = substr(line, 1, 8)
    if (id !~ /^[0-9]{8}$/) { print line; next }

    text = substr(line, 9)
    gsub(/^[ \t]+/, "", text)

    livre = substr(id, 1, 2)
    chapitre_actuel = int(substr(id, 3, 3))
    verset_actuel = int(substr(id, 6, 3))

    pos = 1
    first_segment = 1
    current_id = id
    current_text = text

    while (pos <= length(current_text)) {
        open_paren_pos = index(substr(current_text, pos), "(")
        if (open_paren_pos == 0) break
        pos_in_text = pos + open_paren_pos - 1

        close_paren_pos = index(substr(current_text, pos_in_text), ")")
        if (close_paren_pos == 0) {
            pos = pos_in_text + 1
            continue
        }
        end_pos_in_text = pos_in_text + close_paren_pos - 1

        marker_content = substr(current_text, pos_in_text + 1, end_pos_in_text - pos_in_text - 1)

        if (marker_content ~ /^[0-9]+:[0-9]+$/) {
            split(marker_content, parts, ":")
            marker_chapter = int(parts[1])
            marker_verse = int(parts[2])

            # Règle step3 : on traite tout marqueur dont la valeur diffère du
            # c:v courant (step1 ne traitait que les supérieurs).
            if (marker_chapter != chapitre_actuel || marker_verse != verset_actuel) {

                text_before = substr(current_text, 1, pos_in_text - 1)
                text_after = substr(current_text, pos_in_text)

                sub(/[ \t]+$/, "", text_before)

                new_id = sprintf("%s%03d%03d", livre, marker_chapter, marker_verse)

                if (length(text_before) > 0) {
                    printf "%s %s\n", current_id, text_before
                }
                first_segment = 0

                current_id = new_id
                current_text = text_after
                pos = 1
                chapitre_actuel = marker_chapter
                verset_actuel = marker_verse

            } else {
                pos = end_pos_in_text + 1
            }
        } else {
            pos = end_pos_in_text + 1
        }
    }

    if (!first_segment) {
        if (length(current_text) > 0) {
            printf "%s %s\n", current_id, current_text
        }
    } else {
        print line
    }
}
AWKEND

# Pass 2 : fusionne les lignes consécutives partageant le même ID. Quand
# le fragment précédent finit par , ; ou : (ponctuation non-terminale) et
# que le fragment absorbé commence par une majuscule sur un mot commun
# (article, conjonction, pronom, préposition…), on minuscule cette
# majuscule. Les noms propres (mots non reconnus) restent capitalisés.
# Exemple : Rm 3:22 « ...nulle différence, Vu que tous... » → « ...vu que tous... »
# Mais 2 Co 13:13 « ...saluent. La grâce... » est laissé tel quel (point).
awk -f $PRE "$1" | awk -f $TMP | sed '/^[0-9]\{8\}$/d' | \
awk '
function maybe_lower(prev_tail, frag,    word, lcword) {
    if (prev_tail !~ /[,;:]$/) return frag
    if (frag !~ /^[[:upper:]ÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŒÆ]/) return frag
    if (!match(frag, /^[A-Za-zÀ-ÿ]+/)) return frag
    word = substr(frag, RSTART, RLENGTH)
    lcword = tolower(word)
    if (lcword in COMMON) {
        return tolower(substr(frag, 1, 1)) substr(frag, 2)
    }
    return frag
}
BEGIN {
    split("vu et mais car or ou donc ni si sinon quand lorsque lors depuis " \
          "après avant puis comme parce pourquoi quoique alors encore déjà " \
          "néanmoins toutefois pourtant cependant aussi ainsi même " \
          "le la les un une des du de au aux à dans sur sous entre par pour " \
          "sans avec vers chez ce cet cette ces mon ma mes ton ta tes son sa " \
          "ses notre nos votre vos leur leurs je tu il elle on nous vous ils " \
          "elles ne non tout tous toute toutes que qui quoi dont où " \
          "voici voilà bien plus moins très peu trop assez ", words, " ")
    for (k in words) if (words[k] != "") COMMON[words[k]] = 1
}
{
    if (NF == 0) {
        if (length(saved_line) > 0) print saved_line
        saved_line = ""
        prev_id = ""
        print ""
        next
    }
    current_id = substr($0, 1, 8)
    current_rest = substr($0, 9)
    gsub(/^[ \t]+/, "", current_rest)
    if (current_id == prev_id) {
        # Vérifier le dernier caractère non-blanc de saved_line.
        tail = saved_line
        sub(/[ \t]+$/, "", tail)
        last_char = substr(tail, length(tail), 1)
        current_rest = maybe_lower(tail, current_rest)
        saved_line = saved_line " " current_rest
    } else {
        if (length(saved_line) > 0) print saved_line
        saved_line = $0
        prev_id = current_id
    }
}
END { if (length(saved_line) > 0) print saved_line }
' | \
awk '
{
    if (NF == 0) { print ""; next }
    id = substr($0, 1, 8)
    if (id !~ /^[0-9]{8}$/) { print; next }
    c = int(substr(id, 3, 3))
    v = int(substr(id, 6, 3))
    text = substr($0, 9)
    gsub(/^[ \t]+/, "", text)
    # Retirer toutes les occurrences du marqueur (c:v) correspondant à l''ID,
    # qu''il soit en tête ou en milieu de verset (après fusion).
    pattern = " *\\(" c ":" v "\\) *"
    gsub(pattern, " ", text)
    gsub(/  +/, " ", text)
    gsub(/^ +/, "", text)
    gsub(/ +$/, "", text)
    print id " " text
}
'
