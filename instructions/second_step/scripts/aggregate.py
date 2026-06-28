#!/usr/bin/env python3
"""Merge cache/*.json into boundaries.json.

Usage:
    python3 aggregate.py CACHE_DIR boundaries.json
"""
import argparse
import glob
import json
import os
import sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cache_dir")
    ap.add_argument("out_json")
    args = ap.parse_args()

    result = {"by_chapter": {}, "flat": []}
    n_chapters = n_boundaries = 0

    for path in sorted(glob.glob(os.path.join(args.cache_dir, "*.json"))):
        chap = os.path.basename(path)[:-5]
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        bounds = data.get("boundaries", [])
        if not bounds:
            continue
        n_chapters += 1
        result["by_chapter"][chap] = {
            "model": data.get("model"),
            "verse_count_orig": data.get("verse_count_orig"),
            "verse_count_st": data.get("verse_count_st"),
            "boundaries": bounds,
        }
        for b in bounds:
            result["flat"].append(
                {**b, "source_chapter": chap, "source_model": data.get("model")}
            )
            n_boundaries += 1

    with open(args.out_json, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(
        f"Wrote {args.out_json}: "
        f"{n_chapters} chapters with issues, {n_boundaries} boundaries total",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
