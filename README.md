# DevOps Project 1

<div align="center">
  <img src="https://img.shields.io/badge/DevOps-Server%20Monitoring-blue" alt="DevOps" />
  <img src="https://img.shields.io/badge/Linux-Automation-green" alt="Linux" />
  <img src="https://img.shields.io/badge/Docker-Containerized-orange" alt="Docker" />
  <img src="https://img.shields.io/badge/GitHub-Actions-black" alt="GitHub Actions" />
</div>

A practical DevOps project focused on Linux server health monitoring, automation, and Docker-based deployment workflows.

## Overview

This project demonstrates a real-world DevOps workflow by combining system monitoring, automation, and CI/CD. It includes a Bash-based health check script that monitors key Linux server metrics such as:

- Disk usage
- Memory consumption
- CPU load
- SSH service status

The repository also includes:

- a cron-based scheduler for automatic monitoring
- a GitHub Actions workflow that runs the health check
- Docker support for packaging and publishing the project image

## Why This Project?

This project is designed to teach and demonstrate essential DevOps fundamentals:

- Infrastructure monitoring
- Automated checks and alerts
- Cron-based scheduling
- GitHub Actions automation
- Docker image creation and publishing

## Features

- Monitors disk usage and memory health
- Checks CPU load against available cores
- Verifies whether SSH is active
- Logs health reports for troubleshooting
- Supports scheduled execution with cron
- Integrates with GitHub Actions for CI/CD automation
- Builds and pushes a Docker image to Docker Hub

## Tech Stack

- Linux / Ubuntu
- Bash scripting
- Cron jobs
- Git & GitHub
- GitHub Actions
- Docker

## Project Structure

```text
.
├── .github/
│   └── workflows/
│       └── main.yml
├── .gitignore
├── Dockerfile
├── README.md
├── logs/
├── server_health_check.sh
├── setup_cron_monitoring.sh
``` 

## Prerequisites

Before using this project, make sure the following are available on your system:

- Linux-based environment
- Bash shell
- Standard Linux utilities such as `df`, `awk`, `nproc`, and `systemctl`
- Cron service (for scheduled jobs)
- Docker (optional for local image build testing)

## Local Setup and Usage

### 1. Make the script executable

```bash
chmod +x server_health_check.sh
```

### 2. Run the health check manually

```bash
./server_health_check.sh
```

### 3. View the generated log

```bash
cat logs/health_check.log
```

## Automated Monitoring with Cron

A helper script is included to schedule the health check every 5 minutes.

```bash
chmod +x setup_cron_monitoring.sh
sudo ./setup_cron_monitoring.sh
```

This installs a cron job that appends monitoring output to:

```bash
logs/cron_health.log
```

To preview the cron entry without installing it:

```bash
./setup_cron_monitoring.sh --dry-run
```

## Alerting on Failure

A small helper script is included to notify when the latest health check found a problem.

```bash
chmod +x alert_on_failure.sh
./alert_on_failure.sh
```

This checks the latest entries in `logs/health_check.log` and writes alert details to:

```bash
logs/alert_history.log
```

The alert script is useful when you want a lightweight monitoring workflow without using external notification services.

## GitHub Actions Workflow

The workflow in `.github/workflows/main.yml` performs the following actions:

1. Checks out the project code
2. Runs the health-check script
3. Logs in to Docker Hub using GitHub secrets
4. Builds the Docker image
5. Pushes the image to Docker Hub

The image tag used is:

```text
adeel74954/devops-projectfirst:latest
```

## Docker Image

The Docker image is created from the repository's `Dockerfile` and is based on Ubuntu 24.04.

## Example Output

```text
================================
SERVER HEALTH CHECK - 2026-10-07 13:35:34
================================

Disk Usage: 96%     [WARNING]
Memory Usage: 92%   [WARNING]
CPU Load: 1.13 (Cores: 4)   [OK]
SSH Service:         [NOT RUNNING]

Overall Status: NEEDS ATTENTION
================================
```

## How It Works

The server health script checks each system metric and marks it as either `OK` or `WARNING`.

- If everything is within thresholds, the overall status is `HEALTHY`
- If one or more monitored metrics exceed the threshold, the script marks the server as `NEEDS ATTENTION`
- The script exits with a non-zero status in warning scenarios, which is useful for automation and CI checks

## Notes

- This project is meant for learning and demonstration purposes.
- It can be extended to support email alerts, Slack notifications, or full monitoring dashboards.
- Logs are stored in the `logs/` folder to help trace performance issues over time.

## Future Improvements

Planned enhancements for this project include:

- Email or Slack notifications on server issues
- systemd service support for Linux servers
- Dynamic thresholds based on environment type
- Prometheus/Grafana integration
- More advanced deployment automation

## License

This project is for educational and learning purposes.

## Author

Muhammad Adeel
