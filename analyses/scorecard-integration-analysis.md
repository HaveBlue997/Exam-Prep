# ScoreCard Integration Analysis

**Date:** January 6, 2026
**Analyst:** Claude Code
**Project:** Exam-Prep

---

## 1. Summary: What Each File Type Does

### ScoreCard.txt (in `{Class}/Prepare/` directories)

Human-readable study tracking documents designed for **manual exam preparation**. These files contain:

- **Topic checklists** with checkbox mastery tracking (e.g., `[ ] Topic Name`)
- **Prioritized topics** (High/Medium/Low) based on exam importance
- **Detailed study guidance** per topic including:
  - "What mastery looks like" descriptions
  - "Why this matters" explanations
  - Study resources
- **Study plans** with day-by-day schedules
- **Essay strategies** (for Government and Literature)
- **Progress notes** section for manual tracking
- **Quick reference sections** with key terms and concepts

**Purpose:** Guide the student through studying before the exam using a structured approach.

### ScoreCard.json (in `{Class}/` directories)

Machine-readable JSON files designed for **automated quiz performance tracking**. Current structure:

```json
{
  "class": "Government",
  "sessions": [],
  "overallWeakAreas": [],
  "overallStrongAreas": [],
  "lastUpdated": null
}
```

**Purpose:** Track quiz results over time, identifying patterns in strong and weak areas based on actual quiz performance.

---

## 2. Comparison: Side-by-Side Data Tracking

| Aspect | ScoreCard.txt | ScoreCard.json |
|--------|---------------|----------------|
| **Format** | Human-readable text | Machine-parseable JSON |
| **Primary Purpose** | Pre-exam study planning | Post-quiz performance tracking |
| **Data Entry** | Manual (student/tutor) | Automated (grading system) |
| **Topics** | Comprehensive list (52-72 per class) | None currently; tracks sessions |
| **Mastery Status** | Checkbox-based (manual) | Score-based (automated) |
| **Study Guidance** | Yes (detailed per topic) | No |
| **Performance History** | No (only current status) | Yes (sessions array) |
| **Weak/Strong Areas** | Pre-determined by priority | Calculated from quiz results |
| **Time Dimension** | Study plan (future-focused) | Historical sessions (past-focused) |

---

## 3. Analysis: Purpose Overlap and Data Compatibility

### 3.1 Purpose Overlap

**Minimal overlap - they serve complementary purposes:**

| ScoreCard.txt | ScoreCard.json |
|---------------|----------------|
| What to study BEFORE taking quizzes | How you performed AFTER taking quizzes |
| Static study plan | Dynamic performance record |
| Teacher/tutor-defined priorities | Data-driven weak area identification |
| Prescriptive (tells you what to do) | Descriptive (tells you what happened) |

### 3.2 Data Compatibility

**ScoreCard.txt has valuable data that ScoreCard.json could use:**

1. **Topic Taxonomy**: ScoreCard.txt defines 52-72 topics per class with clear hierarchies (High/Medium/Low priority). ScoreCard.json has no topic structure at all.

2. **Topic Descriptions**: Each topic in ScoreCard.txt has metadata ("why this matters", study resources) that could enrich feedback.

3. **Priority Levels**: The High/Medium/Low categorization could weight quiz question scoring.

**However, current ScoreCard.json has NO topic-level granularity** - it only tracks:
- Session metadata (date, quiz name, student, results file)
- Overall weak/strong areas (arrays, currently empty)

### 3.3 Integration Need Assessment

The grading system (`grade-quiz.sh`) currently:
1. Invokes Claude CLI to grade answers
2. Saves results to HTML file
3. Creates a minimal session entry in ScoreCard.json (date, quiz, student, results file)
4. Does NOT parse results for topic-level performance
5. Does NOT populate `overallWeakAreas` or `overallStrongAreas`

**The grading system could benefit from ScoreCard.txt's topic structure** to:
- Categorize quiz questions by topic
- Track performance by topic over time
- Identify weak areas that align with the study plan priorities
- Suggest which High Priority topics to review next

---

## 4. Recommendation: Option C - Read-Only Reference

### Recommended Approach: **C) Have grading system read from .txt for topic structure (read-only reference)**

**Rationale:**

1. **Different ownership models**: ScoreCard.txt is maintained by educators/tutors for study planning. ScoreCard.json is maintained by the automated system. Bidirectional sync would create conflicts.

2. **Different purposes remain valid**: Study planning (before) and performance tracking (after) are complementary but distinct needs. Merging would reduce the value of each.

3. **Topic taxonomy is valuable**: The carefully structured topic lists in ScoreCard.txt provide the vocabulary needed to make ScoreCard.json more useful.

4. **No migration risk**: Keeping .txt unchanged means no risk of losing the rich study guidance content.

5. **Enhanced integration is beneficial**: The grading system currently doesn't categorize performance by topic. Using ScoreCard.txt as a reference would enable:
   - Topic-tagged quiz results
   - Automated weak area detection aligned with study priorities
   - Suggestions like "Review High Priority topic: Slope interpretation"

### Why NOT other options:

