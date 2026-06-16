<template>
  <div class="optimize-panel">
    <div class="panel-header">
      <h2>System Optimization Engine</h2>
      <p class="subtitle">根据服务器配置自动计算最优网络参数，移植自 frps_sh.sh 智能调优算法</p>
    </div>

    <!-- 服务器信息 -->
    <el-card class="info-card" shadow="hover">
      <template #header>
        <span><el-icon><Monitor /></el-icon> 服务器信息</span>
      </template>
      <el-descriptions :column="3" border>
        <el-descriptions-item label="运行内存">{{ systemInfo.memoryMB }} MB</el-descriptions-item>
        <el-descriptions-item label="CPU 核心">{{ systemInfo.cpuCores }} 核</el-descriptions-item>
        <el-descriptions-item label="操作系统">{{ systemInfo.os }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 传输场景选择 -->
    <el-card class="tier-card" shadow="hover">
      <template #header>
        <span><el-icon><DataAnalysis /></el-icon> 传输场景预设</span>
      </template>
      <div class="tier-selector">
        <el-radio-group v-model="selectedTier" size="large" @change="onTierChange">
          <el-radio-button value="1GB">
            <div class="tier-option">
              <span class="tier-size">1 GB</span>
              <span class="tier-label">轻量优化</span>
            </div>
          </el-radio-button>
          <el-radio-button value="5GB">
            <div class="tier-option">
              <span class="tier-size">5 GB</span>
              <span class="tier-label">适中优化</span>
            </div>
          </el-radio-button>
          <el-radio-button value="10GB">
            <div class="tier-option">
              <span class="tier-size">10 GB</span>
              <span class="tier-label">Recommended</span>
            </div>
          </el-radio-button>
          <el-radio-button value="50GB">
            <div class="tier-option">
              <span class="tier-size">50 GB</span>
              <span class="tier-label">深度优化</span>
            </div>
          </el-radio-button>
          <el-radio-button value="100GB">
            <div class="tier-option">
              <span class="tier-size">100 GB</span>
              <span class="tier-label">极限传输</span>
            </div>
          </el-radio-button>
        </el-radio-group>
      </div>
    </el-card>

    <!-- 优化参数预览 -->
    <el-card v-if="profile" class="profile-card" shadow="hover" v-loading="loading">
      <template #header>
        <span><el-icon><Setting /></el-icon> 推荐优化参数</span>
      </template>

      <el-row :gutter="20">
        <el-col :span="12">
          <el-descriptions title="连接池" :column="2" border size="small">
            <el-descriptions-item label="连接池大小">{{ profile.poolCount }}</el-descriptions-item>
            <el-descriptions-item label="最大连接池">{{ profile.maxPoolCount }}</el-descriptions-item>
            <el-descriptions-item label="最大连接数">{{ profile.maxConns }}</el-descriptions-item>
            <el-descriptions-item label="SYN 队列">{{ profile.maxSynBacklog }}</el-descriptions-item>
          </el-descriptions>
        </el-col>
        <el-col :span="12">
          <el-descriptions title="TCP 缓冲区" :column="2" border size="small">
            <el-descriptions-item label="读缓冲最大">{{ formatBytes(profile.rmemMax) }}</el-descriptions-item>
            <el-descriptions-item label="写缓冲最大">{{ formatBytes(profile.wmemMax) }}</el-descriptions-item>
            <el-descriptions-item label="KeepAlive">{{ profile.tcpKeepAliveTime }}s</el-descriptions-item>
            <el-descriptions-item label="重试次数">{{ profile.tcpRetries }}</el-descriptions-item>
          </el-descriptions>
        </el-col>
      </el-row>

      <!-- 优化建议 -->
      <el-alert
        v-for="(tip, idx) in profile.suggestions"
        :key="idx"
        :title="tip"
        type="info"
        :closable="false"
        show-icon
        style="margin-top: 8px"
      />

      <!-- Sysctl 配置预览 -->
      <el-collapse style="margin-top: 16px">
        <el-collapse-item title="📄 sysctl 配置预览 (点击展开)">
          <pre class="sysctl-preview">{{ sysctlConf }}</pre>
        </el-collapse-item>
      </el-collapse>

      <div class="action-bar">
        <el-button type="primary" @click="applyOptimize" :loading="applying">
          <el-icon><Check /></el-icon> 一键应用优化
        </el-button>
        <el-button @click="rollbackOptimize">
          <el-icon><RefreshLeft /></el-icon> 回滚优化
        </el-button>
        <el-button @click="exportSysctlConf">
          <el-icon><Download /></el-icon> 导出 sysctl.conf
        </el-button>
      </div>

      <el-alert
        v-if="applyResult"
        :title="applyResult"
        :type="applyError ? 'error' : 'success'"
        :closable="true"
        show-icon
        style="margin-top: 12px"
      />
    </el-card>

    <!-- 加载中 -->
    <el-card v-else class="profile-card" shadow="hover">
      <el-empty description="选择传输场景后自动计算优化参数" />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Monitor, DataAnalysis, Setting, Check, RefreshLeft, Download
} from '@element-plus/icons-vue'

