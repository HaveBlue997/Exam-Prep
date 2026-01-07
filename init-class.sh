#!/bin/bash
# init-class.sh - Initialize a new class or regenerate an existing one
#
# Usage: ./init-class.sh ClassName
#
# This script reads Guide materials and generates:
# 1. Prepare/ScoreCard.txt - Human-readable study plan with topic checklist
# 2. topic-index.json - Machine-readable topic taxonomy for grading
# 3. ScoreCard.json - Empty performance tracker (initialized)
# 4. Quiz/{class}_diagnostic_quiz.html - Initial quiz to gauge knowledge
#
# Guide Material Priority:
# 1. Syllabus and Study Guides (most important - defines course scope)
# 2. Previous Tests (second - shows exam format, teacher expectations)
# 3. Previous Quizzes (third - additional question styles)
#
# Processing time: ~2-3 minutes (involves multiple AI calls)

CLASS_NAME=$1

# Get project root (directory containing this script)
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Timestamp for logging
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_DIR="$PROJECT_ROOT/Server/quiz-generation-logs"
LOG_FILE="$LOG_DIR/init_${CLASS_NAME}_${TIMESTAMP}.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_step() {
    log "${BLUE}==>${NC} $1"
}

log_success() {
    log "${GREEN}✓${NC} $1"
}

log_warning() {
    log "${YELLOW}⚠${NC} $1"
}

log_error() {
    log "${RED}✗${NC} $1"
}

# Header
log ""
log "============================================="
log "  Class Initialization Script"
log "============================================="
log "Class: $CLASS_NAME"
log "Timestamp: $TIMESTAMP"
log "Log file: $LOG_FILE"
log "============================================="
log ""

# Validate argument
if [ -z "$CLASS_NAME" ]; then
    log_error "No class name provided"
    log "Usage: ./init-class.sh ClassName"
    exit 1
fi

# Directory paths
CLASS_DIR="$PROJECT_ROOT/$CLASS_NAME"
GUIDE_DIR="$CLASS_DIR/Guide"
QUIZ_DIR="$CLASS_DIR/Quiz"
PREPARE_DIR="$CLASS_DIR/Prepare"
ANSWERS_DIR="$CLASS_DIR/Answers"
ARCHIVE_DIR="$CLASS_DIR/Archive"

# Output files
SCORECARD_TXT="$PREPARE_DIR/ScoreCard.txt"
TOPIC_INDEX="$CLASS_DIR/topic-index.json"
SCORECARD_JSON="$CLASS_DIR/ScoreCard.json"
DIAGNOSTIC_QUIZ="$QUIZ_DIR/${CLASS_NAME}_diagnostic_quiz.html"
DIAGNOSTIC_ANSWER_KEY="$QUIZ_DIR/${CLASS_NAME}_diagnostic_quiz_answer_key.json"

# Validate class directory exists
if [ ! -d "$CLASS_DIR" ]; then
    log_error "Class directory not found: $CLASS_DIR"
    log "Please create the class directory first:"
    log "  cp -r Example_Class $CLASS_NAME"
    exit 1
fi

# Validate Guide directory exists and has files
if [ ! -d "$GUIDE_DIR" ]; then
    log_error "Guide directory not found: $GUIDE_DIR"
    exit 1
fi

GUIDE_FILE_COUNT=$(find "$GUIDE_DIR" -type f ! -name ".gitkeep" ! -name ".*" | wc -l | tr -d ' ')
if [ "$GUIDE_FILE_COUNT" -eq 0 ]; then
    log_error "No files found in Guide directory"
    log "Please add course materials to $GUIDE_DIR:"
    log "  - Syllabus or course outline"
    log "  - Study guides or notes"
    log "  - Previous tests or quizzes (optional)"
    exit 1
fi

log_success "Found $GUIDE_FILE_COUNT file(s) in Guide directory"

# Ensure required directories exist
mkdir -p "$QUIZ_DIR" "$PREPARE_DIR" "$ANSWERS_DIR" "$ARCHIVE_DIR"

# Check for Claude CLI
if ! command -v claude &> /dev/null; then
    log_error "Claude CLI not found in PATH"
    log "Please install Claude CLI: https://claude.ai/cli"
    exit 1
fi

# Read Guide materials with priority ordering
log_step "Reading Guide materials..."

GUIDE_CONTENT=""
SYLLABUS_CONTENT=""
TEST_CONTENT=""
QUIZ_CONTENT=""
OTHER_CONTENT=""

