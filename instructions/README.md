# TASK: Format Bible Translation to bbcccvvv Format

## Objective
Convert any Bible translation (HTML, CSV, text, etc.) to standardized format: `bbcccvvv text`
- `bb` = book number (01-66, zero-padded)
- `ccc` = chapter number (zero-padded)
- `vvv` = verse number (zero-padded)
- Space + verse text

**Example:** `01001001 In the beginning God created the heavens and the earth.`

**IMPORTANT**: Do not sort the verses (nor books) by their references in the final output file, but preserve the original order of the verses (like of the books) present in the translation.

## Scope Handling
The translation may contain:
- **Complete Bible**: OT (01-39) + NT (40-66)
- **OT only**: Books 01-39
- **NT only**: Books 40-66

**IMPORTANT**: If the translation is NT-only, do NOT add OT references. If OT-only, do NOT add NT references. The final output file should have the references only present in the translation, not more.

## Step-by-Step Process

### 1. Identify Source Format

**HTML:**
```
Pattern: <p class="paragraph">Gn 1:1 In the beginning...</p>
Look for: Tag containing verses, abbreviation pattern, reference format
```

**CSV:**
```
Columns: book, chapter, verse, text
Check: delimiter (`,` `;` `\t`), quotes, header row
```

**Plain text:**
```
Pattern: "Gn 1:1 In the beginning..." or similar
Identify: reference format, separators
```

### 2. Create Book Mapping

Map source abbreviations to book numbers (01-66). See `REFERENCE_BOOKS.txt` for standard mappings.

**Common variations to handle:**
- Abbreviations: "Gn" / "Gen" / "Ge"
- Numbers: "1S" / "1 S" / "I S" / "I Samuel"
- Accents: "Esaïe" / "Ésaïe" / "Isaïe"
- Encoding issues: "Hé" (Hébreux/Hebrews) often fails in UTF-8

### 3. Extract and Parse

**IMPORTANT**: If the translation doesn't contain any paragraph symbol (¶) but contains paragraphs, represent these paragraphs by adding the ¶ symbol in the beginning of verses that start new paragraphs. Whenever you add the ¶ symbol, don't put a whitespace between ¶ and the first word of the verse.

**AWK Template for HTML:**
```awk
BEGIN {
    # Book mappings (see REFERENCE_BOOKS.txt)
    BOOK["Gn"]=1; BOOK["Ex"]=2; # ... etc
    BOOK["Mt"]=40; BOOK["Mk"]=41; # ... etc
}

/<p class="paragraph">/ {
    # Pattern may vary - adjust regex to source format
    if (match($0, /<p[^>]*>([A-Za-z0-9]+) ([0-9]+):([0-9]+) (.+)<\/p>/, arr)) {
        abbrev = arr[1]
        chapter = arr[2]
        verse = arr[3]
        text = arr[4]

        # Clean text (after capture, not before)
        gsub(/<[^>]+>/, "", text)
        gsub(/&nbsp;/, " ", text)
        gsub(/&amp;/, "\\&", text)
        gsub(/&[a-z]+;/, "", text)
        gsub(/^[ \t]+/, "", text)
        gsub(/[ \t]+$/, "", text)

        if (abbrev in BOOK && text != "") {
            ref = sprintf("%02d%03d%03d", BOOK[abbrev], chapter, verse)
            print ref " " text
        }
    }
}
```

**AWK Template for CSV:**
```awk
BEGIN { FS="," }  # or ";" or "\t"
NR > 1 {  # Skip header
    gsub(/"/, "", $1); gsub(/"/, "", $2); gsub(/"/, "", $3); gsub(/"/, "", $4)
    book=$1; chapter=$2; verse=$3; text=$4
    ref = sprintf("%02d%03d%03d", book, chapter, verse)
    print ref " " text
}
```

### 4. Text Cleaning Rules

