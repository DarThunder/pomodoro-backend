#!/bin/bash

# CONFIGURACIÓN
# Cambia esto a tu URL de Render/Railway cuando despliegues (ej. https://tu-app.onrender.com)
BASE_URL="http://localhost:8080"
USER="tester_$(date +%s)" # Usuario único cada vez
PASS="password123"
COOKIE_FILE="cookies.txt"

echo "=== INICIANDO TEST DE ENDPOINTS EN: $BASE_URL ==="
echo "Usuario temporal: $USER"

# 1. REGISTER
echo -e "\n1. [POST] Registrando usuario..."
curl -s -X POST "$BASE_URL/api/auth/register" \
     -H "Content-Type: application/json" \
     -d "{\"username\": \"$USER\", \"email\": \"$USER@test.com\", \"password\": \"$PASS\"}"

# 2. LOGIN (Guardamos la cookie)
echo -e "\n\n2. [POST] Iniciando sesión..."
curl -s -c $COOKIE_FILE -X POST "$BASE_URL/api/auth/login" \
     -H "Content-Type: application/json" \
     -d "{\"username\": \"$USER\", \"password\": \"$PASS\"}"

# 3. CREATE SESSION
echo -e "\n\n3. [POST] Creando sesión de Pomodoro..."
RESPONSE=$(curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros" \
     -H "Content-Type: application/json" \
     -d '{"taskName": "Benchmark Task", "durationMinutes": 25}')

echo "Respuesta: $RESPONSE"

# Extraemos IDs usando jq (Asegúrate de tener jq instalado)
SESSION_ID=$(echo $RESPONSE | jq -r '.id')
USER_ID=$(echo $RESPONSE | jq -r '.userId')

if [ "$SESSION_ID" == "null" ]; then
    echo "Error: No se pudo obtener ID de sesión. Abortando."
    exit 1
fi

echo ">> Session ID capturado: $SESSION_ID"
echo ">> User ID capturado: $USER_ID"

# 4. START TIMER
echo -e "\n4. [POST] Iniciando timer ($SESSION_ID)..."
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$SESSION_ID/start" | jq -r '.status'

# 5. SYNC (Ver tiempo)
echo -e "\n5. [GET] Consultando tiempo restante..."
curl -s -b $COOKIE_FILE -X GET "$BASE_URL/api/pomodoros/$SESSION_ID/sync"

# Simular espera
sleep 1

# 6. PAUSE
echo -e "\n\n6. [POST] Pausando timer..."
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$SESSION_ID/pause" | jq -r '.status'

# 7. STOP
echo -e "\n7. [POST] Deteniendo sesión..."
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$SESSION_ID/stop" | jq -r '.status'

# 8. GET ALL SESSIONS
echo -e "\n8. [GET] Listando todas las sesiones..."
curl -s -b $COOKIE_FILE -X GET "$BASE_URL/api/pomodoros" | jq '. | length'

# 9. GET USER STATS
echo -e "\n9. [GET] Estadísticas del usuario ($USER_ID)..."
curl -s -b $COOKIE_FILE -X GET "$BASE_URL/api/pomodoros/stats/$USER_ID" | jq .

# 10. LOGOUT
echo -e "\n10. [POST] Cerrando sesión..."
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/auth/logout"

# Limpieza
rm $COOKIE_FILE
echo -e "\n\n=== TEST COMPLETADO ==="
