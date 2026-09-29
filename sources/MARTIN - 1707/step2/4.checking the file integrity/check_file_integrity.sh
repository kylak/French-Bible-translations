#!/bin/sh
# =============================================================================
# Vérifie l'intégrité de « complete-Bible/MARTIN - 1707 (KJV).txt », le texte
# dans la versification de la KJV / 1551 annoté des marqueurs ⋄/⌇ du step2 : si
# les marqueurs sont bien placés, ils encodent à eux seuls la versification
# d'origine de la traduction, et l'on doit retrouver
# « complete-Bible/MARTIN.txt » — et donc, en pratique, tous les 31 171 versets
# de la traduction. Le script produit ce fichier au passage.
#
# Entrée
# ------
# Le texte de la MARTIN dans la versification de la KJV / 1551, annoté des
# marqueurs placés à la main qui indiquent où la traduction plaçait ses propres
# frontières de versets :
#
#   ⋄N     la frontière du verset N de la versification d'origine tombe ici,
#          dans le même chapitre.
#   ⋄c:N   idem, mais la frontière tombe dans un autre chapitre (c et N étant
#          alors le chapitre et le verset d'origine, dans le même livre).
#   ⋄-     pas de frontière à cet endroit : le texte reste rattaché au verset
#          d'origine précédent (un verset d'origine recouvre donc deux versets
#          KJV / 1551).
#   ⌇ … ⌇  paire encadrant une frontière où l'ordre des mots s'entrecroise ;
#          purement indicative (aucun déplacement de texte), elle est retirée.
#
# L'absence de marqueur signifie que la frontière du verset d'origine coïncide
# avec celle du verset KJV / 1551 portant le même numéro.
#
# Algorithme
# ----------
# 1. Chaque verset est découpé en fragments : un fragment avant le premier
#    marqueur, puis un fragment après chaque marqueur (le marqueur lui-même est
#    retiré du texte).
# 2. On construit la liste des frontières de la versification d'origine. Chaque
#    frontière a une POSITION (absolue, dans le texte concaténé) et une ÉTIQUETTE
#    « (chapitre, verset) » :
#      - un marqueur ⋄N / ⋄c:N donne une frontière à sa position, étiquetée
#        (chapitre visé, N) ;
#      - un verset KJV / 1551 dont le numéro n'est porté par aucun marqueur de
#        son chapitre reçoit sa frontière par défaut au début de ce verset,
#        étiquetée (chapitre, son numéro) — sauf si un ⋄- en tête de ce verset
#        la supprime.
#    Deux frontières à la même position fusionnent, et c'est alors le MARQUEUR
#    qui l'emporte sur la frontière par défaut : le marqueur dit à quel verset
#    appartient la frontière, y compris quand elle est portée par un verset
#    KJV / 1551 d'un autre numéro (déplacements de frontière de chapitre, ex.
#    Nb 12:16 -> 13:1, Job 40:1-5 -> 39:34-38). Comme un marqueur pour le verset
#    N supprime par ailleurs la frontière par défaut de ce numéro, toute une
#    série de marqueurs « propage » le décalage entre deux chapitres (ex. Rm 3,
#    Rm 8, Ac 24).
# 3. Chaque fragment est rattaché à la dernière frontière qui le précède ; les
#    fragments d'un même verset d'origine sont recollés dans l'ordre.
#
# Usage
# -----
#   ./check_file_integrity.sh           # écrit complete-Bible/MARTIN.txt
#   ./check_file_integrity.sh --check   # vérifie tout, n'écrit rien
# =============================================================================
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../../.." && pwd)
MARTIN="$ROOT/sources/MARTIN - 1707"

SRC="$ROOT/complete-Bible/MARTIN - 1707.txt"
OUT="$ROOT/complete-Bible/MARTIN.txt"
# Référence de la versification d'origine, telle qu'obtenue à l'origine depuis
# source.html (step1 → step2 → step3). Sert de garde-fou indicatif.
REF="$MARTIN/step1/2.fixing_versification/step3/output3.txt"

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

command -v gawk >/dev/null 2>&1 || { echo "gawk est requis." >&2; exit 1; }
[ -f "$SRC" ] || { echo "introuvable : $SRC" >&2; exit 1; }

