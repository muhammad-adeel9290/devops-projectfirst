#!/bin/bash
###############################################################################
# Script Name : server_health_check.sh
# Description : Automatically checks Disk, Memory, CPU load and SSH service
#               health on a Linux server. Prints OK/WARNING for each metric,
#               shows an overall status, and logs every run.
# Author      : Muhammad Adeel
# Usage       : ./server_health_check.sh
###############################################################################

# ---------- Configuration (thresholds) ----------
DISK_THRESHOLD=80          # percent
MEMORY_THRESHOLD=80        # percent

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"
LOG_FILE="$LOG_DIR/health_check.log"

mkdir -p "$LOG_DIR"

# ---------- Helper: print to screen AND append to log file ----------
report() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Track overall health (0 = healthy, 1 = warning found)
OVERALL_STATUS=0

# ---------- 1. Disk Usage Monitoring ----------
# df -h / -> root partition usage
# awk grabs the "Use%" column (5th column), tr removes the % sign
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
    DISK_STATUS="WARNING"
    OVERALL_STATUS=1
else
    DISK_STATUS="OK"
fi

# ---------- 2. Memory Monitoring ----------
# free -m -> memory in MB, "Mem:" row has total (col 2) and used (col 3)
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_USAGE=$(( MEM_USED * 100 / MEM_TOTAL ))

if [ "$MEM_USAGE" -ge "$MEMORY_THRESHOLD" ]; then
    MEM_STATUS="WARNING"
    OVERALL_STATUS=1
else
    MEM_STATUS="OK"
fi

# ---------- 3. CPU Monitoring ----------
# uptime shows "load average: 1min, 5min, 15min"
# We use the 1-minute load and compare against number of CPU cores.
CPU_LOAD=$(awk '{print $1}' /proc/loadavg)
CPU_CORES=$(nproc)

# awk handles the float comparison since bash can't compare decimals directly
CPU_HIGH=$(awk -v load_avg="$CPU_LOAD" -v cores="$CPU_CORES" 'BEGIN { print (load_avg >= cores) ? 1 : 0 }')

if [ "$CPU_HIGH" -eq 1 ]; then
    CPU_STATUS="WARNING"
    OVERALL_STATUS=1
else
    CPU_STATUS="OK"
fi

# ---------- 4. SSH Service Monitoring ----------
# Different distros name it "ssh" or "sshd" - check both
if [ "${CI:-false}" = "true" ]; then
    SSH_STATUS="SKIPPED (CI)"
    SSH_STATE="SKIPPED"
elif systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
    SSH_STATUS="OK"
    SSH_STATE="RUNNING"
else
    SSH_STATUS="WARNING"
    SSH_STATE="NOT RUNNING"
    OVERALL_STATUS=1
fi

# ---------- 5. Final Report ----------
if [ "$OVERALL_STATUS" -eq 0 ]; then
    OVERALL_TEXT="HEALTHY"
else
    OVERALL_TEXT="NEEDS ATTENTION"
fi

report "================================"
report "SERVER HEALTH CHECK - $(date '+%Y-%m-%d %H:%M:%S')"
report "================================"
report ""
report "Disk Usage: ${DISK_USAGE}%     [${DISK_STATUS}]"
report "Memory Usage: ${MEM_USAGE}%   [${MEM_STATUS}]"
report "CPU Load: ${CPU_LOAD} (Cores: ${CPU_CORES})   [${CPU_STATUS}]"
report "SSH Service:         [${SSH_STATE}]"
report ""
report "Overall Status: ${OVERALL_TEXT}"
report "================================"
report ""

# ---------- 6. Exit Status ----------
# 0 = everything normal, non-zero = warning/problem found
exit $OVERALL_STATUS
