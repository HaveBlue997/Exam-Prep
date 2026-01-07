#!/bin/bash

# Test script for Exam Prep Server
# Run this after starting the server with 'npm start'

echo "=========================================="
echo "Testing Exam Prep Server"
echo "=========================================="
echo ""

# Check if server is running
echo "1. Checking if server is running on port 3000..."
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo "   ✓ Server is running"
else
    echo "   ✗ Server is not running"
    echo "   Please start the server with: npm start"
    exit 1
fi
echo ""

# Test home page
echo "2. Testing home page..."
if curl -s http://localhost:3000/ | grep -q "Exam Preparation" ; then
    echo "   ✓ Home page loads"
else
    echo "   ✗ Home page failed"
fi
echo ""

# Test API: Get classes
echo "3. Testing API: Get classes..."
CLASSES=$(curl -s http://localhost:3000/api/classes)
if echo "$CLASSES" | grep -q "Government" ; then
    echo "   ✓ Classes API works"
    echo "   Response: $CLASSES"
else
    echo "   ✗ Classes API failed"
fi
echo ""

# Test API: Get class info
echo "4. Testing API: Get Government class info..."
CLASS_INFO=$(curl -s http://localhost:3000/api/class/Government)
if echo "$CLASS_INFO" | grep -q "am_gov_quiz.html" ; then
    echo "   ✓ Class info API works"
else
    echo "   ✗ Class info API failed"
fi
echo ""

# Test quiz serving
echo "5. Testing quiz file serving..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/quiz/Government/am_gov_quiz.html)
if [ "$STATUS" = "200" ]; then
    echo "   ✓ Quiz serves correctly (HTTP $STATUS)"
else
    echo "   ✗ Quiz serving failed (HTTP $STATUS)"
fi
echo ""

# Test save functionality
echo "6. Testing save answers API..."
SAVE_RESULT=$(curl -s -X POST http://localhost:3000/api/answers/Government \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Student",
    "date": "2025-01-05",
    "answers": "Test answers content",
    "quizName": "Test_Quiz"
  }')

if echo "$SAVE_RESULT" | grep -q "success" ; then
    echo "   ✓ Save API works"
    FILENAME=$(echo "$SAVE_RESULT" | grep -o 'Test_Quiz[^"]*\.txt')
    echo "   Saved file: $FILENAME"
else
    echo "   ✗ Save API failed"
fi
echo ""

# Test guide serving
echo "7. Testing study guide serving..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/guide/Government/AMERICAN%20GOVERNMENT%20-%20MIDTERM%20INFO.txt")
if [ "$STATUS" = "200" ]; then
    echo "   ✓ Guide serves correctly (HTTP $STATUS)"
else
    echo "   ✗ Guide serving failed (HTTP $STATUS)"
fi
echo ""

# Get server info
echo "=========================================="
echo "Server Information"
echo "=========================================="
echo "Local URL:   http://localhost:3000"
IP=$(ipconfig getifaddr en0 2>/dev/null || echo "Not available")
echo "Network URL: http://$IP:3000"
echo ""
echo "Access from iPad: http://$IP:3000"
echo "=========================================="
echo ""
echo "All tests completed!"
