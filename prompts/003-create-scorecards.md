<objective>
Create a comprehensive ScoreCard checklist for each of Blake's three classes (Stats, Government, and the third class) that tracks all topics needed for semester finals success. Each ScoreCard should be organized, prioritized, and easy to update as Blake makes progress in studying.

These ScoreCards will serve as Blake's master tracking system for finals preparation, helping focus study time on high-priority topics and providing a clear view of what's been mastered versus what still needs work.
</objective>

<context>
Blake is preparing for semester finals across three classes. Based on test and quiz analyses already completed:

**Stats (Statistics):**
- Study guides created for Chapter 3 (regression) and Chapter 4 (experimental design/sampling)
- Quiz and test analyses show specific weak areas (slope interpretation, residual signs, bias explanations)
- Strong areas identified (r-squared, standard deviation of residuals)

**Other Classes:**
- Identify the other two classes by examining the directory structure
- Extract topics from any existing study materials, teacher guides, or test materials

The ScoreCards should synthesize information from:
- Existing study guides in each class's Prepare folder
- Teacher-provided guides in Guide folders
- Test and quiz results showing Blake's performance patterns
</context>

<workflow>

1. **Discover Class Structure:**
   - Identify all three class directories in the project
   - For each class, examine:
     - Prepare folder (existing study guides)
     - Guide folder (teacher materials, tests, quizzes)
   - Extract all topics covered

2. **Analyze Performance Data (if available):**
   - Read existing study guides and test analyses
   - Identify topics where Blake:
     - Struggles (mark as HIGH PRIORITY)
     - Shows partial understanding (mark as MEDIUM PRIORITY)
     - Has mastered (mark as LOW PRIORITY for review)

3. **Create ScoreCard for Each Class:**
   - Save to: `./[Class-Name]/Prepare/ScoreCard.txt`
   - Use plain text format with simple checkboxes [ ]
   - Organize by priority level and topic categories
   - Include brief descriptions of what mastery means for each topic

4. **Structure Each ScoreCard:**

```
# [CLASS NAME] SCORECARD - SEMESTER FINALS PREPARATION
## Student: Blake
## Created: [Date]
## Last Updated: [Date]

===============================================================================
OVERVIEW
===============================================================================

Total Topics: [number]
Mastered: [ ] (0%)
In Progress: [ ] (0%)
Not Started: [ ] (100%)

High Priority Topics: [number] - Focus here first!
Medium Priority Topics: [number] - Important for solid performance
Low Priority Topics: [number] - Maintain existing mastery

===============================================================================
HIGH PRIORITY TOPICS (Critical for Finals Success)
===============================================================================

These topics have shown consistent weaknesses on tests/quizzes or are
foundational concepts that everything else builds on.

### [Category Name - e.g., Slope Interpretation]

[ ] [Specific Skill/Concept]
    What mastery looks like: [Brief description of what Blake needs to demonstrate]
    Why this matters: [Connection to finals/other concepts]
    Study resources: [Reference to study guide sections]

[Repeat for all high-priority topics]

===============================================================================
MEDIUM PRIORITY TOPICS (Important for Solid Performance)
===============================================================================

These topics show partial understanding or are important but not critical.

### [Category Name]

[ ] [Specific Skill/Concept]
    What mastery looks like: [Brief description]
    Study resources: [Reference to study guide sections]

[Repeat for all medium-priority topics]

===============================================================================
LOW PRIORITY TOPICS (Maintain Existing Mastery)
===============================================================================

These topics Blake has already mastered. Quick review before finals is sufficient.

### [Category Name]

[ ] [Specific Skill/Concept] - Quick review only
    Current status: ✓ Strong performance on [test/quiz]

[Repeat for all low-priority topics]

===============================================================================
STUDY PLAN RECOMMENDATIONS
===============================================================================

Week 1 Focus: [List 3-5 high priority topics]
Week 2 Focus: [List remaining high priority + top medium priority topics]
Final Review: [Quick checklist of all topics for comprehensive review]

===============================================================================
PROGRESS NOTES
===============================================================================

[Space for Blake or tutor to add notes as topics are mastered]

- [Date]: [Topic] - Mastered after [study activity]
- [Date]: [Topic] - Still needs work on [specific aspect]
```