| Option | Reason Against |
|--------|----------------|
| A) Keep separate (no integration) | Misses opportunity for topic-level performance tracking |
| B) Migrate .txt to .json | Loses rich human-readable study guidance; different purposes |
| D) Bidirectional sync | Complex to implement; ownership conflicts; unnecessary |
| E) Other | No compelling alternative identified |

---

## 5. Implementation: Recommended Steps

### Phase 1: Create Topic Taxonomy Files (Low Effort)

Create a machine-readable topic index for each class that the grading system can reference:

**New file:** `{Class}/topic-index.json`

```json
{
  "class": "Stats",
  "topics": [
    {
      "id": "slope-interpretation",
      "name": "Slope interpretation with scaled variables",
      "priority": "high",
      "category": "Regression & Correlation - Communication Skills"
    },
    {
      "id": "residual-calculation",
      "name": "Residual calculation AND sign interpretation",
      "priority": "high",
      "category": "Regression & Correlation - Communication Skills"
    }
    // ... extracted from ScoreCard.txt
  ]
}
```

This can be extracted programmatically from ScoreCard.txt or maintained separately.

### Phase 2: Enhance ScoreCard.json Schema

Update the ScoreCard.json structure to track topic-level performance:

```json
{
  "class": "Stats",
  "sessions": [
    {
      "date": "2026-01-06T15:30:00-05:00",
      "quizName": "Chapter_3_Review",
      "student": "Blake",
      "score": { "earned": 18, "possible": 25, "percentage": 72 },
      "topicPerformance": [
        { "topicId": "slope-interpretation", "correct": 1, "total": 2 },
        { "topicId": "residual-calculation", "correct": 0, "total": 1 }
      ],
      "resultsFile": "Chapter_3_Review_Blake_2026-01-06_results.html"
    }
  ],
  "overallWeakAreas": ["slope-interpretation", "residual-calculation"],
  "overallStrongAreas": ["r-squared-interpretation"],
  "lastUpdated": "2026-01-06T15:35:00-05:00"
}
```

### Phase 3: Enhance Grading Script

Modify `grade-quiz.sh` to:

1. Read `topic-index.json` for the class
2. Prompt Claude CLI to also identify which topics each question covers
3. Parse graded results to extract topic-level scores
4. Update ScoreCard.json with topic performance data
5. Calculate and update `overallWeakAreas` and `overallStrongAreas`

### Phase 4: Feedback Loop (Optional Future Enhancement)

Display weak areas alongside study plan:
- Web UI could show: "You're weak in these High Priority topics: [list]"
- Could highlight which ScoreCard.txt topics need more practice
- No modification to ScoreCard.txt - just read and correlate

---

## 6. No Action Needed (Alternative View)

If integration is deemed too complex or not a priority, the files can remain separate indefinitely because:

### They Complement Each Other Naturally

| Phase | Use ScoreCard.txt | Use ScoreCard.json |
|-------|-------------------|-------------------|
| Before studying | Plan what to study | N/A |
| During studying | Track manual progress | N/A |
| Taking quiz | N/A | N/A |
| After quiz | N/A | Review graded results |
| Planning next session | Consult for next topics | Check weak areas |

### Current Value Is Already Captured

- ScoreCard.txt provides excellent study guidance as-is
- ScoreCard.json stores quiz sessions even without topic analysis
- The HTML results files contain the detailed grading feedback
- The human user (Blake/tutor) can mentally connect weak areas to study topics

### Integration Has Cost

- Additional development effort
- More complexity in grading pipeline
- Risk of bugs affecting grading
- Maintenance burden for topic-index.json

---

## 7. Final Recommendation

**Implement Option C (Read-Only Reference) in phases:**

1. **Immediate**: No changes needed - system works as designed
2. **Near-term** (if desired): Create `topic-index.json` files by extracting topics from ScoreCard.txt
3. **Medium-term** (if desired): Enhance grading to categorize questions by topic
4. **Long-term** (if desired): Add topic-level analytics to web UI

**Priority Assessment:**
- If the goal is simply to prepare for upcoming finals: **No integration needed**
- If building a long-term study platform: **Integration adds significant value**

The ScoreCard.txt files are exceptional study resources that stand alone. The ScoreCard.json system is a foundation that could grow more sophisticated over time. They serve different purposes and should remain separate files, but the grading system can (and eventually should) reference the topic taxonomy from ScoreCard.txt to provide more actionable feedback.

---

## Appendix: Files Examined

| File | Location | Size | Notes |
|------|----------|------|-------|
| ScoreCard.txt | Government/Prepare/ | 607 lines | 58 topics, 3 priority levels |
| ScoreCard.txt | Literature/Prepare/ | 683 lines | 72 topics, essay focus |
| ScoreCard.txt | Stats/Prepare/ | 446 lines | 52 topics, template focus |
| ScoreCard.json | Government/ | 7 lines | Empty sessions array |
| ScoreCard.json | Literature/ | 7 lines | Empty sessions array |
| ScoreCard.json | Stats/ | 7 lines | Empty sessions array |
| server.js | Server/ | 465 lines | Grading job orchestration |
| grade-quiz.sh | Server/ | 175 lines | Claude CLI grading |
