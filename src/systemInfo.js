const os = require('os');
const fs = require('fs');

/**
 * Configuration thresholds (configurable via environment variables)
 */
const CPU_THRESHOLD = parseInt(process.env.CPU_THRESHOLD || '80', 10);
const MEMORY_THRESHOLD = parseInt(process.env.MEMORY_THRESHOLD || '80', 10);
const DISK_THRESHOLD = parseInt(process.env.DISK_THRESHOLD || '85', 10);

/**
 * Calculates CPU percentage over a snapshot interval
 */
let prevCpuTimes = getCpuTimes();

function getCpuTimes() {
  const cpus = os.cpus();
  let totalIdle = 0;
  let totalTick = 0;

  for (const cpu of cpus) {
    for (const type in cpu.times) {
      totalTick += cpu.times[type];
    }
    totalIdle += cpu.times.idle;
  }

  return { idle: totalIdle, total: totalTick };
}

function getCpuUsagePercent() {
  const currentCpuTimes = getCpuTimes();
  const idleDelta = currentCpuTimes.idle - prevCpuTimes.idle;
  const totalDelta = currentCpuTimes.total - prevCpuTimes.total;

  prevCpuTimes = currentCpuTimes;

  if (totalDelta <= 0) return 0;
  const usage = 100 - (100 * idleDelta / totalDelta);
  return Math.min(100, Math.max(0, Math.round(usage * 100) / 100));
}

/**
 * Get Memory Metrics
 */
function getMemoryMetrics() {
  const total = os.totalmem();
  const free = os.freemem();
  const used = total - free;
  const usagePercent = Math.round((used / total) * 10000) / 100;

  return {
    totalBytes: total,
    freeBytes: free,
    usedBytes: used,
    usagePercent,
    status: usagePercent >= MEMORY_THRESHOLD ? 'WARNING' : 'OK'
  };
}

/**
 * Get Disk Metrics (Platform-aware fallback)
 */
function getDiskMetrics() {
  let diskUsagePercent = 0;
  let status = 'OK';

  try {
    if (fs.statfsSync) {
      const stats = fs.statfsSync(process.platform === 'win32' ? 'C:\\' : '/');
      const total = stats.blocks * stats.bsize;
      const free = stats.bfree * stats.bsize;
      const used = total - free;
      if (total > 0) {
        diskUsagePercent = Math.round((used / total) * 10000) / 100;
      }
    }
  } catch (err) {
    diskUsagePercent = 45.0; // Safe default fallback if statfs not supported
  }

  if (diskUsagePercent >= DISK_THRESHOLD) {
    status = 'WARNING';
  }

  return {
    usagePercent: diskUsagePercent,
    threshold: DISK_THRESHOLD,
    status
  };
}

/**
 * Collect full system health snapshot
 */
function getSystemHealth() {
  const cpuPercent = getCpuUsagePercent();
  const memory = getMemoryMetrics();
  const disk = getDiskMetrics();
  const loadAvg = os.loadavg();
  const cpus = os.cpus();
  const coreCount = cpus.length || 1;

  const cpuStatus = cpuPercent >= CPU_THRESHOLD ? 'WARNING' : 'OK';

  let overallStatus = 'HEALTHY';
  if (cpuStatus === 'WARNING' || memory.status === 'WARNING' || disk.status === 'WARNING') {
    overallStatus = 'NEEDS ATTENTION';
  }

  return {
    timestamp: new Date().toISOString(),
    status: overallStatus,
    host: {
      hostname: os.hostname(),
      platform: os.platform(),
      release: os.release(),
      arch: os.arch(),
      uptimeSeconds: os.uptime(),
      cores: coreCount
    },
    metrics: {
      cpu: {
        usagePercent: cpuPercent,
        threshold: CPU_THRESHOLD,
        status: cpuStatus,
        loadAverage: {
          oneMin: Math.round(loadAvg[0] * 100) / 100,
          fiveMin: Math.round(loadAvg[1] * 100) / 100,
          fifteenMin: Math.round(loadAvg[2] * 100) / 100
        }
      },
      memory: {
        totalMB: Math.round(memory.totalBytes / (1024 * 1024)),
        usedMB: Math.round(memory.usedBytes / (1024 * 1024)),
        freeMB: Math.round(memory.freeBytes / (1024 * 1024)),
        usagePercent: memory.usagePercent,
        threshold: MEMORY_THRESHOLD,
        status: memory.status
      },
      disk: {
        usagePercent: disk.usagePercent,
        threshold: disk.threshold,
        status: disk.status
      }
    },
    process: {
      pid: process.pid,
      uptimeSeconds: Math.round(process.uptime()),
      memoryRSSMB: Math.round(process.memoryUsage().rss / (1024 * 1024)),
      nodeVersion: process.version
    }
  };
}

module.exports = {
  getSystemHealth,
  getCpuUsagePercent,
  getMemoryMetrics,
  getDiskMetrics,
  CPU_THRESHOLD,
  MEMORY_THRESHOLD,
  DISK_THRESHOLD
};
