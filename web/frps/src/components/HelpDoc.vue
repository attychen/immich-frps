<template>
  <div class="help-doc">
    <div class="doc-hero">
      <h1>FRP 管理面板</h1>
      <p>内网穿透服务管理平台 | 高性能反向代理 | 多客户端统一管控</p>
    </div>

    <el-row :gutter="24">
      <el-col :span="6">
        <div class="doc-nav">
          <el-menu :default-active="activeSection" @select="scrollTo">
            <el-menu-item index="quick">快速开始</el-menu-item>
            <el-menu-item index="server">服务端配置</el-menu-item>
            <el-menu-item index="client">客户端管理</el-menu-item>
            <el-menu-item index="proxy">代理规则</el-menu-item>
            <el-menu-item index="optimize">性能优化</el-menu-item>
            <el-menu-item index="bandwidth">带宽控制</el-menu-item>
            <el-menu-item index="firewall">安全防护</el-menu-item>
            <el-menu-item index="monitor">监控告警</el-menu-item>
            <el-menu-item index="upgrade">升级维护</el-menu-item>
            <el-menu-item index="faq">常见问题</el-menu-item>
          </el-menu>
        </div>
      </el-col>
      <el-col :span="18">
        <div class="doc-content">
          <!-- 快速开始 -->
          <section id="quick" class="doc-section">
            <h2>快速开始</h2>
            <el-divider />
            <h3>服务端部署</h3>
            <p>在服务器上运行 frps 服务端程序，默认监听 <code>6000</code> 端口用于 frp 通信，<code>6500</code> 端口为 Web 管理面板。</p>
            <pre class="code-block">./acfrps -c frps.toml</pre>
            <p>访问 <code>http://服务器IP:6500</code> 打开管理面板，默认账号 <code>admin</code>。</p>

            <h3>客户端部署</h3>
            <p>在「客户端配置」页面生成客户端程序和配置文件，下载后在目标机器运行：</p>
            <pre class="code-block">./acfrpc -c frpc.toml</pre>
            <p>客户端启动后自动连接服务端，在面板中即可看到在线状态。</p>

            <h3>端口说明</h3>
            <el-table :data="portTable" size="small" border>
              <el-table-column prop="port" label="端口" width="100" />
              <el-table-column prop="proto" label="协议" width="80" />
              <el-table-column prop="desc" label="用途" />
            </el-table>
          </section>

          <!-- 服务端配置 -->
          <section id="server" class="doc-section">
            <h2>服务端配置</h2>
            <el-divider />
            <p>在「服务器配置」页面可以修改所有 frps 参数，包括：</p>
            <ul>
              <li><strong>基础连接</strong> - 绑定地址、frp 端口、KCP/QUIC 端口</li>
              <li><strong>认证安全</strong> - Token 认证密钥、TLS 模式</li>
              <li><strong>管理面板</strong> - 面板地址端口、管理员账号密码</li>
              <li><strong>连接池性能</strong> - 最大连接池、TCP 多路复用、心跳超时</li>
              <li><strong>带宽限制</strong> - 全局上下行限速 (MB/s)，0 表示不限</li>
              <li><strong>虚拟主机</strong> - HTTP/HTTPS 代理端口、子域名配置</li>
              <li><strong>日志</strong> - 日志级别、文件路径、保留天数</li>
            </ul>
            <p>修改配置后服务会自动重启使配置生效。</p>
          </section>

          <!-- 客户端管理 -->
          <section id="client" class="doc-section">
            <h2>客户端管理</h2>
            <el-divider />
            <h3>创建用户</h3>
            <p>每个客户端需要一个用户凭证。在「客户端配置」页面创建用户，设置：</p>
            <ul>
              <li><strong>用户名 / Token</strong> - 客户端认证凭证</li>
              <li><strong>端口范围</strong> - 该用户可使用的远程端口</li>
              <li><strong>域名 / 子域名</strong> - HTTP/HTTPS 代理域名白名单</li>
              <li><strong>连接数限制</strong> - 该用户最大并发连接数</li>
            </ul>

            <h3>生成客户端</h3>
            <p>创建用户后，点击「生成客户端」：</p>
            <ol>
              <li>选择目标操作系统和架构 (linux/amd64, windows/amd64 等)</li>
              <li>填写服务器地址和端口</li>
              <li>选择对应的用户凭证</li>
              <li>系统生成内嵌密钥的客户端二进制文件和 TOML 配置</li>
            </ol>
          </section>

          <!-- 代理规则 -->
          <section id="proxy" class="doc-section">
            <h2>代理规则</h2>
            <el-divider />
            <p>支持的代理类型：</p>
            <el-table :data="proxyTypes" size="small" border>
              <el-table-column prop="type" label="类型" width="100" />
              <el-table-column prop="proto" label="协议" width="80" />
              <el-table-column prop="desc" label="说明" />
              <el-table-column prop="example" label="典型场景" />
            </el-table>
          </section>

          <!-- 性能优化 -->
          <section id="optimize" class="doc-section">
            <h2>性能优化</h2>
            <el-divider />
            <p>「性能优化」页面根据服务器硬件配置自动计算最优网络参数。</p>
            <h3>传输场景分级</h3>
            <el-table :data="tierTable" size="small" border>
              <el-table-column prop="tier" label="级别" width="100" />
              <el-table-column prop="size" label="文件大小" width="120" />
              <el-table-column prop="desc" label="优化策略" />
            </el-table>
            <p>点击「应用优化」后自动生成并写入 sysctl 配置，执行 <code>sysctl --system</code> 使其生效，随后提示重启服务。</p>
          </section>

          <!-- 带宽控制 -->
          <section id="bandwidth" class="doc-section">
            <h2>带宽控制</h2>
            <el-divider />
            <p>「带宽管理」页面提供两级限速：</p>
            <ul>
              <li><strong>全局限制</strong> - 所有客户端共享的上下行带宽上限</li>
              <li><strong>客户端限制</strong> - 针对单个客户端的带宽和每日流量配额</li>
            </ul>
            <p>实时查看当前带宽使用情况和历史趋势图。</p>
          </section>

          <!-- 安全防护 -->
          <section id="firewall" class="doc-section">
            <h2>安全防护</h2>
            <el-divider />
            <p>支持 IP 黑白名单，可设置三种模式：</p>
            <ul>
              <li><strong>黑名单模式</strong> - 禁止列表中的 IP 访问</li>
              <li><strong>白名单模式</strong> - 仅允许列表中的 IP 访问</li>
              <li><strong>禁用</strong> - 不进行 IP 过滤</li>
            </ul>
            <p>规则支持 CIDR 格式，如 <code>192.168.1.0/24</code>。</p>
          </section>

          <!-- 监控告警 -->
          <section id="monitor" class="doc-section">
            <h2>监控告警</h2>
            <el-divider />
            <p>「监控仪表盘」提供实时数据：</p>
            <ul>
              <li>24 小时带宽趋势图</li>
              <li>实时上下行速率</li>
              <li>客户端在线状态列表</li>
              <li>每客户端流量统计</li>
            </ul>
            <p>数据每 5 秒自动刷新。</p>
          </section>

          <!-- 升级维护 -->
          <section id="upgrade" class="doc-section">
            <h2>升级维护</h2>
            <el-divider />
            <p>点击页面标题下拉菜单可进行：</p>
            <ul>
              <li><strong>重启服务</strong> - 重新启动 frps</li>
              <li><strong>升级服务</strong> - 上传新版本二进制或提供 URL 在线升级</li>
              <li><strong>版本检测</strong> - 检查当前版本信息</li>
              <li><strong>查看日志</strong> - 实时查看服务运行日志</li>
              <li><strong>清空数据</strong> - 清除缓存和临时文件</li>
            </ul>
          </section>

          <!-- 常见问题 -->
          <section id="faq" class="doc-section">
            <h2>常见问题</h2>
            <el-divider />
            <el-collapse>
              <el-collapse-item title="客户端连接失败怎么办？" name="1">
                <p>1. 检查服务端 frp 端口 (默认 6000) 是否在防火墙放行</p>
                <p>2. 确认客户端配置中的 serverAddr 和 serverPort 正确</p>
                <p>3. 检查 auth.token 是否与服务端一致</p>
                <p>4. 查看服务端日志排查具体错误</p>
              </el-collapse-item>
              <el-collapse-item title="如何限速某个客户端？" name="2">
                <p>进入「带宽管理」页面，在客户端列表中找到目标客户端，点击「限速」按钮，设置上下行限制和每日流量配额即可。</p>
              </el-collapse-item>
              <el-collapse-item title="为什么代理不生效？" name="3">
                <p>1. 确认代理的远程端口未被占用</p>
                <p>2. 检查代理类型 (tcp/udp/http/https) 是否正确</p>
                <p>3. HTTP/HTTPS 代理需要配置 customDomains</p>
                <p>4. 查看客户端日志确认代理是否成功注册</p>
              </el-collapse-item>
              <el-collapse-item title="如何迁移到新服务器？" name="4">
                <p>1. 在新服务器部署 frps</p>
                <p>2. 导出用户数据 (客户端配置页面)</p>
                <p>3. 导入到新服务器的用户数据</p>
                <p>4. 更新所有客户端配置中的 serverAddr</p>
                <p>5. 重启所有客户端</p>
              </el-collapse-item>
            </el-collapse>
          </section>
        </div>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const activeSection = ref('quick')

