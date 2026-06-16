#!/bin/bash
# ============================================================
# Go 项目国内加速脚本 - go-frp-panel
# 功能: 配置国内 GOPROXY 并下载所有依赖
# 用法: chmod +x setup_goproxy.sh && ./setup_goproxy.sh
# ============================================================

set -e

# --- 颜色输出 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "${CYAN}[STEP]${NC} $1"; }

# --- 可选 GOPROXY 列表 ---
# goproxy.cn    - 七牛云 CDN，国内最稳定
# goproxy.io    - 另一国内代理
# mirrors.aliyun.com/goproxy/ - 阿里云镜像
# proxy.golang.org,direct - Google 官方（国外）
GOPROXY_URL="${GOPROXY_URL:-https://goproxy.cn,direct}"

echo ""
echo "============================================"
echo "   Go 项目依赖一键加速下载"
echo "   项目: go-frp-panel"
echo "   代理: ${GOPROXY_URL}"
echo "============================================"
echo ""

# ---- 1. 检查 Go 是否安装 ----
log_step "1/5 检查 Go 环境..."
if ! command -v go &> /dev/null; then
    log_error "Go 未安装！请先安装 Go 1.23+"
    log_info "安装指引: https://go.dev/dl/  或  https://golang.google.cn/dl/"
    exit 1
fi

GO_VERSION=$(go version | awk '{print $3}')
log_info "已检测到: ${GO_VERSION}"

# ---- 2. 检查项目目录 ----
log_step "2/5 检查项目目录..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f "go.mod" ]; then
    log_error "未找到 go.mod，请在项目根目录执行此脚本"
    exit 1
fi

MODULE_NAME=$(grep -m1 "^module" go.mod | awk '{print $2}')
log_info "模块: ${MODULE_NAME}"
log_info "目录: ${SCRIPT_DIR}"

# ---- 3. 配置 GOPROXY ----
log_step "3/5 配置 GOPROXY..."
go env -w GOPROXY="${GOPROXY_URL}"
log_info "GOPROXY 已设置为: ${GOPROXY_URL}"

# 同时关闭校验和数据库的直连（国内有时连不上 sum.golang.org）
go env -w GONOSUMDB="*"
go env -w GONOSUMCHECK="*"
go env -w GOINSECURE=""
log_info "GONOSUMDB 已设置为: * (跳过公共校验和数据库)"

# 显示当前配置
echo ""
echo "当前 Go 环境配置:"
echo "  GOPROXY:     $(go env GOPROXY)"
echo "  GONOSUMDB:   $(go env GONOSUMDB)"
echo "  GOPATH:      $(go env GOPATH)"
echo "  GOMODCACHE:  $(go env GOMODCACHE)"
echo ""

# ---- 4. 下载依赖 ----
log_step "4/5 下载依赖 (go mod download)..."
echo ""

START_TIME=$(date +%s)

if go mod download 2>&1; then
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    echo ""
    log_info "依赖下载完成！耗时: ${ELAPSED}s"
else
    log_error "依赖下载失败！请检查网络或代理设置"
    exit 1
fi

# ---- 5. 验证 ----
log_step "5/5 验证依赖完整性..."
if go mod verify 2>&1; then
    log_info "依赖校验通过 ✓"
else
    log_warn "部分依赖校验未通过，可尝试重新下载"
fi

# ---- 完成 ----
echo ""
echo "============================================"
echo "   ✓ 全部完成！"
echo "============================================"
echo ""
echo "提示:"
echo "  - GOPROXY 已持久化到 Go 环境配置"
echo "  - 如需恢复默认:  go env -w GOPROXY='https://proxy.golang.org,direct'"
echo "  - 查看配置:      go env GOPROXY"
echo "  - 构建项目:      bash build.sh"
echo ""
