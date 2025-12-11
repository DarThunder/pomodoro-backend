#!/bin/bash

BASE_URL="http://localhost:8080"
ATTACKER="hacker_$(date +%s)"
PASS="123456"
COOKIE_FILE="cookies_hacker.txt"

echo "=== STARTING CHAOS PROTOCOL: $ATTACKER ==="

echo -e "\n[TEST 1] Tokenless access attempt (Should return 401/403)..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/pomodoros")
if [ "$STATUS" == "403" ] || [ "$STATUS" == "401" ]; then
    echo "BLOCKED (Code $STATUS)"
else
    echo "SECURITY FAILURE: Code $STATUS"
fi

echo -e "\n[TEST 2] Login with incorrect password..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/auth/login" \
     -H "Content-Type: application/json" \
     -d "{\"username\": \"admin\", \"password\": \"WRONG_PASS\"}")
if [ "$STATUS" == "401" ]; then
    echo "DENIED (Code $STATUS)"
else
    echo "ERROR: Access allowed or internal error (Code $STATUS)"
fi

echo -e "\n... Creating attacker user for subsequent tests..."
curl -s -X POST "$BASE_URL/api/auth/register" \
     -H "Content-Type: application/json" \
     -d "{\"username\": \"$ATTACKER\", \"email\": \"hack@test.com\", \"password\": \"$PASS\"}" > /dev/null

curl -s -c $COOKIE_FILE -X POST "$BASE_URL/api/auth/login" \
     -H "Content-Type: application/json" \
     -d "{\"username\": \"$ATTACKER\", \"password\": \"$PASS\"}" > /dev/null

echo -e "\n[TEST 3] Send negative duration (Should return 400)..."
RESPONSE=$(curl -s -b $COOKIE_FILE -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/api/pomodoros" \
     -H "Content-Type: application/json" \
     -d '{"taskName": "Crash Task", "durationMinutes": -5}')
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)

if [ "$HTTP_CODE" == "400" ]; then
    echo "VALIDATION OK (Rejected by @Min)"
else
    echo "FAILURE: Server accepted negative time or crashed ($HTTP_CODE)"
fi

echo -e "\n[TEST 4] Send corrupt/empty JSON (Should return 400)..."
STATUS=$(curl -s -b $COOKIE_FILE -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/pomodoros" \
     -H "Content-Type: application/json" \
     -d '{"invalid_field": "test"}')
if [ "$STATUS" == "400" ]; then
    echo "ERROR HANDLING OK (Bad Request)"
else
    echo "FAILURE: Server confused ($STATUS)"
fi

echo -e "\n[TEST 5] Attempt to pause a non-existent session (Should return 400/404)..."
RESPONSE=$(curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/FAKE_ID_123/pause")
if [[ $RESPONSE == *"Session not found"* ]] || [[ $RESPONSE == *"status"* ]]; then
    echo "CONTROLLED ERROR: $RESPONSE"
else
    echo "UNEXPECTED RESPONSE"
fi

SESSION_RES=$(curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros" \
     -H "Content-Type: application/json" \
     -d '{"taskName": "Stress Task", "durationMinutes": 10}')
ID=$(echo $SESSION_RES | jq -r '.id')

echo -e "\n[TEST 6] Spam buttons (Start -> Pause -> Stop -> Start) in milliseconds..."
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$ID/start" > /dev/null &
PID1=$!
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$ID/pause" > /dev/null &
PID2=$!
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$ID/stop" > /dev/null &
PID3=$!

wait $PID1 $PID2 $PID3
echo "Spam sent. Verifying final status..."
FINAL_STATUS=$(curl -s -b $COOKIE_FILE -X GET "$BASE_URL/api/pomodoros" | jq -r ".[] | select(.id==\"$ID\") | .status")
echo "Resulting status: $FINAL_STATUS (Should be consistent, e.g., TERMINATED or IN_PROGRESS)"

echo -e "\n[TEST 7] The 'Machine Gun': Creating 20 sessions in a burst..."
START_TIME=$(date +%s%N)
SUCCESS_COUNT=0
for i in {1..20}; do
   CODE=$(curl -s -b $COOKIE_FILE -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/pomodoros" \
     -H "Content-Type: application/json" \
     -d "{\"taskName\": \"Load Task $i\", \"durationMinutes\": 1}")
   if [ "$CODE" == "200" ]; then
     SUCCESS_COUNT=$((SUCCESS_COUNT+1))
   fi
done
END_TIME=$(date +%s%N)
DURATION=$((($END_TIME - $START_TIME)/1000000))

echo "$SUCCESS_COUNT/20 sessions created in ${DURATION}ms"
if [ $SUCCESS_COUNT -eq 20 ]; then
    echo "SERVER WITHSTOOD THE BURST"
else
    echo "SOME REQUESTS FAILED"
fi

curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/auth/logout" > /dev/null
rm $COOKIE_FILE
echo -e "\n=== END OF DAMAGE REPORT ==="