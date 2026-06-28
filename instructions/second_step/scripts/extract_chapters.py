#!/usr/bin/env python3
"""Extract per-chapter JSON files from ORIG.txt + ST.txt.

Usage:
    python3 extract_chapters.py ORIG.txt ST.txt OUT_DIR [--books FIRST LAST]

Produces OUT_DIR/{bbccc}.json with structure:
    {"chapter": "45001", "book": 45, "chapter_in_book": 1,
     "verse_count_orig": N, "verse_count_st": M,
     "orig": {"45001001": "...", ...},
     "st":   {"45001001": "...", ...}}
"""
import argparse
import json
import os
import sys
from collections import defaultdict


def read_verses(path):
    verses = defaultdict(dict)
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if len(line) < 9 or not line[:8].isdigit() or line[8] != " ":
                continue
            ref = line[:8]
            text = line[9:]
            chap = ref[:5]
            verses[chap][ref] = text
    return verses


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("orig_txt", help="translation in its original versification (bbcccvvv)")
    ap.add_argument("st_txt", help="1551 ST reference (bbcccvvv)")
    ap.add_argument("out_dir", help="output directory for per-chapter JSON files")
    ap.add_argument("--books", nargs=2, type=int, metavar=("FIRST", "LAST"),
                    default=[40, 66], help="book range, default 40 66 (NT)")
    args = ap.parse_args()

    orig = read_verses(args.orig_txt)
    st = read_verses(args.st_txt)
    os.makedirs(args.out_dir, exist_ok=True)

    first, last = args.books
    chapters = sorted(set(orig) | set(st))
    chapters = [c for c in chapters if first <= int(c[:2]) <= last]

    written = 0
    for chap in chapters:
        if chap not in orig:
            print(f"WARN: {chap} present in ST but not in ORIG", file=sys.stderr)
            continue
        if chap not in st:
            print(f"WARN: {chap} present in ORIG but not in ST", file=sys.stderr)
            continue
        data = {
            "chapter": chap,
            "book": int(chap[:2]),
            "chapter_in_book": int(chap[2:]),
            "verse_count_orig": len(orig[chap]),
            "verse_count_st": len(st[chap]),
            "orig": dict(sorted(orig[chap].items())),
            "st": dict(sorted(st[chap].items())),
        }
        out_path = os.path.join(args.out_dir, f"{chap}.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        written += 1
    print(f"Wrote {written} chapter files to {args.out_dir}", file=sys.stderr)


if __name__ == "__main__":
    main()
