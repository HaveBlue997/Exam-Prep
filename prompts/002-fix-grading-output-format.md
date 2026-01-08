<objective>
Fix the grading prompt in Server/grade-quiz.sh so Claude outputs ONLY HTML without any reasoning text before it.

The current prompt has "CRITICAL OUTPUT REQUIREMENTS" at the beginning/middle, but Claude is still outputting reasoning text first, causing the HTML extraction to fail (empty results file).
</objective>

<context>
The issue: `sed -n '/<!DOCTYPE html>/,/<!--SCORECARD_UPDATE:/p'` finds nothing because Claude outputs text like "Let me analyze..." before the HTML.

The fix: Move output format instructions to the VERY END of the prompt. Research shows LLMs pay more attention to the end of prompts (recency effect).
</context>

<requirements>

## Step 1: Read the current prompt structure
Read Server/grade-quiz.sh to understand the full prompt construction, especially around lines 200-285.

## Step 2: Restructure the prompt
Move the "CRITICAL OUTPUT REQUIREMENTS" section to be the ABSOLUTE LAST thing in the prompt, after all the context and instructions.

The final structure should be:
1. All context (quiz, answers, topic index, etc.)
2. All grading instructions
3. Grading philosophy
4. OUTPUT FORMAT (at the very end, most prominent position)

## Step 3: Make the output instructions more prominent
Replace the current output section with this enhanced version at the END of the prompt:

```
=== FINAL OUTPUT INSTRUCTIONS - READ THIS LAST ===

CRITICAL: Your response format determines if the system works or breaks.

YOUR RESPONSE MUST START WITH EXACTLY THESE CHARACTERS: <!DOCTYPE html>

RULES:
1. First character of response = '<'
2. NO text before <!DOCTYPE html> (no "Let me...", no "Based on...", no analysis)
3. NO markdown code blocks
4. After </html>, add: <!--SCORECARD_UPDATE: {json here} -->
5. Nothing after the closing -->

The extraction script uses: sed -n '/<!DOCTYPE html>/,/<!--SCORECARD_UPDATE:/p'
If you output ANYTHING before <!DOCTYPE html>, the student gets an empty results page.

START YOUR RESPONSE NOW WITH: <!DOCTYPE html>
```

## Step 4: Also add a safeguard at the START
Add this at the very beginning of the prompt (first line):

```
OUTPUT REMINDER: This prompt ends with output format instructions. Follow them exactly.
```

</requirements>

<verification>
After making changes, verify:

```bash
# Check output instructions are at the end of the prompt string
grep -n "FINAL OUTPUT INSTRUCTIONS" Server/grade-quiz.sh

# Check the reminder is at the start
grep -n "OUTPUT REMINDER" Server/grade-quiz.sh

# Validate bash syntax
bash -n Server/grade-quiz.sh && echo "grade-quiz.sh: VALID"

# Test with a dry run (just build prompt, don't execute)
# The prompt should now have output instructions at the very end
```
</verification>

<success_criteria>
- [ ] OUTPUT REMINDER appears near the start of the prompt
- [ ] FINAL OUTPUT INSTRUCTIONS appears at the very end of the prompt (after grading philosophy)
- [ ] The instructions explicitly show "<!DOCTYPE html>" as the required first characters
- [ ] bash -n validation passes
</success_criteria>
