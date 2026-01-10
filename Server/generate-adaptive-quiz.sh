#!/bin/bash
# Generate Adaptive Quiz Script
# Creates a new practice quiz focused on weak areas after grading
# Arguments: $1=className
# Called by grade-quiz.sh in background after ScoreCard updates
#
# QUIZ FORMAT: Standardized to 19 multiple choice + 1 short answer = 20 total questions
# - Multiple choice: 1 point each = 19 points
# - Short answer: 0-2 points = 2 points
# - Total possible: 21 points
# - The short answer targets the highest-priority weak area from ScoreCard

CLASS_NAME=$1

# Use environment variable or default
PROJECT_ROOT="${PROJECT_ROOT:-/Users/chadc/dev/GitRepo/Exam-Prep}"

# Log file for this generation job
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_DIR="$PROJECT_ROOT/Server/quiz-generation-logs"
LOG_FILE="$LOG_DIR/generate_${CLASS_NAME}_${TIMESTAMP}.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

echo "=============================================" | tee "$LOG_FILE"
echo "Adaptive Quiz Generation Started" | tee -a "$LOG_FILE"
echo "Class: $CLASS_NAME" | tee -a "$LOG_FILE"
echo "Timestamp: $TIMESTAMP" | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"

# Validate argument
if [ -z "$CLASS_NAME" ]; then
    echo "ERROR: No class name provided" | tee -a "$LOG_FILE"
    exit 1
fi

# Directories and files
CLASS_DIR="$PROJECT_ROOT/$CLASS_NAME"
QUIZ_DIR="$CLASS_DIR/Quiz"
GUIDE_DIR="$CLASS_DIR/Guide"
PREPARE_DIR="$CLASS_DIR/Prepare"
SCORECARD_JSON="$CLASS_DIR/ScoreCard.json"
SCORECARD_TXT="$CLASS_DIR/ScoreCard.txt"
TOPIC_INDEX="$CLASS_DIR/topic-index.json"

# Output files
NEW_QUIZ_FILE="$QUIZ_DIR/adaptive_practice_quiz.html"
NEW_ANSWER_KEY="$QUIZ_DIR/adaptive_practice_quiz_answer_key.json"
TEMP_QUIZ_FILE="$QUIZ_DIR/.adaptive_quiz_temp.html"

# Verify required files exist
if [ ! -f "$SCORECARD_JSON" ]; then
    echo "ERROR: ScoreCard.json not found at $SCORECARD_JSON" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Reading ScoreCard.json..." | tee -a "$LOG_FILE"
SCORECARD_JSON_CONTENT=$(cat "$SCORECARD_JSON")

# Read topic index
TOPIC_INDEX_CONTENT=""
if [ -f "$TOPIC_INDEX" ]; then
    TOPIC_INDEX_CONTENT=$(cat "$TOPIC_INDEX")
    echo "Loaded topic index" | tee -a "$LOG_FILE"
else
    echo "WARNING: Topic index not found at $TOPIC_INDEX" | tee -a "$LOG_FILE"
fi

# Read study guide
SCORECARD_TXT_CONTENT=""
if [ -f "$SCORECARD_TXT" ]; then
    SCORECARD_TXT_CONTENT=$(cat "$SCORECARD_TXT")
    echo "Loaded ScoreCard.txt study guide" | tee -a "$LOG_FILE"
else
    echo "WARNING: ScoreCard.txt not found at $SCORECARD_TXT" | tee -a "$LOG_FILE"
fi

