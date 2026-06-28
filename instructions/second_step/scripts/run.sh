#!/usr/bin/env bash
# Convenience wrapper: extract → analyze → aggregate.
#
# Usage:
#   ./run.sh ORIG.txt ST.txt OUT_DIR [--first FIRST_BOOK] [--last LAST_BOOK]
#
# OUT_DIR will contain:
#   chapters/         input data per chapter
#   cache/            LLM responses per chapter (cached — re-runs skip)
#   boundaries.json   aggregated output

set -euo pipefail

if [ $# -lt 3 ]; then
  echo "usage: $0 ORIG.txt ST.txt OUT_DIR [--first N] [--last N] [--only IDS] [--model MODEL]" >&2
  exit 1
fi

ORIG="$1"; shift
ST="$1"; shift
OUT_DIR="$1"; shift

FIRST=40
LAST=66
MODEL="claude-opus-4-7"
ONLY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --first) FIRST="$2"; shift 2 ;;
    --last)  LAST="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --only)  ONLY="$2"; shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$OUT_DIR/chapters" "$OUT_DIR/cache"

ONLY_ARG=()
[ -n "$ONLY" ] && ONLY_ARG=(--only "$ONLY")

nix-shell -p python3 python3Packages.anthropic --run "
  set -e
  python3 '$HERE/extract_chapters.py' '$ORIG' '$ST' '$OUT_DIR/chapters' --books $FIRST $LAST
  python3 '$HERE/analyze_all.py' '$OUT_DIR/chapters' '$OUT_DIR/cache' --model '$MODEL' ${ONLY_ARG[@]+\"\${ONLY_ARG[@]}\"}
  python3 '$HERE/aggregate.py' '$OUT_DIR/cache' '$OUT_DIR/boundaries.json'
"
