# Exam Prep Server

A Node.js web server for hosting interactive quizzes with iOS compatibility.

## Problem Solved

JavaScript features in HTML files don't work when opened directly on iOS devices (via Files app or email attachments). This server hosts the quiz files locally, making all interactive features work properly on any device with a web browser.

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
└── start-ngrok.sh    # Script to start server with ngrok tunnel
```

**Note:** The Pokemon class is included as a working example to demonstrate all features of the quiz system. Explore it to see how quizzes and study guides are structured.

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

4. **Add quiz files to the Quiz/ directory**

   Place your HTML quiz files in the Quiz/ folder. See the Pokemon/Quiz/ folder for examples of the quiz format.

5. **The server will automatically detect and display the new class**

   Simply restart the server (or it will pick up changes on the next request), and your new class will appear on the home page.