# --- 1. entrée : tout doit être au format « bbcccvvv texte » ----------------
if grep -qv '^[0-9]\{8\} ' "$SRC"; then
    echo "ERREUR : $SRC contient des lignes hors format « bbcccvvv texte » :" >&2
    grep -nv '^[0-9]\{8\} ' "$SRC" | head -5 >&2
    exit 1
fi

TMP=$(mktemp)
AWKSCRIPT=$(mktemp)
trap 'rm -f "$TMP" "$AWKSCRIPT"' EXIT

# --- 2. reconstruction ------------------------------------------------------
cat > "$AWKSCRIPT" << 'AWKEND'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

# addbnd(position, chapitre, verset, est_un_marqueur)
function addbnd(p, c, v, m) {
    if (nb > 0 && p == bpos[nb]) {
        # même position : le marqueur l'emporte sur la frontière par défaut
        if (m && !bmark[nb]) { bchap[nb] = c; blab[nb] = v; bmark[nb] = 1 }
        return
    }
    if (nb > 0 && p < bpos[nb]) {
        print "check_file_integrity.sh : frontière non monotone (ligne " i ")" > "/dev/stderr"
        bad = 1
    }
    nb++
    bpos[nb] = p; bchap[nb] = c; blab[nb] = v; bmark[nb] = m
}

{ raw[NR] = $0 }

END {
    n = NR

    # ------------ 1. découpage des lignes en fragments --------------------
    pos = 0
    for (i = 1; i <= n; i++) {
        line = raw[i]
        id = substr(line, 1, 8)
        if (id !~ /^[0-9]{8}$/) {
            print "check_file_integrity.sh : ligne " i " non conforme : " line > "/dev/stderr"
            bad = 1
            continue
        }

        lpos[i] = pos
        bb      = substr(id, 1, 2)          # livre
        ckey[i] = substr(id, 1, 5)          # livre + chapitre
        vers[i] = substr(id, 6, 3) + 0

        text = trim(substr(line, 9))
        gsub(/⌇/, "", text)                 # paires ⌇ : indicatives seulement
        txt[i]  = text
        tlen[i] = length(text)

        nc[i] = 0
        rest = text
        base = 0
        while ((p = index(rest, "⋄")) > 0) {
            after = substr(rest, p + 1)
            mchap = ckey[i]; mlab = 0; mlen = 1; drop = 0
            if (match(after, /^[0-9]+:[0-9]+/)) {
                t = substr(after, 1, RLENGTH)
                split(t, a, ":")
                mchap = bb sprintf("%03d", a[1] + 0)   # ⋄c:N : autre chapitre
                mlab  = a[2] + 0
                mlen  = RLENGTH
            } else if (match(after, /^[0-9]+/)) {
                mlab = substr(after, 1, RLENGTH) + 0   # ⋄N : même chapitre
                mlen = RLENGTH
            } else if (substr(after, 1, 1) == "-") {
                drop = 1; mlen = 1                     # ⋄- : pas de frontière
            }
            nc[i]++
            dmpos[i, nc[i]] = base + p - 1  # position du marqueur dans text
            dmchap[i, nc[i]] = mchap
            dmlab[i, nc[i]] = mlab
            dmlen[i, nc[i]] = mlen + 1      # + le caractère ⋄

            if (drop) {
                # ⋄- en tête du verset : pas de frontière au début de ce verset
                if (base + p - 1 == 0) marklab[ckey[i], vers[i]] = 1
            } else {
                # la frontière de ce verset d'origine est ici, et non au début
                # du verset KJV / 1551 portant le même numéro
                marklab[mchap, mlab] = 1
            }

            base = base + p + mlen
            rest = substr(text, base + 1)
        }

        pos += tlen[i] + 1
    }

    if (bad) exit 1

    # ------------ 2. frontières de la versification d'origine -------------
    nb = 0
    for (i = 1; i <= n; i++) {
        c = ckey[i]; vv = vers[i]
        if (!((c SUBSEP vv) in marklab)) addbnd(lpos[i], c, vv, 0)
        for (k = 1; k <= nc[i]; k++) {
            if (dmlab[i, k] > 0) addbnd(lpos[i] + dmpos[i, k], dmchap[i, k], dmlab[i, k], 1)
        }
    }

    # ------------ 3. rattachement des fragments ---------------------------
    bi = 0
    for (i = 1; i <= n; i++) {
        c = ckey[i]
        if (!(c in chseen)) { chseen[c] = 1; chorder[++nch] = c }
        for (k = 0; k <= nc[i]; k++) {
            if (k == 0) { fstart = 0; fpos = lpos[i] }
            else        { fstart = dmpos[i, k] + dmlen[i, k]; fpos = lpos[i] + fstart }
            fend = (k < nc[i] ? dmpos[i, k + 1] : tlen[i])
            if (fstart >= fend) continue
            frag = trim(substr(txt[i], fstart + 1, fend - fstart))
            if (frag == "") continue
            while (bi < nb && bpos[bi + 1] <= fpos) bi++
            if (bi == 0) {
                print "check_file_integrity.sh : fragment avant toute frontière (ligne " i ")" > "/dev/stderr"
                bad = 1
                continue
            }
            cc = bchap[bi]; lab = blab[bi]
            if ((cc SUBSEP lab) in out) out[cc SUBSEP lab] = out[cc SUBSEP lab] " " frag
            else                        out[cc SUBSEP lab] = frag
            if (lab > maxlab[cc]) maxlab[cc] = lab
        }
    }

    # ------------ 4. sortie -----------------------------------------------
    for (ix = 1; ix <= nch; ix++) {
        c = chorder[ix]
        bk = substr(c, 1, 2); ch = substr(c, 3, 3) + 0
        for (lab = 1; lab <= maxlab[c]; lab++) {
            t = ((c SUBSEP lab) in out ? out[c SUBSEP lab] : "")
            if (t == "") {
                print "check_file_integrity.sh : chapitre " c " : verset " lab \
                      " vide (marqueurs incohérents)" > "/dev/stderr"
                bad = 1
            }
            printf "%s%03d%03d %s\n", bk, ch, lab, t
        }
    }

    if (bad) exit 1
}
AWKEND

