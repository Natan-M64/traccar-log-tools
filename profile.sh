export LOG_FILE="${LOG_FILE:-/opt/traccar/logs/tracker-server.log}"
export LOG_DIR="${LOG_DIR:-/opt/traccar/logs}"

alias logs='tail -f "$LOG_FILE"'
alias follow='tail -F "$LOG_FILE"'
alias errors='grep -iE "error|exception|failed|timeout|warn" "$LOG_FILE" | tail -100'
alias warnings='grep -iE "warn|warning" "$LOG_FILE" | tail -100'
alias today='grep "$(date +%Y-%m-%d)" "$LOG_FILE" | tail -200'
alias gzerrors='zgrep -iE "error|exception|failed|timeout|warn" "$LOG_DIR"/*.gz 2>/dev/null | tail -100'
alias listlogs='ls -lah "$LOG_DIR"'
alias ll='ls -lah'
alias help='log-help'
alias loghelp='log-help'

echo "================================================="
echo "              Traccar Log Tools"
echo "================================================="
echo "Main log: $LOG_FILE"
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
