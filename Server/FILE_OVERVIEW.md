# File Overview

## Complete File Structure

```
Exam-Prep/
│
├── Government/                                    # Example class directory
│   ├── Quiz/
│   │   └── am_gov_quiz.html                     # ✏️ Modified - uses server API
│   ├── Guide/
│   │   └── AMERICAN GOVERNMENT - MIDTERM INFO.txt
│   └── Answers/
│       └── AmGov_Quiz_Test_2025-01-05_18-05-02.txt  # Test file
│
└── Server/                                        # 🆕 New server directory
    ├── server.js                                  # 🔧 Main Express application
    ├── package.json                               # 📦 Node.js dependencies
    ├── package-lock.json                          # 🔒 Locked dependency versions
    ├── node_modules/                              # 📚 70 installed packages
    │
    ├── public/                                    # 🌐 Static web files
    │   ├── index.html                             # 🏠 Home page
    │   ├── class.html                             # 📋 Class page template
    │   └── styles.css                             # 🎨 Shared styles
    │
    ├── README.md                                  # 📖 Full documentation
    ├── QUICK_START.md                             # ⚡ Quick reference
    ├── IMPLEMENTATION_SUMMARY.md                  # 📝 Implementation details
    ├── FILE_OVERVIEW.md                           # 📄 This file
    └── test-server.sh                             # 🧪 Test script
```

## Files by Purpose

### Core Server Files

**server.js** (10,807 bytes)
- Express application setup
- Route definitions
- Middleware configuration
- File I/O operations
- API endpoints
- Static file serving

**package.json** (413 bytes)
- Project metadata
- Dependencies: express, cors
- Scripts: start, dev

### Web Interface Files

**public/index.html** (2,680 bytes)
- Home page
- Lists all available classes
- Server information display
- Loads classes dynamically via API

**public/class.html** (4,559 bytes)
- Class-specific page
- Shows quizzes, guides, saved answers
- Breadcrumb navigation
- Dynamic content loading

**public/styles.css** (4,983 bytes)
- Shared CSS styles
- Matches quiz aesthetic (navy, burgundy, gold)
- Responsive design
- Card layouts, buttons, lists

### Documentation Files

**README.md** (6,424 bytes)
- Complete user documentation
- Installation instructions
- Usage guide
- API reference
- Troubleshooting
- Network setup instructions

**QUICK_START.md** (968 bytes)
- Essential commands only
- Current IP address
- Quick reference guide
- Minimal instructions for daily use

**IMPLEMENTATION_SUMMARY.md** (8,000+ bytes)
- Technical implementation details
- Architecture overview
- Testing results
- Feature checklist
- Success criteria verification

**FILE_OVERVIEW.md** (This file)
- Visual file structure
- File descriptions
- Size information
- Purpose of each file

### Testing & Utilities

**test-server.sh** (2,000+ bytes)
- Automated test script
- Checks all endpoints
- Verifies functionality
- Reports server status
- Displays access URLs

### Modified Existing Files

**Government/Quiz/am_gov_quiz.html**
- Updated: `saveAnswers()` function
- Now: POSTs to server API
- Fallback: Downloads locally if server unavailable
- Preserved: All existing functionality

## File Sizes Summary

| File | Size | Purpose |
|------|------|---------|
| server.js | 10.8 KB | Main application logic |
| README.md | 6.4 KB | Documentation |
| styles.css | 5.0 KB | Styling |
| class.html | 4.6 KB | Class page template |
| index.html | 2.7 KB | Home page |
| test-server.sh | 2.4 KB | Testing script |
| QUICK_START.md | 1.0 KB | Quick reference |
| package.json | 413 B | Dependencies |

**Total new code**: ~35 KB (excluding node_modules)
**Dependencies**: 70 packages (~20 MB)

## Key Technologies

### Backend
- **Node.js**: JavaScript runtime
- **Express**: Web framework
- **CORS**: Cross-origin resource sharing
- **fs/path**: File system operations

### Frontend
- **Vanilla JavaScript**: No framework needed
- **Fetch API**: For AJAX requests
- **HTML5**: Semantic markup
- **CSS3**: Modern styling, flexbox, grid

### Storage
- **File system**: Plain text files
- **No database**: Simple and sufficient

## Endpoints Implemented

### Pages (HTML)
```
GET  /                                 → index.html
GET  /class/:className                 → class.html
```

