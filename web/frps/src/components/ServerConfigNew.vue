<template>
  <div class="server-config-panel">
    <div class="panel-header">
      <h2>Server Configuration</h2>
      <div class="header-actions">
        <el-button type="primary" @click="fetchConfig">刷新配置</el-button>
        <el-button type="success" @click="applyConfig">应用配置</el-button>
        <el-button @click="showRaw = !showRaw">{{ showRaw ? '表单编辑' : '原始TOML' }}</el-button>
      </div>
    </div>

    <!-- 原始TOML编辑模式 -->
    <el-input
      v-if="showRaw"
      v-model="rawToml"
      :rows="20"
      type="textarea"
      placeholder="frps.toml 配置内容..."
      style="font-family: monospace; margin-bottom: 16px"
    />

    <!-- 结构化表单模式 -->
    <el-form v-else label-width="200px" class="config-form">
      <el-card header="Bind &amp; Connection" shadow="hover">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="绑定地址">
              <el-input v-model="config.bindAddr" placeholder="0.0.0.0" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="绑定端口">
              <el-input-number v-model="config.bindPort" :min="1" :max="65535" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="KCP端口">
              <el-input-number v-model="config.kcpBindPort" :min="0" :max="65535" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="QUIC端口">
              <el-input-number v-model="config.quicBindPort" :min="0" :max="65535" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-card>

      <el-card header="🔐 认证与安全" shadow="hover" style="margin-top:16px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="认证Token">
              <el-input v-model="config.authToken" show-password placeholder="认证密钥" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="认证方式">
              <el-select v-model="config.authMethod" style="width:100%">
                <el-option label="Token" value="token" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="仅TLS模式">
              <el-switch v-model="config.tlsOnly" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-card>

      <el-card header="🖥️ 管理面板" shadow="hover" style="margin-top:16px">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="面板地址">
              <el-input v-model="config.dashboardAddr" placeholder="0.0.0.0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="面板端口">
              <el-input-number v-model="config.dashboardPort" :min="1" :max="65535" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="面板用户">
              <el-input v-model="config.dashboardUser" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="面板密码">
              <el-input v-model="config.dashboardPwd" show-password />
            </el-form-item>
          </el-col>
        </el-row>
      </el-card>

      <el-card header="📡 连接池与性能" shadow="hover" style="margin-top:16px">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="连接池大小">
              <el-input-number v-model="config.maxPoolCount" :min="1" :max="10000" />
              <span class="hint">影响并发处理能力</span>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="TCP多路复用">
              <el-switch v-model="config.tcpMux" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="KeepAlive间隔(秒)">
              <el-input-number v-model="config.tcpKeepAlive" :min="1" :max="300" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="心跳超时(秒)">
              <el-input-number v-model="config.heartbeatTimeout" :min="1" :max="3600" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="每客户端最大代理">
              <el-input-number v-model="config.maxPortsPerClient" :min="0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="允许端口范围">
              <el-input v-model="config.allowPorts" placeholder="如: 6000-9000,10000" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-card>

      <el-card header="Bandwidth &amp; Rate Limit" shadow="hover" style="margin-top:16px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="全局下行限制 (MB/s)">
              <el-input-number v-model="config.globalRxLimitMB" :min="0" :step="1" />
              <span class="hint">0=不限</span>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="全局上行限制 (MB/s)">
              <el-input-number v-model="config.globalTxLimitMB" :min="0" :step="1" />
              <span class="hint">0=不限</span>
            </el-form-item>
          </el-col>
        </el-row>
      </el-card>

      <el-card header="🌐 虚拟主机" shadow="hover" style="margin-top:16px">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="HTTP端口">
              <el-input-number v-model="config.vhostHTTPPort" :min="0" :max="65535" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="HTTPS端口">
              <el-input-number v-model="config.vhostHTTPSPort" :min="0" :max="65535" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="HTTP超时(秒)">
              <el-input-number v-model="config.vhostHTTPTimeout" :min="1" :max="300" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="子域名主机">
              <el-input v-model="config.subDomainHost" placeholder="如: frp.example.com" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-card>

      <el-card header="Logging" shadow="hover" style="margin-top:16px">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="日志级别">
              <el-select v-model="config.logLevel" style="width:100%">
                <el-option label="Debug" value="debug" />
                <el-option label="Info" value="info" />
                <el-option label="Warn" value="warn" />
                <el-option label="Error" value="error" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="日志文件">
              <el-input v-model="config.logFile" placeholder="console" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="日志保留(天)">
              <el-input-number v-model="config.logMaxDays" :min="1" :max="365" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-card>
    </el-form>
  </div>
