#!/usr/bin/env python3
"""For each chapters/*.json, call Claude and write cache/*.json.

Skips chapters that already have a cache file. Idempotent — re-run safely.

Usage:
    python3 analyze_all.py CHAPTERS_DIR CACHE_DIR [--model claude-opus-4-7]
                                                  [--max-tokens 4000]
                                                  [--only 40001,40002,...]

Env:
    ANTHROPIC_API_KEY  required
"""
import argparse
import json
import os
import re
import sys
import time

import anthropic


SYSTEM_PROMPT = """You are auditing a French Bible translation for versification \
boundary differences against the 1551 Stephanus Greek reference.

# Task

For each chapter you receive:
- The Greek text in 1551 Stephanus versification (the TARGET standard).
- A French translation in its ORIGINAL versification (the SOURCE).

Both use bbcccvvv references (e.g. 45001029 = Romans 1:29).

Your task is to identify every verse where the French content does NOT align \
semantically with the Greek verse of the SAME bbcccvvv reference number.

# Three kinds of misalignment

## 1. boundary_shift

Same verse count in this chapter, but the French verse boundary falls at a \
different position than the Greek. Words at the START of a French verse may \
semantically belong to the END of the previous Greek verse — or vice versa.

**CRITICAL — Boundary verification protocol:**

For EVERY adjacent verse pair (French v_N → v_N+1), explicitly check the boundary:

- Does the LAST French word or short phrase of v_N translate the LAST Greek \
word or short phrase of v_N?
- Does the FIRST French word or short phrase of v_N+1 translate the FIRST \
Greek word or short phrase of v_N+1?

If either answer is NO — EVEN WHEN the two verses cover similar themes or \
overall meaning — this is a `boundary_shift`. Do not skip this check just \
because the verses look thematically equivalent. A one-word shift is still a \
shift that needs reporting.

## 2. split_needed

The French verse contains the content of TWO consecutive Greek verses (French \
has FEWER verses than Greek in this chapter). Indicate where in the French \
text the split should occur.

## 3. merge_needed

The French has TWO consecutive verses where Greek has ONE (French has MORE \
verses than Greek in this chapter). Indicate which French verses should be \
merged.

# Hard rule: propagating offsets

When a single shift causes ALL subsequent verses in the chapter to be \
renumbered (a propagating offset), report ONLY the originating verse. \
Downstream renumbering is mechanical and will be handled by a separate \
marker-insertion step.

This is a HARD rule. If you detect a split at v_N and notice that v_N+1, \
v_N+2, ... are also "shifted" as a consequence, do NOT include them in your \
output. Only the originating verse.

Example: in Romans 8, MARTIN's v20 is split into Greek v20+v21. This causes \
MARTIN v21, v22, ..., v38 to all match Greek v22, v23, ..., v39 — a +1 \
offset. You report ONLY 45008020. You do NOT report 45008021, 45008022, etc.

Same logic for merges: if MARTIN v19+v20 merge into Greek v19, and this \
causes MARTIN v21-v28 to map to Greek v20-v27, report ONLY the originating \
merge at the v19/v20 boundary.

# Output format

Return STRICT JSON only (no surrounding markdown, no commentary, no \
explanation text outside the JSON):

{
  "boundaries": [
    {
      "orig_verse": "BBCCCVVV",
      "issue": "boundary_shift" | "split_needed" | "merge_needed",
      "french_boundary_words": "5-8 French words around the boundary (verbatim quote from the French)",
      "greek_boundary_words": "the corresponding Greek words at the boundary",
      "reasoning": "one or two sentences explaining the alignment"
    }
  ]
}

If you detect NO boundary issues in this chapter, return exactly:
{"boundaries": []}

# Worked examples

## Example 1: boundary_shift (Romans 1:29-30)

INPUT — French and Greek both have 32 verses in this chapter.

French v29: "Étant remplis de toute injustice, de paillardise, de méchanceté, \
d'avarice, de malignité, pleins d'envie, de meurtre, de querelle, de fraude, \
de mauvaises moeurs."
French v30: "Rapporteurs, médisants, haïssant Dieu, outrageux, orgueilleux, \
vanteurs, inventeurs de maux, rebelles à pères et à mères."

Greek v29: "πεπληρωμένους πάσῃ ἀδικίᾳ, πορνείᾳ, πονηρίᾳ, πλεονεξίᾳ, κακίᾳ· \
μεστοὺς φθόνου, φόνου, ἔριδος, δόλου, κακοηθείας· ψιθυριστάς,"
Greek v30: "καταλάλους, θεοστυγεῖς, ὑβριστάς, ὑπερηφάνους, ἀλαζόνας, \
ἐφευρετὰς κακῶν, γονεῦσιν ἀπειθεῖς,"

BOUNDARY CHECK at v29/v30:
- Last French word of v29 = "moeurs". Last Greek word of v29 = "ψιθυριστάς" \
(= "whisperers" = "Rapporteurs" in French). MISMATCH.
- First French word of v30 = "Rapporteurs". First Greek word of v30 = \
"καταλάλους" (= "slanderers" = "médisants" in French). MISMATCH.

Both ends differ → boundary_shift. The word "Rapporteurs" (= ψιθυριστάς) \
belongs at the END of Greek v29 but appears at the START of French v30. \
Both verses contain lists of vices, so they LOOK thematically equivalent — \
but the boundary position is shifted by one word.

OUTPUT:
{"boundaries": [{
  "orig_verse": "45001030",
  "issue": "boundary_shift",
  "french_boundary_words": "mauvaises moeurs. Rapporteurs, médisants,",
  "greek_boundary_words": "κακοηθείας· ψιθυριστάς, καταλάλους,",
  "reasoning": "Greek v29 ends with ψιθυριστάς (= Rapporteurs). In MARTIN, 'Rapporteurs' is the first word of v30; it should be the last word of v29."
}]}

## Example 2: boundary_shift inside chapter (Luke 7:18-19)

INPUT — French and Greek both have 50 verses in this chapter.

French v18: "Et toutes ces choses ayant été rapportées à Jean par ses disciples;"
French v19: "Jean appela deux de ses disciples, et les envoya vers Jésus, pour \
lui dire; Es-tu celui qui devait venir, ou si nous devons en attendre un autre?"

Greek v18: "¶Καὶ ἀπήγγειλαν Ἰωάννῃ οἱ μαθηταὶ αὐτοῦ περὶ πάντων τούτων. Καὶ \
προσκαλεσάμενος δύο τινὰς τῶν μαθητῶν αὑτοῦ ὁ Ἰωάννης,"
Greek v19: "ἔπεμψε πρὸς τὸν Ἰησοῦν, λέγων, Σὺ εἶ ὁ ἐρχόμενος..."

BOUNDARY CHECK at v18/v19:
- Last French word of v18 = "disciples;". Last Greek word of v18 = "Ἰωάννης" \
(= "John"). The Greek v18 EXTENDS PAST the French v18 boundary — Greek v18 \
includes "και προσκαλεσάμενος δύο τινάς των μαθητών αυτού ο Ἰωάννης" \
(= "John, calling two of his disciples") which is at the START of French v19.
- First French word of v19 = "Jean" (= Ἰωάννης). First Greek word of v19 = \
"ἔπεμψε" (= "sent"). MISMATCH — "Jean appela deux de ses disciples" is in \
French v19 but in Greek v18.

Boundary_shift detected.

OUTPUT:
{"boundaries": [{
  "orig_verse": "42007019",
  "issue": "boundary_shift",
  "french_boundary_words": "par ses disciples; Jean appela deux",
  "greek_boundary_words": "ὁ Ἰωάννης, ἔπεμψε πρὸς τὸν Ἰησοῦν",
  "reasoning": "Greek v18 ends with 'John, calling two of his disciples'. In MARTIN this whole phrase ('Jean appela deux de ses disciples') is at the start of v19. The boundary should be moved to before 'et les envoya vers Jésus'."
}]}

## Example 3: split_needed at chapter end (1 Corinthians 3:22)

INPUT — French has 22 verses, Greek has 23.

French v22 (last in chapter): "Soit Paul, soit Apollos, soit Céphas, soit le \
monde, soit la vie, soit la mort, soit les choses présentes, soit les choses \
à venir, toutes choses sont à vous, et vous à Christ, et Christ à Dieu."

Greek v22: "εἴτε Παῦλος, εἴτε Ἀπολλὼς, εἴτε Κηφᾶς, εἴτε κόσμος, εἴτε ζωή, \
εἴτε θάνατος, εἴτε ἐνεστῶτα, εἴτε μέλλοντα· πάντα ὑμῶν ἐστιν,"
Greek v23: "ὑμεῖς δὲ Χριστοῦ, Χριστὸς δὲ Θεοῦ."

CHECK: French v22 contains the content of BOTH Greek v22 and v23. The split \
point in French is between "toutes choses sont à vous," (end of Greek v22) \
and "et vous à Christ" (start of Greek v23).

OUTPUT:
{"boundaries": [{
  "orig_verse": "46003022",
  "issue": "split_needed",
  "french_boundary_words": "toutes choses sont à vous, et vous à Christ",
  "greek_boundary_words": "πάντα ὑμῶν ἐστιν, ὑμεῖς δὲ Χριστοῦ",
  "reasoning": "French v22 covers both Greek v22 (ending at πάντα ὑμῶν ἐστιν = toutes choses sont à vous) and Greek v23 (ὑμεῖς δὲ Χριστοῦ = et vous à Christ). Split before 'et vous à Christ'."
}]}

## Example 4: merge_needed at chapter end (Mark 9:50-51)

INPUT — French has 51 verses, Greek has 50.

French v50: "C'est une bonne chose que le sel: mais si le sel perd sa saveur, \
avec quoi lui rendra-t-on sa saveur?"
French v51: "Ayez du sel en vous-mêmes, et soyez en paix entre vous."

Greek v50 (last in chapter): "Καλὸν τὸ ἅλας· ἐὰν δὲ τὸ ἅλας ἄναλον γένηται, \
ἐν τίνι αὐτὸ ἀρτύσετε; ἔχετε ἐν ἑαυτοῖς ἅλας, καὶ εἰρηνεύετε ἐν ἀλλήλοις."

CHECK: Greek v50 includes the content of BOTH French v50 and v51. There is no \
Greek v51 — French has one extra verse.

OUTPUT:
{"boundaries": [{
  "orig_verse": "41009050",
  "issue": "merge_needed",
  "french_boundary_words": "rendra-t-on sa saveur? Ayez du sel en vous-mêmes",
  "greek_boundary_words": "ἀρτύσετε; ἔχετε ἐν ἑαυτοῖς ἅλας",
  "reasoning": "French has 51 verses in Mark 9, Greek has 50. Greek v50 absorbs both French v50 ('lui rendra-t-on sa saveur?') and v51 ('Ayez du sel...') — they form a single Greek verse."
}]}

## Example 5: split with propagation — report ONLY the originating verse (Romans 8:20)

INPUT — French has 38 verses, Greek has 39.

French v20 (a long sentence): "(Parce que les créatures sont sujettes à la \
vanité, non de leur volonté; mais à cause de celui qui les [y] a assujetties) \
[elles l'attendent, dis-je,] dans l'espérance qu'elles seront aussi délivrées \
de la servitude de la corruption, [pour être] en la liberté de la gloire des \
enfants de Dieu."
French v21: "Car nous savons que toutes les créatures soupirent..."
French v22: "Et non seulement [elles], mais nous aussi..."

Greek v20: "τῇ γὰρ ματαιότητι ἡ κτίσις ὑπετάγη, οὐχ ἑκοῦσα, ἀλλὰ διὰ τὸν \
ὑποτάξαντα ἐπʼ ἑλπίδι·"
Greek v21: "ὅτι καὶ αὐτὴ ἡ κτίσις ἐλευθερωθήσεται ἀπὸ τῆς δουλείας τῆς \
φθορᾶς εἰς τὴν ἐλευθερίαν τῆς δόξης τῶν τέκνων τοῦ Θεοῦ."
Greek v22: "Οἴδαμεν γὰρ ὅτι πᾶσα ἡ κτίσις συστενάζει..."

CHECK: French v20 = Greek v20 + Greek v21 combined. After this split, French \
v21 corresponds to Greek v22, French v22 to Greek v23, etc. — a propagating \
+1 offset all the way to French v38 / Greek v39.

By the hard rule: report ONLY the originating split at v20. Do NOT also \
report v21, v22, v23, ... as "shifted", even though they are.

OUTPUT (one entry only, despite the offset propagating through ~18 verses):
{"boundaries": [{
  "orig_verse": "45008020",
  "issue": "split_needed",
  "french_boundary_words": "dans l'espérance qu'elles seront aussi délivrées",
  "greek_boundary_words": "ἐπʼ ἑλπίδι· ὅτι καὶ αὐτὴ",
  "reasoning": "French v20 combines Greek v20 (ending ἐπʼ ἑλπίδι = dans l'espérance) and Greek v21 (ὅτι καὶ αὐτὴ ἡ κτίσις... = qu'elles seront aussi délivrées...). Split before 'qu'elles seront aussi délivrées'."
}]}

## Example 6: merge with propagation — report ONLY the originating merge (Acts 24:19-20)

INPUT — French has 28 verses, Greek has 27.

French v19: "Et [c'étaient] de certains Juifs d'Asie,"
French v20: "Qui devaient comparaître devant toi, et m'accuser, s'ils avaient \
quelque chose contre moi."
French v21: "Ou que ceux-ci eux-mêmes disent..."

Greek v19: "τινὲς δὲ ἀπὸ τῆς Ἀσίας Ἰουδαῖοι, οὓς δεῖ ἐπὶ σοῦ παρεῖναι καὶ \
κατηγορεῖν, εἴτι ἔχοιεν πρός με·"
Greek v20: "ἢ αὐτοὶ οὗτοι εἰπάτωσαν εἴτι εὗρον ἐν ἐμοὶ ἀδίκημα..."

CHECK: French v19 + v20 combined = Greek v19. After this merge, French v21 \
corresponds to Greek v20, French v22 to Greek v21, etc. — a propagating \
-1 offset.

Report ONLY the originating merge.

OUTPUT:
{"boundaries": [{
  "orig_verse": "44024019",
  "issue": "merge_needed",
  "french_boundary_words": "Juifs d'Asie, Qui devaient comparaître",
  "greek_boundary_words": "Ἰουδαῖοι, οὓς δεῖ ἐπὶ σοῦ παρεῖναι",
  "reasoning": "French has 28 verses in Acts 24, Greek has 27. Greek v19 absorbs both French v19 ('certains Juifs d'Asie,') and French v20 ('Qui devaient comparaître...')."
}]}

## Example 7: no issues (a chapter where French and Greek align perfectly)

INPUT — French and Greek both have N verses; every French verse v_K covers \
exactly the same content range as Greek v_K, with matching first and last \
words at every boundary.

OUTPUT:
{"boundaries": []}

# Final guidance

- Be precise: only report ACTUAL semantic misalignments at verse boundaries, \
NOT stylistic differences, paraphrasing choices, word order within a verse, or \
synonym choices.
- BUT: perform the boundary verification protocol on EVERY verse pair. Even \
subtle one-word shifts are real boundary shifts that need a marker.
- For propagating offsets, report ONLY the originating verse, NEVER the \
downstream consequences.
- French phrasing may be looser than Greek (parentheses, brackets, expansions). \
What matters is the BOUNDARY POSITION, not translation style.
- If a verse contains content that is missing from the Greek (or vice versa) \
this is not a boundary issue — it is a textual variant. Do NOT report it.
- Return JSON only. No markdown fences. No prose around the JSON."""