### API (JSON)
```
GET  /api/classes                      → List all classes
GET  /api/class/:className             → Class details (quizzes, guides, answers)
POST /api/answers/:className           → Save quiz answers
GET  /api/answers/:className/:file     → View saved answer
```

### Files (Direct serving)
```
GET  /quiz/:className/:file            → Serve quiz HTML
GET  /guide/:className/:file           → Serve study guide
```

## Data Flow

### Taking a Quiz
1. User navigates to home page (index.html)
2. JavaScript fetches /api/classes
3. User clicks class → loads class.html
4. JavaScript fetches /api/class/Government
5. User clicks quiz → loads am_gov_quiz.html
6. User fills out quiz
7. User clicks "Save Answers"
8. JavaScript POSTs to /api/answers/Government
9. Server saves to Government/Answers/
10. Server responds with success + filename
11. User sees success message

### Viewing Saved Answers
1. User on class page (class.html)
2. JavaScript fetches /api/class/Government
3. savedAnswers array shown in UI
4. User clicks answer file
5. Browser opens /api/answers/Government/{file}
6. Server reads file and returns content
7. Browser displays text file

## Development Workflow

### First Time Setup
```bash
cd /Users/chadc/dev/GitRepo/Exam-Prep/Server
npm install
```

### Daily Use
```bash
cd /Users/chadc/dev/GitRepo/Exam-Prep/Server
npm start
```

### Testing
```bash
# Terminal 1: Start server
npm start

# Terminal 2: Run tests
./test-server.sh
```

### Adding New Class
```bash
cd /Users/chadc/dev/GitRepo/Exam-Prep
mkdir -p NewClassName/Quiz
mkdir -p NewClassName/Guide
mkdir -p NewClassName/Answers

# Add quiz HTML files to NewClassName/Quiz/
# Add study materials to NewClassName/Guide/
# Restart server (or it auto-detects on next request)
```

## Important Paths

| Description | Path |
|-------------|------|
| Project root | `/Users/chadc/dev/GitRepo/Exam-Prep` |
| Server root | `/Users/chadc/dev/GitRepo/Exam-Prep/Server` |
| Government class | `/Users/chadc/dev/GitRepo/Exam-Prep/Government` |
| Saved answers | `/Users/chadc/dev/GitRepo/Exam-Prep/Government/Answers` |
| Quiz files | `/Users/chadc/dev/GitRepo/Exam-Prep/Government/Quiz` |
| Study guides | `/Users/chadc/dev/GitRepo/Exam-Prep/Government/Guide` |

## Network Information

**Current Setup:**
- Server port: 3000
- Binding: 0.0.0.0 (all interfaces)
- Mac IP: 192.168.7.238
- Local URL: http://localhost:3000
- Network URL: http://192.168.7.238:3000

**Access from:**
- Mac: http://localhost:3000
- iPad: http://192.168.7.238:3000
- Other devices: http://192.168.7.238:3000

## Lines of Code

Approximate counts (excluding node_modules):

```
JavaScript (server.js):          ~270 lines
JavaScript (HTML files):         ~150 lines
HTML (3 files):                  ~200 lines
CSS (styles.css):                ~250 lines
Markdown (docs):                 ~600 lines
Shell (test script):             ~80 lines
──────────────────────────────────────────
Total:                           ~1,550 lines
```

## What's NOT Included

The following were considered but not implemented (not needed for current use case):

- Database (SQLite, MongoDB, etc.)
- User authentication
- Session management
- HTTPS/SSL certificates
- Rate limiting
- Input validation/sanitization
- File upload functionality
- Real-time updates (WebSockets)
- Progressive Web App features
- Service workers/offline mode
- Backend testing framework
- Containerization (Docker)
- Deployment configuration
- CI/CD pipeline

## Maintenance Notes

**Regular tasks:**
- None! Just start the server when needed

**Occasional tasks:**
- Update Node.js dependencies: `npm update`
- Clean up old saved answers if desired

**IP Address changes:**
- If Mac IP changes, use `ipconfig getifaddr en0` to find new IP
- Update iPad bookmark if needed

**Adding more quizzes:**
- Just copy HTML files to appropriate Quiz/ directory
- Server will automatically detect them

## Success Indicators

✅ Server starts in < 1 second
✅ All endpoints return 200 OK
✅ Quiz JavaScript works correctly
✅ Save creates files with correct naming
✅ All tests pass
✅ Accessible from local network
✅ Print button works on iOS
✅ No errors in server console
✅ Documentation complete
