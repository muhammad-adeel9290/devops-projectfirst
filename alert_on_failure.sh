#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/health_check.log"
ALERT_FILE="$SCRIPT_DIR/logs/alert_history.log"

mkdir -p "$SCRIPT_DIR/logs"

if [ ! -f "$LOG_FILE" ]; then
    echo "No health log found at $LOG_FILE" >&2
    exit 1
fi

LAST_REPORT=$(tail -n 20 "$LOG_FILE")

if echo "$LAST_REPORT" | grep -q "Overall Status: NEEDS ATTENTION"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: Server health check failed." | tee -a "$ALERT_FILE"
    echo "$LAST_REPORT" >> "$ALERT_FILE"
    echo "----------------------------------------" >> "$ALERT_FILE"
    echo "Alert logged to $ALERT_FILE"
    exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Server health is healthy. No alert needed." | tee -a "$ALERT_FILE"
exit 0
