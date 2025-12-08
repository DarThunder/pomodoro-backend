#!/bin/bash

BASE_URL="http://localhost:8080"
ATTACKER="hacker_$(date +%s)"
PASS="123456"
COOKIE_FILE="cookies_hacker.txt"

echo "=== INICIANDO PROTOCOLO DE CAOS: $ATTACKER ==="

# ---------------------------------------------------------
# NIVEL 1: SEGURIDAD Y AUTENTICACIÓN
# ---------------------------------------------------------
echo -e "\n[TEST 1] Intento de acceso sin token (Debe dar 401/403)..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/pomodoros")
if [ "$STATUS" == "403" ] || [ "$STATUS" == "401" ]; then
    echo "BLOQUEADO (Código $STATUS)"
else
    echo "FALLO DE SEGURIDAD: Código $STATUS"
fi

echo -e "\n[TEST 2] Login con contraseña incorrecta..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/auth/login" \
     -H "Content-Type: application/json" \
     -d "{\"username\": \"admin\", \"password\": \"WRONG_PASS\"}")
if [ "$STATUS" == "401" ]; then
    echo "DENEGADO (Código $STATUS)"
else
    echo "ERROR: Se permitió acceso o error interno (Código $STATUS)"
fi

# Registro legítimo para continuar los ataques
echo -e "\n... Creando usuario atacante para siguientes pruebas..."
curl -s -X POST "$BASE_URL/api/auth/register" \
     -H "Content-Type: application/json" \
     -d "{\"username\": \"$ATTACKER\", \"email\": \"hack@test.com\", \"password\": \"$PASS\"}" > /dev/null

curl -s -c $COOKIE_FILE -X POST "$BASE_URL/api/auth/login" \
     -H "Content-Type: application/json" \
     -d "{\"username\": \"$ATTACKER\", \"password\": \"$PASS\"}" > /dev/null

# ---------------------------------------------------------
# NIVEL 2: VALIDACIÓN DE DATOS (INPUT FUZZING)
# ---------------------------------------------------------
echo -e "\n[TEST 3] Enviar duración negativa (Debe dar 400)..."
RESPONSE=$(curl -s -b $COOKIE_FILE -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/api/pomodoros" \
     -H "Content-Type: application/json" \
     -d '{"taskName": "Crash Task", "durationMinutes": -5}')
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)

if [ "$HTTP_CODE" == "400" ]; then
    echo "VALIDACIÓN OK (Rechazado por @Min)"
else
    echo "FALLO: El servidor aceptó tiempo negativo o crasheó ($HTTP_CODE)"
fi

echo -e "\n[TEST 4] Enviar JSON corrupto/vacío (Debe dar 400)..."
STATUS=$(curl -s -b $COOKIE_FILE -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/pomodoros" \
     -H "Content-Type: application/json" \
     -d '{"invalid_field": "test"}')
if [ "$STATUS" == "400" ]; then
    echo "MANEJO DE ERROR OK (Bad Request)"
else
    echo "FALLO: Servidor confundido ($STATUS)"
fi

# ---------------------------------------------------------
# NIVEL 3: LÓGICA DE ESTADO (STATE MACHINE)
# ---------------------------------------------------------
echo -e "\n[TEST 5] Intentar pausar una sesión inexistente (Debe dar 400/404)..."
RESPONSE=$(curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/ID_FALSO_123/pause")
if [[ $RESPONSE == *"Session not found"* ]] || [[ $RESPONSE == *"status"* ]]; then
    echo "ERROR CONTROLADO: $RESPONSE"
else
    echo "RESPUESTA INESPERADA"
fi

# Crear sesión válida para machacarla
SESSION_RES=$(curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros" \
     -H "Content-Type: application/json" \
     -d '{"taskName": "Stress Task", "durationMinutes": 10}')
ID=$(echo $SESSION_RES | jq -r '.id')

echo -e "\n[TEST 6] Spamear botones (Start -> Pause -> Stop -> Start) en milisegundos..."
# Esto prueba condiciones de carrera y la robustez de la DB
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$ID/start" > /dev/null &
PID1=$!
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$ID/pause" > /dev/null &
PID2=$!
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/pomodoros/$ID/stop" > /dev/null &
PID3=$!

wait $PID1 $PID2 $PID3
echo "Spam enviado. Verificando estado final..."
FINAL_STATUS=$(curl -s -b $COOKIE_FILE -X GET "$BASE_URL/api/pomodoros" | jq -r ".[] | select(.id==\"$ID\") | .status")
echo "Estado resultante: $FINAL_STATUS (Debería ser consistente, ej. TERMINATED o IN_PROGRESS)"

# ---------------------------------------------------------
# NIVEL 4: CARGA (MILD LOAD TESTING)
# ---------------------------------------------------------
echo -e "\n[TEST 7] La 'Ametralladora': Creando 20 sesiones en ráfaga..."
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

echo "$SUCCESS_COUNT/20 sesiones creadas en ${DURATION}ms"
if [ $SUCCESS_COUNT -eq 20 ]; then
    echo "SERVIDOR AGUANTÓ LA RÁFAGA"
else
    echo "ALGUNAS PETICIONES FALLARON"
fi

# Limpieza
curl -s -b $COOKIE_FILE -X POST "$BASE_URL/api/auth/logout" > /dev/null
rm $COOKIE_FILE
echo -e "\n=== FIN DEL REPORTE DE DAÑOS ==="