const portTable = [
  { port: '6000', proto: 'TCP', desc: 'frp 服务端口，客户端通过此端口与服务端通信' },
  { port: '6500', proto: 'TCP', desc: 'Web 管理面板，用于浏览器访问管理后台' },
  { port: '8080', proto: 'TCP', desc: 'vhost HTTP 端口，用于 HTTP 类型代理的域名访问' },
  { port: '8443', proto: 'TCP', desc: 'vhost HTTPS 端口，用于 HTTPS 类型代理的域名访问' },
]

const proxyTypes = [
  { type: 'TCP', proto: 'TCP', desc: '最常用的代理类型，支持任意TCP协议', example: 'SSH、MySQL、RDP' },
  { type: 'UDP', proto: 'UDP', desc: 'UDP协议代理', example: 'DNS、游戏服务' },
  { type: 'HTTP', proto: 'TCP', desc: 'HTTP代理，支持域名绑定', example: 'Web网站' },
  { type: 'HTTPS', proto: 'TCP', desc: 'HTTPS代理，支持域名绑定', example: '安全Web服务' },
  { type: 'STCP', proto: 'TCP', desc: '安全TCP，需要密钥配对', example: '高安全内网服务' },
  { type: 'SUDP', proto: 'UDP', desc: '安全UDP，需要密钥配对', example: '安全UDP通信' },
  { type: 'XTCP', proto: 'P2P', desc: 'P2P打洞，无需服务器带宽', example: '大文件直传' },
  { type: 'TCPMUX', proto: 'TCP', desc: 'TCP多路复用代理', example: 'HTTP Connect代理' },
]

