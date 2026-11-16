#!/usr/bin/env bash

# CampusHub MSE-2 Grader
# Run from project root: bash ./grade.sh

DC="${DC:-docker compose}"
ENV_FILE="${ENV_FILE:-.env}"

set -a
source "$ENV_FILE"
set +a

BASE="http://localhost:${GATEWAY_PORT:-8083}"

PASS=0
FAIL=0

check() {
    if eval "$2" >/dev/null 2>&1; then
        echo "PASS  $1"
        PASS=$((PASS + 1))
    else
        echo "FAIL  $1"
        FAIL=$((FAIL + 1))
    fi
}

echo "Starting CampusHub validation..."
echo

# Stop containers without deleting persistent volumes
$DC down >/dev/null 2>&1

# Build and start services
check "compose up --build --wait (all healthy)" 
    "$DC up -d --build --wait --wait-timeout 300"

# Verify container count
check "exactly 9 containers running" 
    "[ \"\$($DC ps -q | wc -l)\" -eq 9 ]"

# API health
check "health endpoint through gateway" 
    "curl -fs $BASE/api/health"

# Frontend
check "frontend served at / through gateway" 
    "curl -fs $BASE/ | grep -qi '<div id=\"root\">'"

# Database seed
check "events list (Postgres seed)" 
    "curl -fs $BASE/api/events | grep -q 'Hack Night'"

# Redis cache
check "Redis cache: second call is a HIT" 
    "curl -fs -o /dev/null $BASE/api/events && curl -fsI $BASE/api/events | grep -qi 'x-cache: HIT'"

# Registration
check "register accepted (202)" 
    "[ \"\$(curl -s -o /dev/null -w '%{http_code}' -X POST $BASE/api/events/1/register -H 'Content-Type: application/json' -d '{\"name\":\"Asha\",\"email\":\"asha@example.com\"}')\" = 202 ]"

sleep 5

# RabbitMQ queue
check "RabbitMQ queue exists" 
    "curl -fs -u $RABBITMQ_USER:$RABBITMQ_PASS http://127.0.0.1:15672/api/queues | grep -q registration_emails"

# Worker email
check "worker delivered email to MailHog" 
    "curl -fs http://127.0.0.1:8025/api/v2/messages | grep -q 'asha@example.com'"

# MinIO upload
printf 'fake-image-bytes' > /tmp/ch-test.png

URL=$(curl -fs -X POST "$BASE/api/events/1/image" 
    -F "image=@/tmp/ch-test.png;type=image/png" |
    sed -E 's/.*"url":"([^"]+)".*/\1/')

check "upload stored in MinIO, served at /storage" 
    "curl -fs $BASE$URL | grep -q fake-image-bytes"

# Persistence test
$DC down >/dev/null 2>&1
$DC up -d --wait --wait-timeout 300 >/dev/null 2>&1

check "Postgres data survives down/up" 
    "curl -fs $BASE/api/events | grep -Eq '\"registrations\":[1-9]'"

# Non-root checks
for s in api worker frontend gateway; do
    check "$s runs as non-root" 
        "[ \"\$($DC exec -T $s id -u)\" != 0 ]"
done

# Public port check
check "only one port published on all interfaces" 
    "[ \"\$(docker ps --format '{{.Ports}}' | grep -o '0.0.0.0:[0-9]*' | sort -u | wc -l)\" -eq 1 ]"

# API image size
API_IMG=$($DC images api -q 2>/dev/null | head -1)

check "api image under 250 MB" 
    "[ \"\$(docker image inspect $API_IMG --format '{{.Size}}')\" -lt 262144000 ]"

# Secrets check
check "no secrets hardcoded in compose file" 
    "! $DC config --no-interpolate 2>/dev/null | grep -Eiq '(PASSWORD|PASS|SECRET_KEY|ACCESS_KEY): [^\$]'"

echo
echo "================================"
echo "Score: $PASS passed, $FAIL failed"
echo "================================"