<objective>
Create an intelligent, adaptive quiz generator that analyzes student performance on previous quizzes to identify strengths and weaknesses, then generates a new personalized quiz focused on areas needing improvement while incorporating uncovered material from study guides.

This helps students efficiently focus their study time on topics they haven't mastered yet, rather than repeatedly reviewing material they already know well. The generated quiz will use the same beautiful HTML format as existing quizzes.
</objective>

<context>
Project structure:
- Each class has three directories: Quiz/ (HTML quiz files), Guide/ (study materials), Answers/ (saved student responses)
- Quiz format: Beautiful HTML with multiple choice, short answer, and essay questions (@/Users/chadc/dev/GitRepo/Exam-Prep/Government/Quiz/am_gov_quiz.html as reference)
- Answer files: Plain text format with student responses (@{Class}/Answers/ directory)
- Single student use case

This prompt will be interactive - it should ask the user for the class name, then analyze that class's materials.
</context>

<requirements>

## Step 1: Interactive Class Selection

First, use the AskUserQuestion tool to ask the user which class to analyze:
- header: "Class name"
- question: "Which class would you like to create an adaptive quiz for?"
- Provide options based on directories found in /Users/chadc/dev/GitRepo/Exam-Prep/ that contain Quiz/, Guide/, and Answers/ subdirectories
- Always include "Other" option for manual input

## Step 2: Comprehensive Data Collection

Thoroughly analyze the following data sources for the specified class:

