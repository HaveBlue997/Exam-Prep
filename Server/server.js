const express = require('express');
const cors = require('cors');
const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;

// Project root is one level up from Server directory
const PROJECT_ROOT = path.join(__dirname, '..');

// Grading jobs directory
const GRADING_JOBS_DIR = path.join(__dirname, 'grading-jobs');

// In-memory job store (for quick status checks)
const gradingJobs = new Map();

// Middleware
app.use(cors()); // Enable CORS for local network access
app.use(express.json({ limit: '10mb' })); // Parse JSON bodies (with larger limit for essay answers)
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

// Logging middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});

// ============================================================================
// HOME PAGE - List all classes
// ============================================================================
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ============================================================================
// API: Get list of available classes
// ============================================================================
app.get('/api/classes', async (req, res) => {
    try {
        const items = await fs.readdir(PROJECT_ROOT, { withFileTypes: true });
        const classes = items
            .filter(item => item.isDirectory() && !item.name.startsWith('.') && item.name !== 'Server' && item.name !== 'prompts' && item.name !== 'Example_Class')
            .map(item => ({
                name: item.name,
                path: `/class/${item.name}`
            }));

        res.json({ classes });
    } catch (error) {
        console.error('Error reading classes:', error);
        res.status(500).json({ error: 'Failed to read classes' });
    }
});

// ============================================================================
// CLASS PAGE - Show quizzes and guides for a specific class
// ============================================================================
app.get('/class/:className', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'class.html'));
});

// ============================================================================
// API: Get class information (quizzes, guides, saved answers)
// ============================================================================
app.get('/api/class/:className', async (req, res) => {
    const { className } = req.params;
    const classPath = path.join(PROJECT_ROOT, className);

    try {
        // Check if class directory exists
        const exists = await fs.access(classPath).then(() => true).catch(() => false);
        if (!exists) {
            return res.status(404).json({ error: 'Class not found' });
        }

        // Get quizzes
        const quizPath = path.join(classPath, 'Quiz');
        let quizzes = [];
        try {
            const quizFiles = await fs.readdir(quizPath);
            quizzes = quizFiles
                .filter(file => file.endsWith('.html'))
                .map(file => ({
                    name: file.replace('.html', '').replace(/_/g, ' '),
                    filename: file,
                    url: `/quiz/${className}/${file}`
                }));
        } catch (error) {
            console.log(`No quizzes found for ${className}`);
        }

        // Get guides
        const guidePath = path.join(classPath, 'Guide');
        let guides = [];
        try {
            const guideFiles = await fs.readdir(guidePath);
            guides = guideFiles
                .filter(file => !file.startsWith('.'))
                .map(file => ({
                    name: file,
                    filename: file,
                    url: `/guide/${className}/${file}`
                }));
        } catch (error) {
            console.log(`No guides found for ${className}`);
        }

        // Get saved answers (with stats)
        const answersPath = path.join(classPath, 'Answers');
        let savedAnswers = [];
        try {
            const answerFiles = await fs.readdir(answersPath);
            savedAnswers = await Promise.all(
                answerFiles
                    .filter(file => file.endsWith('.txt') && !file.startsWith('.'))
                    .map(async file => {
                        const filePath = path.join(answersPath, file);
                        const stats = await fs.stat(filePath);
                        return {
                            name: file,
                            filename: file,
                            url: `/api/answers/${className}/${file}`,
                            date: stats.mtime,
                            size: stats.size
                        };
                    })
            );
            // Sort by date, most recent first
            savedAnswers.sort((a, b) => b.date - a.date);
        } catch (error) {
            console.log(`No saved answers found for ${className}`);
        }

        res.json({
            className,
            quizzes,
            guides,
            savedAnswers
        });
    } catch (error) {
        console.error('Error getting class info:', error);
        res.status(500).json({ error: 'Failed to get class information' });
    }
});

// ============================================================================
// SERVE QUIZ HTML FILES
// ============================================================================
app.get('/quiz/:className/:quizFile', async (req, res) => {
    const { className, quizFile } = req.params;
    const quizPath = path.join(PROJECT_ROOT, className, 'Quiz', quizFile);

    try {
        const exists = await fs.access(quizPath).then(() => true).catch(() => false);
        if (!exists) {
            return res.status(404).send('Quiz not found');
        }

        res.sendFile(quizPath);
    } catch (error) {
        console.error('Error serving quiz:', error);
        res.status(500).send('Failed to load quiz');
    }
});

