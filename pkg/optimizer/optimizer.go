package optimizer

import (
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
)

// DetectMemoryMB 检测系统内存（MB）
func DetectMemoryMB() int {
	data, err := os.ReadFile("/proc/meminfo")
	if err != nil {
		return 2048 // 默认 2GB
	}
	re := regexp.MustCompile(`MemTotal:\s+(\d+)\s+kB`)
	matches := re.FindStringSubmatch(string(data))
	if len(matches) >= 2 {
		kb, _ := strconv.Atoi(matches[1])
		return kb / 1024
	}
	return 2048
}

// DetectCPUCores 检测 CPU 核心数
func DetectCPUCores() int {
	data, err := os.ReadFile("/proc/cpuinfo")
	if err != nil {
		return 4
	}
	return strings.Count(string(data), "processor\t:")
}

// GetTransferGB 获取传输大小对应的 GB 数
func GetTransferGB(tier TransferTier) int {
	switch tier {
	case Tier1GB:
		return 1
	case Tier5GB:
		return 5
	case Tier10GB:
		return 10
	case Tier50GB:
		return 50
	case Tier100GB:
		return 100
	default:
		return 10
	}
}

// CalculateProfile 根据内存、CPU 和传输大小计算优化参数
// 算法完全移植自 frps_sh.sh 的 apply_sysctl() 函数
func CalculateProfile(memMB int, cpuCores int, tier TransferTier) *OptimizationProfile {
	p := &OptimizationProfile{
		MemoryMB:          memMB,
		CPUCores:          cpuCores,
		TransferTier:      tier,
		TCPKeepAliveIntvl: 5,
		TCPKeepAliveProbes: 9,
		TCPSynRetries:     5,
		TCPSynAckRetries:  5,
		TCPFinTimeout:     10,
		TCPFastOpen:       3,
		FileMax:           2097152,
		MaxUserWatches:    524288,
	}

	transferGB := GetTransferGB(tier)

	// ── 内存分级计算 ──
	switch {
	case memMB <= 1024:
		p.PoolCount = 200
		p.RmemMax = 64 * 1024 * 1024      // 64MB
		p.WmemMax = 64 * 1024 * 1024
		p.RmemDefault = 256 * 1024         // 256KB
		p.WmemDefault = 256 * 1024
		p.Somaxconn = 4096
		p.MaxSynBacklog = 4096
		p.NetdevBacklog = 4096
		p.MaxOrphans = 16384
		p.TCPMemPressure = 4096
		p.TCPMemLimit = 65536
		p.TCPMemMax = 131072
		p.MaxConns = 16384

	case memMB <= 2048:
		p.PoolCount = 500
		p.RmemMax = 128 * 1024 * 1024     // 128MB
		p.WmemMax = 128 * 1024 * 1024
		p.RmemDefault = 512 * 1024         // 512KB
		p.WmemDefault = 512 * 1024
		p.Somaxconn = 8192
		p.MaxSynBacklog = 8192
		p.NetdevBacklog = 8192
		p.MaxOrphans = 32768
		p.TCPMemPressure = 8192
		p.TCPMemLimit = 131072
		p.TCPMemMax = 262144
		p.MaxConns = 32768

	case memMB <= 4096:
		p.PoolCount = 1000
		p.RmemMax = 256 * 1024 * 1024     // 256MB
		p.WmemMax = 256 * 1024 * 1024
		p.RmemDefault = 1024 * 1024        // 1MB
		p.WmemDefault = 1024 * 1024
		p.Somaxconn = 16384
		p.MaxSynBacklog = 16384
		p.NetdevBacklog = 16384
		p.MaxOrphans = 65536
		p.TCPMemPressure = 16384
		p.TCPMemLimit = 262144
		p.TCPMemMax = 524288
		p.MaxConns = 65536

	default: // > 4GB
		p.PoolCount = 2000
		p.RmemMax = 512 * 1024 * 1024     // 512MB
		p.WmemMax = 512 * 1024 * 1024
		p.RmemDefault = 2048 * 1024        // 2MB
		p.WmemDefault = 2048 * 1024
		p.Somaxconn = 32768
		p.MaxSynBacklog = 32768
		p.NetdevBacklog = 32768
		p.MaxOrphans = 131072
		p.TCPMemPressure = 32768
		p.TCPMemLimit = 524288
		p.TCPMemMax = 1048576
		p.MaxConns = 131072
	}

	// ── 传输大小调整（移植自 frps_sh.sh） ──
	switch {
	case transferGB >= 100:
		p.TCPRetries = 20
		p.TCPKeepAliveTime = 20
		p.MaxOrphans = 524288

	case transferGB >= 50:
		p.TCPRetries = 15
		p.TCPKeepAliveTime = 30
		p.MaxOrphans = 262144

	case transferGB >= 10:
		p.TCPRetries = 12
		p.TCPKeepAliveTime = 60
		p.MaxOrphans = 131072

	case transferGB >= 5:
		p.TCPRetries = 10
		p.TCPKeepAliveTime = 60
		p.MaxOrphans = 65536

	default:
		p.TCPRetries = 8
		p.TCPKeepAliveTime = 120
		p.MaxOrphans = 32768
	}

	// ── 构建 TCP 缓冲区字符串 ──
	p.TCPRMem = fmt.Sprintf("%d %d %d", p.RmemDefault, p.TCPMemLimit, p.RmemMax)
	p.TCPWMem = fmt.Sprintf("%d %d %d", p.WmemDefault, p.TCPMemLimit, p.WmemMax)
	p.MaxPoolCount = p.PoolCount * 2

	return p
}