5. **Prioritization Logic:**

**HIGH PRIORITY criteria:**
- Lost 3+ points on test/quiz
- Appeared as mistake on multiple assessments
- Foundational concept needed for other topics
- Teacher emphasized in feedback
- Required skill for common finals question types

**MEDIUM PRIORITY criteria:**
- Lost 1-2 points on test/quiz
- Partial understanding demonstrated
- Important but not foundational
- Specific application of broader concept

**LOW PRIORITY criteria:**
- Perfect or near-perfect performance
- Mastered on both quizzes and tests
- Quick review sufficient

6. **For Stats Class Specifically:**

Based on existing analyses, include these HIGH PRIORITY topics:
- Slope interpretation with scaled variables (thousands, millions, etc.)
- Residual calculation and sign interpretation
- Bias explanations (nonresponse, response, how they affect results)
- Sample size effects on variability vs. center
- Statistical significance from simulations
- Complete randomization procedures
- Confounding explanations

Include these LOW PRIORITY topics:
- R-squared interpretation (mastered)
- Standard deviation of residuals interpretation (mastered)
- Making predictions from LSRL (mastered)
- Basic residual plot interpretation (mastered)

7. **For Classes Without Existing Analyses:**

- Extract topics from teacher guides
- Organize by chapter/unit
- Mark all as MEDIUM PRIORITY initially (can be refined as Blake studies)
- Focus on breadth of coverage

</workflow>

<requirements>

**File Requirements:**
- Save each ScoreCard to: `./[Class-Name]/Prepare/ScoreCard.txt`
- Use plain text format (.txt) for universal compatibility
- Use simple [ ] checkboxes that can be manually changed to [x]
- Include the date created and a "Last Updated" field

**Content Requirements:**
- Comprehensive coverage of all finals-relevant topics
- Clear priority markers (HIGH/MEDIUM/LOW) based on performance data
- Brief "What mastery looks like" descriptions for each topic
- References to study guide sections where applicable
- Organized by categories, not random order

**Usability Requirements:**
- Easy to scan quickly (use clear section headers)
- Checkboxes at start of each line for easy updating
- Progress tracking at top (can be manually updated)
- Space for notes and progress tracking
- Study plan recommendations based on priorities

**Synthesis Requirements:**
- Draw from ALL available sources (study guides, test analyses, teacher materials)
- For Stats: Heavily reference the Chapter 3 and Chapter 4 study guides and analyses
- Ensure consistency with identified strengths/weaknesses
- Don't duplicate topics - consolidate related skills
</requirements>

<output>
Create three ScoreCard files:
- `./Stats/Prepare/ScoreCard.txt`
- `./[Government-or-Class-2]/Prepare/ScoreCard.txt`
- `./[Third-Class]/Prepare/ScoreCard.txt`

Each file should be a complete, self-contained checklist that Blake can use to track finals preparation progress.
</output>

<verification>
Before declaring complete, verify:
- [ ] All three class directories identified
- [ ] Existing study materials read and synthesized
- [ ] Three ScoreCard files created in respective Prepare folders
- [ ] Each ScoreCard uses checkbox format [ ]
- [ ] Topics prioritized as HIGH/MEDIUM/LOW with clear criteria
- [ ] Stats ScoreCard reflects the detailed analyses already completed
- [ ] Each topic includes "what mastery looks like" description
- [ ] Study plan recommendations included in each ScoreCard
- [ ] Progress tracking section included
- [ ] Files saved as .txt format
</verification>

<success_criteria>
- All three classes have ScoreCard files in their Prepare directories
- Topics are comprehensive (cover all finals content)
- Priorities accurately reflect Blake's performance patterns (for Stats especially)
- Format is simple and easy to manually update (checkboxes)
- Clear connection between ScoreCard priorities and existing study guide content
- Blake can use these as a daily/weekly tracking system
- Parents/tutors can quickly see progress at a glance
- Each ScoreCard provides actionable study plan recommendations
</success_criteria>