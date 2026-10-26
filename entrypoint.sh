#!/bin/bash
set -eu

viewer_pid=""
janitor_pid=""
cleanup() {
  [ -z "$viewer_pid" ] || kill "$viewer_pid" 2>/dev/null || :
  [ -z "$janitor_pid" ] || kill "$janitor_pid" 2>/dev/null || :
  [ -z "$viewer_pid" ] || wait "$viewer_pid" 2>/dev/null || :
  [ -z "$janitor_pid" ] || wait "$janitor_pid" 2>/dev/null || :
}
trap cleanup EXIT
trap 'exit 0' TERM INT

LOG_FILE="${LOG_FILE:-/opt/traccar/logs/tracker-server.log}"
LOG_MODE="${LOG_MODE:-${MODE:-tail}}"
TAIL_LINES="${TAIL_LINES:-200}"
LOG_JANITOR="${LOG_JANITOR:-false}"

echo "[INFO] Traccar Log Tools started"
echo "[INFO] LOG_MODE=${LOG_MODE}"
echo "[INFO] LOG_FILE=${LOG_FILE}"
echo "[INFO] TAIL_LINES=${TAIL_LINES}"

case "$LOG_MODE" in
  tail|api) ;;
  *) echo "Invalid LOG_MODE: $LOG_MODE" >&2; exit 1 ;;
esac
case "$LOG_JANITOR" in
  true|false) ;;
  *) echo "Invalid LOG_JANITOR: $LOG_JANITOR" >&2; exit 1 ;;
esac

while [ ! -f "$LOG_FILE" ]; do
  echo "[INFO] Waiting for log file: $LOG_FILE"
  sleep 5
done

if [ "$LOG_JANITOR" = "true" ]; then
  /usr/local/bin/log-janitor --check
fi

if [ "$LOG_MODE" = "api" ]; then
  if [ "$LOG_JANITOR" = "false" ]; then
    exec /api_server.py
  fi
  /api_server.py &
else
  if [ "$LOG_JANITOR" = "false" ]; then
    exec tail -n "$TAIL_LINES" -F "$LOG_FILE"
  fi
  tail -n "$TAIL_LINES" -F "$LOG_FILE" &
fi
viewer_pid=$!
/usr/local/bin/log-janitor &
janitor_pid=$!
wait -n "$viewer_pid" "$janitor_pid"
