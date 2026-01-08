<objective>
Fix the adaptive quiz generation in Server/generate-adaptive-quiz.sh which is failing with "Claude CLI failed with exit code 1".

ROOT CAUSE FOUND: Line 96 does `$(cat "$guide_file")` which reads ALL files including PDFs!
- PDFs are binary files (3MB, 6MB, 9MB)
- `cat` on a PDF outputs garbage binary data
- This corrupts the prompt and causes Claude CLI to fail
</objective>

<context>
The quiz generation loads:
- ScoreCard.json
- Topic index
- ScoreCard.txt study guide
- All PDF files from Guide/ directory (can be huge)
- Existing quiz template

This creates a very large prompt that may exceed context limits or cause timeout.
</context>

<requirements>

## Step 1: Read the current script
Read Server/generate-adaptive-quiz.sh to understand the full structure, especially:
- How PDFs are loaded (look for "Loading guide:")
- How the prompt is built
- Where output format instructions are

## Step 2: FIX THE PDF BUG (Critical!)
Lines 90-98 currently do:
```bash
for guide_file in "$GUIDE_DIR"/*; do
    if [ -f "$guide_file" ]; then
        GUIDE_CONTENT="$GUIDE_CONTENT
=== $(basename "$guide_file") ===
$(cat "$guide_file")"    # <-- THIS BREAKS ON PDFs!
    fi
done
```

Replace with text-only file loading:
```bash
for guide_file in "$GUIDE_DIR"/*; do
    if [ -f "$guide_file" ]; then
        # Only load text files, skip PDFs and other binary files
        case "$guide_file" in
            *.pdf|*.PDF|*.docx|*.xlsx|*.png|*.jpg|*.jpeg)
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
```

## Step 3: Move output instructions to END
Same fix as the grading prompt - move output format to the very end:

```
=== FINAL OUTPUT INSTRUCTIONS - READ THIS LAST ===

CRITICAL: Your response format determines if the system works or breaks.

YOUR RESPONSE MUST START WITH EXACTLY THESE CHARACTERS: <!DOCTYPE html>

RULES:
1. First character of response = '<'
2. NO text before <!DOCTYPE html> (no "Now I have...", no "Based on...", no planning)
3. NO markdown code blocks
4. After </html>, add: <!--ANSWER_KEY: {json array here} -->
5. Nothing after the closing -->

If you output ANYTHING before <!DOCTYPE html>, the quiz generation fails.

START YOUR RESPONSE NOW WITH: <!DOCTYPE html>
```

## Step 4: Add error capture
Improve error logging to capture why Claude CLI fails:

```bash
# Before the Claude invocation, add:
echo "Prompt size: $(wc -c < "$PROMPT_FILE") bytes" | tee -a "$LOG_FILE"

# After Claude invocation, capture stderr:
if [ $CLAUDE_EXIT_CODE -ne 0 ]; then
    echo "ERROR: Claude CLI failed with exit code $CLAUDE_EXIT_CODE" | tee -a "$LOG_FILE"
    echo "Last 20 lines of output:" | tee -a "$LOG_FILE"
    tail -20 "$TEMP_OUTPUT" 2>/dev/null | tee -a "$LOG_FILE"
fi
```

</requirements>

<verification>
After making changes:

```bash
# Validate bash syntax
bash -n Server/generate-adaptive-quiz.sh && echo "generate-adaptive-quiz.sh: VALID"

# Check output instructions are at the end
grep -n "FINAL OUTPUT INSTRUCTIONS" Server/generate-adaptive-quiz.sh

# Check size logging was added
grep -n "Prompt size" Server/generate-adaptive-quiz.sh

# Test by running for Stats class
bash Server/generate-adaptive-quiz.sh Stats

# Check if quiz was generated
ls -la Stats/Quiz/adaptive_practice_quiz.html

# Validate the generated HTML
head -5 Stats/Quiz/adaptive_practice_quiz.html | grep -q "<!DOCTYPE" && echo "HTML format: VALID"

# Validate the answer key JSON
jq . Stats/Quiz/adaptive_practice_quiz_answer_key.json > /dev/null && echo "JSON format: VALID"
```
</verification>

<success_criteria>
- [ ] bash -n validation passes
- [ ] PDF loading is limited to prevent huge prompts
- [ ] Output instructions are at the end of the prompt
- [ ] Prompt size is logged
- [ ] Running the script produces a valid HTML quiz file
- [ ] Running the script produces a valid JSON answer key
</success_criteria>
