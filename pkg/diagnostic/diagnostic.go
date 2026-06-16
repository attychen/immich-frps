package diagnostic

import (
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// CheckItem 单项检测结果
type CheckItem struct {
	Name    string `json:"name"`
	Status  string `json:"status"` // ok / warn / error
	Message string `json:"message"`
	Value   string `json:"value"`
}

// DiagnosticReport 诊断报告
type DiagnosticReport struct {
	Time     time.Time   `json:"time"`
	OS       string      `json:"os"`
	Arch     string      `json:"arch"`
	Hostname string      `json:"hostname"`
	Checks   []CheckItem `json:"checks"`
	Summary  string      `json:"summary"`
	Score    int         `json:"score"` // 0-100
}

// CheckBBR 检测 BBR 是否启用
func CheckBBR() CheckItem {
	if runtime.GOOS != "linux" {
		return CheckItem{Name: "BBR拥塞控制", Status: "warn", Message: "仅Linux支持", Value: "N/A"}
	}
	data, err := os.ReadFile("/proc/sys/net/ipv4/tcp_congestion_control")
	if err != nil {
		return CheckItem{Name: "BBR拥塞控制", Status: "error", Message: "无法读取", Value: err.Error()}
	}
	val := strings.TrimSpace(string(data))
	if val == "bbr" {
		return CheckItem{Name: "BBR拥塞控制", Status: "ok", Message: "BBR已启用", Value: val}
	}
	return CheckItem{Name: "BBR拥塞控制", Status: "warn", Message: "建议启用BBR", Value: val}
}

// CheckTCPFastOpen 检测 TCP Fast Open 状态
func CheckTCPFastOpen() CheckItem {
	if runtime.GOOS != "linux" {
		return CheckItem{Name: "TCP Fast Open", Status: "warn", Message: "仅Linux支持", Value: "N/A"}
	}
	data, err := os.ReadFile("/proc/sys/net/ipv4/tcp_fastopen")
	if err != nil {
		return CheckItem{Name: "TCP Fast Open", Status: "error", Message: "无法读取", Value: err.Error()}
	}
	val := strings.TrimSpace(string(data))
	v, _ := strconv.Atoi(val)
	if v >= 3 {
		return CheckItem{Name: "TCP Fast Open", Status: "ok", Message: "已启用(客户端+服务端)", Value: val}
	}
	if v == 1 {
		return CheckItem{Name: "TCP Fast Open", Status: "warn", Message: "仅客户端启用，建议设为3", Value: val}
	}
	return CheckItem{Name: "TCP Fast Open", Status: "warn", Message: "未启用，建议设为3", Value: val}
}

// CheckFileDescriptors 检测文件描述符限制
func CheckFileDescriptors() CheckItem {
	var rlim syscall.Rlimit
	if err := syscall.Getrlimit(syscall.RLIMIT_NOFILE, &rlim); err != nil {
		return CheckItem{Name: "文件描述符限制", Status: "error", Message: "无法获取", Value: err.Error()}
	}
	val := fmt.Sprintf("soft=%d hard=%d", rlim.Cur, rlim.Max)
	if rlim.Cur >= 65535 {
		return CheckItem{Name: "文件描述符限制", Status: "ok", Message: "限制充足", Value: val}
	}
	if rlim.Cur >= 10000 {
		return CheckItem{Name: "文件描述符限制", Status: "warn", Message: "建议提升到65535+", Value: val}
	}
	return CheckItem{Name: "文件描述符限制", Status: "warn", Message: "限制过低，可能影响并发", Value: val}
}

// CheckPorts 检测端口可用性
func CheckPorts(ports []int) CheckItem {
	var unavailable []string
	for _, port := range ports {
		if !isPortAvailable(port) {
			unavailable = append(unavailable, strconv.Itoa(port))
		}
	}
	if len(unavailable) == 0 {
		return CheckItem{Name: "端口可用性", Status: "ok", Message: "所有端口可用",
			Value: fmt.Sprintf("检测%d个端口均可用", len(ports))}
	}
	return CheckItem{Name: "端口可用性", Status: "error", Message: "部分端口被占用",
		Value: strings.Join(unavailable, ", ")}
}

// CheckMemory 检测内存使用率（读取 /proc/meminfo）
func CheckMemory() CheckItem {
	data, err := os.ReadFile("/proc/meminfo")
	if err != nil {
		return CheckItem{Name: "内存使用率", Status: "error", Message: "无法读取 /proc/meminfo", Value: err.Error()}
	}
	total := extractMemValue(data, "MemTotal")
	avail := extractMemValue(data, "MemAvailable")
	if total == 0 {
		return CheckItem{Name: "内存使用率", Status: "error", Message: "无法解析内存信息", Value: ""}
	}
	used := total - avail
	percent := float64(used) / float64(total) * 100
	val := fmt.Sprintf("%.1f%% (已用%.0fMB/总量%.0fMB)", percent, float64(used)/1024, float64(total)/1024)
	if percent < 80 {
		return CheckItem{Name: "内存使用率", Status: "ok", Message: "正常", Value: val}
	}
	if percent < 95 {
		return CheckItem{Name: "内存使用率", Status: "warn", Message: "偏高", Value: val}
	}
	return CheckItem{Name: "内存使用率", Status: "error", Message: "严重不足", Value: val}
}

// CheckDisk 检测磁盘使用率（使用 syscall.Statfs）
func CheckDisk() CheckItem {
	var stat syscall.Statfs_t
	if err := syscall.Statfs("/", &stat); err != nil {
		return CheckItem{Name: "磁盘使用率", Status: "error", Message: "无法获取", Value: err.Error()}
	}
	total := stat.Blocks * uint64(stat.Bsize)
	avail := stat.Bavail * uint64(stat.Bsize)
	used := total - avail
	percent := float64(used) / float64(total) * 100
	val := fmt.Sprintf("%.1f%% (已用%.0fGB/总量%.0fGB)", percent,
		float64(used)/1024/1024/1024, float64(total)/1024/1024/1024)
	if percent < 80 {
		return CheckItem{Name: "磁盘使用率", Status: "ok", Message: "正常", Value: val}
	}
	if percent < 95 {
		return CheckItem{Name: "磁盘使用率", Status: "warn", Message: "偏高", Value: val}
	}
	return CheckItem{Name: "磁盘使用率", Status: "error", Message: "磁盘空间不足", Value: val}
}

// CheckCPU 检测 CPU 使用率（简单采样 /proc/stat）
func CheckCPU() CheckItem {
	usage := sampleCPU(300 * time.Millisecond)
	val := fmt.Sprintf("%.1f%%", usage)
	if usage < 70 {
		return CheckItem{Name: "CPU使用率", Status: "ok", Message: "正常", Value: val}
	}
	if usage < 90 {
		return CheckItem{Name: "CPU使用率", Status: "warn", Message: "偏高", Value: val}
	}
	return CheckItem{Name: "CPU使用率", Status: "error", Message: "负载过高", Value: val}
}

// RunDiagnostic 运行完整诊断
func RunDiagnostic(ports []int) *DiagnosticReport {
	hostname, _ := os.Hostname()
	report := &DiagnosticReport{
		Time:     time.Now(),
		OS:       runtime.GOOS,
		Arch:     runtime.GOARCH,
		Hostname: hostname,
	}

	if len(ports) == 0 {
		ports = []int{7000, 7500, 80, 443, 8080}
	}

	report.Checks = []CheckItem{
		CheckBBR(),
		CheckTCPFastOpen(),
		CheckFileDescriptors(),
		CheckMemory(),
		CheckDisk(),
		CheckCPU(),
		CheckPorts(ports),
	}

	okCount := 0
	for _, c := range report.Checks {
		if c.Status == "ok" {
			okCount++
		}
	}
	report.Score = okCount * 100 / len(report.Checks)

	switch {
	case report.Score >= 80:
		report.Summary = "系统状态良好，优化配置可正常运行"
	case report.Score >= 50:
		report.Summary = "系统存在部分问题，建议根据检查项进行优化"
	default:
		report.Summary = "系统存在较多问题，请优先处理 error 级别的检查项"
	}

	return report
}

// ─── internal helpers ───

func extractMemValue(data []byte, key string) int {
	re := regexp.MustCompile(key + `:\s+(\d+)\s+kB`)
	matches := re.FindStringSubmatch(string(data))
	if len(matches) >= 2 {
		v, _ := strconv.Atoi(matches[1])
		return v
	}
	return 0
}

// ponytail: simple /proc/stat sampling, adequate for monitoring dashboard
func sampleCPU(wait time.Duration) float64 {
	readCPU := func() (uint64, uint64) {
		data, err := os.ReadFile("/proc/stat")
		if err != nil {
			return 0, 0
		}
		re := regexp.MustCompile(`cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)`)
		matches := re.FindStringSubmatch(string(data))
		if len(matches) < 5 {
			return 0, 0
		}
		var total, idle uint64
		for i := 1; i <= 4; i++ {
			v, _ := strconv.ParseUint(matches[i], 10, 64)
			total += v
			if i == 4 {
				idle = v
			}
		}
		return total, idle
	}

	t1, i1 := readCPU()
	time.Sleep(wait)
	t2, i2 := readCPU()

	if t2 == t1 || t2 == 0 {
		return 0
	}
	return float64((t2-t1)-(i2-i1)) / float64(t2-t1) * 100
}

// ponytail: use `ss` command for port check, simple and effective
func isPortAvailable(port int) bool {
	cmd := exec.Command("ss", "-tln", fmt.Sprintf("sport = :%d", port))
	out, _ := cmd.CombinedOutput()
	return len(strings.TrimSpace(string(out))) == 0
}