</template>

<script lang="ts" setup>
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { showErrorTips, showLoading, showTips } from '../utils/utils.ts'

const showRaw = ref(false)
const rawToml = ref('')
const config = reactive({
  bindAddr: '0.0.0.0',
  bindPort: 6000,
  kcpBindPort: 0,
  quicBindPort: 0,
  authToken: '',
  authMethod: 'token',
  tlsOnly: false,
  dashboardAddr: '0.0.0.0',
  dashboardPort: 6500,
  dashboardUser: 'admin',
  dashboardPwd: '',
  maxPoolCount: 5,
  tcpMux: true,
  tcpKeepAlive: 15,
  heartbeatTimeout: 90,
  maxPortsPerClient: 0,
  allowPorts: '',
  globalRxLimitMB: 0,
  globalTxLimitMB: 0,
  vhostHTTPPort: 8080,
  vhostHTTPSPort: 8443,
  vhostHTTPTimeout: 60,
  subDomainHost: '',
  logLevel: 'info',
  logFile: 'console',
  logMaxDays: 3,
})

function parseTomlToConfig(toml: string) {
  // 简单解析TOML到config对象
  const getVal = (key: string, def: any) => {
    const re = new RegExp(`^${key}\\s*=\\s*["']?([^"'\n#]+)["']?`, 'm')
    const m = toml.match(re)
    return m ? m[1].trim() : def
  }
  const getNum = (key: string, def: number) => {
    const re = new RegExp(`^${key}\\s*=\\s*([\\d]+)`, 'm')
    const m = toml.match(re)
    return m ? parseInt(m[1]) : def
  }
  const getBool = (key: string, def: boolean) => {
    const re = new RegExp(`^${key}\\s*=\\s*(true|false)`, 'm')
    const m = toml.match(re)
    return m ? m[1] === 'true' : def
  }

  config.bindAddr = getVal('bindAddr', '0.0.0.0')
  config.bindPort = getNum('bindPort', 6000)
  config.kcpBindPort = getNum('kcpBindPort', 0)
  config.quicBindPort = getNum('quicBindPort', 0)
  config.authToken = getVal('auth.token', '')
  config.tlsOnly = getBool('tlsOnly', false)
  config.dashboardAddr = getVal('webServer.addr', '0.0.0.0')
  config.dashboardPort = getNum('webServer.port', 6500)
  config.dashboardUser = getVal('webServer.user', 'admin')
  config.dashboardPwd = getVal('webServer.password', '')
  config.maxPoolCount = getNum('transport.maxPoolCount', 5)
  config.tcpMux = getBool('transport.tcpMux', true)
  config.tcpKeepAlive = getNum('transport.tcpKeepAlive', 15)
  config.heartbeatTimeout = getNum('transport.heartbeatTimeout', 90)
  config.maxPortsPerClient = getNum('maxPortsPerClient', 0)
  config.allowPorts = getVal('allowPorts', '')
  config.vhostHTTPPort = getNum('vhostHTTPPort', 8080)
  config.vhostHTTPSPort = getNum('vhostHTTPSPort', 8443)
  config.vhostHTTPTimeout = getNum('vhostHTTPTimeout', 60)
  config.subDomainHost = getVal('subDomainHost', '')
  config.logLevel = getVal('log.level', 'info')
  config.logFile = getVal('log.to', 'console')
  config.logMaxDays = getNum('log.maxDays', 3)
}

