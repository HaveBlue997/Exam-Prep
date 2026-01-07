<objective>
Update the Statistics Midterm Practice Quiz HTML file to create a targeted diagnostic assessment that validates Blake's known strengths, identifies persistent weaknesses, and aligns with the teacher's grading expectations and study guide content.

This is a DIAGNOSTIC quiz - the primary goal is to verify what Blake truly knows vs. what still needs work before the actual midterm, based on patterns observed in his Chapter 3 & 4 test performance.
</objective>

<context>
Blake is preparing for a statistics midterm with one week remaining. We have comprehensive data about his performance:

**Known Strengths (Verify Retention):**
- R-squared interpretation (perfect on both quiz and test)
- Standard deviation of residuals interpretation (mastered)
- Basic residual plot interpretation (understands no curve = linear OK)
- Identifying bias types (confounding, sample types)
- Making predictions from LSRL equations

**Persistent Weaknesses (Heavy Diagnostic Focus):**
- Slope interpretation with scaled variables (thousands, millions) - Lost points on BOTH quiz and test
- Residual sign interpretation (negative = fewer, positive = more) - Lost points on BOTH quiz and test
- Complete explanations for bias (must explain HOW it affects results, not just THAT it exists)
- Extrapolation reasoning (must explain WHY it's problematic, mention data range)
- Statistical significance interpretation (confused simulation vs actual results)

**Teacher's Grading Style (Critical to Match):**
- Demands COMPLETE explanations, not partial answers
- Expects specific statistical vocabulary and units
- Marks down vague language ("might affect" → wants "HOW does it affect")
- Requires context in every interpretation
- Values templates: "The predicted [y] increases/decreases by [slope] [y-units] for each [x-unit]"

**Files to Reference:**
- @"Stats/Guide/STAT Midterm Exam Study Guide 2025-2026.pdf" - Teacher's official study guide (topics, emphasis)
- @"Stats/Prepare/Chapter 3 Study Guide.txt" - Blake's test analysis with templates
- @"Stats/Prepare/Chapter 4 Study Guide.txt" - Blake's experiment/sampling analysis
- @"Stats/Prepare/Chapter 3 Quiz Analysis.txt" - Progression tracking quiz→test

**File to Modify:**
- @"Stats/Quiz/stats_midterm_practice_quiz.html" - Current generic quiz to be updated
</context>

<workflow>

**Phase 1: Analyze Source Materials (Read-Only)**

1. Read the teacher's study guide to understand:
   - Which topics are emphasized for the midterm
   - The level of detail expected
   - Any specific formulas or concepts highlighted

2. Read Blake's three study guides to extract:
   - Exact questions Blake got wrong (with teacher feedback)
   - Templates for correct answers
   - Persistent vs. improving issues
   - Misconceptions to test for

3. Read the current quiz HTML to understand:
   - Current question structure and format
   - Sections and question types
   - How answers are collected/saved

**Phase 2: Design Diagnostic Question Strategy**

Based on Blake's performance patterns, create a question distribution:

**Section I: Multiple Choice - Data Types & Descriptive Statistics (5 questions)**
- Keep 1-2 questions on strong areas (graph types, categorical vs quantitative)
- Add 2-3 questions targeting mean/median/skew interpretation
- Include 1 question on outlier identification (boxplot rule)

**Section II: Multiple Choice - Normal Distributions (5 questions)**
- Keep 1 question on Empirical Rule (Blake is solid here)
- Add 2 questions on z-score interpretation (testing negative vs positive)
- Add 1 question on percentile interpretation
- Add 1 question on density curve properties

**Section III: Multiple Choice - Correlation & Regression (5 questions)**
- Include 1 R-squared question (verify retention of mastered concept)
- Add 2-3 questions on slope/intercept interpretation (Blake's WEAK AREA)
- Add 1 question on correlation vs causation
- Add 1 question on residual definition

**Section IV: Short Answer - Calculations (7 questions)**
- Light touch on mean/median (Blake can calculate)
- Heavy emphasis on:
  - Q: Slope interpretation with SCALED data (enrollment in thousands, price in millions)
  - Q: Residual calculation AND sign interpretation (test if Blake catches negative sign)
  - Q: Extrapolation with complete explanation of WHY it's problematic
  - Q: Bias identification AND explanation of HOW it affects results
  - Q: z-score calculation and interpretation

**Section V: Extended Response (3 questions)**
- Q23: Normal distribution multi-part (Empirical Rule application)
- Q24: Regression interpretation multi-part (slope, intercept, r-squared, residual - CRITICAL for Blake)
- Q25: Experimental design (bias explanation, random assignment, statistical significance)

**Phase 3: Write Targeted Diagnostic Questions**

For EACH question targeting Blake's weak areas, ensure:

**Slope Interpretation Questions:**
- Use scaled variables (thousands, millions, hundreds of thousands)
- Require full template: "The predicted [y-var] increases/decreases by [slope value] [y-units] for each additional [x-unit]"
- Example: "Price (in thousands of dollars) vs. Square Feet" with ŷ = 45.2 + 0.18x
- This tests if Blake correctly interprets 0.18 as "$180 per square foot" (0.18 thousand = 180)

**Residual Sign Questions:**
- Provide actual value, predicted value, and ask for residual + interpretation
- Include NEGATIVE residuals to test if Blake says "fewer" not "more"
- Example: Actual = 23, Predicted = 28, Residual = -5 → "5 fewer [y-units] than predicted"

**Bias Explanation Questions:**
- Not just "identify the bias type" but "explain HOW this bias affects the results"
- Must include: direction (over/underestimate), mechanism, why it matters
- Example: Nonresponse bias in cheating survey → explain WHO doesn't respond and HOW this affects the 4% figure

**Extrapolation Questions:**
- Must mention data range explicitly
- Must explain WHY prediction is unreliable (no evidence relationship continues)
- Example: Data from x=2 to x=26, predict for x=50 → "outside data range, relationship may not continue"

**Statistical Significance Questions:**
- Test Blake's understanding of simulation vs actual results
- Clarify that simulation creates NULL distribution, actual is compared TO it
- Example: Simulation shows differences -8 to +8, actual is +10 → explain what this means

**Phase 4: Update the HTML File**

Modify @"Stats/Quiz/stats_midterm_practice_quiz.html":

1. Preserve all existing HTML structure, styling, and JavaScript functionality
2. Replace questions in each section with diagnostic questions
3. Update question numbering to remain sequential
4. Maintain the same input types (radio buttons for MC, text inputs for short answer, textareas for extended)
5. Update placeholder text to guide Blake toward complete answers
6. Ensure "Save Answers" functionality remains intact

**Question Quality Standards:**

For Multiple Choice:
- One clearly correct answer
- Distractors should target common misconceptions
- Options should be mutually exclusive

For Short Answer:
- Clear what format is expected (use placeholder hints)
- Example: placeholder="Slope: [value] [units], Interpretation: [complete sentence]"

For Extended Response:
- Multi-part questions (a, b, c, d) testing related concepts
- Hints that guide toward complete explanations without giving answers
- Space for showing work

**Phase 5: Verification**

After updating, verify:
- All 25 questions are present and numbered correctly
- Blake's weak areas have 3-4 targeted questions each
- Blake's strong areas have 1-2 retention check questions
- Every question requiring interpretation includes units/context
- Placeholder text guides toward teacher's expected format
- HTML structure and functionality preserved
- Questions align with teacher's study guide topics

</workflow>

<requirements>

**Content Requirements:**
- Heavily weight questions toward Blake's known weak areas:
  - 3-4 questions on slope interpretation (various scaled units)
  - 3-4 questions on residual signs and interpretation
  - 2-3 questions on bias explanation (not just identification)
  - 2 questions on extrapolation reasoning
  - 2 questions on statistical significance understanding
- Include 2-3 questions on Blake's strong areas to verify retention
- All questions must align with topics in teacher's study guide
- Questions must test the DEPTH of understanding the teacher expects

**Teacher's Grading Style Requirements:**
- Questions must demand complete explanations, not one-word answers
- Use placeholder text that prompts for: "[answer] because [explanation]"
- For interpretation questions, require: value + units + context + meaning
- For bias questions, require: type + direction + mechanism + impact
- Match the level of detail seen in teacher's feedback on Blake's tests

**Technical Requirements:**
- Preserve ALL existing HTML structure exactly
- Maintain all CSS styling and classes
- Keep all JavaScript functionality intact (progress tracking, auto-save, save to server)
- Preserve iPad optimizations
- Only modify question text, options, and placeholder hints
- Keep input types consistent (radio for MC, text for short answer, textarea for extended)

**Diagnostic Quality Requirements:**
- Each weak area should have questions of varying difficulty to diagnose depth of issue
- Include "trap" questions that test if Blake falls into his known misconceptions
- Verify retention of previously mastered concepts (don't assume they're still mastered)
- Questions should allow us to distinguish between:
  - Fully mastered (can apply in any context)
  - Partially understood (correct in simple cases, fails in complex)
  - Not understood (consistent errors)

</requirements>

<implementation>

**Step-by-Step Approach:**

1. Read and analyze ALL source documents first
2. Create question bank organized by:
   - Topic area (descriptive stats, normal dist, regression, sampling)
   - Difficulty level (basic, intermediate, advanced)
   - Blake's performance level (mastered, improving, weak)
3. Map questions to the 5-section structure
4. Write each question with:
   - Clear stem
   - Appropriate options/input format
   - Placeholder guidance for expected answer format
   - Alignment to teacher's grading standards
5. Update HTML file section by section
6. Verify question numbering and functionality

**Question Writing Guidelines:**

For Slope Interpretation (Blake's #1 weak area):
```
Question: "The regression equation for predicting house price (in thousands of
dollars) based on square footage is ŷ = 45.2 + 0.18x. Interpret the slope."

Placeholder: "The predicted ___ increases/decreases by ___ ___ for each ___"

This tests:
- Can Blake identify 0.18 thousand = $180?
- Does Blake include units (dollars, not just "180")?
- Does Blake say "per square foot"?
```

For Residual Signs (Blake's #2 weak area):
```
Question: "For a student with 12 hours of study, the regression line predicts
a GPA of 3.4. The student's actual GPA is 3.1. Calculate and interpret the residual."

Placeholder: "Residual = ___, Interpretation: The student had ___ [higher/lower]
GPA than ___"

This tests:
- Calculation: 3.1 - 3.4 = -0.3
- Sign awareness: negative means LOWER, not higher
- Complete interpretation with units
```

**What NOT to Do:**
- Don't create "gotcha" questions that are unfairly tricky
- Don't use different statistical methods than what Blake has learned
- Don't break the HTML structure or JavaScript functionality
- Don't remove diagnostic value by making questions too easy
- Don't add new sections or change the overall quiz format

</implementation>

<output>
Modify the existing file:
- `./Stats/Quiz/stats_midterm_practice_quiz.html` - Updated with diagnostic questions

The updated quiz should:
- Test Blake's known weak areas with 3-4 targeted questions each
- Verify retention of mastered concepts with 2-3 questions
- Match teacher's grading expectations and study guide emphasis
- Provide clear diagnostic data about what Blake truly understands
- Remain fully functional with all save/print/progress features intact
</output>

<verification>
Before declaring complete, verify:
- [ ] Read teacher's study guide and all Blake's study guides
- [ ] Analyzed Blake's test performance patterns (quiz → test progression)
- [ ] Created 25 questions distributed appropriately across 5 sections
- [ ] Heavy emphasis (3-4 questions) on each persistent weak area:
  - [ ] Slope interpretation with scaled variables
  - [ ] Residual sign interpretation
  - [ ] Bias explanation (how/why, not just identification)
  - [ ] Extrapolation reasoning with data range
  - [ ] Statistical significance interpretation
- [ ] Light verification (2-3 questions) of mastered concepts
- [ ] All interpretation questions require complete explanations with units
- [ ] Placeholder text guides toward teacher's expected format
- [ ] HTML structure, styling, and JavaScript functionality preserved
- [ ] Questions align with teacher's study guide topics
- [ ] Quiz provides actionable diagnostic information about Blake's understanding
</verification>

<success_criteria>
- Quiz contains targeted diagnostic questions based on Blake's actual performance data
- 60-70% of questions focus on Blake's persistent weak areas
- 10-15% of questions verify retention of mastered concepts
- 20-25% of questions cover new midterm topics from teacher's study guide
- Every question requiring explanation includes guidance for complete answers
- Questions match the level of rigor and detail the teacher expects
- HTML file remains fully functional after modifications
- Quiz will reveal whether Blake has truly mastered weak areas or still needs work
- Results will inform final week of study priorities
</success_criteria>

<examples>

**Example: Good Diagnostic Slope Question**
```html
<div class="question">
    <span class="question-number">12</span>
    <span class="question-text">The regression equation for predicting enrollment
    (in thousands of students) based on tuition (in dollars) is ŷ = 15.2 - 0.003x.
    Interpret the slope in context.</span>
    <div class="short-answer">
        <input type="text" id="q12" placeholder="The predicted enrollment decreases
        by ____ thousand students (or ____ students) for each additional ____ in tuition">
    </div>
</div>
```
Why this is good:
- Tests scaled variable understanding (0.003 thousand = 3 students)
- Requires complete interpretation with units
- Placeholder guides format without giving answer
- Matches teacher's expected level of detail

**Example: Good Diagnostic Residual Question**
```html
<div class="question">
    <span class="question-number">18</span>
    <span class="question-text">Using the regression equation ŷ = 12.5 + 2.3x,
    the predicted value for x = 10 is 35.5. If the actual observed value is 32,
    calculate and interpret the residual.</span>
    <div class="short-answer">
        <input type="text" id="q18" placeholder="Residual = ____, The actual value
        was ____ [higher/lower] than predicted">
    </div>
</div>
```
Why this is good:
- Tests calculation accuracy
- Tests sign interpretation (32 - 35.5 = -3.5 = LOWER)
- Requires interpretation, not just calculation
- Catches Blake's tendency to ignore negative signs

</examples>