#!/bin/bash
###############################################################################
# Script Name : server_health_check.sh
# Description : Automatically checks disk, memory, CPU load, and SSH service
#               health on a Linux server. Prints OK/WARNING for each metric,
#               shows an overall status, and logs every run.
# Author      : Muhammad Adeel
# Usage       : ./server_health_check.sh
###############################################################################

# ---------- Configuration (thresholds) ----------
DISK_THRESHOLD=80          # percent
MEMORY_THRESHOLD=80        # percent

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/health_check.log"

mkdir -p "$LOG_DIR"

# ---------- Helper: print to screen AND append to log file ----------
report() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Track overall health (0 = healthy, 1 = warning found)
OVERALL_STATUS=0

# ---------- 1. Disk Usage Monitoring ----------
# Use the last numeric usage field, which remains stable even when the filesystem path contains spaces.
DISK_USAGE=$(df -P / 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $(NF-1)); print $(NF-1)}')

if [ -n "$DISK_USAGE" ] && [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
    DISK_STATUS="WARNING"
    OVERALL_STATUS=1
else
    DISK_STATUS="OK"
fi

# ---------- 2. Memory Monitoring ----------
# Prefer /proc/meminfo because `free` is not always installed on minimal Linux/Git Bash systems.
if [ -f /proc/meminfo ]; then
    MEM_TOTAL_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)

    if awk '/MemAvailable/ { exit 0 } END { exit 1 }' /proc/meminfo >/dev/null 2>&1; then
        MEM_AVAILABLE_KB=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    else
        MEM_AVAILABLE_KB=$(awk '/MemFree/ {print $2}' /proc/meminfo)
    fi

    if [ -n "$MEM_TOTAL_KB" ] && [ "$MEM_TOTAL_KB" -gt 0 ]; then
        MEM_USED_KB=$(( MEM_TOTAL_KB - MEM_AVAILABLE_KB ))
        MEM_USAGE=$(( MEM_USED_KB * 100 / MEM_TOTAL_KB ))
    else
        MEM_USAGE=0
    fi
else
    MEM_USAGE=0
fi

if [ "$MEM_USAGE" -ge "$MEMORY_THRESHOLD" ]; then
    MEM_STATUS="WARNING"
    OVERALL_STATUS=1
else
    MEM_STATUS="OK"
fi

# ---------- 3. CPU Monitoring ----------
# uptime shows "load average: 1min, 5min, 15min"
# We use the 1-minute load and compare against the number of CPU cores.
CPU_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
CPU_CORES=$(nproc 2>/dev/null)

if [ -n "$CPU_LOAD" ] && [ -n "$CPU_CORES" ] && [ "$CPU_CORES" -gt 0 ]; then
    CPU_HIGH=$(awk -v load_avg="$CPU_LOAD" -v cores="$CPU_CORES" 'BEGIN { print (load_avg >= cores) ? 1 : 0 }')
else
    CPU_HIGH=0
    CPU_LOAD="N/A"
    CPU_CORES="N/A"
fi

if [ "$CPU_HIGH" -eq 1 ]; then
    CPU_STATUS="WARNING"
    OVERALL_STATUS=1
else
    CPU_STATUS="OK"
fi

# ---------- 4. SSH Service Monitoring ----------
# Different distros name it "ssh" or "sshd" - check both.
if [ "${CI:-false}" = "true" ]; then
    SSH_STATUS="SKIPPED (CI)"
    SSH_STATE="SKIPPED"
elif command -v systemctl >/dev/null 2>&1 && (systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null); then
    SSH_STATUS="OK"
    SSH_STATE="RUNNING"
elif command -v service >/dev/null 2>&1 && (service ssh status >/dev/null 2>&1 || service sshd status >/dev/null 2>&1); then
    SSH_STATUS="OK"
    SSH_STATE="RUNNING"
elif [ -f /etc/init.d/ssh ] && /etc/init.d/ssh status >/dev/null 2>&1; then
    SSH_STATUS="OK"
    SSH_STATE="RUNNING"
elif [ -f /etc/init.d/sshd ] && /etc/init.d/sshd status >/dev/null 2>&1; then
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
report "Disk Usage: ${DISK_USAGE:-0}%     [${DISK_STATUS}]"
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