function buildTomlFromConfig(): string {
  const lines: string[] = []
  lines.push(`bindAddr = "${config.bindAddr}"`)
  lines.push(`bindPort = ${config.bindPort}`)
  if (config.kcpBindPort > 0) lines.push(`kcpBindPort = ${config.kcpBindPort}`)
  if (config.quicBindPort > 0) lines.push(`quicBindPort = ${config.quicBindPort}`)
  lines.push('')
  lines.push('auth.method = "token"')
  lines.push(`auth.token = "${config.authToken}"`)
  if (config.tlsOnly) lines.push('tlsOnly = true')
  if (config.maxPortsPerClient > 0) lines.push(`maxPortsPerClient = ${config.maxPortsPerClient}`)
  if (config.allowPorts) lines.push(`allowPorts = "${config.allowPorts}"`)
  lines.push('')
  lines.push('[webServer]')
  lines.push(`addr = "${config.dashboardAddr}"`)
  lines.push(`port = ${config.dashboardPort}`)
  lines.push(`user = "${config.dashboardUser}"`)
  lines.push(`password = "${config.dashboardPwd}"`)
  lines.push('')
  lines.push('[transport]')
  lines.push(`maxPoolCount = ${config.maxPoolCount}`)
  lines.push(`tcpMux = ${config.tcpMux}`)
  lines.push(`tcpKeepAlive = ${config.tcpKeepAlive}`)
  if (config.heartbeatTimeout > 0) lines.push(`heartbeatTimeout = ${config.heartbeatTimeout}`)
  if (config.vhostHTTPPort > 0) lines.push(`vhostHTTPPort = ${config.vhostHTTPPort}`)
  if (config.vhostHTTPSPort > 0) lines.push(`vhostHTTPSPort = ${config.vhostHTTPSPort}`)
  if (config.vhostHTTPTimeout > 0) lines.push(`vhostHTTPTimeout = ${config.vhostHTTPTimeout}`)
  if (config.subDomainHost) lines.push(`subDomainHost = "${config.subDomainHost}"`)
  lines.push('')
  lines.push('[log]')
  lines.push(`to = "${config.logFile}"`)
  lines.push(`level = "${config.logLevel}"`)
  lines.push(`maxDays = ${config.logMaxDays}`)
  return lines.join('\n')
}

async function fetchConfig() {
  try {
    const res = await fetch('../api/server/config/get', { credentials: 'include' })
    const text = await res.text()
    rawToml.value = text
    parseTomlToConfig(text)
    ElMessage.success('配置已加载')
  } catch {
    showErrorTips('获取配置失败')
  }
}

async function applyConfig() {
  const toml = showRaw.value ? rawToml.value : buildTomlFromConfig()
  if (!toml.trim()) {
    ElMessage.warning('配置内容不能为空')
    return
  }
  try {
    await ElMessageBox.confirm('更新配置后将重启服务，确定继续？', '确认', {
      confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
    })
  } catch { return }

  const loading = showLoading('配置更新中...')
  try {
    const res = await fetch('../api/server/config/set', {
      credentials: 'include', method: 'PUT', body: toml
    })
    const json = await res.json()
    showTips(json.code, json.msg)
    // 同时更新带宽限制
    if (config.globalRxLimitMB > 0 || config.globalTxLimitMB > 0) {
      await fetch('../api/bandwidth/global', {
        credentials: 'include', method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          rxLimit: config.globalRxLimitMB * 1024 * 1024,
          txLimit: config.globalTxLimitMB * 1024 * 1024,
        })
      })
    }
    setTimeout(() => window.location.reload(), 1500)
  } catch {
    showErrorTips('配置更新失败')
  } finally {
    loading.close()
  }
}

fetchConfig()
</script>

<style scoped>
.server-config-panel { padding: 20px; max-width: 1000px; }
.panel-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
.panel-header h2 { margin: 0; font-size: 22px; }
.header-actions { display: flex; gap: 8px; }
.config-form { max-width: 100%; }
.hint { font-size: 12px; color: #999; margin-left: 8px; }
</style>
