#!/bin/bash
# Start Exam Prep server with remote access via ngrok

echo "Starting Exam Prep Server with Remote Access..."
echo ""

# Kill any existing ngrok
pkill -f ngrok 2>/dev/null

# Start the Express server if not already running
if ! curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "Starting Express server..."
    cd "$(dirname "$0")/Server"
    npm start &
    sleep 3
fi

# Start ngrok
echo "Starting ngrok tunnel..."
ngrok http 3000 --log=stdout > /tmp/ngrok.log 2>&1 &
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
echo "  Local access:  http://localhost:3000"
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
echo "Press Ctrl+C to stop the server."
echo ""

# Keep script running and show ngrok status
wait