// 系统信息
const systemInfo = reactive({
  memoryMB: 0,
  cpuCores: 0,
  os: 'Linux'
})

// 选中的传输级别
const selectedTier = ref('10GB')
const loading = ref(false)
const applying = ref(false)
const applyResult = ref('')
const applyError = ref(false)
const profile = ref<any>(null)
const sysctlConf = ref('')

// 格式化字节
function formatBytes(bytes: number): string {
  if (bytes >= 1024 * 1024 * 1024) return (bytes / (1024 * 1024 * 1024)).toFixed(1) + ' GB'
  if (bytes >= 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(0) + ' MB'
  if (bytes >= 1024) return (bytes / 1024).toFixed(0) + ' KB'
  return bytes + ' B'
}

// 获取优化推荐
async function fetchProfile() {
  loading.value = true
  try {
    const resp = await fetch(`/api/optimize/profile?tier=${selectedTier.value}`)
    const data = await resp.json()
    if (data.code === 0) {
      profile.value = data.data
      // 同时获取 sysctl 配置
      const sysctlResp = await fetch(`/api/optimize/sysctl?tier=${selectedTier.value}`)
      const sysctlData = await sysctlResp.json()
      if (sysctlData.code === 0) {
        sysctlConf.value = sysctlData.data.sysctlConf
      }
    }
  } catch (e: any) {
    ElMessage.error('获取优化方案失败: ' + e.message)
  } finally {
    loading.value = false
  }
}

// 传输级别变化
function onTierChange() {
  fetchProfile()
}

// 应用优化
async function applyOptimize() {
  applying.value = true
  applyResult.value = ''
  try {
    const resp = await fetch('/api/optimize/apply', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tier: selectedTier.value, applySysctl: true })
    })
    const data = await resp.json()
    if (data.code === 0) {
      applyError.value = false
      const d = data.data
      applyResult.value = d.sysctlMessage || '优化配置已应用'
      if (d.needRestart) {
        ElMessageBox.confirm('优化配置已生效，需要重启服务以应用所有参数。是否立即重启？', '重启确认', {
          confirmButtonText: '立即重启', cancelButtonText: '稍后', type: 'info'
        }).then(() => {
          fetch('/api/restart', { credentials: 'include' })
          setTimeout(() => window.location.reload(), 2000)
        }).catch(() => {})
      }
      ElMessage.success('优化已应用' + (d.needRestart ? '，请重启服务' : ''))
    } else {
      applyError.value = true
      applyResult.value = data.msg || '应用失败'
      ElMessage.error(data.msg || '应用失败')
    }
  } catch (e: any) {
    applyError.value = true
    applyResult.value = e.message
    ElMessage.error('应用失败: ' + e.message)
  } finally {
    applying.value = false
  }
}

// 回滚优化
async function rollbackOptimize() {
  try {
    await ElMessageBox.confirm('确认回滚系统优化配置？', '确认操作', {
      confirmButtonText: '确认回滚',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await fetch('/api/optimize/rollback', { method: 'POST' })
    ElMessage.success('优化已回滚')
    applyResult.value = ''
  } catch {}
}

// 导出 sysctl 配置
function exportSysctlConf() {
  if (!sysctlConf.value) return
  const blob = new Blob([sysctlConf.value], { type: 'text/plain' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = '99-frps-optimize.conf'
  a.click()
  URL.revokeObjectURL(url)
  ElMessage.success('配置文件已下载')
}

// 获取系统信息
async function fetchSystemInfo() {
  try {
    const resp = await fetch('/api/optimize/profile')
    const data = await resp.json()
    if (data.code === 0 && data.data) {
      systemInfo.memoryMB = data.data.memoryMB
      systemInfo.cpuCores = data.data.cpuCores
    }
  } catch {}
}

onMounted(() => {
  fetchSystemInfo()
  fetchProfile()
})
</script>

<style scoped>
.optimize-panel {
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

.info-card, .tier-card, .profile-card {
  margin-bottom: 16px;
}

.tier-selector {
  display: flex;
  justify-content: center;
  padding: 12px 0;
}

.tier-option {
  text-align: center;
  padding: 4px 8px;
}

.tier-size {
  display: block;
  font-size: 18px;
  font-weight: bold;
}

.tier-label {
  display: block;
  font-size: 12px;
  color: var(--el-text-color-secondary);
  margin-top: 4px;
}

.sysctl-preview {
  background: var(--el-fill-color-light);
  padding: 16px;
  border-radius: 8px;
  font-family: 'Courier New', monospace;
  font-size: 13px;
  line-height: 1.6;
  overflow-x: auto;
  max-height: 400px;
}

.action-bar {
  display: flex;
  gap: 12px;
  margin-top: 20px;
  justify-content: center;
}
</style>