# Read any existing quiz as a template example
EXISTING_QUIZ_CONTENT=""
EXISTING_QUIZ=$(ls -t "$QUIZ_DIR"/*.html 2>/dev/null | grep -v "adaptive_practice" | head -1)
if [ -n "$EXISTING_QUIZ" ] && [ -f "$EXISTING_QUIZ" ]; then
    EXISTING_QUIZ_CONTENT=$(cat "$EXISTING_QUIZ")
    echo "Loaded existing quiz as template: $EXISTING_QUIZ" | tee -a "$LOG_FILE"
fi

# Read study guide materials from Guide directory
# IMPORTANT: Skip binary files (PDFs, images, etc.) - they can't be read as text
GUIDE_CONTENT=""
if [ -d "$GUIDE_DIR" ]; then
    for guide_file in "$GUIDE_DIR"/*; do
        if [ -f "$guide_file" ]; then
            # Skip binary files - cat on PDFs outputs garbage and crashes Claude CLI
            case "$guide_file" in
                *.pdf|*.PDF|*.docx|*.DOCX|*.xlsx|*.XLSX|*.png|*.PNG|*.jpg|*.JPG|*.jpeg|*.JPEG|*.gif|*.GIF)
                    echo "Skipping binary file: $guide_file" | tee -a "$LOG_FILE"
                    continue
                    ;;
            esac

            # Check file size - skip if too large (>50KB)
            FILE_SIZE=$(wc -c < "$guide_file" 2>/dev/null | tr -d ' ')
            if [ "$FILE_SIZE" -gt 50000 ]; then
                echo "Skipping large file ($FILE_SIZE bytes): $guide_file" | tee -a "$LOG_FILE"
                continue
            fi

            echo "Loading guide: $guide_file ($FILE_SIZE bytes)" | tee -a "$LOG_FILE"
            GUIDE_CONTENT="$GUIDE_CONTENT

=== $(basename "$guide_file") ===
$(cat "$guide_file")"
        fi
    done
fi

# Build list of PDF file paths for Claude to read directly
# (Claude CLI can read PDFs when given absolute paths in prompt)
PDF_REFS=""
for pdf_file in "$GUIDE_DIR"/*.pdf "$GUIDE_DIR"/*.PDF; do
    if [ -f "$pdf_file" ]; then
        echo "Adding PDF reference: $pdf_file" | tee -a "$LOG_FILE"
        PDF_REFS="$PDF_REFS
- $pdf_file"
    fi
done

# Extract weak and strong areas using jq if available
WEAK_AREAS=""
STRONG_AREAS=""
if command -v jq &> /dev/null; then
    WEAK_AREAS=$(echo "$SCORECARD_JSON_CONTENT" | jq -r '.overallWeakAreas | join(", ")' 2>/dev/null)
    STRONG_AREAS=$(echo "$SCORECARD_JSON_CONTENT" | jq -r '.overallStrongAreas | join(", ")' 2>/dev/null)
    echo "Weak areas: $WEAK_AREAS" | tee -a "$LOG_FILE"
    echo "Strong areas: $STRONG_AREAS" | tee -a "$LOG_FILE"
else
    echo "WARNING: jq not available, Claude will parse ScoreCard directly" | tee -a "$LOG_FILE"
fi

# Verify Claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "ERROR: Claude CLI not found in PATH" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Building quiz generation prompt..." | tee -a "$LOG_FILE"

# Build the comprehensive quiz generation prompt
QUIZ_GEN_PROMPT="You are creating an adaptive practice quiz for Blake, a student preparing for his exams.

=== CONTEXT ===
CLASS: $CLASS_NAME
GENERATION DATE: $TIMESTAMP
STUDENT: Blake

=== SCORECARD.JSON (Performance Data) ===
$SCORECARD_JSON_CONTENT

=== TOPIC INDEX (Topic Definitions with Keywords) ===
$TOPIC_INDEX_CONTENT

=== STUDY GUIDE (ScoreCard.txt) ===
$SCORECARD_TXT_CONTENT

=== COURSE MATERIALS (Guide Directory) ===
$GUIDE_CONTENT

=== PDF STUDY MATERIALS (Read these files for additional questions) ===
The following PDF files contain exam questions and study content.
Read each file and use the questions as inspiration for creating similar quiz questions:
$PDF_REFS

=== EXISTING QUIZ (Template for Style/Format) ===
$EXISTING_QUIZ_CONTENT

=== YOUR TASK ===

Generate a NEW adaptive practice quiz HTML file that focuses on Blake's weak areas while reinforcing his knowledge.

QUESTION DISTRIBUTION:
- 70% of questions should focus on WEAK AREAS (topics where Blake scored below 70%):
  Weak areas: $WEAK_AREAS
- 20% of questions should cover topics NOT YET TESTED (to expand coverage)
- 10% of questions should REVIEW STRONG AREAS (to maintain confidence):
  Strong areas: $STRONG_AREAS

QUIZ STRUCTURE (STANDARDIZED FORMAT - 19 MC + 1 SA = 20 TOTAL):
1. Multiple Choice Section (EXACTLY 19 questions)
   - Each question must have exactly 4 options (A, B, C, D)
   - Focus heavily on weak area topics (70% of questions)
   - Include questions on topics not yet tested (20% of questions)
   - Include 1-2 questions on strong areas for confidence (10% of questions)
   - Tag each question with data-topic attribute for tracking

2. Short Answer Section (EXACTLY 1 question)
   - Focus on the HIGHEST PRIORITY weak area from ScoreCard
   - Should target concepts Blake needs to practice explaining
   - Expected response length: 3-6 sentences
   - Tag with data-topic attribute for the highest-priority weak topic
   - This is NOT an essay - keep it focused and concise

IMPORTANT: DO NOT include essay questions in regular quizzes. Essays are for midterms/finals only.

DIFFICULTY LEVELS:
- Include a mix: 40% foundational, 40% intermediate, 20% challenging
- Challenging questions should still be fair and based on course materials

QUESTION QUALITY:
- Use ACCURATE information from the study guide and course materials
- Create CLEAR, unambiguous questions
- For multiple choice, ensure distractors are plausible but clearly wrong
- Reference specific concepts, not vague generalizations

ENCOURAGING LANGUAGE:
- Include a brief encouraging message in the instructions mentioning this quiz was created to help Blake improve
- Frame it positively: 'This quiz focuses on areas where extra practice will help you shine on the exam!'

HTML REQUIREMENTS:
1. Use the EXACT same HTML structure and CSS styling as the existing quiz template
2. Keep the same:
   - Color scheme (navy #1a2744, burgundy #7c2d3e, cream #f8f5f0, gold #c9a959)
   - Font families (Libre Baskerville, Source Sans 3)
   - Section structure with icons (I, II, III, etc.)
   - Question numbering with burgundy circles
   - Progress bar functionality
   - Navigation bar with home link
   - Grading overlay and JavaScript functionality
   - Button styling and actions
   - Mobile/iPad responsive design

3. Update the following:
   - Quiz title to indicate it's an adaptive practice quiz
   - Subtitle to show focus areas
   - Total question count in progress bar
   - API endpoint should still be /api/answers/$CLASS_NAME
   - Quiz name in saveAnswers() should be 'Adaptive_Practice_Quiz'

4. CRITICAL - JavaScript Submission Code:
   The quiz MUST use this EXACT submission pattern. Copy this code exactly:

   async function saveAnswers(answers) {
       const studentName = 'Blake_';
       const quizName = 'Adaptive_Practice_Quiz';
       const date = new Date().toISOString().split('T')[0];
       const timestamp = new Date().toISOString();

       // Format answers as text (REQUIRED - server expects text, not JSON object)
       let content = \`ADAPTIVE PRACTICE QUIZ\\n\`;
       content += \`Student: \${studentName.replace('_', '')}\\n\`;
       content += \`Date: \${date}\\n\`;
       content += \`Submitted: \${new Date().toLocaleString()}\\n\\n\`;
       content += \`\${'='.repeat(60)}\\n\\n\`;
       content += \`PART I: MULTIPLE CHOICE (19 questions)\\n\`;
       content += \`\${'-'.repeat(30)}\\n\`;

       for (let i = 1; i <= 19; i++) {
           content += \`Q\${i}: \${answers['q' + i] || '(not answered)'}\\n\`;
       }

       content += \`\\nPART II: SHORT ANSWER\\n\`;
       content += \`\${'-'.repeat(30)}\\n\`;
       content += \`\\nQ20:\\n\${answers['q20'] || '(not answered)'}\\n\`;

       // Update overlay text
       const gradingText = document.querySelector('.grading-text');
       gradingText.textContent = 'Saving your answers...';

       try {
           const response = await fetch('/api/answers/$CLASS_NAME', {
               method: 'POST',
               headers: { 'Content-Type': 'application/json' },
               body: JSON.stringify({
                   name: studentName,      // MUST be 'name' not 'student'
                   date: date,
                   timestamp: timestamp,
                   answers: content,       // MUST be formatted text string
                   quizName: quizName      // MUST be 'quizName' not 'quiz'
               })
           });

           if (!response.ok) throw new Error('Failed to save answers');
           const result = await response.json();

           if (result.jobId) {
               gradingText.textContent = 'Grading your quiz...';
               pollGradingStatus(result.jobId);
           } else {
               throw new Error('No job ID returned');
           }
       } catch (error) {
           console.error('Error:', error);
           alert('Error submitting quiz. Please try again.');
           document.getElementById('gradingOverlay').classList.remove('active');
           document.getElementById('submitBtn').disabled = false;
       }
   }

   async function pollGradingStatus(jobId) {
       const maxAttempts = 120;
       let attempts = 0;
       const gradingText = document.querySelector('.grading-text');

       const poll = async () => {
           attempts++;
           try {
               const response = await fetch(\`/api/grading-status/\${jobId}\`);
               const data = await response.json();

               if (data.status === 'complete' && data.resultsUrl) {
                   gradingText.textContent = 'Grading complete! Redirecting...';
                   setTimeout(() => { window.location.href = data.resultsUrl; }, 1000);
                   return;
               } else if (data.status === 'error') {
                   alert(data.error || 'Grading failed. Please try again.');
                   document.getElementById('gradingOverlay').classList.remove('active');
                   document.getElementById('submitBtn').disabled = false;
                   return;
               } else if (data.status === 'processing') {
                   gradingText.textContent = \`Analyzing your answers... (\${attempts * 2}s)\`;
                   if (attempts < maxAttempts) setTimeout(poll, 2000);
                   else {
                       alert('Grading is taking longer than expected.');
                       document.getElementById('gradingOverlay').classList.remove('active');
                   }
               }
           } catch (error) {
               console.error('Error polling status:', error);
               if (attempts < maxAttempts) setTimeout(poll, 2000);
               else {
                   alert('Connection lost. Please refresh.');
                   document.getElementById('gradingOverlay').classList.remove('active');
               }
           }
       };
       poll();
   }

   IMPORTANT: The above code is REQUIRED. Do NOT modify field names or use different patterns.
   - Server expects 'name' field (NOT 'student' or 'studentName')
   - Server expects 'quizName' field (NOT 'quiz')
   - Server expects 'answers' as formatted TEXT string (NOT JSON object)
   - Grading is ASYNC - must poll /api/grading-status/{jobId} until complete

5. Add data-topic attribute to each question div:
   <div class=\"question\" data-topic=\"topic-id-here\">

=== CRITICAL OUTPUT REQUIREMENTS ===
Your output MUST follow this EXACT format with NO exceptions:

1. The VERY FIRST characters of your response must be: <!DOCTYPE html>
2. Do NOT include ANY text before <!DOCTYPE html> - no thinking, no analysis, no planning
3. Do NOT use markdown code blocks (\`\`\`) around the HTML
4. After the closing </html> tag, output the answer key on a NEW line
5. The answer key format: <!--ANSWER_KEY: {json} -->
6. Do NOT include ANY text after the closing --> of the answer key

INCORRECT (will break the system):
\"Now I have the quiz template...\" or \"Based on the weak areas...\" before HTML

CORRECT:
<!DOCTYPE html>
<html>...

=== ANSWER KEY FORMAT ===

After the closing </html> tag, output the answer key in this format:
<!--ANSWER_KEY:
{
  \"quizName\": \"Adaptive Practice Quiz\",
  \"generatedFor\": \"Blake\",
  \"generatedAt\": \"$TIMESTAMP\",
  \"focusAreas\": [...weak areas...],
  \"format\": \"19 multiple choice + 1 short answer = 20 total questions\",
  \"answers\": {
    \"q1\": {\"correct\": \"b\", \"topic\": \"topic-id\", \"explanation\": \"Brief explanation\"},
    \"q2\": {\"correct\": \"c\", \"topic\": \"topic-id\", \"explanation\": \"Brief explanation\"},
    ...
    \"q19\": {\"correct\": \"a\", \"topic\": \"topic-id\", \"explanation\": \"Brief explanation\"},
    \"q20\": {\"type\": \"short_answer\", \"topic\": \"highest-priority-weak-topic\", \"keyPoints\": [\"point1\", \"point2\", \"point3\"]}
  },
  \"totalPoints\": {
    \"multipleChoice\": 19,
    \"shortAnswer\": 2,
    \"total\": 21
  },
  \"grading\": {
    \"multipleChoice\": \"1 point each (19 total)\",
    \"shortAnswer\": \"0-2 points (2 = complete/accurate, 1 = partial, 0 = incorrect)\"
  }
}
-->

IMPORTANT:
- Make sure the quiz is COMPLETE and FUNCTIONAL
- Ensure all JavaScript event handlers are properly attached

=== FINAL OUTPUT INSTRUCTIONS - THIS IS THE MOST IMPORTANT PART ===

YOUR RESPONSE MUST START WITH EXACTLY: <!DOCTYPE html>

RULES (violations will break the system):
1. First character = '<' (the < of <!DOCTYPE html>)
2. NO text before <!DOCTYPE html> - no 'Now I have...', no 'Based on...', no 'Let me...', no planning
3. NO markdown code blocks around HTML
4. After </html>, add on new line: <!--ANSWER_KEY: {json} -->
5. Nothing after the closing -->

The system uses: sed -n '/<!DOCTYPE html>/,/<!--ANSWER_KEY:/p'
If you output ANYTHING before <!DOCTYPE html>, quiz generation FAILS.

START YOUR RESPONSE NOW: <!DOCTYPE html>"

# Write prompt to temporary file
PROMPT_FILE="$LOG_DIR/prompt_${TIMESTAMP}.tmp"
printf '%s' "$QUIZ_GEN_PROMPT" > "$PROMPT_FILE"

echo "Invoking Claude CLI for quiz generation..." | tee -a "$LOG_FILE"

# Create temp file for output
TEMP_OUTPUT="$LOG_DIR/output_${TIMESTAMP}.tmp"

# Run Claude CLI with 5-minute timeout
if command -v gtimeout &> /dev/null; then
    gtimeout 300 claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
elif command -v timeout &> /dev/null; then
    timeout 300 claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
else
    echo "WARNING: No timeout command available, running without timeout" | tee -a "$LOG_FILE"
    claude -p --dangerously-skip-permissions < "$PROMPT_FILE" > "$TEMP_OUTPUT" 2>> "$LOG_FILE"
fi

CLAUDE_EXIT_CODE=$?

# Clean up prompt file
rm -f "$PROMPT_FILE"

# Check for timeout
if [ $CLAUDE_EXIT_CODE -eq 124 ]; then
    echo "ERROR: Claude CLI timed out after 5 minutes" | tee -a "$LOG_FILE"
    rm -f "$TEMP_OUTPUT"
    exit 1
fi

if [ $CLAUDE_EXIT_CODE -ne 0 ]; then
    echo "ERROR: Claude CLI failed with exit code $CLAUDE_EXIT_CODE" | tee -a "$LOG_FILE"
    rm -f "$TEMP_OUTPUT"
    exit 1
fi

echo "Claude CLI completed successfully" | tee -a "$LOG_FILE"

# Verify output is not empty
if [ ! -s "$TEMP_OUTPUT" ]; then
    echo "ERROR: Claude output is empty" | tee -a "$LOG_FILE"
    rm -f "$TEMP_OUTPUT"
    exit 1
fi

# Extract the HTML (everything before <!--ANSWER_KEY:)
echo "Extracting quiz HTML..." | tee -a "$LOG_FILE"
sed -n '1,/<!--ANSWER_KEY:/p' "$TEMP_OUTPUT" | sed '$d' > "$TEMP_QUIZ_FILE"

# Verify HTML was extracted
if [ ! -s "$TEMP_QUIZ_FILE" ]; then
    echo "ERROR: Failed to extract HTML from output" | tee -a "$LOG_FILE"
    rm -f "$TEMP_OUTPUT" "$TEMP_QUIZ_FILE"
    exit 1
fi

# Verify it looks like HTML
if ! head -5 "$TEMP_QUIZ_FILE" | grep -q "DOCTYPE\|html"; then
    echo "ERROR: Output does not appear to be valid HTML" | tee -a "$LOG_FILE"
    echo "First 10 lines of output:" | tee -a "$LOG_FILE"
    head -10 "$TEMP_QUIZ_FILE" | tee -a "$LOG_FILE"
    rm -f "$TEMP_OUTPUT" "$TEMP_QUIZ_FILE"
    exit 1
fi

# Extract the answer key JSON
echo "Extracting answer key..." | tee -a "$LOG_FILE"
ANSWER_KEY=$(sed -n '/<!--ANSWER_KEY:/,/-->/p' "$TEMP_OUTPUT" | sed '1d;$d')

if [ -n "$ANSWER_KEY" ]; then
    # Validate JSON if jq is available
    if command -v jq &> /dev/null; then
        if echo "$ANSWER_KEY" | jq . > /dev/null 2>&1; then
            echo "$ANSWER_KEY" | jq . > "$NEW_ANSWER_KEY"
            echo "Answer key saved to: $NEW_ANSWER_KEY" | tee -a "$LOG_FILE"
        else
            echo "WARNING: Answer key is not valid JSON, saving raw content" | tee -a "$LOG_FILE"
            echo "$ANSWER_KEY" > "$NEW_ANSWER_KEY"
        fi
    else
        echo "$ANSWER_KEY" > "$NEW_ANSWER_KEY"
        echo "Answer key saved to: $NEW_ANSWER_KEY" | tee -a "$LOG_FILE"
    fi
else
    echo "WARNING: No answer key found in output" | tee -a "$LOG_FILE"
fi

# Move temp quiz file to final location (atomic operation)
mv "$TEMP_QUIZ_FILE" "$NEW_QUIZ_FILE"
echo "Quiz saved to: $NEW_QUIZ_FILE" | tee -a "$LOG_FILE"

# Clean up
rm -f "$TEMP_OUTPUT"

# Verify final quiz file exists and has content
if [ -s "$NEW_QUIZ_FILE" ]; then
    QUIZ_SIZE=$(wc -c < "$NEW_QUIZ_FILE")
    echo "SUCCESS: Adaptive quiz generated ($QUIZ_SIZE bytes)" | tee -a "$LOG_FILE"

    # Validate quiz format (19 MC + 1 SA = 20 total questions)
    echo "Validating quiz format..." | tee -a "$LOG_FILE"
    QUESTION_COUNT=$(grep -o 'class="question"' "$NEW_QUIZ_FILE" | wc -l | tr -d ' ')

    if [ "$QUESTION_COUNT" -eq 20 ]; then
        echo "FORMAT VALIDATION PASSED: Quiz has exactly 20 questions (19 MC + 1 SA)" | tee -a "$LOG_FILE"
    else
        echo "WARNING: Quiz has $QUESTION_COUNT questions (expected 20). This may indicate a generation error." | tee -a "$LOG_FILE"
        echo "The quiz was still saved, but please review it manually." | tee -a "$LOG_FILE"
    fi
else
    echo "ERROR: Final quiz file is empty or missing" | tee -a "$LOG_FILE"
    exit 1
fi

echo "=============================================" | tee -a "$LOG_FILE"
echo "Adaptive Quiz Generation Complete" | tee -a "$LOG_FILE"
echo "Quiz: $NEW_QUIZ_FILE" | tee -a "$LOG_FILE"
echo "Answer Key: $NEW_ANSWER_KEY" | tee -a "$LOG_FILE"
echo "Log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"

exit 0
