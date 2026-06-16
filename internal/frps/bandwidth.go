package frps

import (
	"encoding/json"
	"sync"
	"sync/atomic"
	"time"
)

// ClientBandwidthLimit 客户端带宽限制
type ClientBandwidthLimit struct {
	ClientID   string `json:"clientId"`
	RxLimit    int64  `json:"rxLimit"`    // 下载限速 bytes/sec, 0=不限
	TxLimit    int64  `json:"txLimit"`    // 上传限速 bytes/sec, 0=不限
	DailyQuota int64  `json:"dailyQuota"` // 每日流量配额 bytes, 0=不限
	UsedToday  int64  `json:"usedToday"`  // 今日已用 bytes
}

// BandwidthStats 带宽统计
type BandwidthStats struct {
	GlobalRxBytes    int64 `json:"globalRxBytes"`
	GlobalTxBytes    int64 `json:"globalTxBytes"`
	GlobalRxSpeed    int64 `json:"globalRxSpeed"`    // bytes/sec
	GlobalTxSpeed    int64 `json:"globalTxSpeed"`    // bytes/sec
	GlobalRxLimit    int64 `json:"globalRxLimit"`    // 0=不限
	GlobalTxLimit    int64 `json:"globalTxLimit"`    // 0=不限
	ClientStats      map[string]*ClientBandwidthStats `json:"clientStats"`
}

// ClientBandwidthStats 客户端带宽统计
type ClientBandwidthStats struct {
	ClientID    string `json:"clientId"`
	ClientName  string `json:"clientName"`
	RxBytes     int64  `json:"rxBytes"`
	TxBytes     int64  `json:"txBytes"`
	RxSpeed     int64  `json:"rxSpeed"`
	TxSpeed     int64  `json:"txSpeed"`
	RxLimit     int64  `json:"rxLimit"`
	TxLimit     int64  `json:"txLimit"`
	DailyQuota  int64  `json:"dailyQuota"`
	UsedToday   int64  `json:"usedToday"`
	IsOnline    bool   `json:"isOnline"`
}

// BandwidthController 带宽管理器
type BandwidthController struct {
	mu sync.RWMutex

	// 全局限制
	globalRxLimit int64
	globalTxLimit int64

	// 全局计数器
	globalRxBytes int64
	globalTxBytes int64
	lastRxBytes   int64
	lastTxBytes   int64
	lastCalcTime  time.Time

	// 客户端限制
	clientLimits map[string]*ClientBandwidthLimit

	// 客户端统计
	clientStats map[string]*ClientBandwidthStats

	// 速率计算窗口
	speedWindow time.Duration
}

// NewBandwidthController 创建带宽管理器
func NewBandwidthController() *BandwidthController {
	return &BandwidthController{
		clientLimits: make(map[string]*ClientBandwidthLimit),
		clientStats:  make(map[string]*ClientBandwidthStats),
		speedWindow:  5 * time.Second,
		lastCalcTime: time.Now(),
	}
}

// SetGlobalLimit 设置全局带宽限制
func (bc *BandwidthController) SetGlobalLimit(rxLimit, txLimit int64) {
	bc.mu.Lock()
	defer bc.mu.Unlock()
	bc.globalRxLimit = rxLimit
	bc.globalTxLimit = txLimit
}

// GetGlobalLimit 获取全局带宽限制
func (bc *BandwidthController) GetGlobalLimit() (int64, int64) {
	bc.mu.RLock()
	defer bc.mu.RUnlock()
	return bc.globalRxLimit, bc.globalTxLimit
}

// SetClientLimit 设置客户端带宽限制
func (bc *BandwidthController) SetClientLimit(limit *ClientBandwidthLimit) {
	bc.mu.Lock()
	defer bc.mu.Unlock()
	bc.clientLimits[limit.ClientID] = limit

	// 同步到统计
	if stat, exists := bc.clientStats[limit.ClientID]; exists {
		stat.RxLimit = limit.RxLimit
		stat.TxLimit = limit.TxLimit
		stat.DailyQuota = limit.DailyQuota
	}
}

// GetClientLimit 获取客户端带宽限制
func (bc *BandwidthController) GetClientLimit(clientID string) *ClientBandwidthLimit {
	bc.mu.RLock()
	defer bc.mu.RUnlock()
	if limit, exists := bc.clientLimits[clientID]; exists {
		cp := *limit
		return &cp
	}
	return &ClientBandwidthLimit{ClientID: clientID}
}

// GetAllClientLimits 获取所有客户端带宽限制
func (bc *BandwidthController) GetAllClientLimits() []*ClientBandwidthLimit {
	bc.mu.RLock()
	defer bc.mu.RUnlock()
	result := make([]*ClientBandwidthLimit, 0, len(bc.clientLimits))
	for _, limit := range bc.clientLimits {
		cp := *limit
		result = append(result, &cp)
	}
	return result
}

