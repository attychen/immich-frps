<template>
  <div class="bandwidth-panel">
    <div class="panel-header">
      <h2>Bandwidth &amp; Traffic Management</h2>
      <p class="subtitle">全局带宽限制 + 客户端限速 + 每日配额管理</p>
    </div>

    <!-- 全局带宽设置 -->
    <el-card class="section-card" shadow="hover">
      <template #header>
        <span><el-icon><Odometer /></el-icon> 全局带宽限制</span>
      </template>

      <el-row :gutter="20">
        <el-col :span="12">
          <div class="limit-item">
            <label>全局下行限制 (服务端→客户端)</label>
            <el-input-number
              v-model="globalRxLimit"
              :min="0"
              :step="1"
              :max="10240"
              size="large"
              style="width: 100%"
            />
            <span class="unit-hint">MB/s，0 = 不限</span>
          </div>
        </el-col>
        <el-col :span="12">
          <div class="limit-item">
            <label>全局上行限制 (客户端→服务端)</label>
            <el-input-number
              v-model="globalTxLimit"
              :min="0"
              :step="1"
              :max="10240"
              size="large"
              style="width: 100%"
            />
            <span class="unit-hint">MB/s，0 = 不限</span>
          </div>
        </el-col>
      </el-row>

      <div class="action-bar">
        <el-button type="primary" @click="setGlobalLimit" :loading="saving">
          <el-icon><Check /></el-icon> 应用全局限制
        </el-button>
      </div>
    </el-card>

    <!-- 实时带宽统计 -->
    <el-card class="section-card" shadow="hover">
      <template #header>
        <span><el-icon><TrendCharts /></el-icon> 实时带宽统计</span>
        <el-button size="small" style="float: right" @click="refreshStats" :loading="statsLoading">
          刷新
        </el-button>
      </template>

      <el-row :gutter="20" v-if="stats">
        <el-col :span="6">
          <el-statistic title="实时下行速度" :value="formatSpeed(stats.globalRxSpeed)" />
        </el-col>
        <el-col :span="6">
          <el-statistic title="实时上行速度" :value="formatSpeed(stats.globalTxSpeed)" />
        </el-col>
        <el-col :span="6">
          <el-statistic title="总下载量" :value="formatBytes(stats.globalRxBytes)" />
        </el-col>
        <el-col :span="6">
          <el-statistic title="总上传量" :value="formatBytes(stats.globalTxBytes)" />
        </el-col>
      </el-row>

      <!-- 客户端带宽详情 -->
      <el-divider v-if="clientStats.length > 0" />
      <h3 v-if="clientStats.length > 0">客户端带宽详情</h3>

      <el-table :data="clientStats" stripe style="margin-top: 12px" v-if="clientStats.length > 0">
        <el-table-column prop="clientName" label="客户端" width="140" />
        <el-table-column prop="clientId" label="ID" width="120" />
        <el-table-column label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.isOnline ? 'success' : 'info'" size="small">
              {{ row.isOnline ? '在线' : '离线' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="下行速度" width="110">
          <template #default="{ row }">{{ formatSpeed(row.rxSpeed) }}</template>
        </el-table-column>
        <el-table-column label="上行速度" width="110">
          <template #default="{ row }">{{ formatSpeed(row.txSpeed) }}</template>
        </el-table-column>
        <el-table-column label="下行限制" width="110">
          <template #default="{ row }">{{ row.rxLimit > 0 ? formatSpeed(row.rxLimit) : '不限' }}</template>
        </el-table-column>
        <el-table-column label="上行限制" width="110">
          <template #default="{ row }">{{ row.txLimit > 0 ? formatSpeed(row.txLimit) : '不限' }}</template>
        </el-table-column>
        <el-table-column label="今日流量" width="130">
          <template #default="{ row }">
            {{ formatBytes(row.usedToday) }}
            <template v-if="row.dailyQuota > 0">
              / {{ formatBytes(row.dailyQuota) }}
            </template>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button size="small" type="primary" link @click="editClientLimit(row)">
              限速
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty v-else description="暂无客户端连接" />
    </el-card>

    <!-- 客户端限速弹窗 -->
    <el-dialog v-model="dialogVisible" title="设置客户端带宽限制" width="500">
      <el-form :model="clientForm" label-width="120px">
        <el-form-item label="客户端 ID">
          <el-input :model-value="clientForm.clientId" disabled />
        </el-form-item>
        <el-form-item label="下行限制">
          <el-input-number
            v-model="clientForm.rxLimit"
            :min="0"
            :step="1"
            :max="10240"
          />
          <span class="unit-hint-inline">MB/s，0 = 不限</span>
        </el-form-item>
        <el-form-item label="上行限制">
          <el-input-number
            v-model="clientForm.txLimit"
            :min="0"
            :step="1"
            :max="10240"
          />
          <span class="unit-hint-inline">MB/s，0 = 不限</span>
        </el-form-item>
        <el-form-item label="每日流量配额">
          <el-input-number
            v-model="clientForm.dailyQuota"
            :min="0"
            :step="1"
            :max="102400"
          />
          <span class="unit-hint-inline">GB，0 = 不限</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveClientLimit" :loading="saving">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  Odometer, TrendCharts, Check
} from '@element-plus/icons-vue'

// 全局限制
const globalRxLimit = ref(0)
const globalTxLimit = ref(0)
const saving = ref(false)
const statsLoading = ref(false)

// 统计
const stats = ref<any>(null)
const clientStats = ref<any[]>([])

// 客户端限速弹窗
const dialogVisible = ref(false)
const clientForm = reactive({
  clientId: '',
  rxLimit: 0,
  txLimit: 0,
  dailyQuota: 0
})

let refreshTimer: any = null

function formatSpeed(bytesPerSec: number): string {
  if (!bytesPerSec || bytesPerSec <= 0) return '0 B/s'
  if (bytesPerSec >= 1024 * 1024 * 1024) return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(2) + ' GB/s'
  if (bytesPerSec >= 1024 * 1024) return (bytesPerSec / (1024 * 1024)).toFixed(1) + ' MB/s'
  if (bytesPerSec >= 1024) return (bytesPerSec / 1024).toFixed(0) + ' KB/s'
  return bytesPerSec + ' B/s'
}

function formatBytes(bytes: number): string {
  if (!bytes || bytes <= 0) return '0 B'
  if (bytes >= 1024 * 1024 * 1024) return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB'
  if (bytes >= 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
  if (bytes >= 1024) return (bytes / 1024).toFixed(0) + ' KB'
  return bytes + ' B'
}

async function fetchGlobalLimit() {
  try {
    const resp = await fetch('/api/bandwidth/global')
    const data = await resp.json()
    if (data.code === 0 && data.data) {
      globalRxLimit.value = Math.round(data.data.rxLimit / (1024 * 1024))
      globalTxLimit.value = Math.round(data.data.txLimit / (1024 * 1024))
    }
  } catch {}
}

async function setGlobalLimit() {
  saving.value = true
  try {
    const resp = await fetch('/api/bandwidth/global', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        rxLimit: globalRxLimit.value * 1024 * 1024,
        txLimit: globalTxLimit.value * 1024 * 1024
      })
    })
    const data = await resp.json()
    if (data.code === 0) {
      ElMessage.success('全局带宽限制已更新')
    } else {
      ElMessage.error(data.msg || '更新失败')
    }
  } catch (e: any) {
    ElMessage.error('更新失败: ' + e.message)
  } finally {
    saving.value = false
  }
}

