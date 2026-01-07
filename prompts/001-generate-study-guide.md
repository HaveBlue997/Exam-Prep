<objective>
Create a comprehensive, categorized study guide to help a student prepare for an upcoming test. The study guide should be organized by topic categories (e.g., Judicial Branch, Executive Branch, Constitutional Amendments, Types of Statistical Graphs, Types of Surveys) with factual bullet points that provide the essential information needed to perform well on the test.

This prompt is designed to be reusable across multiple classes and tests. Each execution should prompt the user to select which class they're preparing for, then generate or update the study guide accordingly.
</objective>

<context>
The student has three classes, each with its own directory structure:
- Each class directory contains a "Prepare" folder for study materials
- Teacher-provided guides exist but need more detail and better organization
- Some classes may have existing study guides that need updating
- Students may have taken practice quizzes that reveal their strengths and weaknesses

The goal is to create study materials that are more detailed than the teacher's outline while being organized in a way that makes studying efficient and effective.
</context>

<workflow>
1. **Class Selection**: Ask the user which class they want to create/update a study guide for using AskUserQuestion with these options:
   - List the three class directories found in the project
   - Allow them to select which one to work on

2. **Discovery Phase**: Examine the selected class's Prepare folder and identify:
   - Teacher-provided guide (if exists) - read to understand topics covered
   - Existing study guide (if exists) - read to understand current coverage
   - Practice quiz results (if exist) - analyze correct vs incorrect answers to identify weak areas
   - Any other relevant materials

3. **Content Analysis**:
   - Extract all topics from teacher's guide
   - Identify natural category groupings (e.g., Government branches, Constitutional topics, Statistical methods)
   - If practice quiz exists, map incorrect answers to specific categories to understand gaps
   - If existing study guide exists, identify areas that need more detail or emphasis

4. **Study Guide Generation**:
   - Organize content by clear, logical categories
   - Within each category, present information as factual bullet points
   - Use **mixed depth approach**:
     - Categories where student answered incorrectly on practice quiz: provide comprehensive detail with definitions, examples, key facts, and relationships
     - Categories where student performed well: provide focused essentials
     - For categories without quiz data: provide balanced, moderate detail
   - Include special markers (⚠️) for categories that need extra attention based on quiz performance
   - Ensure all bullet points are factual, concise, and test-relevant
   - Maintain balanced coverage across all topics even when emphasizing weak areas

5. **Archiving**: If an existing study guide is found:
   - Create an "Archive" subfolder in the Prepare directory if it doesn't exist
   - Move the old study guide to Archive with timestamp in filename (e.g., `Study-Guide-2026-01-06.md`)
   - Explain to the user what was archived and why

6. **File Creation**: Save the new study guide as:
   - `./[Class-Name]/Prepare/Study-Guide.md`
</workflow>

<requirements>
**Content Requirements:**
- Organize by clear category headers (## Category Name)
- Use bullet points for all factual information
- Include ⚠️ marker for categories needing extra attention (based on quiz performance)
- Ensure accuracy - only include verifiable facts relevant to the test
- Make information dense but readable - avoid fluff or filler

**Structure Requirements:**
- Begin with a header showing class name and date created
- Include a "Focus Areas" section at top if practice quiz data exists
- Group related topics into logical categories
- Use consistent formatting throughout

**Archiving Requirements:**
- Always preserve existing study guides before creating new ones
- Use clear timestamps in archived filenames
- Organize archives in dedicated subfolder
- Never overwrite previous study guides

**User Communication:**
- Clearly explain what you found (existing guides, quiz results, etc.)
- Show which categories are being emphasized based on quiz performance
- Confirm successful creation and archiving
</requirements>

<output>
Primary output:
- `./[Class-Name]/Prepare/Study-Guide.md` - The new or updated study guide

If archiving:
- `./[Class-Name]/Prepare/Archive/Study-Guide-[YYYY-MM-DD].md` - Archived previous version
</output>

<verification>
Before declaring complete, verify:
- [ ] User was prompted to select a class
- [ ] All relevant existing materials were read and analyzed
- [ ] Practice quiz results were incorporated if available
- [ ] Previous study guide was archived if it existed
- [ ] New study guide contains all categories from teacher's outline
- [ ] Categories are organized logically with clear headers
- [ ] Weak areas (from quiz) have ⚠️ markers and comprehensive detail
- [ ] All content is factual and test-relevant
- [ ] File was saved to correct location
</verification>

<success_criteria>
- Study guide is better organized than teacher's original outline
- Content is presented as scannable, factual bullet points
- Students can quickly identify which areas need the most attention
- Previous work is preserved in archive
- Guide is comprehensive enough to support effective test preparation
- Mixed depth approach provides emphasis on weak areas while maintaining full topic coverage
</success_criteria>