// ============================================================================
// SAVE QUIZ ANSWERS AND TRIGGER GRADING
// ============================================================================
app.post('/api/answers/:className', async (req, res) => {
    const { className } = req.params;
    const { name, date, timestamp, answers, quizName } = req.body;

    if (!name || !answers) {
        return res.status(400).json({ error: 'Missing required fields: name and answers' });
    }

    try {
        // Create Answers directory if it doesn't exist
        const answersPath = path.join(PROJECT_ROOT, className, 'Answers');
        await fs.mkdir(answersPath, { recursive: true });

        // Generate filename with student name and timestamp
        const safeName = (quizName || 'Quiz').replace(/[^a-zA-Z0-9]/g, '_');
        const safeStudentName = name.replace(/\s+/g, '_').replace(/[^a-zA-Z0-9_]/g, '');
        const timestampStr = timestamp || new Date().toISOString().replace(/[:.]/g, '-').replace('T', '_').split('.')[0];
        const filename = `${safeName}_${safeStudentName}_${timestampStr}.txt`;
        const filePath = path.join(answersPath, filename);

        // Write answers to file
        await fs.writeFile(filePath, answers, 'utf8');

        console.log(`Saved answers to: ${filePath}`);

        // Generate a unique job ID for grading
        const jobId = crypto.randomBytes(8).toString('hex');

        // Initialize job status
        gradingJobs.set(jobId, {
            status: 'processing',
            className,
            studentName: name,
            quizName: safeName,
            answersFile: filename,
            startTime: new Date().toISOString(),
            resultsUrl: null
        });

        // Create job status file
        const jobStatusPath = path.join(GRADING_JOBS_DIR, `${jobId}.status`);
        await fs.writeFile(jobStatusPath, 'processing', 'utf8');

        // Trigger async grading
        triggerGrading(jobId, className, filePath, safeName, safeStudentName, timestampStr);

        res.json({
            success: true,
            message: 'Answers saved successfully. Grading started.',
            filename,
            path: `/api/answers/${className}/${filename}`,
            jobId,
            statusUrl: `/api/grading-status/${jobId}`
        });
    } catch (error) {
        console.error('Error saving answers:', error);
        res.status(500).json({ error: 'Failed to save answers' });
    }
});

// ============================================================================
// TRIGGER GRADING (ASYNC)
// ============================================================================
async function triggerGrading(jobId, className, answersFilePath, quizName, studentName, timestamp) {
    console.log(`[${jobId}] Starting grading for ${className}...`);

    try {
        const gradeScript = path.join(__dirname, 'grade-quiz.sh');

        // Spawn the grading script
        const gradeProcess = spawn('bash', [gradeScript, className, answersFilePath, jobId], {
            cwd: PROJECT_ROOT,
            env: {
                ...process.env,
                PROJECT_ROOT,
                QUIZ_NAME: quizName,
                STUDENT_NAME: studentName,
                TIMESTAMP: timestamp
            }
        });

        let stdout = '';
        let stderr = '';

        gradeProcess.stdout.on('data', (data) => {
            stdout += data.toString();
            console.log(`[${jobId}] stdout: ${data}`);
        });

        gradeProcess.stderr.on('data', (data) => {
            stderr += data.toString();
            console.error(`[${jobId}] stderr: ${data}`);
        });

        gradeProcess.on('close', async (code) => {
            console.log(`[${jobId}] Grade script exited with code ${code}`);

            const job = gradingJobs.get(jobId);
            if (job) {
                if (code === 0) {
                    // Check for results file
                    const resultsFilename = `${quizName}_${studentName}_${timestamp}_results.html`;
                    const resultsUrl = `/results/${className}/${resultsFilename}`;

                    job.status = 'complete';
                    job.resultsUrl = resultsUrl;
                    job.endTime = new Date().toISOString();

                    // Update status file
                    const jobStatusPath = path.join(GRADING_JOBS_DIR, `${jobId}.status`);
                    await fs.writeFile(jobStatusPath, JSON.stringify({
                        status: 'complete',
                        resultsUrl
                    }), 'utf8');
                } else {
                    job.status = 'error';
                    job.error = stderr || 'Grading failed';
                    job.endTime = new Date().toISOString();

                    // Update status file
                    const jobStatusPath = path.join(GRADING_JOBS_DIR, `${jobId}.status`);
                    await fs.writeFile(jobStatusPath, JSON.stringify({
                        status: 'error',
                        error: job.error
                    }), 'utf8');
                }
            }
        });

        gradeProcess.on('error', async (err) => {
            console.error(`[${jobId}] Failed to start grading process:`, err);
            const job = gradingJobs.get(jobId);
            if (job) {
                job.status = 'error';
                job.error = err.message;

                const jobStatusPath = path.join(GRADING_JOBS_DIR, `${jobId}.status`);
                await fs.writeFile(jobStatusPath, JSON.stringify({
                    status: 'error',
                    error: err.message
                }), 'utf8');
            }
        });

    } catch (error) {
        console.error(`[${jobId}] Error triggering grading:`, error);
        const job = gradingJobs.get(jobId);
        if (job) {
            job.status = 'error';
            job.error = error.message;
        }
    }
}