**NOTE**: For the French Darby translation, keep the '*' in "*Dieu", and in "*Seigneur". If you see a cross just before the word 'Dieu', like "✝Dieu", keep this cross.
If it's '#' that is just before the word "Dieu", replace '#' by the '✝', do not add a whitespace between the cross you've added and the word just in front of it.

**Remove:**
- HTML tags: `/<[^>]+>/`
- HTML entities: `&nbsp;` `&amp;` `&lt;` etc.
- Leading/trailing spaces
- Multiple consecutive spaces
- Footnote markers: `*` `**` `¹` `²` `³`
- Strong's numbers: `<1234>`
- Alternate versification information inside the verses: `(chapter:verse)`

**Keep:**
- Accents: é è à ç ô
- Quotes: « » " '
- Punctuation: . , ; : ! ? - —
- Brackets: [ ] (used in some translations for additions)
- Paragraph symbols: ¶

### 5. Sort and Merge

```bash
# Extract
awk -f parse.awk source.html > raw_output.txt

# Sort numerically
sort -n raw_output.txt > TRANSLATION_NAME.txt

# Merge OT+NT if separate
cat ot.txt nt.txt | sort -n > complete_bible.txt
```

## Critical Validations

### Format Check
```bash
# All lines must be: 8 digits + space + text
grep -nv "^[0-9]\{8\} .+" file.txt
# Should return nothing
```

### Residual HTML
```bash
grep -n "<[^>]*>" file.txt  # Should return nothing
grep -n "&[a-z]\+;" file.txt  # Should return nothing
```

### Encoding
```bash
file -i file.txt  # Should show: charset=utf-8
```

## Common Issues and Solutions

### Issue 1: HTML Tags Inside Verse Text
**Problem:** Regex stops at first `<` character
**Solution:** Capture entire content with `.+`, then clean HTML after
```awk
# WRONG: /<p>Gn 1:1 ([^<]+)<\/p>/
# RIGHT: /<p>Gn 1:1 (.+)<\/p>/ then gsub(/<[^>]+>/, "", text)
```

### Issue 2: Encoding of Accented Characters
**Problem:** "Hé" (Hebrews) doesn't match in AWK
**Solution:** Add multiple variants or extract separately
```awk
BOOK["Hé"] = 58
BOOK["He"] = 58
BOOK["Hébreux"] = 58
BOOK["Hebrews"] = 58
```

### Issue 3: Multiple Paragraph Classes
**Problem:** Only captures one class, misses poetry/prose
**Solution:** Match all paragraph types
```awk
# Instead of: /<p class="paragraph-Standard">/
# Use: /<p class="paragraph-/ and filter out unwanted classes
```

## Verification Checklist

**Format:**
- [ ] All lines match `^[0-9]{8} .+` pattern
- [ ] References are exactly 8 digits
- [ ] Single space between reference and text
- [ ] File sorted numerically
- [ ] UTF-8 encoding
- [ ] Unix line endings (LF, not CRLF)

**Content:**
- [ ] Correct scope (OT-only: 01-39, NT-only: 40-66, Complete: 01-66)

**Cleaning:**
- [ ] No HTML tags remain
- [ ] No HTML entities remain
- [ ] No extra spaces
- [ ] Accents preserved
- [ ] Punctuation intact

## Output Format Requirements

**File name:** `TRANSLATION_NAME.txt` (e.g., `MARTIN_1707.txt`, `DARBY.txt`)

**Example output:**
```
01001001 Au commencement Dieu créa les cieux et la terre.
01001002 La terre était informe et vide; il y avait des ténèbres...
01001003 Dieu dit: Que la lumière soit! Et la lumière fut.
...
40001001 Généalogie de Jésus-Christ, fils de David, fils d'Abraham.
40001002 Abraham engendra Isaac; Isaac engendra Jacob...
```

## Reference Files

- `REFERENCE_BOOKS.md` - Standard book number mappings

---

**Version:** 3.0
**Last updated:** 2026-04-14
