# Linux Server Health Monitoring Script

A Bash automation script that checks the health of a Linux server — Disk,
Memory, CPU load, and SSH service — and reports **OK / WARNING** for each,
along with an overall health status. Every run is logged automatically.

## 📌 Project Statement

**Project Name:** Linux Server Health Monitoring Script

**Scenario:**
A DevOps engineer needs a Bash script that automatically checks the health of
a Linux server instead of manually checking different system resources one
by one.

**The script performs:**

1. **Disk Usage Monitoring** — checks root (`/`) disk usage.
   - `< 80%` → `OK`
   - `>= 80%` → `WARNING`
2. **Memory Monitoring** — calculates RAM usage percentage.
   - `< 80%` → `OK`
   - `>= 80%` → `WARNING`
3. **CPU Monitoring** — checks current 1-minute load average against number
   of CPU cores.
   - High load → `WARNING`
   - Normal load → `OK`
4. **SSH Service Monitoring** — checks whether the SSH service is running.
   - Running → `OK`
   - Not running → `WARNING`
5. **Final Report** — prints a complete summary at the end, including an
   overall status (`HEALTHY` / `NEEDS ATTENTION`).
6. **Logging** — every check result is appended to `logs/health_check.log`.
7. **Exit Status** — `0` if everything is normal, non-zero if any warning was
   found (useful for cron jobs, alerting, or CI/CD pipelines).

## 📁 Project Structure

```text
linux-server-automation/
│
├── scripts/
│   └── server_health_check.sh
│
├── logs/
│   └── health_check.log   (auto-generated / appended on every run)
│
└── README.md
```

## 🚀 Usage

```bash
chmod +x scripts/server_health_check.sh
./scripts/server_health_check.sh
```

### Sample Output

```text
================================
SERVER HEALTH CHECK - 2026-08-10 14:58:08
================================

Disk Usage: 45%     [OK]
Memory Usage: 62%   [OK]
CPU Load: 1.2 (Cores: 4)   [OK]
SSH Service:         [RUNNING]

Overall Status: HEALTHY
================================
```

## ⚙️ Configuration

Thresholds are set at the top of the script and can be changed easily:

```bash
DISK_THRESHOLD=80      # percent
MEMORY_THRESHOLD=80    # percent
```

CPU load is considered high when the 1-minute load average is **greater than
or equal to** the number of CPU cores (`nproc`).

## ⏰ Automating with Cron

Run the health check automatically every hour:

```bash
crontab -e
```

Add:

```text
0 * * * * /path/to/linux-server-automation/scripts/server_health_check.sh
```

## 🛠️ Commands Used

| Command      | Purpose                          |
|--------------|-----------------------------------|
| `df`         | Disk usage                        |
| `free`       | Memory (RAM) usage                 |
| `uptime`     | CPU load average                   |
| `nproc`      | Number of CPU cores                 |
| `systemctl`  | Check SSH service status            |
| `awk`        | Parse and calculate values           |

## 🎯 Objective

Create a Bash-based Linux server monitoring script that automatically checks
disk, memory, CPU, and SSH service health, reports warnings when thresholds
are exceeded, and records every result in a log file.

## 📄 License

Free to use for learning and personal projects.
