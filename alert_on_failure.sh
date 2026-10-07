#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/health_check.log"
ALERT_FILE="$SCRIPT_DIR/logs/alert_history.log"
STATE_FILE="$SCRIPT_DIR/logs/.alert_state"
ALERT_CONFIG_FILE="${ALERT_CONFIG_FILE:-/etc/devops-projectfirst/alerting.env}"

mkdir -p "$SCRIPT_DIR/logs"

if [ -e "$ALERT_CONFIG_FILE" ]; then
    if [ ! -f "$ALERT_CONFIG_FILE" ] || [ -L "$ALERT_CONFIG_FILE" ]; then
        echo "Alert configuration must be a regular, non-symlink file: $ALERT_CONFIG_FILE" >&2
        exit 1
    fi

    CONFIG_OWNER=$(stat -c '%u' -- "$ALERT_CONFIG_FILE")
    CONFIG_MODE=$(stat -c '%a' -- "$ALERT_CONFIG_FILE")
    if [ "$CONFIG_OWNER" != "0" ] || (( (8#$CONFIG_MODE & 077) != 0 )); then
        echo "Alert configuration must be root-owned and not accessible by group or other users: $ALERT_CONFIG_FILE" >&2
        exit 1
    fi

    # This file is intentionally a shell environment file and must only be editable by trusted administrators.
    . "$ALERT_CONFIG_FILE"
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "No health log found at $LOG_FILE" >&2
    exit 1
fi

LAST_REPORT=$(awk '
    /^SERVER HEALTH CHECK - / {
        report = $0
        found = 1
        next
    }
    found {
        report = report "\n" $0
    }
    END {
        if (found) {
            print report
        }
    }
' "$LOG_FILE")

if [ -z "$LAST_REPORT" ]; then
    echo "No complete health check report found in $LOG_FILE" >&2
    exit 1
fi

if printf '%s\n' "$LAST_REPORT" | grep -Fq "Overall Status: NEEDS ATTENTION"; then
    CURRENT_STATE="unhealthy"
elif printf '%s\n' "$LAST_REPORT" | grep -Fq "Overall Status: HEALTHY"; then
    CURRENT_STATE="healthy"
else
    echo "The latest health check report has no recognized overall status." >&2
    exit 1
fi

PREVIOUS_STATE=""
if [ -f "$STATE_FILE" ]; then
    PREVIOUS_STATE=$(cat "$STATE_FILE")
    case "$PREVIOUS_STATE" in
        healthy|unhealthy) ;;
        *)
            echo "Invalid alert state in $STATE_FILE" >&2
            exit 1
            ;;
    esac
fi

if [ "$CURRENT_STATE" = "$PREVIOUS_STATE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Health state unchanged ($CURRENT_STATE); no alert sent." | tee -a "$ALERT_FILE"
    exit 0
fi

HOST_NAME=$(hostname)
if [ "$CURRENT_STATE" = "unhealthy" ]; then
    SUBJECT="ALERT: Server health needs attention on $HOST_NAME"
    MESSAGE="$SUBJECT

$LAST_REPORT"
else
    SUBJECT="RECOVERY: Server health is healthy on $HOST_NAME"
    MESSAGE="$SUBJECT

The latest server health check is healthy.

$LAST_REPORT"
fi

SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
ALERT_EMAIL_TO="${ALERT_EMAIL_TO:-}"
ALERT_EMAIL_FROM="${ALERT_EMAIL_FROM:-}"
DELIVERY_FAILED=0
NOTIFICATION_CONFIGURED=0

if [ -n "$SLACK_WEBHOOK_URL" ]; then
    NOTIFICATION_CONFIGURED=1
    case "$SLACK_WEBHOOK_URL" in
        https://hooks.slack.com/services/*) ;;
        *)
            echo "SLACK_WEBHOOK_URL must be an HTTPS Slack incoming webhook URL." >&2
            exit 1
            ;;
    esac

    if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        echo "Slack notifications require both curl and jq." >&2
        exit 1
    fi

    SLACK_PAYLOAD=$(jq -n --arg text "$MESSAGE" '{text: $text}')
    CURL_CONFIG=$(jq -n --arg url "$SLACK_WEBHOOK_URL" --arg payload "$SLACK_PAYLOAD" \
        '"url = " + ($url | @json) + "\nheader = \"Content-Type: application/json\"\ndata = " + ($payload | @json)')
    if ! printf '%s' "$CURL_CONFIG" | curl --config - --fail --silent --show-error --max-time 15 \
        --retry 3 --retry-all-errors >/dev/null 2>&1; then
        echo "Slack notification delivery failed; webhook details were suppressed." >&2
        DELIVERY_FAILED=1
    fi
fi

if [ -n "$ALERT_EMAIL_TO" ]; then
    NOTIFICATION_CONFIGURED=1
    case "$ALERT_EMAIL_TO$ALERT_EMAIL_FROM" in
        *[$'\r\n']*)
            echo "Email addresses must not contain line breaks." >&2
            exit 1
            ;;
    esac
    case "$ALERT_EMAIL_TO" in
        -*|*[[:space:]]*)
            echo "ALERT_EMAIL_TO must be a single address and must not start with a dash." >&2
            exit 1
            ;;
    esac

    MAIL_COMMAND=$(command -v mail || command -v mailx || true)
    if [ -z "$MAIL_COMMAND" ]; then
        echo "Email notifications require mail or mailx and a configured local mail transfer agent." >&2
        exit 1
    fi

    if [ -n "$ALERT_EMAIL_FROM" ]; then
        if ! printf '%s\n' "$MESSAGE" | "$MAIL_COMMAND" -r "$ALERT_EMAIL_FROM" -s "$SUBJECT" "$ALERT_EMAIL_TO" >/dev/null 2>&1; then
            echo "Email notification delivery failed." >&2
            DELIVERY_FAILED=1
        fi
    elif ! printf '%s\n' "$MESSAGE" | "$MAIL_COMMAND" -s "$SUBJECT" "$ALERT_EMAIL_TO" >/dev/null 2>&1; then
        echo "Email notification delivery failed." >&2
        DELIVERY_FAILED=1
    fi
fi

if [ "$NOTIFICATION_CONFIGURED" -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: No notification destination configured; recording state change only." | tee -a "$ALERT_FILE"
fi

if [ "$DELIVERY_FAILED" -ne 0 ]; then
    echo "Alert state was not updated; the next monitoring run will retry delivery." >&2
    exit 1
fi

STATE_TMP=$(mktemp "$SCRIPT_DIR/logs/.alert_state.XXXXXX")
trap 'rm -f "$STATE_TMP"' EXIT
chmod 600 "$STATE_TMP"
printf '%s\n' "$CURRENT_STATE" > "$STATE_TMP"
mv -f "$STATE_TMP" "$STATE_FILE"
trap - EXIT

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: Server health state changed to $CURRENT_STATE." | tee -a "$ALERT_FILE"
printf '%s\n' "$MESSAGE" >> "$ALERT_FILE"
echo "----------------------------------------" >> "$ALERT_FILE"
