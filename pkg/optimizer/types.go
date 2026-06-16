package optimizer

// TransferTier 传输大小分级（移植自 frps_sh.sh）
type TransferTier string

const (
	Tier1GB   TransferTier = "1GB"
	Tier5GB   TransferTier = "5GB"
	Tier10GB  TransferTier = "10GB"
	Tier50GB  TransferTier = "50GB"
	Tier100GB TransferTier = "100GB"
	TierCustom TransferTier = "custom"
)

// OptimizationProfile 优化参数配置
type OptimizationProfile struct {
	// 基础信息
	MemoryMB     int          `json:"memoryMB"`
	CPUCores     int          `json:"cpuCores"`
	TransferTier TransferTier `json:"transferTier"`

	// 连接池
	PoolCount    int `json:"poolCount"`
	MaxPoolCount int `json:"maxPoolCount"`

	// TCP 缓冲区 (字节)
	TCPRMem string `json:"tcpRmem"` // "4096 87380 134217728"
	TCPWMem string `json:"tcpWmem"`

	// 连接限制
	MaxConns         int `json:"maxConns"`
	MaxSynBacklog    int `json:"maxSynBacklog"`
	NetdevBacklog    int `json:"netdevBacklog"`
	MaxOrphans       int `json:"maxOrphans"`
	Somaxconn        int `json:"somaxconn"`

	// 缓冲区最大/默认值
	RmemMax     int `json:"rmemMax"`
	WmemMax     int `json:"wmemMax"`
	RmemDefault int `json:"rmemDefault"`
	WmemDefault int `json:"wmemDefault"`

	// KeepAlive
	TCPKeepAliveTime  int `json:"tcpKeepAliveTime"`
	TCPKeepAliveIntvl int `json:"tcpKeepAliveIntvl"`
	TCPKeepAliveProbes int `json:"tcpKeepAliveProbes"`

	// TCP 重试
	TCPRetries    int `json:"tcpRetries"`
	TCPSynRetries int `json:"tcpSynRetries"`
	TCPSynAckRetries int `json:"tcpSynAckRetries"`

	// 其他
	TCPFinTimeout   int `json:"tcpFinTimeout"`
	TCPFastOpen     int `json:"tcpFastOpen"`
	FileMax         int `json:"fileMax"`
	MaxUserWatches  int `json:"maxUserWatches"`

	// 内存压力参数
	TCPMemPressure int `json:"tcpMemPressure"`
	TCPMemLimit    int `json:"tcpMemLimit"`
	TCPMemMax      int `json:"tcpMemMax"`

	// 带宽控制
	GlobalRxLimit int64 `json:"globalRxLimit"` // bytes/sec, 0=不限
	GlobalTxLimit int64 `json:"globalTxLimit"` // bytes/sec, 0=不限

	// 运行时填充
	Suggestions []string `json:"suggestions,omitempty"`
}
