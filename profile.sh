clear

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

echo "================================================="
echo "              Traccar Log Tools"
echo "================================================="
echo ""
echo "Main log file:"
echo "  $LOG_FILE"
echo ""
echo "Log directory:"
echo "  $LOG_DIR"
echo ""
echo "Quick aliases:"
echo "  logs      -> follow current log with tail -f"
echo "  follow    -> follow current log with tail -F"
echo "  errors    -> show latest errors/warnings"
echo "  warnings  -> show latest warnings"
echo "  today     -> show latest log lines from today"
echo "  gzerrors  -> search errors in compressed logs"
echo "  listlogs  -> list log files"
echo "  ll        -> ls -lah"
echo ""
echo "Examples:"
echo ""
echo "Search by IMEI:"
echo "  grep \"000000000000000\" \"\$LOG_FILE\" | tail -50"
echo ""
echo "Search by IP address:"
echo "  grep \"0.0.0.0\" \"\$LOG_FILE\" | tail -50"
echo ""
echo "Search by protocol:"
echo "  grep -i \"gt06\" \"\$LOG_FILE\" | tail -100"
echo ""
echo "Search common problems:"
echo "  grep -iE \"error|exception|failed|timeout|warn\" \"\$LOG_FILE\" | tail -100"
echo ""
echo "Search compressed logs:"
echo "  zgrep -i \"000000000000000\" \"\$LOG_DIR\"/*.gz | tail -100"
echo ""
echo "Live follow:"
echo "  tail -F \"\$LOG_FILE\""
echo ""
echo "================================================="
echo ""