// ============================================================================
// GET GRADING STATUS
// ============================================================================
app.get('/api/grading-status/:jobId', async (req, res) => {
    const { jobId } = req.params;

    // First check in-memory store
    const job = gradingJobs.get(jobId);
    if (job) {
        return res.json({
            status: job.status,
            resultsUrl: job.resultsUrl || null,
            error: job.error || null
        });
    }

    // Fallback: check status file
    try {
        const jobStatusPath = path.join(GRADING_JOBS_DIR, `${jobId}.status`);
        const statusContent = await fs.readFile(jobStatusPath, 'utf8');

        // Try to parse as JSON
        try {
            const statusData = JSON.parse(statusContent);
            return res.json(statusData);
        } catch {
            // Simple text status
            return res.json({ status: statusContent.trim() });
        }
    } catch (error) {
        return res.status(404).json({ error: 'Job not found' });
    }
});

// ============================================================================
// SERVE GRADED RESULTS FROM ARCHIVE
// ============================================================================
app.get('/results/:className/:filename', async (req, res) => {
    const { className, filename } = req.params;
    const resultsPath = path.join(PROJECT_ROOT, className, 'Archive', filename);

    try {
        const exists = await fs.access(resultsPath).then(() => true).catch(() => false);
        if (!exists) {
            return res.status(404).send('Results not found');
        }

        res.type('text/html').sendFile(resultsPath);
    } catch (error) {
        console.error('Error serving results:', error);
        res.status(500).send('Failed to load results');
    }
});

// ============================================================================
// VIEW SAVED ANSWER FILE
// ============================================================================
app.get('/api/answers/:className/:filename', async (req, res) => {
    const { className, filename } = req.params;
    const filePath = path.join(PROJECT_ROOT, className, 'Answers', filename);

    try {
        const content = await fs.readFile(filePath, 'utf8');
        res.type('text/plain').send(content);
    } catch (error) {
        console.error('Error reading answer file:', error);
        res.status(404).send('Answer file not found');
    }
});

// ============================================================================
// SERVE STUDY GUIDE FILES
// ============================================================================
app.get('/guide/:className/:filename', async (req, res) => {
    const { className, filename } = req.params;
    const guidePath = path.join(PROJECT_ROOT, className, 'Guide', filename);

    try {
        const exists = await fs.access(guidePath).then(() => true).catch(() => false);
        if (!exists) {
            return res.status(404).send('Guide not found');
        }

        // Set appropriate content type based on file extension
        const ext = path.extname(filename).toLowerCase();
        const contentTypes = {
            '.pdf': 'application/pdf',
            '.doc': 'application/msword',
            '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            '.txt': 'text/plain',
            '.png': 'image/png',
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.gif': 'image/gif'
        };

        if (contentTypes[ext]) {
            res.type(contentTypes[ext]);
        }

        res.sendFile(guidePath);
    } catch (error) {
        console.error('Error serving guide:', error);
        res.status(500).send('Failed to load guide');
    }
});

// ============================================================================
// ERROR HANDLING
// ============================================================================
app.use((req, res) => {
    res.status(404).send('Page not found');
});

app.use((error, req, res, next) => {
    console.error('Server error:', error);
    res.status(500).send('Internal server error');
});

// ============================================================================
// START SERVER
// ============================================================================
app.listen(PORT, '0.0.0.0', () => {
    console.log('='.repeat(60));
    console.log('Exam Prep Server Started');
    console.log('='.repeat(60));
    console.log(`Local:            http://localhost:${PORT}`);
    console.log(`Network:          http://<YOUR-IP>:${PORT}`);
    console.log('');
    console.log('To find your IP address:');
    console.log('  Mac:    System Settings > Network > Wi-Fi > Details');
    console.log('  Or run: ipconfig getifaddr en0');
    console.log('');
    console.log('Access from iPad: http://<YOUR-MAC-IP>:3000');
    console.log('='.repeat(60));
});
