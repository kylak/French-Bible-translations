BEGIN {
    book = 0
    chapter = 0
    pending_paragraph_marker = 0
    in_paragraph = 0
    paragraph_text = ""
}

# Detect book changes
/<h2 class="Livre"><a name="at([0-9]+)">/ {
    if (match($0, /<a name="at([0-9]+)">/, arr)) {
        book = arr[1] + 0
        pending_paragraph_marker = 1  # First verse of each book starts a new paragraph
    }
}

/<h2 class="Livre"><a name="nt([0-9]+)">/ {
    if (match($0, /<a name="nt([0-9]+)">/, arr)) {
        book = arr[1] + 39
        pending_paragraph_marker = 1  # First verse of each book starts a new paragraph
    }
}

# Detect chapter changes
/<h2 class="Chapitre">/ {
    if (match($0, /<a name="[an]t[0-9]+_([0-9]+)">/, arr)) {
        chapter = arr[1] + 0
        # Don't set pending_paragraph_marker for chapter changes
    }
}

# Detect paragraph breaks
/<br>/ {
    pending_paragraph_marker = 1
    next
}

# Skip note paragraphs
/<p class="Note">/ {
    pending_paragraph_marker = 1
    next
}

# Skip other special classes (but NOT Posie, which contains verses)
/<p class="Clustermoyen">/ {
    next
}

# Start of regular paragraph (including Posie)
/<p/ && !/<p class="Note">/ && !/<p class="Clustermoyen">/ {
    if (book == 0 || chapter == 0) next

    in_paragraph = 1
    paragraph_text = $0

    # If paragraph closes on same line
    if (/<\/p>/) {
        process_paragraph()
        in_paragraph = 0
        paragraph_text = ""
    }
    next
}

# Continue accumulating paragraph text
in_paragraph == 1 {
    paragraph_text = paragraph_text " " $0

    # Check if paragraph closes
    if (/<\/p>/) {
        process_paragraph()
        in_paragraph = 0
        paragraph_text = ""
    }
    next
}

function process_paragraph() {
    text = paragraph_text

    # Remove opening/closing p tags
    gsub(/<\/?p[^>]*>/, "", text)

    # Remove all HTML tags
    gsub(/<[^>]+>/, "", text)

    # Replace HTML entities
    gsub(/&nbsp;/, " ", text)
    gsub(/&amp;/, "\\&", text)
    gsub(/&lt;/, "<", text)
    gsub(/&gt;/, ">", text)
    gsub(/&quot;/, "\"", text)
    gsub(/&#8217;/, "'", text)
    gsub(/&[a-z]+;/, "", text)

    # Remove carriage returns (\r) that may be in the middle of text
    gsub(/\r/, "", text)

    # Replace #Dieu and #dieu with ✝Dieu and ✝dieu
    gsub(/#Dieu/, "✝Dieu", text)
    gsub(/#dieu/, "✝dieu", text)

    # Keep biblical cross-references like [Ésaïe 7:14], [Exode 20:12], etc.
    # Also keep square brackets used for textual additions like [qui sont], [tout], etc.

    # Keep all asterisks (they are part of Darby's divine name notation)

    # Normalize spaces
    gsub(/[ \t]+/, " ", text)
    gsub(/^[ \t]+/, "", text)
    gsub(/[ \t]+$/, "", text)

    # Skip empty paragraphs
    if (text == "") return

    # Extract verse number at start
    if (match(text, /^([0-9]+) (.*)$/, arr)) {
        verse = arr[1] + 0
        verse_text = arr[2]

        # Format reference
        ref = sprintf("%02d%03d%03d", book, chapter, verse)

        # Add paragraph marker if needed
        if (pending_paragraph_marker == 1) {
            print ref " ¶" verse_text
            pending_paragraph_marker = 0
        } else {
            print ref " " verse_text
        }
    }
}
