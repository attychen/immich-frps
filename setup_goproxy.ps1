# ============================================================
# Go 项目国内加速脚本 (Windows PowerShell) - go-frp-panel
# 功能: 配置国内 GOPROXY 并下载所有依赖
# 用法: .\setup_goproxy.ps1
# ============================================================

$ErrorActionPreference = "Stop"

# --- 可选 GOPROXY ---
$GOPROXY_URL = if ($env:GOPROXY_URL) { $env:GOPROXY_URL } else { "https://goproxy.cn,direct" }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Go 项目依赖一键加速下载 (Windows)"
Write-Host "   项目: go-frp-panel"
Write-Host "   代理: $GOPROXY_URL"
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ---- 1. 检查 Go 是否安装 ----
Write-Host "[STEP] 1/5 检查 Go 环境..." -ForegroundColor Cyan
$goCmd = Get-Command go -ErrorAction SilentlyContinue
if (-not $goCmd) {
    Write-Host "[ERROR] Go 未安装！请先安装 Go 1.23+" -ForegroundColor Red
    Write-Host "[INFO]  国内下载: https://golang.google.cn/dl/" -ForegroundColor Green
    exit 1
}
$goVersion = & go version
Write-Host "[INFO]  已检测到: $goVersion" -ForegroundColor Green

# ---- 2. 检查项目目录 ----
Write-Host "[STEP] 2/5 检查项目目录..." -ForegroundColor Cyan
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

if (-not (Test-Path "go.mod")) {
    Write-Host "[ERROR] 未找到 go.mod，请在项目根目录执行此脚本" -ForegroundColor Red
    exit 1
}

$moduleName = (Select-String -Path "go.mod" -Pattern "^module" | Select-Object -First 1).Line.Split(" ")[1]
Write-Host "[INFO]  模块: $moduleName" -ForegroundColor Green
Write-Host "[INFO]  目录: $ScriptDir" -ForegroundColor Green

# ---- 3. 配置 GOPROXY ----
Write-Host "[STEP] 3/5 配置 GOPROXY..." -ForegroundColor Cyan
& go env -w GOPROXY="$GOPROXY_URL"
& go env -w GONOSUMDB="*"
& go env -w GONOSUMCHECK="*"

Write-Host "[INFO]  GOPROXY 已设置为: $GOPROXY_URL" -ForegroundColor Green
Write-Host ""

Write-Host "当前 Go 环境配置:"
Write-Host "  GOPROXY:     $(go env GOPROXY)"
Write-Host "  GONOSUMDB:   $(go env GONOSUMDB)"
Write-Host "  GOPATH:      $(go env GOPATH)"
Write-Host "  GOMODCACHE:  $(go env GOMODCACHE)"
Write-Host ""

# ---- 4. 下载依赖 ----
Write-Host "[STEP] 4/5 下载依赖 (go mod download)..." -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

$env:GOPROXY = $GOPROXY_URL
& go mod download
if ($LASTEXITCODE -eq 0) {
    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    Write-Host ""
    Write-Host "[INFO]  依赖下载完成！耗时: $($elapsed.ToString('F1'))s" -ForegroundColor Green
} else {
    Write-Host "[ERROR] 依赖下载失败！请检查网络或代理设置" -ForegroundColor Red
    exit 1
}

# ---- 5. 验证 ----
Write-Host "[STEP] 5/5 验证依赖完整性..." -ForegroundColor Cyan
& go mod verify
if ($LASTEXITCODE -eq 0) {
    Write-Host "[INFO]  依赖校验通过" -ForegroundColor Green
} else {
    Write-Host "[WARN]  部分依赖校验未通过，可尝试重新下载" -ForegroundColor Yellow
}

# ---- 完成 ----
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   全部完成！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "提示:"
Write-Host "  - GOPROXY 已持久化到 Go 环境配置"
Write-Host "  - 如需恢复默认:  go env -w GOPROXY='https://proxy.golang.org,direct'"
Write-Host "  - 查看配置:      go env GOPROXY"
Write-Host "  - 构建项目:      .\build.bat"
Write-Host ""
