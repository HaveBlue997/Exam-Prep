#!/bin/bash
# Start Exam Prep server with remote access via ngrok
# Server runs independently - survives ngrok restarts and script exits

echo "Starting Exam Prep Server with Remote Access..."
echo ""

# Kill any existing ngrok (but NOT the exam-prep server)
pkill -f ngrok 2>/dev/null

# Start the Express server if not already running
# Uses nohup and disown so server survives when this script exits
if ! curl -s http://localhost:3001 > /dev/null 2>&1; then
    echo "Starting Express server..."
    cd "$(dirname "$0")/Server"
    # Run node directly (not npm) so process.title takes effect
    # Server will show as 'exam-prep-server' in ps, not 'node' or 'npm'
    nohup node server.js > /tmp/exam-prep-server.log 2>&1 &
    disown
    sleep 3
    echo "Server started (PID: $!)"
    echo "Logs: /tmp/exam-prep-server.log"
else
    echo "Server already running at http://localhost:3001"
fi

# Start ngrok in foreground (so Ctrl+C only kills ngrok, not server)
echo ""
echo "Starting ngrok tunnel..."
sleep 1

# Start ngrok in background briefly to get URL
ngrok http 3001 --log=stdout > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!
sleep 4

# Get and display the URL
PUBLIC_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data.get('tunnels') else '')" 2>/dev/null)

if [ -z "$PUBLIC_URL" ]; then
    PUBLIC_URL=$(curl -s http://localhost:4041/api/tunnels | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data.get('tunnels') else '')" 2>/dev/null)
fi

echo ""
echo "============================================"
echo "  EXAM PREP SERVER IS RUNNING!"
echo "============================================"
echo ""
echo "  Local access:  http://localhost:3001"
echo ""
echo "  PHONE ACCESS:  $PUBLIC_URL"
echo ""
echo "============================================"
echo ""
echo "Share the PHONE ACCESS URL with your student!"
echo ""
echo "Note: First visit on phone will show an ngrok"
echo "warning page - just click 'Visit Site' to continue."
echo ""
echo "Press Ctrl+C to stop ngrok (server keeps running)"
echo "To stop server: pkill -f exam-prep-server"
echo ""

# Wait for ngrok - when it dies (Ctrl+C or error), server keeps running
wait $NGROK_PID 2>/dev/null

echo ""
echo "ngrok stopped. Server still running at http://localhost:3001"
echo "To stop server: pkill -f exam-prep-server"
