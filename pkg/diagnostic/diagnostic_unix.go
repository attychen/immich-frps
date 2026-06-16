//go:build !windows

package diagnostic

import (
	"fmt"

	"golang.org/x/sys/unix"
)

func checkFileDescriptorsUnix() CheckItem {
	var rlim unix.Rlimit
	if err := unix.Getrlimit(unix.RLIMIT_NOFILE, &rlim); err != nil {
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

func checkDiskUnix() CheckItem {
	var stat unix.Statfs_t
	if err := unix.Statfs("/", &stat); err != nil {
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
