# Exam Prep Server

A local Node.js web server for hosting interactive quizzes, study guides, and saving quiz answers. This server allows you to take quizzes on your iPad (or any device on your local network) with full JavaScript functionality.

## Problem Solved

When HTML quiz files are opened directly from iCloud or the file system on iOS devices, JavaScript features like the "Save Answers" button don't work properly. By serving the quizzes through this web server, all functionality works correctly across all devices.

## Features

- Serve interactive HTML quizzes with working JavaScript
- Browse and view study guides (PDF, DOCX, TXT, images)
- Save quiz answers to the server (accessible from any device)
- View previously saved answers
- Support for multiple classes/subjects
- Accessible on local network (iPad, iPhone, other computers)

## Installation

### Prerequisites

- Node.js installed on your Mac ([download here](https://nodejs.org/))
- All quiz files should be in the project directory structure

### Setup Steps

1. Open Terminal on your Mac

2. Navigate to the Server directory:
   ```bash
   cd /Users/chadc/dev/GitRepo/Exam-Prep/Server
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

## Starting the Server

From the Server directory, run:

```bash
npm start
```

You should see output like:
```
============================================================
Exam Prep Server Started
============================================================
Local:            http://localhost:3000
Network:          http://<YOUR-IP>:3000

To find your IP address:
  Mac:    System Settings > Network > Wi-Fi > Details
  Or run: ipconfig getifaddr en0

Access from iPad: http://<YOUR-MAC-IP>:3000
============================================================
```

## Finding Your Mac's IP Address

### Method 1: System Settings
1. Open System Settings
2. Click on Network
3. Select Wi-Fi (make sure you're connected)
4. Click Details
5. Your IP address is listed (e.g., 192.168.1.100)

### Method 2: Terminal
```bash
ipconfig getifaddr en0
```

This will output your local IP address (e.g., 192.168.1.100)

## Accessing from iPad or Other Devices

1. Make sure your iPad/device is on the same Wi-Fi network as your Mac
2. Open Safari (or any browser) on your iPad
3. Navigate to: `http://YOUR-MAC-IP:3000`
   - Replace YOUR-MAC-IP with the IP address you found above
   - Example: `http://192.168.1.100:3000`

## Directory Structure

```
Exam-Prep/
├── Server/                  # Server code (this directory)
│   ├── server.js           # Main Express application
│   ├── package.json        # Node.js dependencies
│   ├── public/             # Static web pages
│   │   ├── index.html      # Home page
│   │   ├── class.html      # Class page template
│   │   └── styles.css      # Shared styles
│   └── README.md           # This file
│
└── {ClassName}/            # One directory per class (e.g., Government)
    ├── Quiz/               # Quiz HTML files go here
    ├── Guide/              # Study guides (PDF, DOCX, etc.)
    └── Answers/            # Server saves quiz answers here
```

## Adding New Classes

To add a new class (e.g., "History"):

1. Create the class directory structure:
   ```bash
   cd /Users/chadc/dev/GitRepo/Exam-Prep
   mkdir -p History/Quiz History/Guide History/Answers
   ```

2. Add quiz HTML files to `History/Quiz/`
3. Add study materials to `History/Guide/`
4. The class will automatically appear on the home page

## How It Works

### Taking a Quiz

1. Navigate to the server home page
2. Click on a class (e.g., "Government")
3. Click on a quiz to start
4. Fill out your name and date
5. Answer the questions
6. Click "Save Answers" - answers are saved to the server
7. You can also click "Print Quiz" to print (works on iPad!)

### Viewing Saved Answers

1. Go to the class page
2. Scroll to "Saved Answers" section
3. Click on any saved answer file to view it
4. Files are sorted by date (most recent first)

### Viewing Study Guides

1. Go to the class page
2. Look under "Study Guides" section
3. Click on any guide to open it

## API Endpoints

The server provides these endpoints:

- `GET /` - Home page with class list
- `GET /api/classes` - JSON list of available classes
- `GET /class/:className` - Class page
- `GET /api/class/:className` - JSON class information
- `GET /quiz/:className/:quizFile` - Serve quiz HTML
- `POST /api/answers/:className` - Save quiz answers
- `GET /api/answers/:className/:filename` - View saved answer
- `GET /guide/:className/:filename` - Serve study guide

## Troubleshooting

### Server won't start
- Make sure Node.js is installed: `node --version`
- Make sure you ran `npm install` first
- Check if port 3000 is already in use

### Can't access from iPad
- Make sure both devices are on the same Wi-Fi network
- Check your Mac's firewall settings (System Settings > Network > Firewall)
- Make sure the server is running
- Try accessing from your Mac's browser first: `http://localhost:3000`

### Quiz answers not saving
- Check that the Answers directory exists for that class
- Check the server console for error messages
- Make sure you have write permissions in the Answers directory

### Print button not working
- The print button uses `window.print()` which works when served through a web server
- Make sure you're accessing the quiz through the server (not opening the HTML file directly)

## Stopping the Server

Press `Ctrl+C` in the Terminal window where the server is running.

## Development Mode

For development with auto-restart on file changes:

```bash
npm run dev
```

This requires Node.js version 18+ (uses the --watch flag).

## Security Notes

- This server is designed for **local network use only**
- No authentication is required (single student use case)
- The server binds to `0.0.0.0` to allow network access
- Do not expose this server to the public internet
- All data is stored locally in plain text files

## File Naming

Saved answer files use this format:
```
{QuizName}_{Date}_{Time}.txt
```

Example: `AmGov_Quiz_2025-01-05_14-30-15.txt`

## Support

For issues or questions, check:
1. Server console output for error messages
2. Browser console (F12 or Cmd+Option+I) for client-side errors
3. File permissions in the Answers directories
4. Network connectivity between devices
