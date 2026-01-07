#!/bin/bash
# Update ScoreCard.txt Script
# Updates the human-readable study guide after quiz grading
# Arguments: $1=className
# Called by grade-quiz.sh after ScoreCard.json is updated

CLASS_NAME=$1

# Use environment variable or default
PROJECT_ROOT="${PROJECT_ROOT:-/Users/chadc/dev/GitRepo/Exam-Prep}"

# File paths
SCORECARD_JSON="$PROJECT_ROOT/$CLASS_NAME/ScoreCard.json"
SCORECARD_TXT="$PROJECT_ROOT/$CLASS_NAME/Prepare/ScoreCard.txt"
TOPIC_INDEX="$PROJECT_ROOT/$CLASS_NAME/topic-index.json"
TEMP_FILE="$PROJECT_ROOT/$CLASS_NAME/Prepare/ScoreCard.txt.tmp"

# Logging
LOG_PREFIX="[update-scorecard-txt]"

log() {
    echo "$LOG_PREFIX $1"
}

# Check if required files exist
if [ ! -f "$SCORECARD_JSON" ]; then
    log "ERROR: ScoreCard.json not found at $SCORECARD_JSON"
    exit 1
fi

if [ ! -f "$SCORECARD_TXT" ]; then
    log "WARNING: ScoreCard.txt not found at $SCORECARD_TXT - skipping update"
    exit 0
fi

# Check for jq - required for JSON processing
if ! command -v jq &> /dev/null; then
    log "ERROR: jq is required but not installed. Please install jq."
    exit 1
fi

log "Starting ScoreCard.txt update for class: $CLASS_NAME"

# =============================================================================
# STEP 1: Calculate topic performance averages from all sessions
# =============================================================================

log "Calculating topic performance from ScoreCard.json..."