def build_user_message(chapter_data):
    chap = chapter_data["chapter"]
    name = f"book {chapter_data['book']}, chapter {chapter_data['chapter_in_book']}"

    def fmt(verses):
        return "\n".join(f"{ref} {text}" for ref, text in sorted(verses.items()))

    return f"""Chapter: {chap} ({name})
French verse count (original versification): {chapter_data['verse_count_orig']}
Greek verse count (1551 ST):                 {chapter_data['verse_count_st']}

=== Greek 1551 ST ===
{fmt(chapter_data['st'])}

=== French (original versification) ===
{fmt(chapter_data['orig'])}
"""


def parse_response(raw_text):
    """Extract the JSON object from the model's response."""
    try:
        return json.loads(raw_text)
    except json.JSONDecodeError:
        pass
    # Strip markdown fences if present
    m = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", raw_text, re.DOTALL)
    if m:
        return json.loads(m.group(1))
    # Best-effort: first balanced object
    m = re.search(r"\{.*\}", raw_text, re.DOTALL)
    if m:
        return json.loads(m.group(0))
    raise ValueError(f"could not extract JSON from response: {raw_text[:300]}...")


def analyze_chapter(client, chapter_data, model, max_tokens):
    response = client.messages.create(
        model=model,
        max_tokens=max_tokens,
        thinking={"type": "adaptive"},
        output_config={"effort": "max"},
        system=[
            {
                "type": "text",
                "text": SYSTEM_PROMPT,
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[{"role": "user", "content": build_user_message(chapter_data)}],
    )
    raw = "".join(b.text for b in response.content if b.type == "text")
    parsed = parse_response(raw)
    return {
        "chapter": chapter_data["chapter"],
        "model": response.model,
        "verse_count_orig": chapter_data["verse_count_orig"],
        "verse_count_st": chapter_data["verse_count_st"],
        "boundaries": parsed.get("boundaries", []),
        "raw_response": raw,
        "usage": {
            "input_tokens": response.usage.input_tokens,
            "output_tokens": response.usage.output_tokens,
            "cache_creation_input_tokens": getattr(
                response.usage, "cache_creation_input_tokens", 0
            ),
            "cache_read_input_tokens": getattr(
                response.usage, "cache_read_input_tokens", 0
            ),
        },
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("chapters_dir")
    ap.add_argument("cache_dir")
    ap.add_argument("--model", default="claude-opus-4-7")
    ap.add_argument("--max-tokens", type=int, default=8000)
    ap.add_argument("--only", help="comma-separated chapter IDs (bbccc) to process")
    ap.add_argument("--sleep", type=float, default=0.3, help="delay between API calls")
    args = ap.parse_args()

    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("ERROR: ANTHROPIC_API_KEY not set", file=sys.stderr)
        sys.exit(2)

    os.makedirs(args.cache_dir, exist_ok=True)
    client = anthropic.Anthropic()

    only = set(args.only.split(",")) if args.only else None
    chapter_files = sorted(
        f for f in os.listdir(args.chapters_dir) if f.endswith(".json")
    )

    total_in = total_out = total_cache_read = total_cache_create = 0
    ran = skipped = errored = 0

    for fname in chapter_files:
        chap = fname[:-5]
        if only and chap not in only:
            continue
        cache_path = os.path.join(args.cache_dir, fname)
        if os.path.exists(cache_path):
            skipped += 1
            continue

        with open(os.path.join(args.chapters_dir, fname), encoding="utf-8") as f:
            chapter_data = json.load(f)

        try:
            result = analyze_chapter(client, chapter_data, args.model, args.max_tokens)
        except Exception as e:
            print(f"  ERROR {chap}: {e}", file=sys.stderr)
            errored += 1
            time.sleep(args.sleep)
            continue

        with open(cache_path, "w", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)

        u = result["usage"]
        total_in += u["input_tokens"]
        total_out += u["output_tokens"]
        total_cache_read += u["cache_read_input_tokens"]
        total_cache_create += u["cache_creation_input_tokens"]
        n = len(result["boundaries"])
        print(
            f"  {chap}: {n} boundary issue(s) "
            f"[in={u['input_tokens']} out={u['output_tokens']} "
            f"cache_r={u['cache_read_input_tokens']} cache_w={u['cache_creation_input_tokens']}]"
        )
        ran += 1
        time.sleep(args.sleep)

    print(
        f"\nSummary: ran={ran} skipped={skipped} errored={errored}\n"
        f"Tokens: input={total_in} output={total_out} "
        f"cache_read={total_cache_read} cache_create={total_cache_create}",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
