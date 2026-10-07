#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
CRON_FILE="/etc/cron.d/devops-projectfirst-healthcheck"

if [ "${1:-}" = "--dry-run" ]; then
    cat <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/5 * * * * root ( /bin/bash "$SCRIPT_DIR/server_health_check.sh"; /bin/bash "$SCRIPT_DIR/alert_on_failure.sh" ) >> "$LOG_DIR/cron_health.log" 2>&1
EOF
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "This installer must be run with sudo privileges."
    exit 1
fi

mkdir -p "$LOG_DIR"
chmod 750 "$LOG_DIR"

CRON_TMP=$(mktemp "$CRON_FILE.XXXXXX")
trap 'rm -f "$CRON_TMP"' EXIT

cat > "$CRON_TMP" <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/5 * * * * root ( /bin/bash "$SCRIPT_DIR/server_health_check.sh"; /bin/bash "$SCRIPT_DIR/alert_on_failure.sh" ) >> "$LOG_DIR/cron_health.log" 2>&1
EOF

install -m 0644 "$CRON_TMP" "$CRON_FILE"
rm -f "$CRON_TMP"
trap - EXIT

if command -v systemctl >/dev/null 2>&1; then
    systemctl reload cron 2>/dev/null || true
    systemctl restart cron 2>/dev/null || true
elif command -v service >/dev/null 2>&1; then
    service cron reload 2>/dev/null || true
    service cron restart 2>/dev/null || true
fi

echo "Cron monitoring installed successfully."
echo "The script will run every 5 minutes."
echo "Log file: $LOG_DIR/cron_health.log"
