# TASK: Format Bible Translation to bbcccvvv Format

## Objective
Convert any Bible translation (HTML, CSV, text, etc.) to standardized format: `bbcccvvv text`
- `bb` = book number (01-66, zero-padded)
- `ccc` = chapter number (zero-padded)
- `vvv` = verse number (zero-padded)
- Space + verse text

**Example:** `01001001 In the beginning God created the heavens and the earth.`

## Scope Handling
The translation may contain:
- **Complete Bible**: OT (01-39) + NT (40-66)
- **OT only**: Books 01-39
- **NT only**: Books 40-66

**IMPORTANT**: Only add missing verse references for books that EXIST in the source. If the translation is NT-only, do NOT add OT references. If OT-only, do NOT add NT references.

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

**Remove:**
- HTML tags: `/<[^>]+>/`
- HTML entities: `&nbsp;` `&amp;` `&lt;` etc.
- Leading/trailing spaces
- Multiple consecutive spaces
- Footnote markers: `*` `**` `¹` `²` `³`
- Strong's numbers: `<1234>`

**Keep:**
- Accents: é è à ç ô
- Quotes: « » " '
- Punctuation: . , ; : ! ? - —
- Brackets: [ ] (used in some translations for additions)

### 5. Sort and Merge

```bash
# Extract
awk -f parse.awk source.html > raw_output.txt

# Sort numerically
sort -n raw_output.txt > TRANSLATION_NAME.txt

# Merge OT+NT if separate
cat ot.txt nt.txt | sort -n > complete_bible.txt
```

### 6. Handle Missing Verses

**Rule:** If a verse is missing in the source, add a line with reference only (no text).

**Example:**
```
42007028 They answered, "John the Baptist..."
42007029
42007030 And he asked them, "But who do you say..."
```
Luke 7:29 is missing → blank line with reference only.

**Common missing verses:**
- Matthew: 17:21, 18:11, 23:14
- Mark: 7:16, 9:44, 9:46, 11:26, 15:28
- Luke: 17:36, 23:17
- John: 5:4, 7:53
- Acts: 8:37, 15:34, 24:7, 28:29
- Romans: 16:24

**Detection script:**
```bash
# For NT translations, check against nt_versification.txt
while read -r ref count; do
    book=$(echo $ref | cut -c1-2)
    chap=$(echo $ref | cut -c3-5)
    for v in $(seq 1 $count); do
        vref=$(printf "%02d%03d%03d" $book $chap $v)
        grep -q "^$vref" TRANSLATION.txt || echo "$vref" >> missing.txt
    done
done < nt_versification.txt

# Add missing verses
cat TRANSLATION.txt missing.txt | sort -n > TRANSLATION_complete.txt
```

## Critical Validations

### Format Check
```bash
# All lines must be: 8 digits + space + text OR 8 digits only (missing verse)
grep -nv "^[0-9]\{8\}\( \|$\)" file.txt
# Should return nothing
```

### Volume Check
```bash
# Count verses by testament
grep -c "^[0-3][0-9]" file.txt  # OT: ~23,000 expected
grep -c "^[4-6][0-9]" file.txt  # NT: 7,957 expected
```

### Residual HTML
```bash
grep -n "<[^>]*>" file.txt  # Should return nothing
grep -n "&[a-z]\+;" file.txt  # Should return nothing
```

### First/Last Verses
```bash
head -1 file.txt  # Should be 01001001 (Genesis) or 40001001 (Matthew for NT-only)
tail -1 file.txt  # Should be 39... (Malachi) or 66022021 (Revelation)
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

### Issue 4: Missing Entire Book
**Problem:** Book has 0 verses after extraction
**Solution:** Check for:
1. Encoding issue (especially Hebrews)
2. Different HTML class/tag
3. Different abbreviation
4. Book actually absent in source

## Verification Checklist

**Format:**
- [ ] All lines match `^[0-9]{8}( |$)` pattern
- [ ] References are exactly 8 digits
- [ ] Single space between reference and text
- [ ] File sorted numerically
- [ ] UTF-8 encoding
- [ ] Unix line endings (LF, not CRLF)

**Content:**
- [ ] Correct scope (OT-only: 01-39, NT-only: 40-66, Complete: 01-66)
- [ ] Volume matches expected (~23k OT, ~7957 NT)
- [ ] First verse correct (01001001 or 40001001)
- [ ] Last verse correct (39... or 66022021)
- [ ] Missing verses added (reference-only lines)

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

**Example with missing verse:**
```
40017020 Jésus leur répondit: C'est à cause de votre incrédulité...
40017021
40017022 Pendant qu'ils se tenaient réunis en Galilée, Jésus leur dit...
```

## Reference Files

- `REFERENCE_BOOKS.txt` - Standard book number mappings
- `nt_versification.txt` - NT chapter/verse counts (format: `BBCCC count`)
- `ot_versification.txt` - OT chapter/verse counts (if available)

## Expected Verse Counts

| Book | Code | Verses | Book | Code | Verses |
|------|------|--------|------|------|--------|
| Genesis | 01 | ~1530 | Matthew | 40 | 1071 |
| Exodus | 02 | ~1210 | Mark | 41 | 678 |
| Psalms | 19 | ~2530 | Luke | 42 | 1151 |
| Isaiah | 23 | ~1290 | John | 43 | 879 |
| Jeremiah | 24 | ~1360 | Acts | 44 | 1007 |
| Ezekiel | 26 | ~1270 | Romans | 45 | 433 |
| | | | Revelation | 66 | 404 |

**Total OT:** ~23,000 verses
**Total NT:** 7,957 verses
**Complete Bible:** ~31,000 verses

---

**Version:** 2.0
**Last updated:** 2026-04-05
