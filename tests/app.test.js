const test = require('node:test');
const assert = require('node:assert');
const { getSystemHealth, getCpuUsagePercent, getMemoryMetrics, getDiskMetrics } = require('../src/systemInfo');
const app = require('../src/app');

test('System Metrics: returns valid metrics and health structure', () => {
  const health = getSystemHealth();
  assert.ok(health.timestamp, 'timestamp must be present');
  assert.ok(['HEALTHY', 'NEEDS ATTENTION'].includes(health.status), 'status must be valid');
  assert.ok(typeof health.host.hostname === 'string', 'hostname must be string');
  assert.ok(health.host.cores >= 1, 'must have at least 1 core');

  // Metrics validation
  assert.ok(typeof health.metrics.cpu.usagePercent === 'number');
  assert.ok(typeof health.metrics.memory.usagePercent === 'number');
  assert.ok(typeof health.metrics.disk.usagePercent === 'number');

  // Process info
  assert.ok(health.process.pid > 0);
  assert.ok(health.process.uptimeSeconds >= 0);
});

test('CPU Usage: calculates realistic CPU percentage', () => {
  const cpu = getCpuUsagePercent();
  assert.ok(typeof cpu === 'number');
  assert.ok(cpu >= 0 && cpu <= 100, 'CPU percent must be between 0 and 100');
});

test('Memory Metrics: reports total and used memory', () => {
  const mem = getMemoryMetrics();
  assert.ok(mem.totalBytes > 0, 'Total memory must be > 0');
  assert.ok(mem.usedBytes >= 0, 'Used memory must be >= 0');
  assert.ok(mem.freeBytes >= 0, 'Free memory must be >= 0');
  assert.ok(mem.usagePercent >= 0 && mem.usagePercent <= 100);
});

test('Disk Metrics: reports valid disk usage percentage', () => {
  const disk = getDiskMetrics();
  assert.ok(typeof disk.usagePercent === 'number');
  assert.ok(disk.threshold > 0);
  assert.ok(['OK', 'WARNING'].includes(disk.status));
});

