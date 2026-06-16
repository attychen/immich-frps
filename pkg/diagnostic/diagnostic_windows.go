//go:build windows

package diagnostic

func checkFileDescriptorsUnix() CheckItem {
	return CheckItem{Name: "文件描述符限制", Status: "warn", Message: "Windows 不适用", Value: "N/A"}
}

func checkDiskUnix() CheckItem {
	return CheckItem{Name: "磁盘使用率", Status: "warn", Message: "Windows 不支持", Value: "N/A"}
}
