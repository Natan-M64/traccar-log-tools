#!/bin/sh
set -eu

LOG_FILE="${LOG_FILE:-/opt/traccar/logs/tracker-server.log}"
LOG_MODE="${LOG_MODE:-${MODE:-tail}}"
TAIL_LINES="${TAIL_LINES:-200}"

echo "[INFO] Traccar Log Tools started"
echo "[INFO] LOG_MODE=${LOG_MODE}"
echo "[INFO] LOG_FILE=${LOG_FILE}"
echo "[INFO] TAIL_LINES=${TAIL_LINES}"

while [ ! -f "$LOG_FILE" ]; do
  echo "[INFO] Waiting for log file: $LOG_FILE"
  sleep 5
done

if [ "$LOG_MODE" = "api" ]; then
  echo "[INFO] Starting HTTP API"
  exec /api_server.py
fi

echo "[INFO] Following log with tail -F"
exec tail -n "$TAIL_LINES" -F "$LOG_FILE"