echo "== vérification d'intégrité : MARTIN - 1707 (KJV).txt -> MARTIN.txt (versification d'origine)"
gawk -f "$AWKSCRIPT" "$SRC" > "$TMP"

# --- 3. sortie : format, marqueurs résiduels, numérotation ------------------
if grep -qv '^[0-9]\{8\} .' "$TMP"; then
    echo "ERREUR : la sortie contient des lignes hors format « bbcccvvv texte »." >&2
    exit 1
fi
if grep -q '⋄\|⌇' "$TMP"; then
    echo "ERREUR : des marqueurs ⋄/⌇ subsistent dans la sortie." >&2
    exit 1
fi
awk '
{
    id = substr($0, 1, 8)
    b = substr(id, 1, 2); c = substr(id, 3, 3) + 0; v = substr(id, 6, 3) + 0
    if (b == pb && c == pc) {
        if (v != pv + 1) { print "ERREUR : " id " (verset attendu : " pv + 1 ")" > "/dev/stderr"; bad = 1 }
    } else if (v != 1) {
        print "ERREUR : " id " : le chapitre commence au verset " v > "/dev/stderr"; bad = 1
    }
    pb = b; pc = c; pv = v
}
END { exit bad }' "$TMP"

# --- 4. comparaison avec la référence (indicatif) ---------------------------
if [ -f "$REF" ]; then
    if diff -q "$TMP" "$REF" >/dev/null; then
        echo "   = identique à la référence step3/output3.txt"
    else
        echo "   ATTENTION : $(diff "$REF" "$TMP" | grep -c '^[<>]' || true) lignes diffèrent de la référence step3/output3.txt :"
        diff "$REF" "$TMP" | head -10 | sed 's/^/     /'
    fi
fi

if [ "$CHECK" = 1 ]; then
    if [ ! -f "$OUT" ]; then
        echo "ERREUR : $OUT est absent ; lancez le script sans --check." >&2
        exit 1
    fi
    if ! diff -q "$TMP" "$OUT" >/dev/null; then
        echo "ERREUR : $OUT n'est pas à jour." >&2
        exit 1
    fi
    echo "OK : rien à écrire, $OUT est à jour."
    exit 0
fi

# --- 5. écriture + bilan ----------------------------------------------------
mkdir -p "$(dirname "$OUT")"
cp "$TMP" "$OUT"

n=$(grep -c . "$OUT" || true)
ot=$(awk 'substr($0, 1, 2) + 0 < 40' "$OUT" | grep -c . || true)
nt=$(awk 'substr($0, 1, 2) + 0 >= 40' "$OUT" | grep -c . || true)
echo "écrit : $OUT ($n versets : $ot AT + $nt NT)"
