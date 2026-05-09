#!/bin/sh
set -eu

LOG_FILE="${LOG_FILE:-/opt/traccar/logs/tracker-server.log}"

echo "[INFO] Traccar Log Tools started"
echo "[INFO] LOG_FILE=${LOG_FILE}"

while [ ! -f "$LOG_FILE" ]; do
  echo "[INFO] Waiting for log file: $LOG_FILE"
  sleep 5
done

echo "[INFO] Following log with tail -F"
exec tail -F "$LOG_FILE"