// RecordBytes 记录流量
func (bc *BandwidthController) RecordBytes(clientID string, rxBytes, txBytes int64) {
	bc.mu.Lock()
	defer bc.mu.Unlock()

	atomic.AddInt64(&bc.globalRxBytes, rxBytes)
	atomic.AddInt64(&bc.globalTxBytes, txBytes)

	if stat, exists := bc.clientStats[clientID]; exists {
		atomic.AddInt64(&stat.RxBytes, rxBytes)
		atomic.AddInt64(&stat.TxBytes, txBytes)

		if limit, exists := bc.clientLimits[clientID]; exists {
			atomic.AddInt64(&limit.UsedToday, rxBytes+txBytes)
			stat.UsedToday = atomic.LoadInt64(&limit.UsedToday)
		}
	} else {
		bc.clientStats[clientID] = &ClientBandwidthStats{
			ClientID: clientID,
			RxBytes:  rxBytes,
			TxBytes:  txBytes,
			IsOnline: true,
		}
	}
}

// SetClientOnline 设置客户端在线状态
func (bc *BandwidthController) SetClientOnline(clientID, clientName string, online bool) {
	bc.mu.Lock()
	defer bc.mu.Unlock()

	if stat, exists := bc.clientStats[clientID]; exists {
		stat.IsOnline = online
		if clientName != "" {
			stat.ClientName = clientName
		}
	} else if online {
		bc.clientStats[clientID] = &ClientBandwidthStats{
			ClientID:   clientID,
			ClientName: clientName,
			IsOnline:   true,
		}
	}
}

// GetStats 获取带宽统计
func (bc *BandwidthController) GetStats() *BandwidthStats {
	bc.mu.Lock()
	defer bc.mu.Unlock()

	now := time.Now()
	elapsed := now.Sub(bc.lastCalcTime).Seconds()
	if elapsed < 0.1 {
		elapsed = 1
	}

	rxBytes := bc.globalRxBytes
	txBytes := bc.globalTxBytes

	stats := &BandwidthStats{
		GlobalRxBytes: rxBytes,
		GlobalTxBytes: txBytes,
		GlobalRxSpeed: int64(float64(rxBytes-bc.lastRxBytes) / elapsed),
		GlobalTxSpeed: int64(float64(txBytes-bc.lastTxBytes) / elapsed),
		GlobalRxLimit: bc.globalRxLimit,
		GlobalTxLimit: bc.globalTxLimit,
		ClientStats:   make(map[string]*ClientBandwidthStats),
	}

	// 复制客户端统计
	for id, stat := range bc.clientStats {
		cp := *stat
		// 计算速率
		if elapsed > 0 {
			cp.RxSpeed = int64(float64(stat.RxBytes) / elapsed)
			cp.TxSpeed = int64(float64(stat.TxBytes) / elapsed)
		}
		stats.ClientStats[id] = &cp
	}

	// 更新上次计算值
	bc.lastRxBytes = rxBytes
	bc.lastTxBytes = txBytes
	bc.lastCalcTime = now

	return stats
}

// ResetDailyQuota 重置每日配额（建议每天凌晨调用）
func (bc *BandwidthController) ResetDailyQuota() {
	bc.mu.Lock()
	defer bc.mu.Unlock()
	for _, limit := range bc.clientLimits {
		atomic.StoreInt64(&limit.UsedToday, 0)
	}
}

// Save 保存带宽配置（用于持久化）
func (bc *BandwidthController) Save() ([]byte, error) {
	bc.mu.RLock()
	defer bc.mu.RUnlock()

	data := struct {
		GlobalRxLimit int64                          `json:"globalRxLimit"`
		GlobalTxLimit int64                          `json:"globalTxLimit"`
		ClientLimits  map[string]*ClientBandwidthLimit `json:"clientLimits"`
	}{
		GlobalRxLimit: bc.globalRxLimit,
		GlobalTxLimit: bc.globalTxLimit,
		ClientLimits:  bc.clientLimits,
	}

	return json.Marshal(data)
}

// Load 加载带宽配置
func (bc *BandwidthController) Load(data []byte) error {
	bc.mu.Lock()
	defer bc.mu.Unlock()

	var loaded struct {
		GlobalRxLimit int64                          `json:"globalRxLimit"`
		GlobalTxLimit int64                          `json:"globalTxLimit"`
		ClientLimits  map[string]*ClientBandwidthLimit `json:"clientLimits"`
	}

	if err := json.Unmarshal(data, &loaded); err != nil {
		return err
	}

	bc.globalRxLimit = loaded.GlobalRxLimit
	bc.globalTxLimit = loaded.GlobalTxLimit
	if loaded.ClientLimits != nil {
		bc.clientLimits = loaded.ClientLimits
	}

	return nil
}
