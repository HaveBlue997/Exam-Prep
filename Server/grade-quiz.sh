#!/bin/bash
# Grade Quiz Script
# Called by server when new answers are saved
# Arguments: $1=className, $2=answersFile, $3=jobId
# Environment: PROJECT_ROOT, QUIZ_NAME, STUDENT_NAME, TIMESTAMP
#
# STANDARD QUIZ FORMAT: 19 multiple choice + 1 short answer = 20 total questions
# - Multiple choice: 1 point each = 19 points
# - Short answer: 0-2 points = 2 points
# - Total possible: 21 points
# Note: Older quizzes or midterms/finals may have different formats

CLASS_NAME=$1
ANSWERS_FILE=$2
JOB_ID=$3

# Use environment variable or default
PROJECT_ROOT="${PROJECT_ROOT:-/Users/chadc/dev/GitRepo/Exam-Prep}"

# Environment variables from server
QUIZ_NAME="${QUIZ_NAME:-Quiz}"
STUDENT_NAME="${STUDENT_NAME:-Unknown}"
TIMESTAMP="${TIMESTAMP:-$(date +%Y-%m-%d_%H-%M-%S)}"

# Directories and files
ARCHIVE_DIR="$PROJECT_ROOT/$CLASS_NAME/Archive"
QUIZ_DIR="$PROJECT_ROOT/$CLASS_NAME/Quiz"
PREPARE_DIR="$PROJECT_ROOT/$CLASS_NAME/Prepare"
GRADING_JOBS_DIR="$PROJECT_ROOT/Server/grading-jobs"
TEMPLATES_DIR="$PROJECT_ROOT/Server/templates"
PROMPTS_DIR="$PROJECT_ROOT/Server/prompts"
SCORECARD_JSON="$PROJECT_ROOT/$CLASS_NAME/ScoreCard.json"
SCORECARD_TXT="$PROJECT_ROOT/$CLASS_NAME/Prepare/ScoreCard.txt"
TOPIC_INDEX="$PROJECT_ROOT/$CLASS_NAME/topic-index.json"
GRADING_PROMPT_FILE="$PROJECT_ROOT/Server/prompts/grade-quiz-prompt.md"

# Output files
RESULTS_FILENAME="${QUIZ_NAME}_${STUDENT_NAME}_${TIMESTAMP}_results.html"
RESULTS_FILE="$ARCHIVE_DIR/$RESULTS_FILENAME"
LOG_FILE="$GRADING_JOBS_DIR/${JOB_ID}.log"
SCORECARD_UPDATE_FILE="$GRADING_JOBS_DIR/${JOB_ID}_scorecard_update.json"

# Ensure directories exist
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$GRADING_JOBS_DIR"

# CRITICAL: Verify Claude CLI is available before proceeding
if ! command -v claude &> /dev/null; then
    echo "CRITICAL ERROR: Claude CLI not found in PATH" | tee "$LOG_FILE"
    echo '{"status":"error","error":"Claude CLI not installed or not in PATH"}' > "$GRADING_JOBS_DIR/${JOB_ID}.status"
    exit 1
fi

echo "Starting grading job: $JOB_ID" | tee "$LOG_FILE"
echo "Class: $CLASS_NAME" | tee -a "$LOG_FILE"
echo "Answers file: $ANSWERS_FILE" | tee -a "$LOG_FILE"
echo "Results will be saved to: $RESULTS_FILE" | tee -a "$LOG_FILE"