# Extract aggregated topic data from all sessions
# Format: topic_id|avg_percentage|times_tested
TOPIC_STATS=$(jq -r '
    # Gather all byTopic entries from all sessions
    [.sessions[].byTopic // {} | to_entries[]] |
    # Group by topic
    group_by(.key) |
    # Calculate stats for each topic
    map({
        topic: .[0].key,
        avgPct: ([.[].value.percentage] | add / length),
        timesTested: length,
        totalCorrect: ([.[].value.correct] | add),
        totalAttempted: ([.[].value.total] | add)
    }) |
    # Output as pipe-delimited lines
    .[] | "\(.topic)|\(.avgPct)|\(.timesTested)"
' "$SCORECARD_JSON")

# Count topics by mastery level
MASTERED_COUNT=0
IN_PROGRESS_COUNT=0
MASTERED_TOPICS=""
IN_PROGRESS_TOPICS=""

while IFS='|' read -r topic avg_pct times_tested; do
    if [ -z "$topic" ]; then continue; fi

    # Round percentage for comparison (bash doesn't do floats well)
    avg_pct_int=$(printf "%.0f" "$avg_pct")

    if [ "$avg_pct_int" -ge 85 ]; then
        MASTERED_COUNT=$((MASTERED_COUNT + 1))
        MASTERED_TOPICS="$MASTERED_TOPICS $topic"
    else
        IN_PROGRESS_COUNT=$((IN_PROGRESS_COUNT + 1))
        IN_PROGRESS_TOPICS="$IN_PROGRESS_TOPICS $topic"
    fi
done <<< "$TOPIC_STATS"

log "Mastered topics ($MASTERED_COUNT):$MASTERED_TOPICS"
log "In-progress topics ($IN_PROGRESS_COUNT):$IN_PROGRESS_TOPICS"

# =============================================================================
# STEP 2: Get the latest session data for progress notes
# =============================================================================

LATEST_SESSION=$(jq -r '.sessions[-1] // empty' "$SCORECARD_JSON")

if [ -z "$LATEST_SESSION" ]; then
    log "No sessions found in ScoreCard.json - nothing to update"
    exit 0
fi

LATEST_DATE=$(echo "$LATEST_SESSION" | jq -r '.date // "Unknown"')
LATEST_SCORE=$(echo "$LATEST_SESSION" | jq -r '.score // "N/A"')
LATEST_TOTAL=$(echo "$LATEST_SESSION" | jq -r '.totalPoints // .totalQuestions // "N/A"')
LATEST_PCT=$(echo "$LATEST_SESSION" | jq -r '.percentage // "N/A"')
LATEST_QUIZ=$(echo "$LATEST_SESSION" | jq -r '.quiz // "Quiz"')
LATEST_WEAK=$(echo "$LATEST_SESSION" | jq -r '.weakAreas // [] | join(", ")')
LATEST_STRONG=$(echo "$LATEST_SESSION" | jq -r '.strongAreas // [] | join(", ")')

# Format date for display (extract just the date part if it's ISO format)
DISPLAY_DATE=$(echo "$LATEST_DATE" | sed 's/T.*//' | sed 's/_/-/g')

log "Latest session: $DISPLAY_DATE - Score: $LATEST_SCORE/$LATEST_TOTAL ($LATEST_PCT%)"

# =============================================================================
# STEP 3: Load topic index for fuzzy matching (bash 3 compatible)
# =============================================================================

# Store topic index in a temp file for lookup (bash 3 compatible - no assoc arrays)
TOPIC_INDEX_CACHE=""
if [ -f "$TOPIC_INDEX" ]; then
    log "Loading topic index for matching..."
    TOPIC_INDEX_CACHE=$(jq -r '.topics[] | "\(.id)|\(.name)|\(.keywords | join(" "))"' "$TOPIC_INDEX")
fi

# Function to get topic info from cache (bash 3 compatible)
get_topic_info() {
    local topic_id=$1
    echo "$TOPIC_INDEX_CACHE" | grep "^${topic_id}|" | head -1
}

# =============================================================================
# STEP 4: Create mapping between topic IDs and ScoreCard.txt content
# =============================================================================

# Function to check if a line relates to a topic (unused but kept for reference)
topic_matches_line() {
    local topic_id=$1
    local line=$2
    local line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')

    # Get keywords for this topic from cache
    local topic_info=$(get_topic_info "$topic_id")
    if [ -z "$topic_info" ]; then
        # Fallback: convert topic ID to readable form
        local topic_readable=$(echo "$topic_id" | tr '-' ' ')
        if echo "$line_lower" | grep -qi "$topic_readable"; then
            return 0
        fi
        return 1
    fi

    # Split into name and keywords
    local topic_name=$(echo "$topic_info" | cut -d'|' -f2 | tr '[:upper:]' '[:lower:]')
    local keywords=$(echo "$topic_info" | cut -d'|' -f3 | tr '[:upper:]' '[:lower:]')

    # Check if line contains topic name
    if echo "$line_lower" | grep -qi "$topic_name"; then
        return 0
    fi

    # Check for keyword matches (need at least 2 for reliability)
    local match_count=0
    for keyword in $keywords; do
        if echo "$line_lower" | grep -qi "$keyword"; then
            match_count=$((match_count + 1))
        fi
    done

    if [ $match_count -ge 2 ]; then
        return 0
    fi

    return 1
}

# =============================================================================
# STEP 5: Update ScoreCard.txt
# =============================================================================

log "Updating ScoreCard.txt..."

# Count total topics in ScoreCard.txt (lines starting with [ ], [x], or [~])
count_unchecked=$(grep -c '^\[ \]' "$SCORECARD_TXT" 2>/dev/null) || count_unchecked=0
count_mastered=$(grep -c '^\[x\]' "$SCORECARD_TXT" 2>/dev/null) || count_mastered=0
count_progress=$(grep -c '^\[~\]' "$SCORECARD_TXT" 2>/dev/null) || count_progress=0
TOTAL_TOPICS=$((count_unchecked + count_mastered + count_progress))

# If we couldn't count, use default
if [ "$TOTAL_TOPICS" -eq 0 ]; then
    TOTAL_TOPICS=45
fi

NOT_STARTED_COUNT=$((TOTAL_TOPICS - MASTERED_COUNT - IN_PROGRESS_COUNT))
if [ "$NOT_STARTED_COUNT" -lt 0 ]; then
    NOT_STARTED_COUNT=0
fi

# Calculate percentages
if [ "$TOTAL_TOPICS" -gt 0 ]; then
    MASTERED_PCT=$((MASTERED_COUNT * 100 / TOTAL_TOPICS))
    IN_PROGRESS_PCT=$((IN_PROGRESS_COUNT * 100 / TOTAL_TOPICS))
    NOT_STARTED_PCT=$((NOT_STARTED_COUNT * 100 / TOTAL_TOPICS))
else
    MASTERED_PCT=0
    IN_PROGRESS_PCT=0
    NOT_STARTED_PCT=100
fi

# Copy original file
cp "$SCORECARD_TXT" "$TEMP_FILE"

# Update OVERVIEW section statistics
log "Updating OVERVIEW statistics..."

# Update the "Last Updated" date
sed -i.bak "s/^## Last Updated:.*/## Last Updated: $(date '+%B %d, %Y')/" "$TEMP_FILE"

# Update Mastered count (handle both "[ ]" placeholder and numeric formats)
sed -i.bak "s/^Mastered: \[[ ]*\] ([0-9]*%)/Mastered: $MASTERED_COUNT ($MASTERED_PCT%)/" "$TEMP_FILE"
sed -i.bak "s/^Mastered: [0-9]* ([0-9]*%)/Mastered: $MASTERED_COUNT ($MASTERED_PCT%)/" "$TEMP_FILE"

# Update In Progress count (handle both "[ ]" placeholder and numeric formats)
sed -i.bak "s/^In Progress: \[[ ]*\] ([0-9]*%)/In Progress: $IN_PROGRESS_COUNT ($IN_PROGRESS_PCT%)/" "$TEMP_FILE"
sed -i.bak "s/^In Progress: [0-9]* ([0-9]*%)/In Progress: $IN_PROGRESS_COUNT ($IN_PROGRESS_PCT%)/" "$TEMP_FILE"

# Update Not Started count (handle both "[ ]" placeholder and numeric formats)
sed -i.bak "s/^Not Started: \[[ ]*\] ([0-9]*%)/Not Started: $NOT_STARTED_COUNT ($NOT_STARTED_PCT%)/" "$TEMP_FILE"
sed -i.bak "s/^Not Started: [0-9]* ([0-9]*%)/Not Started: $NOT_STARTED_COUNT ($NOT_STARTED_PCT%)/" "$TEMP_FILE"

# =============================================================================
# STEP 6: Update checkboxes based on topic performance
# =============================================================================

log "Updating topic checkboxes..."

# =============================================================================
# Dynamic topic matching function
# Searches for checkbox lines that match topic keywords
# =============================================================================

find_matching_checkbox_line() {
    local topic_id=$1
    local checkbox_pattern=$2  # Either "^\[ \]" for unchecked or "^\[.\]" for any

    # First, try to get keywords from topic-index.json if available (bash 3 compatible)
    local topic_info=$(get_topic_info "$topic_id")
    local topic_name=""
    local topic_keywords=""

    if [ -n "$topic_info" ]; then
        topic_name=$(echo "$topic_info" | cut -d'|' -f2)
        topic_keywords=$(echo "$topic_info" | cut -d'|' -f3)
    fi

    # If we have a topic name from the index, search for it first (most reliable)
    if [ -n "$topic_name" ]; then
        # Search case-insensitively for the topic name in checkbox lines
        local line_num=$(grep -in "$checkbox_pattern.*$topic_name" "$TEMP_FILE" 2>/dev/null | head -1 | cut -d: -f1)
        if [ -n "$line_num" ]; then
            echo "$line_num"
            return 0
        fi
    fi

    # Fallback: Convert topic-id to keywords (e.g., "articles-weaknesses" -> "articles weaknesses")
    # This is more reliable than topic-index keywords which can be too generic
    local id_keywords=$(echo "$topic_id" | tr '-' ' ')

    # Filter out common suffix words that don't help matching
    # e.g., "pikachu-analysis" -> just use "pikachu" for matching
    local filtered_keywords=""
    for kw in $id_keywords; do
        case "$kw" in
            analysis|basics|overview|review|concept|role|roles|type|types)
                # Skip generic suffixes, but keep if it's the only word
                if [ -n "$filtered_keywords" ]; then
                    continue
                fi
                ;;
        esac
        filtered_keywords="$filtered_keywords $kw"
    done
    filtered_keywords=$(echo "$filtered_keywords" | xargs)  # trim whitespace

    # If all words were filtered, use original keywords
    if [ -z "$filtered_keywords" ]; then
        filtered_keywords=$id_keywords
    fi

    # Split keywords into array
    local keyword_array
    read -ra keyword_array <<< "$filtered_keywords"
    local num_keywords=${#keyword_array[@]}

    # Determine required matches:
    # - 1 word: require 1 match (the word must be specific enough)
    # - 2+ words: require at least 2 matches OR all words if only 2 keywords
    local required_matches=2
    if [ "$num_keywords" -eq 1 ]; then
        required_matches=1
    fi

    # Search checkbox lines for keyword matches using topic ID keywords
    local result=""
    result=$(grep -n "$checkbox_pattern" "$TEMP_FILE" 2>/dev/null | while IFS=: read -r lnum line_content; do
        line_lower=$(echo "$line_content" | tr '[:upper:]' '[:lower:]')
        match_count=0

        for kw in "${keyword_array[@]}"; do
            kw_lower=$(echo "$kw" | tr '[:upper:]' '[:lower:]')
            # Check for keyword in line - use word boundaries to avoid partial matches
            if echo "$line_lower" | grep -qiE "(^|[^a-z])$kw_lower([^a-z]|$)"; then
                match_count=$((match_count + 1))
            fi
        done

        if [ "$match_count" -ge "$required_matches" ]; then
            echo "$lnum"
            break
        fi
    done)

    if [ -n "$result" ]; then
        echo "$result"
        return 0
    fi

    # No match found
    return 1
}

# For each mastered topic, dynamically find and update the checkbox
for topic in $MASTERED_TOPICS; do
    # Find matching checkbox line (only unchecked lines)
    line_num=$(find_matching_checkbox_line "$topic" '^\[ \]')

    if [ -n "$line_num" ]; then
        sed -i.bak "${line_num}s/^\[ \]/[x]/" "$TEMP_FILE"
        log "  Marked mastered (line $line_num): $topic"
    else
        log "  Could not find checkbox for mastered topic: $topic"
    fi
done

# For in-progress topics (tested but <85%), mark with [~]
for topic in $IN_PROGRESS_TOPICS; do
    # Find matching checkbox line (only unchecked lines)
    line_num=$(find_matching_checkbox_line "$topic" '^\[ \]')

    if [ -n "$line_num" ]; then
        sed -i.bak "${line_num}s/^\[ \]/[~]/" "$TEMP_FILE"
        log "  Marked in-progress (line $line_num): $topic"
    else
        log "  Could not find checkbox for in-progress topic: $topic"
    fi
done

# =============================================================================
# STEP 7: Add progress note entry
# =============================================================================

log "Adding progress note entry..."

# Create the progress note entry
PROGRESS_ENTRY="- $DISPLAY_DATE: $LATEST_QUIZ - Score: $LATEST_SCORE/$LATEST_TOTAL ($LATEST_PCT%)"

if [ -n "$LATEST_STRONG" ]; then
    PROGRESS_ENTRY="$PROGRESS_ENTRY\n  Strong areas: $LATEST_STRONG"
fi

if [ -n "$LATEST_WEAK" ]; then
    PROGRESS_ENTRY="$PROGRESS_ENTRY\n  Needs work: $LATEST_WEAK"
fi

# Find the PROGRESS NOTES section and add the entry
# Look for the line "Study sessions and mastery tracking:" and add after it

if grep -q "Study sessions and mastery tracking:" "$TEMP_FILE"; then
    # Use awk to insert after the tracking line
    awk -v entry="$PROGRESS_ENTRY" '
        /Study sessions and mastery tracking:/ {
            print
            getline  # Get the next line (empty line)
            print
            print entry
            next
        }
        { print }
    ' "$TEMP_FILE" > "$TEMP_FILE.new"
    mv "$TEMP_FILE.new" "$TEMP_FILE"
fi

# =============================================================================
# STEP 8: Finalize
# =============================================================================

# Move temp file to final location
mv "$TEMP_FILE" "$SCORECARD_TXT"

# Clean up backup files created by sed -i
rm -f "$TEMP_FILE.bak" "$SCORECARD_TXT.bak" 2>/dev/null
find "$PROJECT_ROOT/$CLASS_NAME/Prepare" -name "*.bak" -delete 2>/dev/null

log "ScoreCard.txt update complete!"
log "  - Updated OVERVIEW statistics"
log "  - Mastered: $MASTERED_COUNT, In Progress: $IN_PROGRESS_COUNT, Not Started: $NOT_STARTED_COUNT"
log "  - Added progress note for $DISPLAY_DATE session"

exit 0
