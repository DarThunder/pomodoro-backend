#!/bin/bash

BASE_URL="http://localhost:8080"
USER="tester_$(date +%s)"
PASS="password123"
COOKIE_FILE="cookies.txt"

echo "=== STARTING ENDPOINT TEST ON: $BASE_URL ==="
echo "Temporary User: $USER"

echo -e "\n1. [POST] Registering user..."
curl -s -X POST "$BASE_URL/api/auth/register" \
     -H "Content-Type: application/json" \
     -d "{\"username\": \"$USER\", \"email\": \"$USER@test.com\", \"password\": \"$PASS\"}"

echo -e "\n\n2. [POST] Logging in..."
curl -s -c $COOKIE_FILE -X POST "$BASE_URL/api/auth/login" \
     -H "Content-Type: application/json" \
     -d "{\"username\": \"$USER\", \"password\": \"$PASS\"}"

echo -e "\n\n3. [POST] Creating Pomodoro session..."
RESPONSE=$(curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros" \
     -H "Content-Type: application/json" \
     -d '{"taskName": "Benchmark Task", "durationMinutes": 25}')

echo "Response: $RESPONSE"

SESSION_ID=$(echo $RESPONSE | jq -r '.id')
USER_ID=$(echo $RESPONSE | jq -r '.userId')

if [ "$SESSION_ID" == "null" ]; then
    echo "Error: Could not retrieve Session ID. Aborting."
    exit 1
fi

echo ">> Captured Session ID: $SESSION_ID"
echo ">> Captured User ID: $USER_ID"

echo -e "\n4. [POST] Starting timer ($SESSION_ID)..."
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$SESSION_ID/start" | jq -r '.status'

echo -e "\n5. [GET] Querying remaining time..."
curl -s -b $COOKIE_FILE -X GET "$BASE_URL/api/pomodoros/$SESSION_ID/sync"

sleep 1

echo -e "\n\n6. [POST] Pausing timer..."
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$SESSION_ID/pause" | jq -r '.status'

echo -e "\n7. [POST] Stopping session..."
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$SESSION_ID/stop" | jq -r '.status'

echo -e "\n8. [GET] Listing all sessions..."
curl -s -b $COOKIE_FILE -X GET "$BASE_URL/api/pomodoros" | jq '. | length'

echo -e "\n9. [GET] User statistics ($USER_ID)..."
curl -s -b $COOKIE_FILE -X GET "$BASE_URL/api/pomodoros/stats/$USER_ID" | jq .

echo -e "\n10. [POST] Logging out..."
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/auth/logout"

rm $COOKIE_FILE
echo -e "\n\n=== TEST COMPLETE ==="