// GenerateSysctlConf 生成 sysctl 配置文件内容
func (p *OptimizationProfile) GenerateSysctlConf() string {
	return fmt.Sprintf(`# frps 网络优化 - 由 go-frp-panel 优化引擎生成
# 传输大小: %s | 内存: %dMB | CPU: %d核
net.ipv4.tcp_rmem = %s
net.ipv4.tcp_wmem = %s
net.ipv4.tcp_mem = %d %d %d
net.ipv4.udp_mem = %d %d %d
net.core.somaxconn = %d
net.ipv4.tcp_max_syn_backlog = %d
net.core.netdev_max_backlog = %d
net.core.rmem_max = %d
net.core.wmem_max = %d
net.core.rmem_default = %d
net.core.wmem_default = %d
net.ipv4.tcp_keepalive_time = %d
net.ipv4.tcp_keepalive_intvl = %d
net.ipv4.tcp_keepalive_probes = %d
net.ipv4.tcp_retries2 = %d
net.ipv4.tcp_syn_retries = %d
net.ipv4.tcp_synack_retries = %d
net.ipv4.tcp_fin_timeout = %d
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_max_orphans = %d
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = %d
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = %d
fs.inotify.max_user_watches = %d
`,
		p.TransferTier, p.MemoryMB, p.CPUCores,
		p.TCPRMem,
		p.TCPWMem,
		p.TCPMemPressure, p.TCPMemLimit, p.TCPMemMax,
		p.TCPMemPressure, p.TCPMemLimit, p.TCPMemMax,
		p.Somaxconn,
		p.MaxSynBacklog,
		p.NetdevBacklog,
		p.RmemMax,
		p.WmemMax,
		p.RmemDefault,
		p.WmemDefault,
		p.TCPKeepAliveTime,
		p.TCPKeepAliveIntvl,
		p.TCPKeepAliveProbes,
		p.TCPRetries,
		p.TCPSynRetries,
		p.TCPSynAckRetries,
		p.TCPFinTimeout,
		p.MaxOrphans,
		p.TCPFastOpen,
		p.FileMax,
		p.MaxUserWatches,
	)
}

// GetSuggestion 获取针对当前档位的优化建议描述
func (p *OptimizationProfile) GetSuggestion() []string {
	suggestions := []string{}

	// BBR 检查
	suggestions = append(suggestions, "建议启用 BBR 拥塞控制: echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf")

	// TCP Fast Open
	if p.TCPFastOpen > 0 {
		suggestions = append(suggestions,
			fmt.Sprintf("已配置 TCP Fast Open=%d，可提升连接建立速度", p.TCPFastOpen))
	}

	// 连接池建议
	suggestions = append(suggestions,
		fmt.Sprintf("当前连接池大小: %d，最大 %d 个并发连接", p.PoolCount, p.MaxPoolCount))

	// 传输大小建议
	transferGB := GetTransferGB(p.TransferTier)
	if transferGB >= 50 {
		suggestions = append(suggestions, "⚠️ 极限传输模式：建议确保磁盘 IO 和带宽充足")
	}

	// 内存建议
	if p.MemoryMB <= 1024 {
		suggestions = append(suggestions, "⚠️ 内存较小（≤1GB），建议限制同时在线客户端数量")
	}

	return suggestions
}