for guide_file in "$GUIDE_DIR"/*; do
    if [ -f "$guide_file" ] && [ "$(basename "$guide_file")" != ".gitkeep" ]; then
        filename=$(basename "$guide_file")
        filename_lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
        file_content=$(cat "$guide_file")

        log "  Loading: $filename"

        # Categorize by priority
        if [[ "$filename_lower" == *"syllabus"* ]] || [[ "$filename_lower" == *"study"* ]] || [[ "$filename_lower" == *"guide"* ]]; then
            SYLLABUS_CONTENT="$SYLLABUS_CONTENT

=== $filename (SYLLABUS/STUDY GUIDE - HIGH PRIORITY) ===
$file_content"
        elif [[ "$filename_lower" == *"test"* ]] || [[ "$filename_lower" == *"exam"* ]] || [[ "$filename_lower" == *"midterm"* ]] || [[ "$filename_lower" == *"final"* ]]; then
            TEST_CONTENT="$TEST_CONTENT

=== $filename (PREVIOUS TEST - MEDIUM PRIORITY) ===
$file_content"
        elif [[ "$filename_lower" == *"quiz"* ]]; then
            QUIZ_CONTENT="$QUIZ_CONTENT

=== $filename (PREVIOUS QUIZ - LOWER PRIORITY) ===
$file_content"
        else
            OTHER_CONTENT="$OTHER_CONTENT

=== $filename ===
$file_content"
        fi
    fi
done

# Combine in priority order
GUIDE_CONTENT="$SYLLABUS_CONTENT$TEST_CONTENT$QUIZ_CONTENT$OTHER_CONTENT"

if [ -z "$GUIDE_CONTENT" ]; then
    log_error "Failed to read any Guide materials"
    exit 1
fi

log_success "Guide materials loaded"

# ============================================
# STEP 1: Generate ScoreCard.txt
# ============================================
log ""
log_step "Step 1/4: Generating ScoreCard.txt (study plan)..."

SCORECARD_PROMPT="You are creating a comprehensive study plan and topic checklist for a student preparing for exams.

=== CLASS NAME ===
$CLASS_NAME

=== COURSE MATERIALS ===
$GUIDE_CONTENT

=== YOUR TASK ===
Create a ScoreCard.txt file - a human-readable study plan with topic checklist.

IMPORTANT: Analyze the course materials to identify:
1. All testable topics from the syllabus/study guide
2. Question types and formats from previous tests/quizzes
3. Teacher's grading style and expectations
4. Key concepts that appear frequently

FORMAT REQUIREMENTS:
Use this exact format structure:

# [CLASS NAME] SCORECARD - EXAM PREPARATION
## Student: (Your Name)
## Created: $(date '+%B %d, %Y')
## Last Updated: $(date '+%B %d, %Y')

===============================================================================
OVERVIEW
===============================================================================

Total Topics: [count]
Mastered: 0 (0%)
In Progress: 0 (0%)
Not Started: [count] (100%)

High Priority Topics: [count] - Focus here first!
Medium Priority Topics: [count] - Important for solid performance
Low Priority Topics: [count] - Maintain existing mastery

===============================================================================
HIGH PRIORITY TOPICS (Critical for Exam Success)
===============================================================================

[Brief intro explaining why these topics are critical]

### [Category Name]

[ ] [Topic name]
    What mastery looks like: [specific measurable outcome]
    Why this matters: [importance for exam]
    Study resources: [reference to specific materials]

[Continue for all high priority topics...]

===============================================================================
MEDIUM PRIORITY TOPICS (Important for Solid Performance)
===============================================================================

[Topics that are important but not critical...]

===============================================================================
LOW PRIORITY TOPICS (Review/Foundational)
===============================================================================

[Topics that are foundational or less frequently tested...]

===============================================================================
STUDY PLAN RECOMMENDATIONS
===============================================================================

[Week-by-week study suggestions based on typical exam prep timeline]

===============================================================================
QUICK REFERENCE CHARTS
===============================================================================

[Any quick reference info - key formulas, dates, terms, etc.]

===============================================================================
PROGRESS NOTES
===============================================================================

Study sessions and mastery tracking:

- [Date]: [Quiz] - Score: XX/30 (XX%)
  Strong areas: [topics where you scored well]
  Needs work: [topics needing more practice]
- [Date]: [Topic] - Mastered after [study activity]
- [Date]: [Topic] - Still needs work on [specific aspect]

===============================================================================
FINAL EXAM SELF-CHECK (Use This Night Before)
===============================================================================

You're ready if you can do ALL of this without notes:

[List of self-check items based on high priority topics]

===============================================================================
TIPS FOR SUCCESS
===============================================================================

[10 study tips specific to this course/subject]

Good luck!

CHECKLIST SYMBOLS:
- [ ] = Not started
- [~] = In progress (partially understood)
- [x] = Mastered

REQUIREMENTS:
1. Extract ALL topics from the course materials
2. Organize by priority (high/medium/low) based on:
   - Frequency in materials
   - Teacher emphasis
   - Exam weight/importance
3. Include specific study resources for each topic
4. Make 'What mastery looks like' measurable and specific
5. Include any formulas, key terms, or reference info

OUTPUT: Only the ScoreCard.txt content, no explanations or markdown code blocks."

PROMPT_FILE="$LOG_DIR/prompt_scorecard_${TIMESTAMP}.tmp"
printf '%s' "$SCORECARD_PROMPT" > "$PROMPT_FILE"

TEMP_OUTPUT="$LOG_DIR/output_scorecard_${TIMESTAMP}.tmp"

if command -v gtimeout &> /dev/null; then
    gtimeout 300 claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
elif command -v timeout &> /dev/null; then
    timeout 300 claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
else
    claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
fi

if [ $? -ne 0 ] || [ ! -s "$TEMP_OUTPUT" ]; then
    log_error "Failed to generate ScoreCard.txt"
    rm -f "$PROMPT_FILE" "$TEMP_OUTPUT"
    exit 1
fi

# Save ScoreCard.txt
mv "$TEMP_OUTPUT" "$SCORECARD_TXT"
rm -f "$PROMPT_FILE"

log_success "ScoreCard.txt created: $SCORECARD_TXT"

# ============================================
# STEP 2: Generate topic-index.json
# ============================================
log ""
log_step "Step 2/4: Generating topic-index.json..."

SCORECARD_TXT_CONTENT=$(cat "$SCORECARD_TXT")

TOPIC_INDEX_PROMPT="You are extracting a machine-readable topic index from a study guide.

=== CLASS NAME ===
$CLASS_NAME

=== SCORECARD.TXT (Study Guide) ===
$SCORECARD_TXT_CONTENT

=== YOUR TASK ===
Extract all topics from the ScoreCard.txt and create a JSON topic index.

OUTPUT FORMAT (valid JSON only):
{
  \"class\": \"$CLASS_NAME\",
  \"lastUpdated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
  \"topics\": [
    {
      \"id\": \"topic-id-lowercase-with-dashes\",
      \"name\": \"Human Readable Topic Name\",
      \"priority\": \"high|medium|low\",
      \"category\": \"Category from ScoreCard\",
      \"keywords\": [\"keyword1\", \"keyword2\", \"keyword3\"]
    }
  ]
}

REQUIREMENTS:
1. Extract EVERY topic from the ScoreCard (all [ ], [~], [x] items)
2. Create meaningful topic IDs (lowercase, dashes, descriptive)
3. Include 4-8 keywords per topic for question matching
4. Keywords should include:
   - Core concept terms
   - Related vocabulary
   - Names, dates, formulas mentioned
   - Variations and synonyms
5. Preserve the priority level from the ScoreCard section

OUTPUT: Only valid JSON, no markdown code blocks or explanations."

PROMPT_FILE="$LOG_DIR/prompt_topicindex_${TIMESTAMP}.tmp"
printf '%s' "$TOPIC_INDEX_PROMPT" > "$PROMPT_FILE"

TEMP_OUTPUT="$LOG_DIR/output_topicindex_${TIMESTAMP}.tmp"

if command -v gtimeout &> /dev/null; then
    gtimeout 180 claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
elif command -v timeout &> /dev/null; then
    timeout 180 claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
else
    claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
fi

if [ $? -ne 0 ] || [ ! -s "$TEMP_OUTPUT" ]; then
    log_error "Failed to generate topic-index.json"
    rm -f "$PROMPT_FILE" "$TEMP_OUTPUT"
    exit 1
fi

# Validate and format JSON
if command -v jq &> /dev/null; then
    if jq . "$TEMP_OUTPUT" > "$TOPIC_INDEX" 2>/dev/null; then
        log_success "topic-index.json created: $TOPIC_INDEX"
    else
        log_warning "JSON validation failed, saving raw output"
        mv "$TEMP_OUTPUT" "$TOPIC_INDEX"
    fi
else
    mv "$TEMP_OUTPUT" "$TOPIC_INDEX"
    log_success "topic-index.json created: $TOPIC_INDEX"
fi

rm -f "$PROMPT_FILE" "$TEMP_OUTPUT"

# ============================================
# STEP 3: Initialize ScoreCard.json
# ============================================
log ""
log_step "Step 3/4: Initializing ScoreCard.json..."

cat > "$SCORECARD_JSON" << EOF
{
  "class": "$CLASS_NAME",
  "sessions": [],
  "overallWeakAreas": [],
  "overallStrongAreas": [],
  "lastUpdated": null
}
EOF

log_success "ScoreCard.json initialized: $SCORECARD_JSON"

# ============================================
# STEP 4: Generate Diagnostic Quiz
# ============================================
log ""
log_step "Step 4/4: Generating diagnostic quiz..."
log "  This may take 1-2 minutes..."

TOPIC_INDEX_CONTENT=$(cat "$TOPIC_INDEX")

# Find an existing quiz template from Pokemon class
TEMPLATE_QUIZ=""
if [ -f "$PROJECT_ROOT/Pokemon/Quiz/pokemon_quiz.html" ]; then
    TEMPLATE_QUIZ=$(cat "$PROJECT_ROOT/Pokemon/Quiz/pokemon_quiz.html")
fi

DIAGNOSTIC_PROMPT="You are creating an initial diagnostic quiz to assess a student's baseline knowledge.

=== CLASS NAME ===
$CLASS_NAME

=== COURSE MATERIALS ===
$GUIDE_CONTENT

=== TOPIC INDEX ===
$TOPIC_INDEX_CONTENT

=== STUDY GUIDE (ScoreCard.txt) ===
$SCORECARD_TXT_CONTENT

=== TEMPLATE QUIZ (for HTML/CSS style reference) ===
$TEMPLATE_QUIZ

=== YOUR TASK ===
Create a DIAGNOSTIC QUIZ - an initial broad quiz to gauge the student's current knowledge and build confidence.

DIAGNOSTIC QUIZ PHILOSOPHY:
- BROAD COVERAGE: Touch all major topics from the syllabus (don't focus on any one area)
- SIMPLE DIFFICULTY: Build confidence, not discourage (60-70% should be achievable with basic knowledge)
- BASELINE ASSESSMENT: Help identify starting weak areas for future adaptive quizzes

QUIZ STRUCTURE (STANDARDIZED FORMAT):
- EXACTLY 19 Multiple Choice questions (1 point each = 19 points)
- EXACTLY 1 Short Answer question (0-2 points)
- Total: 20 questions, 21 possible points

QUESTION DISTRIBUTION:
- Distribute questions evenly across HIGH and MEDIUM priority topics
- Include at least one question from each major category
- Start with easier questions, gradually increase difficulty
- Final short answer should cover a foundational concept

QUESTION DIFFICULTY:
- 50% foundational (student with basic exposure should get these)
- 35% intermediate (requires some study)
- 15% slightly challenging (shows deeper understanding)

HTML REQUIREMENTS:
1. Use this color scheme:
   - Navy: #1a2744
   - Burgundy: #7c2d3e
   - Cream: #f8f5f0
   - Gold: #c9a959

2. Include these features:
   - Progress bar showing completion
   - Navigation bar with home link (/)
   - Print and Clear buttons
   - Auto-save functionality
   - Grading overlay after submission
   - Mobile/iPad responsive design

3. API endpoint: /api/answers/$CLASS_NAME
4. Quiz name in saveAnswers(): '${CLASS_NAME}_Diagnostic_Quiz'

5. Add data-topic attribute to each question:
   <div class=\"question\" data-topic=\"topic-id-here\">

6. Include encouraging intro message:
   'This diagnostic quiz helps identify your current knowledge level. Don't worry about getting everything right - this is just a starting point!'

=== OUTPUT FORMAT ===

Output TWO things:

1. FIRST: Complete HTML document
   - Start with <!DOCTYPE html>
   - Include all CSS, HTML, and JavaScript inline
   - End with </html>

2. SECOND: Answer key as HTML comment:
<!--ANSWER_KEY:
{
  \"quizName\": \"${CLASS_NAME} Diagnostic Quiz\",
  \"generatedFor\": \"Student\",
  \"generatedAt\": \"$TIMESTAMP\",
  \"quizType\": \"diagnostic\",
  \"format\": \"19 multiple choice + 1 short answer = 20 total questions\",
  \"answers\": {
    \"q1\": {\"correct\": \"b\", \"topic\": \"topic-id\", \"explanation\": \"Brief explanation\"},
    ...
    \"q20\": {\"type\": \"short_answer\", \"topic\": \"topic-id\", \"keyPoints\": [\"point1\", \"point2\", \"point3\"]}
  },
  \"totalPoints\": {
    \"multipleChoice\": 19,
    \"shortAnswer\": 2,
    \"total\": 21
  }
}
-->

IMPORTANT:
- Output ONLY the HTML document and answer key comment
- Do NOT include any text before <!DOCTYPE html>
- Do NOT include any text after the closing -->
- Make sure the quiz is COMPLETE and FUNCTIONAL"

PROMPT_FILE="$LOG_DIR/prompt_diagnostic_${TIMESTAMP}.tmp"
printf '%s' "$DIAGNOSTIC_PROMPT" > "$PROMPT_FILE"

TEMP_OUTPUT="$LOG_DIR/output_diagnostic_${TIMESTAMP}.tmp"

if command -v gtimeout &> /dev/null; then
    gtimeout 300 claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
elif command -v timeout &> /dev/null; then
    timeout 300 claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
else
    claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
fi

if [ $? -ne 0 ] || [ ! -s "$TEMP_OUTPUT" ]; then
    log_error "Failed to generate diagnostic quiz"
    rm -f "$PROMPT_FILE" "$TEMP_OUTPUT"
    exit 1
fi

# Extract HTML (everything before <!--ANSWER_KEY:)
TEMP_QUIZ="$LOG_DIR/quiz_temp_${TIMESTAMP}.html"
sed -n '1,/<!--ANSWER_KEY:/p' "$TEMP_OUTPUT" | sed '$d' > "$TEMP_QUIZ"

# Verify HTML
if [ ! -s "$TEMP_QUIZ" ] || ! head -5 "$TEMP_QUIZ" | grep -q "DOCTYPE\|html"; then
    log_error "Output does not appear to be valid HTML"
    rm -f "$PROMPT_FILE" "$TEMP_OUTPUT" "$TEMP_QUIZ"
    exit 1
fi

# Save quiz
mv "$TEMP_QUIZ" "$DIAGNOSTIC_QUIZ"
log_success "Diagnostic quiz created: $DIAGNOSTIC_QUIZ"

# Extract and save answer key
ANSWER_KEY=$(sed -n '/<!--ANSWER_KEY:/,/-->/p' "$TEMP_OUTPUT" | sed '1d;$d')
if [ -n "$ANSWER_KEY" ]; then
    if command -v jq &> /dev/null && echo "$ANSWER_KEY" | jq . > /dev/null 2>&1; then
        echo "$ANSWER_KEY" | jq . > "$DIAGNOSTIC_ANSWER_KEY"
    else
        echo "$ANSWER_KEY" > "$DIAGNOSTIC_ANSWER_KEY"
    fi
    log_success "Answer key created: $DIAGNOSTIC_ANSWER_KEY"
else
    log_warning "No answer key found in output"
fi

rm -f "$PROMPT_FILE" "$TEMP_OUTPUT"

# ============================================
# Summary
# ============================================
log ""
log "============================================="
log "${GREEN}  Class Initialization Complete!${NC}"
log "============================================="
log ""
log "Created files:"
log "  ${GREEN}✓${NC} $SCORECARD_TXT"
log "  ${GREEN}✓${NC} $TOPIC_INDEX"
log "  ${GREEN}✓${NC} $SCORECARD_JSON"
log "  ${GREEN}✓${NC} $DIAGNOSTIC_QUIZ"
log "  ${GREEN}✓${NC} $DIAGNOSTIC_ANSWER_KEY"
log ""
log "Next steps:"
log "  1. Start the server: cd Server && npm start"
log "  2. Open http://localhost:3000"
log "  3. Select '$CLASS_NAME' and take the diagnostic quiz"
log "  4. After grading, an adaptive quiz will be generated"
log ""
log "Log file: $LOG_FILE"
log "============================================="

exit 0