# Find the corresponding quiz file
QUIZ_FILE=$(ls -t "$QUIZ_DIR"/*.html 2>/dev/null | head -1)

if [ -z "$QUIZ_FILE" ]; then
    echo "ERROR: No quiz file found in $QUIZ_DIR" | tee -a "$LOG_FILE"
    echo '{"status":"error","error":"No quiz file found"}' > "$GRADING_JOBS_DIR/${JOB_ID}.status"
    exit 1
fi

echo "Quiz file: $QUIZ_FILE" | tee -a "$LOG_FILE"

# Read the answers content
if [ ! -f "$ANSWERS_FILE" ]; then
    echo "ERROR: Answers file not found: $ANSWERS_FILE" | tee -a "$LOG_FILE"
    echo '{"status":"error","error":"Answers file not found"}' > "$GRADING_JOBS_DIR/${JOB_ID}.status"
    exit 1
fi

ANSWERS_CONTENT=$(cat "$ANSWERS_FILE")
echo "Read answers file successfully" | tee -a "$LOG_FILE"

# Read the topic index
TOPIC_INDEX_CONTENT=""
if [ -f "$TOPIC_INDEX" ]; then
    TOPIC_INDEX_CONTENT=$(cat "$TOPIC_INDEX")
    echo "Loaded topic index: $TOPIC_INDEX" | tee -a "$LOG_FILE"
else
    echo "WARNING: Topic index not found at $TOPIC_INDEX" | tee -a "$LOG_FILE"
fi

# Read the current ScoreCard.json
SCORECARD_JSON_CONTENT=""
if [ -f "$SCORECARD_JSON" ]; then
    SCORECARD_JSON_CONTENT=$(cat "$SCORECARD_JSON")
    echo "Loaded ScoreCard.json" | tee -a "$LOG_FILE"
else
    SCORECARD_JSON_CONTENT="{\"class\":\"$CLASS_NAME\",\"sessions\":[],\"overallWeakAreas\":[],\"overallStrongAreas\":[],\"lastUpdated\":null}"
    echo "ScoreCard.json not found, using default" | tee -a "$LOG_FILE"
fi

# Read the ScoreCard.txt for study guide context
SCORECARD_TXT_CONTENT=""
if [ -f "$SCORECARD_TXT" ]; then
    SCORECARD_TXT_CONTENT=$(cat "$SCORECARD_TXT")
    echo "Loaded ScoreCard.txt study guide" | tee -a "$LOG_FILE"
fi

# Read the answer key for multiple choice grading
ANSWER_KEY_FILE="$PREPARE_DIR/answer_key.json"
ANSWER_KEY_CONTENT=""
if [ -f "$ANSWER_KEY_FILE" ]; then
    ANSWER_KEY_CONTENT=$(cat "$ANSWER_KEY_FILE")
    echo "Loaded answer key: $ANSWER_KEY_FILE" | tee -a "$LOG_FILE"
else
    echo "WARNING: Answer key not found at $ANSWER_KEY_FILE" | tee -a "$LOG_FILE"
fi

# Read the quiz HTML for question context
QUIZ_HTML_CONTENT=$(cat "$QUIZ_FILE")

# Read the grading prompt template
if [ -f "$GRADING_PROMPT_FILE" ]; then
    GRADING_PROMPT_TEMPLATE=$(cat "$GRADING_PROMPT_FILE")
    echo "Loaded grading prompt template" | tee -a "$LOG_FILE"
else
    echo "WARNING: Grading prompt template not found, using inline prompt" | tee -a "$LOG_FILE"
    GRADING_PROMPT_TEMPLATE=""
fi

# Build the comprehensive grading prompt
GRADING_PROMPT="You are a warm, encouraging tutor helping Blake learn from his quiz results.
Your grading philosophy emphasizes LEARNING - give credit for partial understanding while clearly explaining what was missed.

=== CONTEXT ===
CLASS: $CLASS_NAME
QUIZ: $QUIZ_NAME
STUDENT: $STUDENT_NAME
DATE: $TIMESTAMP
RESULTS_FILENAME: $RESULTS_FILENAME

=== STUDENT'S ANSWERS ===
$ANSWERS_CONTENT

=== QUIZ HTML (for question text and structure) ===
$QUIZ_HTML_CONTENT

=== TOPIC INDEX (for tagging questions) ===
$TOPIC_INDEX_CONTENT

=== CURRENT SCORECARD.JSON ===
$SCORECARD_JSON_CONTENT

=== STUDY GUIDE CONTEXT (ScoreCard.txt) ===
$SCORECARD_TXT_CONTENT

=== MULTIPLE CHOICE ANSWER KEY ===
$ANSWER_KEY_CONTENT

=== YOUR TASKS ===

1. GRADE EACH QUESTION:
   - Multiple choice: 1 point each, check against correct answers (typically 19 questions)
   - Short answer: 0-2 points, give partial credit generously (typically 1 question)
     * 2 = Complete, accurate, includes key concepts
     * 1 = Partially correct or missing elements
     * 0 = Incorrect or no answer
   - Essays: 0-5 points, grade on completeness, accuracy, organization (only in midterms/finals, NOT regular quizzes)

2. TAG EACH QUESTION WITH TOPICS:
   - Match question content to topic IDs from the topic index
   - Use keywords to find the best match

3. CALCULATE PER-TOPIC PERFORMANCE:
   - For each topic: { \"correct\": X, \"total\": Y, \"percentage\": Z }
   - Weak areas: < 70% on topic
   - Strong areas: >= 85% on topic

4. GENERATE BEAUTIFUL HTML RESULTS:
   Use this color scheme:
   - Navy: #1a2744
   - Burgundy: #7c2d3e
   - Cream: #f8f5f0
   - Gold: #c9a959
   - Success (green): #2e7d4a
   - Error (red): #c62828

   Include:
   - Header with score circle
   - Section breakdown
   - Per-topic performance table (NEW!)
   - Detailed question review with topic tags
   - Strengths and areas for improvement
   - Encouraging feedback
   - 'If you disagree with any grading, take a screenshot and send it to Dad!'
   - Action buttons (Take Another Quiz, Return Home, Print)

5. OUTPUT SCORECARD UPDATE:
   After the HTML, on a new line starting with '<!--SCORECARD_UPDATE:', output the JSON for the new session:
   <!--SCORECARD_UPDATE:
   {
     \"date\": \"$TIMESTAMP\",
     \"quiz\": \"$QUIZ_NAME\",
     \"student\": \"$STUDENT_NAME\",
     \"score\": X,
     \"totalQuestions\": Y,
     \"percentage\": Z,
     \"byTopic\": { ... },
     \"weakAreas\": [...],
     \"strongAreas\": [...],
     \"resultsFile\": \"$RESULTS_FILENAME\"
   }
   -->

=== GRADING PHILOSOPHY ===
- Be ENCOURAGING - Blake is working hard
- Give PARTIAL CREDIT if any understanding shown
- EXPLAIN wrong answers - make it a teaching moment
- Use Blake's NAME and reference specific things he wrote
- Frame weaknesses as 'areas for improvement'

=== OUTPUT FORMAT ===
Output ONLY:
1. The complete HTML document (no markdown code blocks)
2. Followed by the scorecard update comment

Do NOT include any text before the <!DOCTYPE html> or after the closing --> of the scorecard update."

# Run Claude CLI for grading
echo "Invoking Claude CLI for grading..." | tee -a "$LOG_FILE"

# Create a temporary file for the full output
TEMP_OUTPUT="$GRADING_JOBS_DIR/${JOB_ID}_output.tmp"

# Write prompt to a temporary file to avoid shell injection via heredoc
# SECURITY: Using a temp file instead of heredoc prevents command injection
# if student answers contain $(command) or `backticks`
PROMPT_FILE="$GRADING_JOBS_DIR/${JOB_ID}_prompt.tmp"
printf '%s' "$GRADING_PROMPT" > "$PROMPT_FILE"

# Use claude command with the prompt from file with 5-minute timeout
# macOS compatibility: use gtimeout (brew install coreutils) or timeout, or run without
if command -v gtimeout &> /dev/null; then
    gtimeout 300 claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
elif command -v timeout &> /dev/null; then
    timeout 300 claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
else
    echo "WARNING: No timeout command available, running without timeout" | tee -a "$LOG_FILE"
    claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
fi

# Clean up prompt file
rm -f "$PROMPT_FILE"

CLAUDE_EXIT_CODE=$?

# Check for timeout (exit code 124)
if [ $CLAUDE_EXIT_CODE -eq 124 ]; then
    echo "ERROR: Claude CLI timed out after 5 minutes" | tee -a "$LOG_FILE"

    # Create a timeout error results page
    cat > "$RESULTS_FILE" << 'TIMEOUT_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Grading Timeout</title>
    <link href="https://fonts.googleapis.com/css2?family=Libre+Baskerville:ital,wght@0,400;0,700;1,400&family=Source+Sans+3:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --navy: #1a2744; --burgundy: #7c2d3e; --cream: #f8f5f0; --gold: #c9a959; }
        body { font-family: 'Source Sans 3', sans-serif; background: var(--cream); padding: 2rem; min-height: 100vh; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 4px 20px rgba(26,39,68,0.12); }
        h1 { font-family: 'Libre Baskerville', serif; color: var(--burgundy); margin-bottom: 1rem; }
        p { color: #2d2d2d; line-height: 1.7; margin-bottom: 1rem; }
        .error { background: #fff3e0; border-left: 4px solid var(--gold); padding: 1.5rem; border-radius: 4px; margin: 1.5rem 0; }
        .error p { margin-bottom: 0.5rem; }
        .btn { display: inline-block; padding: 0.9rem 1.8rem; background: var(--navy); color: white; text-decoration: none; border-radius: 8px; font-weight: 600; margin-top: 1rem; margin-right: 0.5rem; }
        .btn:hover { background: #2a3d5c; }
        .notice { background: #e8f5e9; border-left: 4px solid #2e7d4a; padding: 1rem; margin-top: 1.5rem; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Grading Taking Longer Than Expected</h1>
        <div class="error">
            <p><strong>The grading process timed out.</strong></p>
            <p>This sometimes happens when the AI is very busy. Your answers have been saved safely!</p>
        </div>
        <div class="notice">
            <p><strong>What to do next:</strong></p>
            <p>You can try submitting your quiz again, or ask Dad to grade it manually.</p>
        </div>
        <a href="/" class="btn">Return to Home</a>
        <a href="javascript:history.back()" class="btn">Try Again</a>
    </div>
</body>
</html>
TIMEOUT_EOF

    echo '{"status":"error","error":"Grading timed out after 5 minutes"}' > "$GRADING_JOBS_DIR/${JOB_ID}.status"
    rm -f "$TEMP_OUTPUT"
    exit 1
fi

if [ $CLAUDE_EXIT_CODE -ne 0 ]; then
    echo "ERROR: Claude CLI failed with exit code $CLAUDE_EXIT_CODE" | tee -a "$LOG_FILE"

    # Create a fallback results page
    cat > "$RESULTS_FILE" << 'FALLBACK_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Grading Error</title>
    <link href="https://fonts.googleapis.com/css2?family=Libre+Baskerville:ital,wght@0,400;0,700;1,400&family=Source+Sans+3:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --navy: #1a2744; --burgundy: #7c2d3e; --cream: #f8f5f0; --gold: #c9a959; }
        body { font-family: 'Source Sans 3', sans-serif; background: var(--cream); padding: 2rem; min-height: 100vh; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 4px 20px rgba(26,39,68,0.12); }
        h1 { font-family: 'Libre Baskerville', serif; color: var(--burgundy); margin-bottom: 1rem; }
        p { color: #2d2d2d; line-height: 1.7; margin-bottom: 1rem; }
        .error { background: #ffebee; border-left: 4px solid #c62828; padding: 1.5rem; border-radius: 4px; margin: 1.5rem 0; }
        .error p { margin-bottom: 0.5rem; }
        .btn { display: inline-block; padding: 0.9rem 1.8rem; background: var(--navy); color: white; text-decoration: none; border-radius: 8px; font-weight: 600; margin-top: 1rem; }
        .btn:hover { background: #2a3d5c; }
        .notice { background: #fff3e0; border-left: 4px solid var(--gold); padding: 1rem; margin-top: 1.5rem; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Grading Temporarily Unavailable</h1>
        <div class="error">
            <p><strong>The automatic grading system encountered an error.</strong></p>
            <p>Don't worry! Your answers have been saved successfully.</p>
        </div>
        <div class="notice">
            <p><strong>What to do next:</strong></p>
            <p>Please ask Dad to manually grade your quiz, or try submitting again later.</p>
        </div>
        <a href="/" class="btn">Return to Home</a>
    </div>
</body>
</html>
FALLBACK_EOF

    echo '{"status":"error","error":"Claude CLI grading failed"}' > "$GRADING_JOBS_DIR/${JOB_ID}.status"
    rm -f "$TEMP_OUTPUT"
    exit 1
fi

echo "Claude CLI completed successfully" | tee -a "$LOG_FILE"

# Extract the HTML (everything before <!--SCORECARD_UPDATE:)
sed -n '1,/<!--SCORECARD_UPDATE:/p' "$TEMP_OUTPUT" | sed '$d' > "$RESULTS_FILE"

# Extract the ScoreCard update JSON (between <!--SCORECARD_UPDATE: and -->)
SCORECARD_UPDATE=$(sed -n '/<!--SCORECARD_UPDATE:/,/-->/p' "$TEMP_OUTPUT" | sed '1d;$d')

echo "Grading complete. Results saved to: $RESULTS_FILE" | tee -a "$LOG_FILE"

# Archive the original answers file
ARCHIVED_ANSWERS="$ARCHIVE_DIR/${QUIZ_NAME}_${STUDENT_NAME}_${TIMESTAMP}_answers.txt"
cp "$ANSWERS_FILE" "$ARCHIVED_ANSWERS"
echo "Archived answers to: $ARCHIVED_ANSWERS" | tee -a "$LOG_FILE"

# Archive the quiz file as well
ARCHIVED_QUIZ="$ARCHIVE_DIR/${QUIZ_NAME}_${STUDENT_NAME}_${TIMESTAMP}_quiz.html"
cp "$QUIZ_FILE" "$ARCHIVED_QUIZ"
echo "Archived quiz to: $ARCHIVED_QUIZ" | tee -a "$LOG_FILE"

# Update ScoreCard.json
echo "Updating ScoreCard.json..." | tee -a "$LOG_FILE"

if [ -n "$SCORECARD_UPDATE" ]; then
    echo "ScoreCard update data extracted from Claude output" | tee -a "$LOG_FILE"
    echo "$SCORECARD_UPDATE" > "$SCORECARD_UPDATE_FILE"

    # Use jq if available to properly merge the session
    if command -v jq &> /dev/null; then
        # Read current scorecard
        if [ -f "$SCORECARD_JSON" ]; then
            CURRENT_SCORECARD=$(cat "$SCORECARD_JSON")
        else
            CURRENT_SCORECARD="{\"class\":\"$CLASS_NAME\",\"sessions\":[],\"overallWeakAreas\":[],\"overallStrongAreas\":[],\"lastUpdated\":null}"
        fi

        # Parse the new session and update
        NEW_SESSION="$SCORECARD_UPDATE"

        # Add the new session and update timestamp
        UPDATED_SCORECARD=$(echo "$CURRENT_SCORECARD" | jq --argjson session "$NEW_SESSION" '
            .sessions += [$session] |
            .lastUpdated = (now | todate)
        ')

        # Calculate overall weak and strong areas from all sessions
        UPDATED_SCORECARD=$(echo "$UPDATED_SCORECARD" | jq '
            # Collect all topic data across sessions
            .overallWeakAreas = (
                [.sessions[].byTopic // {} | to_entries[]] |
                group_by(.key) |
                map({
                    topic: .[0].key,
                    avgPct: ([.[].value.percentage] | add / length)
                }) |
                map(select(.avgPct < 70)) |
                map(.topic)
            ) |
            .overallStrongAreas = (
                [.sessions[].byTopic // {} | to_entries[]] |
                group_by(.key) |
                map({
                    topic: .[0].key,
                    avgPct: ([.[].value.percentage] | add / length)
                }) |
                map(select(.avgPct >= 85)) |
                map(.topic)
            )
        ')

        echo "$UPDATED_SCORECARD" > "$SCORECARD_JSON"
        echo "ScoreCard.json updated with session data and overall areas calculated" | tee -a "$LOG_FILE"
    else
        # Fallback without jq - just create a simple update
        echo "WARNING: jq not available, ScoreCard update may be incomplete" | tee -a "$LOG_FILE"

        if [ -f "$SCORECARD_JSON" ]; then
            CURRENT_SCORECARD=$(cat "$SCORECARD_JSON")
        else
            CURRENT_SCORECARD="{\"class\":\"$CLASS_NAME\",\"sessions\":[],\"overallWeakAreas\":[],\"overallStrongAreas\":[],\"lastUpdated\":null}"
        fi

        # Simple fallback - just preserve the file
        echo "$CURRENT_SCORECARD" > "$SCORECARD_JSON"
    fi
else
    echo "WARNING: No ScoreCard update data found in Claude output" | tee -a "$LOG_FILE"

    # Create a minimal session entry
    if command -v jq &> /dev/null; then
        if [ -f "$SCORECARD_JSON" ]; then
            CURRENT_SCORECARD=$(cat "$SCORECARD_JSON")
        else
            CURRENT_SCORECARD="{\"class\":\"$CLASS_NAME\",\"sessions\":[],\"overallWeakAreas\":[],\"overallStrongAreas\":[],\"lastUpdated\":null}"
        fi

        NEW_SESSION="{\"date\":\"$(date -Iseconds)\",\"quiz\":\"$QUIZ_NAME\",\"student\":\"$STUDENT_NAME\",\"resultsFile\":\"$RESULTS_FILENAME\"}"
        echo "$CURRENT_SCORECARD" | jq --argjson session "$NEW_SESSION" '.sessions += [$session] | .lastUpdated = (now | todate)' > "$SCORECARD_JSON"
    fi
fi

echo "ScoreCard.json update complete" | tee -a "$LOG_FILE"

# Update ScoreCard.txt (human-readable study guide)
UPDATE_SCORECARD_TXT_SCRIPT="$PROJECT_ROOT/Server/update-scorecard-txt.sh"
if [ -f "$UPDATE_SCORECARD_TXT_SCRIPT" ]; then
    echo "Updating ScoreCard.txt study guide..." | tee -a "$LOG_FILE"
    bash "$UPDATE_SCORECARD_TXT_SCRIPT" "$CLASS_NAME" 2>&1 | tee -a "$LOG_FILE"
    if [ $? -eq 0 ]; then
        echo "ScoreCard.txt update complete" | tee -a "$LOG_FILE"
    else
        echo "WARNING: ScoreCard.txt update encountered issues (non-fatal)" | tee -a "$LOG_FILE"
    fi
else
    echo "WARNING: update-scorecard-txt.sh not found, skipping ScoreCard.txt update" | tee -a "$LOG_FILE"
fi

# Generate adaptive quiz in background (don't block grading response)
GENERATE_QUIZ_SCRIPT="$PROJECT_ROOT/Server/generate-adaptive-quiz.sh"
if [ -f "$GENERATE_QUIZ_SCRIPT" ]; then
    echo "Starting adaptive quiz generation in background..." | tee -a "$LOG_FILE"
    # Run in background with nohup to survive parent process exit
    # Redirect output to log file, don't wait for completion
    nohup bash "$GENERATE_QUIZ_SCRIPT" "$CLASS_NAME" >> "$LOG_FILE" 2>&1 &
    QUIZ_GEN_PID=$!
    echo "Adaptive quiz generation started (PID: $QUIZ_GEN_PID)" | tee -a "$LOG_FILE"
    echo "Quiz generation runs in background - grading response will not be delayed" | tee -a "$LOG_FILE"
else
    echo "NOTE: generate-adaptive-quiz.sh not found, skipping adaptive quiz generation" | tee -a "$LOG_FILE"
fi

# Cleanup temp file
rm -f "$TEMP_OUTPUT"

# Signal completion
echo "{\"status\":\"complete\",\"resultsUrl\":\"/results/$CLASS_NAME/$RESULTS_FILENAME\"}" > "$GRADING_JOBS_DIR/${JOB_ID}.status"
echo "Grading job $JOB_ID completed successfully" | tee -a "$LOG_FILE"

exit 0
