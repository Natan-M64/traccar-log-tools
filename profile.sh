clear

export LOG_FILE="${LOG_FILE:-/opt/traccar/logs/tracker-server.log}"
export LOG_DIR="${LOG_DIR:-/opt/traccar/logs}"
export TAIL_LINES="${TAIL_LINES:-200}"

alias logs='tail -n "$TAIL_LINES" -f "$LOG_FILE"'
alias follow='tail -n "$TAIL_LINES" -F "$LOG_FILE"'
alias errors='grep -iE "error|exception|failed|timeout|warn" "$LOG_FILE" | tail -n 100'
alias warnings='grep -iE "warn|warning" "$LOG_FILE" | tail -n 100'
alias today='grep "$(date +%Y-%m-%d)" "$LOG_FILE" | tail -n "$TAIL_LINES"'
alias gzerrors='zgrep -iE "error|exception|failed|timeout|warn" "$LOG_DIR"/*.gz 2>/dev/null | tail -n 100'
alias listlogs='ls -lah "$LOG_DIR"'
alias ll='ls -lah'
alias help='log-help'
alias loghelp='log-help'

echo "================================================="
echo "              Traccar Log Tools"
echo "================================================="
echo "Main log: $LOG_FILE"
echo "Tail lines: $TAIL_LINES"
echo ""
echo "Aliases:"
echo "  logs | follow | errors | warnings | today | gzerrors | listlogs"
echo ""
echo "Run:"
echo "  log-help"
echo ""
echo "to show full examples."
echo "================================================="
echo ""
