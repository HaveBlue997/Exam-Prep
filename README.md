# Exam Prep

An AI-powered exam tutoring system that helps students master course material through adaptive quizzing and personalized feedback.

## What It Does

This application acts as a personal exam tutor that:

- **Assesses mastery** - Analyzes student responses to identify strengths and areas needing improvement
- **Generates adaptive quizzes** - Creates personalized practice quizzes (multiple choice and short answer) that focus on topics where the student needs more work
- **Provides AI-graded feedback** - Delivers detailed explanations on incorrect answers to reinforce learning
- **Tracks progress** - Maintains a scorecard showing improvement over time across different topics
- **Builds confidence** - Helps students feel prepared and confident by systematically addressing knowledge gaps

The system uses study guides, syllabi, and previous exams as source material to generate relevant quiz questions aligned with actual course content.

## Technical Overview

Built on Node.js with Express, the server hosts interactive HTML quizzes that work on any device with a web browser, including iOS devices where JavaScript-heavy HTML files don't work when opened directly.

## Quick Start

```bash
cd Server
npm install
npm start
```

Server runs at http://localhost:3000

## Remote Access with ngrok

To access quizzes from devices outside your local network (e.g., from school or on the go):

1. **Sign up for free** at https://ngrok.com

2. **Install ngrok**:
   - Mac: `brew install ngrok`
   - Other platforms: Download from https://ngrok.com/download

3. **Authenticate** (one-time setup):
   ```bash
   ngrok authtoken YOUR_AUTH_TOKEN
   ```
   Find your auth token in the ngrok dashboard after signing up.

4. **Run the tunnel**:
   ```bash
   ./start-ngrok.sh
   ```
   This starts the server and creates a public URL.

5. **Share the URL**: The generated ngrok URL (e.g., `https://abc123.ngrok.io`) can be accessed from anywhere.

## Local Network Access

For devices on the same WiFi network:

1. Find your Mac's IP address (System Preferences > Network)
2. Access the server at `http://YOUR_MAC_IP:3000`

## Project Structure

```
Exam-Prep/
├── Server/           # Node.js server application
│   ├── server.js     # Main server file
│   ├── templates/    # HTML templates
│   └── prompts/      # AI grading prompts
├── Pokemon/          # Functional example class with real quiz content
│   ├── Quiz/         # Quiz HTML files
│   ├── Guide/        # Study guides and reference materials
│   ├── Answers/      # Student answer submissions (gitignored)
│   └── Archive/      # Archived quizzes (gitignored)
├── Example_Class/    # Template directory - duplicate this to create new classes
│   ├── Quiz/         # Place quiz HTML files here
│   ├── Guide/        # Placeholder files showing what to add
│   ├── Answers/      # Student submissions will be saved here
│   ├── Archive/      # Move old quizzes here when done
│   └── Prepare/      # Preparation materials
├── init-class.sh     # Script to initialize a new class (generates quizzes from Guide materials)
└── start-ngrok.sh    # Script to start server with ngrok tunnel
```

**Note:** The Pokemon class is included as a working example demonstrating the full tutoring workflow: study guides, quizzes, AI grading, and adaptive quiz generation. Explore it to see how the system works before adding your own classes.

## Adding New Classes

To add a new class or subject:

1. **Duplicate the Example_Class directory**
   ```bash
   cp -r Example_Class Biology
   ```

2. **Rename it to your class name** (e.g., "Biology", "History", "Math")

3. **Populate the Guide/ directory with actual class materials:**

   The Example_Class/Guide/ folder contains empty placeholder files with descriptive names. Replace these with your real documents:

   | Placeholder File | Replace With |
   |-----------------|--------------|
   | `ClassSyllabus` | Your course syllabus (PDF, DOC, or TXT) |
   | `PreviousQuiz` | Sample quizzes from the class |
   | `PreviousTest` | Sample tests from the class |
   | `StudyGuide` | Study materials, notes, or review sheets |

   You can add multiple files of each type and use any naming convention that works for you.

   **Material Priority** (for AI analysis):
   - Syllabus and study guides are most important (define course scope)
   - Previous tests are second (show exam format and teacher expectations)
   - Previous quizzes are third (additional question styles)

4. **Initialize the class**
   ```bash
   ./init-class.sh YourClassName
   ```

   This script reads your Guide materials and generates:
   - `Prepare/ScoreCard.txt` - Study plan with topic checklist
   - `topic-index.json` - Topic taxonomy for AI grading
   - `ScoreCard.json` - Performance tracker (starts empty)
   - `Quiz/YourClassName_diagnostic_quiz.html` - Initial quiz to assess baseline knowledge

   **Note:** This takes 2-3 minutes as it involves multiple AI processing steps.

5. **Start using the system**

   Start the server and take the diagnostic quiz:
   ```bash
   cd Server && npm start
   ```

   Open http://localhost:3000, select your class, and take the diagnostic quiz. After grading, the system will automatically generate adaptive quizzes targeting areas that need work.