1. **Existing Quizzes** (@{Class}/Quiz/*.html):
   - Read all quiz HTML files to understand question topics and structure
   - Extract all questions by section (multiple choice, short answer, essay)
   - Identify subject areas covered (e.g., "Articles of Confederation", "Federalism", "Congress")
   - Note the styling, structure, and format to replicate

2. **Student Answers** (@{Class}/Answers/*.txt):
   - Read ALL answer files (may be multiple attempts at same quiz)
   - Parse each file to extract responses for each question
   - Track which questions were answered correctly/incorrectly across attempts
   - Identify patterns: consistently correct topics vs. consistently struggled topics
   - Note questions left blank or incomplete

3. **Study Guides** (@{Class}/Guide/*):
   - List all files in Guide directory
   - Read available study materials (PDF, DOCX, TXT, MD, images)
   - Extract topics, concepts, and key information covered
   - Identify material NOT yet covered in existing quizzes

## Step 3: Performance Analysis

Thoroughly analyze the student's performance data:

**For each topic/concept:**
- Calculate success rate: How many times answered correctly vs. total attempts?
- Identify "mastered" topics (consistently correct, 80%+ success rate)
- Identify "struggling" topics (inconsistent or incorrect, <60% success rate)
- Identify "improving" topics (getting better over time)
- Note topics with no data (never quizzed or always skipped)

**Overall patterns:**
- Which question types does the student excel at? (MC, short answer, essay)
- Which question types need more practice?
- Are there time-based patterns? (rushing through certain sections)
- Topic gaps: What's in the guides but never quizzed?

## Step 4: Quiz Design Strategy

Create a balanced adaptive quiz with this distribution:

**Content Mix (25 questions total, matching existing format):**
- 40% (10 questions): Weak areas needing improvement
- 30% (8 questions): New material from guides not yet covered
- 20% (5 questions): Topics showing improvement (reinforce learning)
- 10% (2 questions): Mastered topics (confidence building + retention check)

**Question Type Distribution:**
- Multiple choice: 15-16 questions (60-64%)
- Short answer: 3-4 questions (12-16%)
- Essay: 2 questions (8%)

Adjust difficulty based on topic mastery:
- Weak areas: More detailed, nuanced questions
- New material: Foundational, conceptual questions
- Mastered topics: Brief review or application questions

## Step 5: Quiz Generation

Generate a complete HTML quiz file matching the existing format exactly:

**Structural requirements:**
- Copy the exact HTML structure, CSS styling, and JavaScript from @{Class}/Quiz/am_gov_quiz.html
- Maintain color scheme, fonts, layout, and responsive design
- Keep all existing functionality: progress tracking, auto-save, save to server, print
- Update title and header to reflect this is an "Adaptive Practice Quiz"
- Add a subtitle indicating it's "Personalized based on previous performance"

**Question quality:**
- Each question should be clear, specific, and educationally sound
- Multiple choice: 4 options, one clearly correct, plausible distractors
- Short answer: Specific prompt with clear expectations
- Essay: Include helpful hints about what to address (like existing essays)
- Cover different cognitive levels: recall, comprehension, application, analysis

**Metadata:**
- Include HTML comments at the top noting:
  - Generation date
  - Topics covered (weak areas, new material, review)
  - Performance data summary used to create this quiz

</requirements>

<implementation>

**Analysis Process:**

1. Use Glob to find all class directories with required subdirectories
2. Use AskUserQuestion to get class name from user
3. Use Glob and Read extensively to gather all data from Quiz/, Answers/, and Guide/ directories
4. For maximum efficiency, when reading multiple files, invoke Read tools in parallel
5. After gathering data, deeply analyze patterns and performance metrics
6. Design quiz strategy based on analysis
7. Generate complete HTML quiz file

**Why this approach:**
- Interactive class selection: Makes the prompt reusable for any class
- Comprehensive analysis: Reading all available data ensures accurate assessment
- Balanced quiz design: Mix of challenge and confidence-building for effective learning
- Exact format matching: Student gets consistent, familiar experience
- Data-driven decisions: Questions target actual learning gaps, not assumptions

**Constraints:**
- Never invent fake performance data - only use what exists in Answers/ files
- If no answer files exist, create a general quiz covering guide material and existing quiz topics
- Maintain exact CSS/JavaScript from original - don't "improve" the styling
- All questions must be on-topic and educationally appropriate
- File naming: Use descriptive name indicating it's adaptive (e.g., "adaptive_practice_quiz_1.html")

</implementation>

<output>

Generate and save:

**Analysis Report** - `./Analysis/{ClassName}_performance_analysis.md`:
- Summary of files analyzed
- Performance breakdown by topic/question type
- Identified strengths and weaknesses
- Topics from guides not yet covered
- Quiz generation strategy and rationale

**Adaptive Quiz** - `./{ClassName}/Quiz/adaptive_practice_quiz_{date}.html`:
- Complete HTML file matching existing quiz format exactly
- 25 questions distributed according to strategy above
- All styling, JavaScript, and functionality intact
- Questions focused on learning gaps and new material

</output>

<verification>

Before declaring complete, verify:

1. **Data Analysis:**
   - All answer files were read and parsed
   - Performance metrics calculated for each topic
   - Guide materials reviewed for coverage gaps
   - Clear strengths/weaknesses identified

2. **Quiz Quality:**
   - Exactly 25 questions total
   - Distribution matches strategy (weak areas, new material, review, mastery)
   - All questions are clear, specific, and grammatically correct
   - Multiple choice options are plausible and non-ambiguous
   - Essay hints provide helpful guidance

3. **Technical Quality:**
   - HTML validates and renders correctly
   - CSS matches existing quiz exactly (colors, fonts, layout)
   - JavaScript functionality preserved (progress bar, save, print, clear)
   - Save button POSTs to correct server endpoint
   - File saved in correct Quiz/ directory with descriptive name

4. **Documentation:**
   - Analysis report explains the data-driven decisions
   - Quiz generation strategy is clearly documented
   - Performance insights are actionable and specific

Test by opening the generated HTML file in a browser and verifying:
- Visual appearance matches existing quiz
- All interactive elements work (radio buttons, text inputs, progress bar)
- Save and print buttons function correctly

</verification>

<success_criteria>

- User is asked to select class name interactively
- All quiz, answer, and guide files for selected class are analyzed
- Performance analysis identifies specific strengths, weaknesses, and gaps
- Generated quiz has exactly 25 questions in the specified distribution
- Quiz HTML matches existing format exactly (visual and functional)
- Questions target identified learning gaps and uncovered material
- Analysis report documents the data-driven decision process
- Quiz file saved in correct location with descriptive filename
- All functionality preserved: save to server, print, progress tracking, auto-save

</success_criteria>

<examples>

**Good question targeting weak area (student struggled with federalism concepts):**
```
<div class="question">
    <span class="question-number">8</span>
    <span class="question-text">Which of the following best describes "cooperative federalism"?</span>
    <div class="options">
        <div class="option">
            <input type="radio" name="q8" id="q8a" value="a">
            <label for="q8a">A) State and federal governments working together on shared policy goals</label>
        </div>
        <!-- ... more options -->
    </div>
</div>
```

**Good question on new material from guides (never quizzed before):**
```
<div class="question">
    <span class="question-number">21</span>
    <span class="question-text">According to the study guide, what role did James Madison play in the Constitutional Convention?</span>
    <div class="short-answer">
        <input type="text" id="q21" placeholder="Type your answer here...">
    </div>
</div>
```

**Bad question (too vague, not actionable):**
```
<div class="question">
    <span class="question-number">15</span>
    <span class="question-text">What do you think about government?</span>
    <!-- Too broad, not testable -->
</div>
```

</examples>