async function refreshStats() {
  statsLoading.value = true
  try {
    const resp = await fetch('/api/bandwidth/stats')
    const data = await resp.json()
    if (data.code === 0 && data.data) {
      stats.value = data.data
      // 转换客户端统计为数组
      const arr: any[] = []
      if (data.data.clientStats) {
        for (const key of Object.keys(data.data.clientStats)) {
          arr.push(data.data.clientStats[key])
        }
      }
      clientStats.value = arr
    }
  } catch {} finally {
    statsLoading.value = false
  }
}

function editClientLimit(row: any) {
  clientForm.clientId = row.clientId
  clientForm.rxLimit = row.rxLimit > 0 ? Math.round(row.rxLimit / (1024 * 1024)) : 0
  clientForm.txLimit = row.txLimit > 0 ? Math.round(row.txLimit / (1024 * 1024)) : 0
  clientForm.dailyQuota = row.dailyQuota > 0 ? Math.round(row.dailyQuota / (1024 * 1024 * 1024)) : 0
  dialogVisible.value = true
}

async function saveClientLimit() {
  saving.value = true
  try {
    const resp = await fetch(`/api/bandwidth/client?id=${encodeURIComponent(clientForm.clientId)}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        rxLimit: clientForm.rxLimit * 1024 * 1024,
        txLimit: clientForm.txLimit * 1024 * 1024,
        dailyQuota: clientForm.dailyQuota * 1024 * 1024 * 1024
      })
    })
    const data = await resp.json()
    if (data.code === 0) {
      ElMessage.success('客户端限制已更新')
      dialogVisible.value = false
      refreshStats()
    } else {
      ElMessage.error(data.msg || '更新失败')
    }
  } catch (e: any) {
    ElMessage.error('更新失败: ' + e.message)
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  fetchGlobalLimit()
  refreshStats()
  refreshTimer = setInterval(refreshStats, 5000)
})

onUnmounted(() => {
  if (refreshTimer) clearInterval(refreshTimer)
})
</script>

<style scoped>
.bandwidth-panel {
  padding: 20px;
  max-width: 1200px;
}

.panel-header {
  margin-bottom: 24px;
}

.panel-header h2 {
  font-size: 24px;
  color: var(--el-text-color-primary);
  margin: 0 0 8px 0;
}

.subtitle {
  color: var(--el-text-color-secondary);
  font-size: 14px;
  margin: 0;
}

.section-card {
  margin-bottom: 16px;
}

.limit-item {
  margin-bottom: 8px;
}

.limit-item label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: var(--el-text-color-regular);
}

.unit-hint {
  display: block;
  font-size: 12px;
  color: var(--el-text-color-secondary);
  margin-top: 4px;
}

.unit-hint-inline {
  margin-left: 8px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.action-bar {
  display: flex;
  gap: 12px;
  margin-top: 20px;
  justify-content: center;
}
</style>
