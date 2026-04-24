#!/usr/bin/env bash

# Script to verify that the local CAHEN source folder matches Sefaria's git repository
# Checks against the latest commit on the master branch

set -euo pipefail

REPO_OWNER="Sefaria"
REPO_NAME="Sefaria-Data"
BRANCH="master"
REMOTE_PATH="sources/French Levangile Tanakh"
LOCAL_SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)/source"

echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Branch: $BRANCH"
echo ""

# Get the latest commit hash
echo "Fetching latest commit from $BRANCH branch..."
COMMIT_RESPONSE=$(curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/commits/$BRANCH")

# Extract commit hash
COMMIT_HASH=$(echo "$COMMIT_RESPONSE" | grep '"sha":' | head -1 | sed 's/.*"sha": "\([^"]*\)".*/\1/')

if [ -z "$COMMIT_HASH" ]; then
    echo "ERROR: Could not fetch latest commit hash"
    exit 1
fi

echo "Latest commit: $COMMIT_HASH"
echo "Remote path: $REMOTE_PATH"
echo "Local source: $LOCAL_SOURCE_DIR"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Fetching file list with SHA hashes from GitHub API..."

# URL-encode the remote path (replace spaces with %20)
ENCODED_REMOTE_PATH=$(echo "$REMOTE_PATH" | sed 's/ /%20/g')

# Get the file list from GitHub API
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/$ENCODED_REMOTE_PATH?ref=$COMMIT_HASH"
FILE_LIST=$(curl -s "$API_URL")

# Save the full JSON response for SHA extraction
echo "$FILE_LIST" > "$TEMP_DIR/api_response.json"

# Check for API errors
if [ -z "$FILE_LIST" ]; then
    echo "ERROR: API request failed - no response received"
    exit 1
fi

# Check if response contains an error message (disable exit on error temporarily)
set +e
echo "$FILE_LIST" | grep -q '"message"'
HAS_MESSAGE=$?
set -e

if [ $HAS_MESSAGE -eq 0 ]; then
    # Has a message field, check if it's an error
    set +e
    echo "$FILE_LIST" | grep -q '"Not Found"'
    IS_NOT_FOUND=$?
    set -e

    if [ $IS_NOT_FOUND -eq 0 ]; then
        echo "ERROR: Remote path not found in repository"
        exit 1
    fi
fi

# Extract file names from JSON
REMOTE_FILES=$(echo "$FILE_LIST" | grep '"name":' | sed 's/.*"name": "\([^"]*\)".*/\1/' | sort)

if [ -z "$REMOTE_FILES" ]; then
    echo "ERROR: Could not parse file list from GitHub API"
    exit 1
fi

REMOTE_COUNT=$(echo "$REMOTE_FILES" | wc -l)

# Get local files
if [ ! -d "$LOCAL_SOURCE_DIR" ]; then
    echo "ERROR: Local source directory not found: $LOCAL_SOURCE_DIR"
    exit 1
fi

LOCAL_FILES=$(cd "$LOCAL_SOURCE_DIR" && ls -1 2>/dev/null | sort)
LOCAL_COUNT=$(echo "$LOCAL_FILES" | wc -l)

echo "Remote files: $REMOTE_COUNT"
echo "Local files: $LOCAL_COUNT"
echo ""

# Check if file lists match
if [ "$REMOTE_FILES" != "$LOCAL_FILES" ]; then
    echo "✗ ERROR: File lists differ!"
    echo ""

    # Files only in remote
    ONLY_REMOTE=$(comm -23 <(echo "$REMOTE_FILES") <(echo "$LOCAL_FILES"))
    if [ -n "$ONLY_REMOTE" ]; then
        echo "Files only in remote:"
        echo "$ONLY_REMOTE"
        echo ""
    fi

    # Files only in local
    ONLY_LOCAL=$(comm -13 <(echo "$REMOTE_FILES") <(echo "$LOCAL_FILES"))
    if [ -n "$ONLY_LOCAL" ]; then
        echo "Files only in local:"
        echo "$ONLY_LOCAL"
        echo ""
    fi

    exit 1
fi

echo "File names match. Comparing file hashes..."

# Compare each file using SHA hashes
DIFFERENCES=0
CHECKED=0
while IFS= read -r filename; do
    if [ -z "$filename" ]; then
        continue
    fi

    # Extract the SHA for this file from the API response
    # Git stores files as blobs with SHA-1 hash
    REMOTE_SHA=$(grep -A 3 "\"name\": \"$filename\"" "$TEMP_DIR/api_response.json" | grep '"sha":' | sed 's/.*"sha": "\([^"]*\)".*/\1/')

    if [ -z "$REMOTE_SHA" ]; then
        echo "✗ ERROR: Could not extract SHA for: $filename"
        DIFFERENCES=$((DIFFERENCES + 1))
        continue
    fi

    # Check if local file exists
    LOCAL_FILE="$LOCAL_SOURCE_DIR/$filename"
    if [ ! -f "$LOCAL_FILE" ]; then
        echo "✗ MISSING: $filename"
        DIFFERENCES=$((DIFFERENCES + 1))
        continue
    fi

    # Calculate git blob SHA of local file (git format: "blob <size>\0<content>")
    FILE_SIZE=$(wc -c < "$LOCAL_FILE")
    LOCAL_SHA=$(( printf "blob %d\0" "$FILE_SIZE"; cat "$LOCAL_FILE" ) | sha1sum | cut -d' ' -f1)

    # Compare hashes
    if [ "$LOCAL_SHA" != "$REMOTE_SHA" ]; then
        echo "✗ DIFFERS: $filename (local: ${LOCAL_SHA:0:8}... remote: ${REMOTE_SHA:0:8}...)"
        DIFFERENCES=$((DIFFERENCES + 1))
    fi

    CHECKED=$((CHECKED + 1))

    # Show progress every 100 files
    if [ $((CHECKED % 100)) -eq 0 ]; then
        echo "Checked $CHECKED files..."
    fi
done <<< "$REMOTE_FILES"

echo ""
if [ $DIFFERENCES -eq 0 ]; then
    echo "✓ SUCCESS: Local source matches Sefaria's git repository perfectly!"
    echo "All $CHECKED files are identical to commit $COMMIT_HASH"
    exit 0
else
    echo "✗ FAILURE: Found $DIFFERENCES file(s) with differences."
    echo "The local source does NOT match the Sefaria repository (commit $COMMIT_HASH)"
    exit 1
fi
