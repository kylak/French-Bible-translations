#!/bin/sh
# =============================================================================
# Produit « complete-Bible/MARTIN - 1707 (KJV).txt » : la MARTIN - 1707 redivisée
# selon le découpage (versification) de la KJV.
#
# AT (livres 01-39)
#   Repris de step1/1.getting_the_translation/output.txt, qui est déjà la MARTIN
#   dans la versification de la KJV (31 102 versets, structure identique à
#   KJV.csv). Les notes (c:v) de la source — elles donnent la référence du
#   verset dans la versification d'origine de la MARTIN — sont converties en
#   marqueurs ⋄, comme ceux du NT :
#       ⋄N     la frontière du verset N (versification d'origine MARTIN) tombe
#              ici, dans le même chapitre ;
#       ⋄c:N   idem, mais la frontière tombe dans un autre chapitre (déplacements
#              de frontière de chapitre, ex. Job 38:39 = MARTIN 39:1).
#   Une note en tête de verset qui redonne la référence du verset lui-même est
#   redondante (la frontière coïncide déjà) : elle est supprimée.
#
# NT (livres 40-66)
#   Repris tel quel de « complete-Bible/MARTIN - 1707.txt » (déjà dans la
#   versification de la KJV, avec les marqueurs ⋄/⌇ issus du step2).
#
# Usage : ./versification_kjv.sh
# =============================================================================
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../../.." && pwd)

SRC="$ROOT/sources/MARTIN - 1707/step1/1.getting_the_translation/output.txt"
CUR="$ROOT/complete-Bible/MARTIN - 1707.txt"
OUT="$ROOT/complete-Bible/MARTIN - 1707 (KJV).txt"
FIRST_NT_BOOK=40

[ -f "$SRC" ] || { echo "introuvable : $SRC" >&2; exit 1; }
[ -f "$CUR" ] || { echo "introuvable : $CUR" >&2; exit 1; }

# --- AT : notes (c:v) -> marqueurs ⋄ ----------------------------------------
gawk '
{
  line = $0
  if (substr(line,1,8) !~ /^[0-9]{8}$/ || substr(line,9,1) != " ") { print line; next }

  id = substr(line,1,8)
  c  = substr(id,3,3) + 0
  v  = substr(id,6,3) + 0

  rest = substr(line,10)
  out  = ""

  while (match(rest, /\([0-9]+:[0-9]+\)/)) {
    pre  = substr(rest, 1, RSTART - 1)
    note = substr(rest, RSTART, RLENGTH)
    rest = substr(rest, RSTART + RLENGTH)

    split(substr(note, 2, length(note) - 2), a, ":")
    nc = a[1] + 0
    nv = a[2] + 0

    # Note redondante en tête de verset : la frontière coïncide, rien à marquer.
    if (out == "" && pre == "" && nc == c && nv == v) {
      sub(/^[ ]+/, "", rest)
      continue
    }

    out = out pre
    if (out != "") { sub(/[ ]+$/, "", out); out = out " " }
    out = out "⋄" (nc == c ? nv "" : nc ":" nv)
    sub(/^[ ]+/, "", rest)
  }

  out = out rest
  sub(/[ ]+$/, "", out)
  print id " " out
}' "$SRC" | gawk -v limit="$FIRST_NT_BOOK" 'substr($0,1,2)+0 < limit' > "$OUT"

# --- NT : repris tel quel ----------------------------------------------------
gawk -v limit="$FIRST_NT_BOOK" 'substr($0,1,2)+0 >= limit' "$CUR" >> "$OUT"

echo "écrit : $OUT"
