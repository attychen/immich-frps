<template>
  <div class="monitor-dashboard">
    <div class="panel-header">
      <h2>Real-time Monitoring Dashboard</h2>
      <p class="subtitle">24小时带宽趋势 · 实时流量 · 客户端在线状态 · 5秒自动刷新</p>
    </div>

    <!-- 流量卡片 -->
    <el-row :gutter="20" class="stat-cards">
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <el-statistic title="实时下行速度" :value="formatSpeed(stats?.globalRxSpeed || 0)" />
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <el-statistic title="实时上行速度" :value="formatSpeed(stats?.globalTxSpeed || 0)" />
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <el-statistic title="在线客户端" :value="onlineCount" />
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <el-statistic title="总下载量" :value="formatBytes(stats?.globalRxBytes || 0)" />
        </el-card>
      </el-col>
    </el-row>

    <!-- 24小时带宽趋势图 -->
    <el-card class="chart-card" shadow="hover">
      <template #header>
        <span><el-icon><TrendCharts /></el-icon> 24小时带宽趋势</span>
      </template>
      <div ref="chartRef" style="height: 350px"></div>
    </el-card>

    <!-- 客户端在线状态 -->
    <el-card class="section-card" shadow="hover">
      <template #header>
        <span><el-icon><Connection /></el-icon> 客户端在线状态</span>
      </template>
      <el-table :data="clientList" stripe>
        <el-table-column prop="clientName" label="客户端名称" width="160" />
        <el-table-column prop="clientId" label="客户端ID" min-width="140" />
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.isOnline ? 'success' : 'info'" size="small">
              {{ row.isOnline ? '在线' : '离线' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="下行速度" width="120">
          <template #default="{ row }">{{ formatSpeed(row.rxSpeed || 0) }}</template>
        </el-table-column>
        <el-table-column label="上行速度" width="120">
          <template #default="{ row }">{{ formatSpeed(row.txSpeed || 0) }}</template>
        </el-table-column>
        <el-table-column label="今日流量" width="120">
          <template #default="{ row }">{{ formatBytes(row.usedToday || 0) }}</template>
        </el-table-column>
        <el-table-column label="限制" min-width="140">
          <template #default="{ row }">
            <span v-if="row.rxLimit > 0 || row.txLimit > 0">
              下{{ formatSpeed(row.rxLimit) }} / 上{{ formatSpeed(row.txLimit) }}
            </span>
            <span v-else class="no-limit">不限</span>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'

// ── 状态 ──
const stats = ref<any>(null)
const clientList = ref<any[]>([])
const chartRef = ref<HTMLDivElement | null>(null)
let chart: echarts.ECharts | null = null
let timer: ReturnType<typeof setInterval> | null = null

// ponytail: store last 1440 data points (24h * 60m), trimmed on client side
const history: { time: string; rx: number; tx: number }[] = []

const onlineCount = computed(() => clientList.value.filter((c: any) => c.isOnline).length)

// ── API calls ──
async function fetchData() {
  try {
    const [statsRes, clientsRes] = await Promise.all([
      fetch('/api/bandwidth/stats').then(r => r.json()),
      fetch('/api/bandwidth/clients').then(r => r.json()),
    ])
    stats.value = statsRes.data
    const clients = clientsRes.data || []
    clientList.value = clients.map((c: any) => ({
      ...c,
      clientName: c.clientName || c.clientId?.substring(0, 8) || '-',
    }))
    // push history
    const now = new Date()
    const time = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
    history.push({ time, rx: stats.value?.globalRxSpeed || 0, tx: stats.value?.globalTxSpeed || 0 })
    if (history.length > 1440) history.shift()
    updateChart()
  } catch (e) {
    console.error('获取监控数据失败', e)
  }
}

// ── ECharts ──
function initChart() {
  if (!chartRef.value) return
  chart = echarts.init(chartRef.value)
  chart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['下行', '上行'], bottom: 0 },
    grid: { left: 60, right: 20, top: 20, bottom: 40 },
    xAxis: { type: 'category', data: [], boundaryGap: false },
    yAxis: {
      type: 'value',
      axisLabel: { formatter: (v: number) => formatSpeed(v) },
    },
    series: [
      { name: '下行', type: 'line', smooth: true, data: [], lineStyle: { color: '#409EFF' }, symbol: 'none' },
      { name: '上行', type: 'line', smooth: true, data: [], lineStyle: { color: '#67C23A' }, symbol: 'none' },
    ],
  })
}

function updateChart() {
  if (!chart) return
  chart.setOption({
    xAxis: { data: history.map((h) => h.time) },
    series: [
      { data: history.map((h) => (h.rx / 1024 / 1024).toFixed(2)) },
      { data: history.map((h) => (h.tx / 1024 / 1024).toFixed(2)) },
    ],
  })
}

// ── format helpers ──
function formatSpeed(bytesPerSec: number): string {
  if (!bytesPerSec || bytesPerSec <= 0) return '0 B/s'
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s']
  let i = 0
  let v = bytesPerSec
  while (v >= 1024 && i < units.length - 1) { v /= 1024; i++ }
  return v.toFixed(1) + ' ' + units[i]
}

function formatBytes(bytes: number): string {
  if (!bytes || bytes <= 0) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  let i = 0
  let v = bytes
  while (v >= 1024 && i < units.length - 1) { v /= 1024; i++ }
  return v.toFixed(1) + ' ' + units[i]
}

// ── lifecycle ──
onMounted(() => {
  fetchData()
  initChart()
  timer = setInterval(fetchData, 5000)
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
  if (chart) chart.dispose()
})
</script>

<style scoped>
.monitor-dashboard {
  padding: 20px;
}
.panel-header {
  margin-bottom: 20px;
}
.panel-header h2 {
  margin: 0 0 4px;
}
.subtitle {
  color: #909399;
  font-size: 13px;
  margin: 0;
}
.stat-cards {
  margin-bottom: 20px;
}
.stat-card {
  text-align: center;
}
.chart-card {
  margin-bottom: 20px;
}
.section-card {
  margin-bottom: 20px;
}
.no-limit {
  color: #c0c4cc;
}
</style>