const tierTable = [
  { tier: '1GB', size: '1 GB', desc: '轻量优化 - 小文件传输' },
  { tier: '5GB', size: '5 GB', desc: '适中优化 - 中等文件' },
  { tier: '10GB', size: '10 GB', desc: '标准优化 - 推荐默认级别，大文件传输' },
  { tier: '50GB', size: '50 GB', desc: '深度优化 - 超大文件，连接池增大25%' },
  { tier: '100GB', size: '100 GB', desc: '极限传输 - 缓冲区翻倍，最强优化' },
]

function scrollTo(index: string) {
  activeSection.value = index
  const el = document.getElementById(index)
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
}
</script>

<style scoped>
.help-doc { padding: 0; max-width: 1200px; }
.doc-hero { padding: 32px 0 24px; border-bottom: 1px solid var(--el-border-color-light); margin-bottom: 24px; }
.doc-hero h1 { font-size: 28px; font-weight: 600; margin: 0 0 8px; color: var(--el-text-color-primary); }
.doc-hero p { font-size: 14px; color: var(--el-text-color-secondary); margin: 0; }
.doc-nav { position: sticky; top: 16px; }
.doc-nav .el-menu { border-right: none; }
.doc-content { padding: 0 16px; }
.doc-section { margin-bottom: 48px; }
.doc-section h2 { font-size: 20px; font-weight: 600; margin: 0; }
.doc-section h3 { font-size: 16px; font-weight: 600; margin: 20px 0 8px; }
.doc-section p { font-size: 14px; line-height: 1.8; color: var(--el-text-color-regular); margin: 8px 0; }
.doc-section li { font-size: 14px; line-height: 2; }
.doc-section code { background: var(--el-fill-color-light); padding: 2px 6px; border-radius: 3px; font-size: 13px; }
.code-block { background: #1e1e2e; color: #cdd6f4; padding: 16px; border-radius: 6px; font-size: 13px; line-height: 1.6; overflow-x: auto; }
</style>
