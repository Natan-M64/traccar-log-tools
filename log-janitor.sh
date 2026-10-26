#!/bin/sh
set -eu

LOG_DIR="${LOG_DIR:-/opt/traccar/logs}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-15}"
LOG_CLEAN_INTERVAL="${LOG_CLEAN_INTERVAL:-86400}"
LOG_GZIP_LEVEL="${LOG_GZIP_LEVEL:-9}"

case "$LOG_RETENTION_DAYS" in ''|*[!0-9]*) echo "Invalid LOG_RETENTION_DAYS" >&2; exit 1;; esac
case "$LOG_CLEAN_INTERVAL" in ''|*[!0-9]*) echo "Invalid LOG_CLEAN_INTERVAL" >&2; exit 1;; esac
case "$LOG_GZIP_LEVEL" in [1-9]) ;; *) echo "Invalid LOG_GZIP_LEVEL" >&2; exit 1;; esac
if [ "$LOG_CLEAN_INTERVAL" -eq 0 ]; then
  echo "LOG_CLEAN_INTERVAL must be positive" >&2
  exit 1
fi
if [ ! -d "$LOG_DIR" ]; then
  echo "Log directory does not exist: $LOG_DIR" >&2
  exit 1
fi

probe="$LOG_DIR/.log-janitor-write-check-$$"
if ! ( umask 077; : > "$probe" ) 2>/dev/null; then
  echo "Log directory is not writable: $LOG_DIR" >&2
  exit 1
fi
rm -f "$probe"

if [ "${1:-}" = "--check" ]; then
  exit 0
fi

echo "[INFO] Log janitor started: dir=$LOG_DIR retention=${LOG_RETENTION_DAYS}d interval=${LOG_CLEAN_INTERVAL}s"
while :; do
  echo "[INFO] Cleaning rotated logs in $LOG_DIR"
  find "$LOG_DIR" -maxdepth 1 -type f -name 'tracker-server.log.[0-9]*' ! -name '*.gz' -mmin +30 -size +1024k -exec gzip "-$LOG_GZIP_LEVEL" -f {} \; || echo "[WARN] Log compression cycle failed" >&2
  find "$LOG_DIR" -maxdepth 1 -type f -name 'tracker-server.log.[0-9]*.gz' -mtime "+$LOG_RETENTION_DAYS" -exec rm -f {} \; || echo "[WARN] Log retention cycle failed" >&2
  find "$LOG_DIR" -maxdepth 1 -type f -name 'tracker-server.log.[0-9]*' ! -name '*.gz' -mtime "+$LOG_RETENTION_DAYS" -exec rm -f {} \; || echo "[WARN] Uncompressed log retention cycle failed" >&2
  sleep "$LOG_CLEAN_INTERVAL"
done
