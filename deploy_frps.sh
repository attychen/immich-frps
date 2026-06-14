#!/bin/bash
# ============================================================
# frps 一键部署脚本 (交互式菜单)
# 版本: 0.69.1 | 架构: 自动检测 | 内存: 自适应
# 兼容: Debian 10/11/12, Ubuntu 20.04/22.04/24.04
# 作者: Ac.All.Sh (Github)
# ============================================================

if [ -z "$BASH_VERSION" ]; then
    exec /bin/bash "$0" "$@"
fi

set -e

# ===================== 配置变量 =====================
FRPS_VERSION="0.69.1"
FRPS_CONFIG_DIR="/etc/frp"
FRPS_LOG_DIR="/var/log/frp"
FRPS_BIN="/usr/local/bin/frps"
SYSCTL_CONF="/etc/sysctl.d/99-frps-optimize.conf"

# 默认配置
DEFAULT_BIND_PORT=7000
DEFAULT_DASHBOARD_PORT=7500
DEFAULT_DASHBOARD_USER="admin"
DEFAULT_DASHBOARD_PASS="admin123"
DEFAULT_AUTH_TOKEN="your_frp_token_here"
DEFAULT_VHOST_HTTP_PORT=8080
DEFAULT_VHOST_HTTPS_PORT=8443

# ===================== 颜色定义 =====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ===================== 工具函数 =====================
info()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; }
title()   { echo -e "${CYAN}${BOLD}$1${NC}"; }
hint()    { echo -e "${MAGENTA}  → $1${NC}"; }

clear_screen() {
    clear
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║           frps 一键部署脚本 v${FRPS_VERSION}                  ║"
    echo "  ║           动态自适应 | 内存优化 | 100GB传输              ║"
    echo "  ║           Author: Ac.All.Sh (Github)                    ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_line() {
    echo -e "${CYAN}  ──────────────────────────────────────────────────────────${NC}"
}

print_config() {
    local label=$1
    local value=$2
    local default=$3
    if [ "$value" = "$default" ]; then
        printf "  %-20s ${GREEN}%-25s${NC} (默认)\n" "$label:" "$value"
    else
        printf "  %-20s ${YELLOW}%-25s${NC} (已修改)\n" "$label:" "$value"
    fi
}

# ===================== 默认配置 =====================
BIND_PORT=$DEFAULT_BIND_PORT
DASHBOARD_PORT=$DEFAULT_DASHBOARD_PORT
DASHBOARD_USER=$DEFAULT_DASHBOARD_USER
DASHBOARD_PASS=$DEFAULT_DASHBOARD_PASS
AUTH_TOKEN=$DEFAULT_AUTH_TOKEN
VHOST_HTTP_PORT=$DEFAULT_VHOST_HTTP_PORT
VHOST_HTTPS_PORT=$DEFAULT_VHOST_HTTPS_PORT
TRANSFER_SIZE="10GB"
DEFAULT_TRANSFER_SIZE="10GB"

# ===================== 检查环境 =====================
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "请使用 root 用户运行此脚本"
        echo ""
        hint "执行: sudo bash $0"
        exit 1
    fi
}

detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)   echo "amd64" ;;
        aarch64|arm64)  echo "arm64" ;;
        armv7l|armhf)   echo "arm"   ;;
        *) echo "amd64" ;;
    esac
}

detect_memory_mb() {
    awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo
}

detect_cpu_cores() {
    nproc
}

# ===================== 清理旧安装 =====================
cleanup_old_install() {
    info "清理旧的 frps 安装..."
    systemctl stop frps 2>/dev/null || true
    systemctl disable frps 2>/dev/null || true
    rm -f /etc/systemd/system/frps.service
    systemctl daemon-reload 2>/dev/null || true
    rm -f "$FRPS_CONFIG_DIR/frps.toml"
    rm -f "$FRPS_CONFIG_DIR/frps.toml.backup"
    rm -f /etc/sysctl.d/99-100gb-upload-optimize.conf
    rm -f /etc/sysctl.d/99-frps-large-upload.conf
    rm -f /etc/sysctl.d/99-network-optimization.conf
    rm -f "$SYSCTL_CONF"
    sed -i '/# frps 大文件传输优化/,/root hard nofile 1048576/d' /etc/security/limits.conf 2>/dev/null || true
    local nic
    nic=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')
    if [ -n "$nic" ]; then
        tc qdisc del dev "$nic" root 2>/dev/null || true
        tc qdisc del dev "$nic" ingress 2>/dev/null || true
    fi
    tc qdisc del dev ifb0 root 2>/dev/null || true
}

# ===================== 安装依赖 =====================
install_deps() {
    info "检查并安装依赖..."
    if command -v apt-get &>/dev/null; then
        apt-get update -qq
        apt-get install -y -qq curl tar > /dev/null 2>&1
    elif command -v yum &>/dev/null; then
        yum install -y -q curl tar > /dev/null 2>&1
    elif command -v dnf &>/dev/null; then
        dnf install -y -q curl tar > /dev/null 2>&1
    fi
}

# ===================== 下载安装 frps =====================
install_frps() {
    local version="$1"
    local arch="$2"
    local url="https://github.com/fatedier/frp/releases/download/v${version}/frp_${version}_linux_${arch}.tar.gz"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    info "下载 frps ${version}..."
    if ! curl -fsSL --connect-timeout 30 --retry 3 -o "$tmp_dir/frp.tar.gz" "$url"; then
        rm -rf "$tmp_dir"
        error "下载失败"
        exit 1
    fi
    tar -xzf "$tmp_dir/frp.tar.gz" -C "$tmp_dir"
    cp "$tmp_dir/frp_${version}_linux_${arch}/frps" "$FRPS_BIN"
    chmod +x "$FRPS_BIN"
    rm -rf "$tmp_dir"
}

# ===================== 获取传输大小对应的 GB 数 =====================
get_transfer_gb() {
    local size="$1"
    case "$size" in
        *GB|*gb) echo "${size%GB}" | sed 's/gb//' ;;
        *TB|*tb) echo $((${size%TB} * 1024)) | sed 's/tb//' ;;
        *) echo "10" ;;
    esac
}

# ===================== 写入 sysctl 配置 =====================
apply_sysctl() {
    local mem_mb=$1
    local cpu_cores=$2
    local transfer_gb=$(get_transfer_gb "$TRANSFER_SIZE")

    # 根据内存和传输大小计算参数
    if [ "$mem_mb" -le 1024 ]; then
        TCP_RMEM="4096 87380 4194304"
        TCP_WMEM="4096 65536 4194304"
        TCP_MEM_PRESSURE=262144
        TCP_MEM_LIMIT=524288
        TCP_MEM_MAX=1048576
        CONN_BACKLOG=16384
        NETDEV_BACKLOG=16384
        RMEM_MAX=4194304
        WMEM_MAX=4194304
        RMEM_DEFAULT=524288
        WMEM_DEFAULT=524288
        SOMAXCONN=32768
        MAX_ORPHANS=65536
        POOL_COUNT=200
    elif [ "$mem_mb" -le 2048 ]; then
        TCP_RMEM="4096 87380 16777216"
        TCP_WMEM="4096 65536 16777216"
        TCP_MEM_PRESSURE=524288
        TCP_MEM_LIMIT=1048576
        TCP_MEM_MAX=2097152
        CONN_BACKLOG=32768
        NETDEV_BACKLOG=32768
        RMEM_MAX=16777216
        WMEM_MAX=16777216
        RMEM_DEFAULT=1048576
        WMEM_DEFAULT=1048576
        SOMAXCONN=49152
        MAX_ORPHANS=131072
        POOL_COUNT=500
    elif [ "$mem_mb" -le 4096 ]; then
        TCP_RMEM="4096 87380 33554432"
        TCP_WMEM="4096 65536 33554432"
        TCP_MEM_PRESSURE=786432
        TCP_MEM_LIMIT=1572864
        TCP_MEM_MAX=3145728
        CONN_BACKLOG=49152
        NETDEV_BACKLOG=49152
        RMEM_MAX=33554432
        WMEM_MAX=33554432
        RMEM_DEFAULT=2097152
        WMEM_DEFAULT=2097152
        SOMAXCONN=65535
        MAX_ORPHANS=262144
        POOL_COUNT=1000
    else
        TCP_RMEM="4096 1048576 67108864"
        TCP_WMEM="4096 1048576 67108864"
        TCP_MEM_PRESSURE=786432
        TCP_MEM_LIMIT=1048576
        TCP_MEM_MAX=2097152
        CONN_BACKLOG=65536
        NETDEV_BACKLOG=65536
        RMEM_MAX=67108864
        WMEM_MAX=67108864
        RMEM_DEFAULT=2097152
        WMEM_DEFAULT=2097152
        SOMAXCONN=65535
        MAX_ORPHANS=524288
        POOL_COUNT=2000
    fi

    # 根据传输大小调整参数
    if [ "$transfer_gb" -ge 100 ]; then
        # 100GB: 最大优化
        MAX_ORPHANS=524288
        TCP_RETRIES=20
        TCP_KEEPALIVE=20
    elif [ "$transfer_gb" -ge 50 ]; then
        # 50GB: 深度优化
        MAX_ORPHANS=262144
        TCP_RETRIES=15
        TCP_KEEPALIVE=30
    elif [ "$transfer_gb" -ge 10 ]; then
        # 10GB: 适中优化
        MAX_ORPHANS=131072
        TCP_RETRIES=12
        TCP_KEEPALIVE=60
    elif [ "$transfer_gb" -ge 5 ]; then
        # 5GB: 轻度优化
        MAX_ORPHANS=65536
        TCP_RETRIES=10
        TCP_KEEPALIVE=60
    else
        # 1GB: 默认
        MAX_ORPHANS=32768
        TCP_RETRIES=8
        TCP_KEEPALIVE=120
    fi

    mkdir -p /etc/sysctl.d

    cat > "$SYSCTL_CONF" << SYSCTLCONF
# frps 网络优化 - 传输大小: ${TRANSFER_SIZE}
net.ipv4.tcp_rmem = ${TCP_RMEM}
net.ipv4.tcp_wmem = ${TCP_WMEM}
net.ipv4.tcp_mem = ${TCP_MEM_PRESSURE} ${TCP_MEM_LIMIT} ${TCP_MEM_MAX}
net.ipv4.udp_mem = ${TCP_MEM_PRESSURE} ${TCP_MEM_LIMIT} ${TCP_MEM_MAX}
net.core.somaxconn = ${SOMAXCONN}
net.ipv4.tcp_max_syn_backlog = ${CONN_BACKLOG}
net.core.netdev_max_backlog = ${NETDEV_BACKLOG}
net.core.rmem_max = ${RMEM_MAX}
net.core.wmem_max = ${WMEM_MAX}
net.core.rmem_default = ${RMEM_DEFAULT}
net.core.wmem_default = ${WMEM_DEFAULT}
net.ipv4.tcp_keepalive_time = ${TCP_KEEPALIVE}
net.ipv4.tcp_keepalive_intvl = 5
net.ipv4.tcp_keepalive_probes = 9
net.ipv4.tcp_retries2 = ${TCP_RETRIES}
net.ipv4.tcp_syn_retries = 5
net.ipv4.tcp_synack_retries = 5
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_max_orphans = ${MAX_ORPHANS}
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
SYSCTLCONF

    sysctl --system > /dev/null 2>&1
}

# ===================== 写入 frps 配置 =====================
write_frps_config() {
    mkdir -p "$FRPS_CONFIG_DIR"
    mkdir -p "$FRPS_LOG_DIR"

    cat > "$FRPS_CONFIG_DIR/frps.toml" << FRPSCONFIG
bindPort = ${BIND_PORT}
auth.method = "token"
auth.token = "${AUTH_TOKEN}"
webServer.addr = "0.0.0.0"
webServer.port = ${DASHBOARD_PORT}
webServer.user = "${DASHBOARD_USER}"
webServer.password = "${DASHBOARD_PASS}"
transport.maxPoolCount = ${POOL_COUNT}
transport.tcpMux = true
transport.tcpMuxKeepaliveInterval = 30
transport.tcpKeepAlive = 15
vhostHTTPPort = ${VHOST_HTTP_PORT}
vhostHTTPSPort = ${VHOST_HTTPS_PORT}
log.to = "/var/log/frp/frps.log"
log.level = "info"
log.maxDays = 30
FRPSCONFIG
}

# ===================== 创建 systemd 服务 =====================
create_service() {
    cat > /etc/systemd/system/frps.service << 'EOF'
[Unit]
Description=frps service
Documentation=https://github.com/fatedier/frp
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/frps -c /etc/frp/frps.toml
Restart=on-failure
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
}

# ===================== 获取公网 IP =====================
get_public_ip() {
    curl -s4 --connect-timeout 5 https://ifconfig.me 2>/dev/null \
        || curl -s4 --connect-timeout 5 https://api.ip.sb/ip 2>/dev/null \
        || echo "请手动替换为服务器IP"
}

# ===================== 菜单: 选择传输大小 =====================
menu_transfer_size() {
    clear_screen
    title "  选择文件传输大小"
    print_line
    echo ""
    echo -e "  选择您需要传输的文件大小, 脚本会自动优化网络参数"
    echo ""
    echo -e "  ${BOLD}[1]${NC} ${GREEN}1GB${NC}    - 小文件传输 (轻量优化)"
    echo -e "  ${BOLD}[2]${NC} ${GREEN}5GB${NC}    - 中等文件 (适中优化)"
    echo -e "  ${BOLD}[3]${NC} ${GREEN}10GB${NC}   - 大文件传输 (默认, 推荐)"
    echo -e "  ${BOLD}[4]${NC} ${GREEN}50GB${NC}   - 超大文件 (深度优化)"
    echo -e "  ${BOLD}[5]${NC} ${GREEN}100GB${NC}  - 极限传输 (最大优化)"
    echo -e "  ${BOLD}[6]${NC} ${GREEN}自定义${NC} - 手动输入大小"
    echo -e "  ${BOLD}[0]${NC} 返回主菜单"
    echo ""
    print_line

    read -p "  请选择 [0-6]: " choice
    case $choice in
        1) TRANSFER_SIZE="1GB"; info "已选择: 1GB"; sleep 1; menu_config ;;
        2) TRANSFER_SIZE="5GB"; info "已选择: 5GB"; sleep 1; menu_config ;;
        3) TRANSFER_SIZE="10GB"; info "已选择: 10GB"; sleep 1; menu_config ;;
        4) TRANSFER_SIZE="50GB"; info "已选择: 50GB"; sleep 1; menu_config ;;
        5) TRANSFER_SIZE="100GB"; info "已选择: 100GB"; sleep 1; menu_config ;;
        6)
            read -p "  输入传输大小 (例如: 20GB): " val
            if [ -n "$val" ]; then
                TRANSFER_SIZE="$val"
                info "已选择: $val"
                sleep 1
            fi
            menu_config
            ;;
        0) menu_main ;;
        *) menu_transfer_size ;;
    esac
}

# ===================== 菜单: 修改配置 =====================
menu_config() {
    clear_screen
    title "  修改部署配置"
    print_line
    echo ""
    print_config "frps 监听端口" "$BIND_PORT" "$DEFAULT_BIND_PORT"
    print_config "Dashboard 端口" "$DASHBOARD_PORT" "$DEFAULT_DASHBOARD_PORT"
    print_config "Dashboard 用户" "$DASHBOARD_USER" "$DEFAULT_DASHBOARD_USER"
    print_config "Dashboard 密码" "$DASHBOARD_PASS" "$DEFAULT_DASHBOARD_PASS"
    print_config "认证 Token" "$AUTH_TOKEN" "$DEFAULT_AUTH_TOKEN"
    print_config "HTTP 代理端口" "$VHOST_HTTP_PORT" "$DEFAULT_VHOST_HTTP_PORT"
    print_config "HTTPS 代理端口" "$VHOST_HTTPS_PORT" "$DEFAULT_VHOST_HTTPS_PORT"
    print_config "传输大小" "$TRANSFER_SIZE" "$DEFAULT_TRANSFER_SIZE"
    echo ""
    print_line
    echo ""
    echo -e "  ${BOLD}[1]${NC} 修改 frps 监听端口"
    echo -e "  ${BOLD}[2]${NC} 修改 Dashboard 端口"
    echo -e "  ${BOLD}[3]${NC} 修改 Dashboard 用户名"
    echo -e "  ${BOLD}[4]${NC} 修改 Dashboard 密码"
    echo -e "  ${BOLD}[5]${NC} 修改认证 Token"
    echo -e "  ${BOLD}[6]${NC} 修改 HTTP 代理端口"
    echo -e "  ${BOLD}[7]${NC} 修改 HTTPS 代理端口"
    echo -e "  ${BOLD}[8]${NC} ${MAGENTA}选择传输大小${NC} (当前: $TRANSFER_SIZE)"
    echo -e "  ${BOLD}[0]${NC} 返回主菜单"
    echo ""
    print_line

    read -p "  请选择 [0-8]: " choice
    case $choice in
        1)
            read -p "  输入 frps 监听端口 (当前: $BIND_PORT): " val
            [ -n "$val" ] && BIND_PORT=$val
            menu_config
            ;;
        2)
            read -p "  输入 Dashboard 端口 (当前: $DASHBOARD_PORT): " val
            [ -n "$val" ] && DASHBOARD_PORT=$val
            menu_config
            ;;
        3)
            read -p "  输入 Dashboard 用户名 (当前: $DASHBOARD_USER): " val
            [ -n "$val" ] && DASHBOARD_USER=$val
            menu_config
            ;;
        4)
            read -p "  输入 Dashboard 密码 (当前: $DASHBOARD_PASS): " val
            [ -n "$val" ] && DASHBOARD_PASS=$val
            menu_config
            ;;
        5)
            read -p "  输入认证 Token (当前: $AUTH_TOKEN): " val
            [ -n "$val" ] && AUTH_TOKEN=$val
            menu_config
            ;;
        6)
            read -p "  输入 HTTP 代理端口 (当前: $VHOST_HTTP_PORT): " val
            [ -n "$val" ] && VHOST_HTTP_PORT=$val
            menu_config
            ;;
        7)
            read -p "  输入 HTTPS 代理端口 (当前: $VHOST_HTTPS_PORT): " val
            [ -n "$val" ] && VHOST_HTTPS_PORT=$val
            menu_config
            ;;
        8)
            menu_transfer_size
            ;;
        0|*)
            menu_main
            ;;
    esac
}

# ===================== 菜单: 主菜单 =====================
menu_main() {
    clear_screen

    local arch=$(detect_arch)
    local mem_mb=$(detect_memory_mb)
    local cpu_cores=$(detect_cpu_cores)

    echo -e "  ${BOLD}系统信息${NC}"
    echo -e "  架构: ${GREEN}${arch}${NC} | 内存: ${GREEN}${mem_mb}MB${NC} | CPU: ${GREEN}${cpu_cores}核${NC}"
    echo -e "  传输大小: ${MAGENTA}${TRANSFER_SIZE}${NC}"
    echo ""
    print_line
    echo ""
    echo -e "  ${BOLD}[1]${NC} ${GREEN}一键部署 frps${NC}"
    echo -e "      使用当前配置部署 frps 服务端"
    echo ""
    echo -e "  ${BOLD}[2]${NC} ${YELLOW}修改配置${NC}"
    echo -e "      修改端口、用户名、密码、Token 等"
    echo ""
    echo -e "  ${BOLD}[3]${NC} ${CYAN}查看配置${NC}"
    echo -e "      查看当前所有配置项"
    echo ""
    echo -e "  ${BOLD}[4]${NC} ${MAGENTA}管理服务${NC}"
    echo -e "      启动/停止/重启/状态/日志"
    echo ""
    echo -e "  ${BOLD}[5]${NC} ${BLUE}生成 frpc 配置${NC}"
    echo -e "      生成客户端配置文件, 支持所有协议"
    echo ""
    echo -e "  ${BOLD}[6]${NC} ${RED}卸载 frps${NC}"
    echo -e "      清除所有 frps 相关配置"
    echo ""
    echo -e "  ${BOLD}[0]${NC} 退出脚本"
    echo ""
    print_line

    read -p "  请选择 [0-6]: " choice
    case $choice in
        1) menu_deploy ;;
        2) menu_config ;;
        3) menu_show_config ;;
        4) menu_service ;;
        5) menu_generate_frpc ;;
        6) menu_uninstall ;;
        0) echo ""; info "退出脚本"; exit 0 ;;
        *) menu_main ;;
    esac
}

# ===================== 菜单: 查看配置 =====================
menu_show_config() {
    clear_screen
    title "  当前配置"
    print_line
    echo ""
    print_config "frps 监听端口" "$BIND_PORT" "$DEFAULT_BIND_PORT"
    print_config "Dashboard 端口" "$DASHBOARD_PORT" "$DEFAULT_DASHBOARD_PORT"
    print_config "Dashboard 用户" "$DASHBOARD_USER" "$DEFAULT_DASHBOARD_USER"
    print_config "Dashboard 密码" "$DASHBOARD_PASS" "$DEFAULT_DASHBOARD_PASS"
    print_config "认证 Token" "$AUTH_TOKEN" "$DEFAULT_AUTH_TOKEN"
    print_config "HTTP 代理端口" "$VHOST_HTTP_PORT" "$DEFAULT_VHOST_HTTP_PORT"
    print_config "HTTPS 代理端口" "$VHOST_HTTPS_PORT" "$DEFAULT_VHOST_HTTPS_PORT"
    print_config "传输大小" "$TRANSFER_SIZE" "$DEFAULT_TRANSFER_SIZE"
    echo ""
    print_line
    echo ""
    echo -e "  ${BOLD}frpc 配置示例${NC}"
    echo ""

    local public_ip=$(get_public_ip)
    cat << FRPCDEMO
  serverAddr = "${public_ip}"
  serverPort = ${BIND_PORT}
  auth.method = "token"
  auth.token = "${AUTH_TOKEN}"
  transport.poolCount = 10
  transport.tcpMux = true
  transport.heartbeatInterval = 10
  transport.heartbeatTimeout = 300
  log.to = "/var/log/frp/frpc.log"
  log.level = "info"

  [[proxies]]
  name = "ssh"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 22
  remotePort = 6000

  [[proxies]]
  name = "immich-web"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 2283
  remotePort = 20080
FRPCDEMO
    echo ""
    print_line
    echo ""
    read -p "  按回车返回主菜单..."
    menu_main
}

# ===================== 菜单: 管理服务 =====================
menu_service() {
    clear_screen
    title "  管理 frps 服务"
    print_line
    echo ""

    if systemctl is-active --quiet frps 2>/dev/null; then
        echo -e "  状态: ${GREEN}● 运行中${NC}"
    else
        echo -e "  状态: ${RED}○ 已停止${NC}"
    fi
    echo ""
    echo -e "  ${BOLD}[1]${NC} 启动服务"
    echo -e "  ${BOLD}[2]${NC} 停止服务"
    echo -e "  ${BOLD}[3]${NC} 重启服务"
    echo -e "  ${BOLD}[4]${NC} 查看状态"
    echo -e "  ${BOLD}[5]${NC} 查看日志 (实时)"
    echo -e "  ${BOLD}[0]${NC} 返回主菜单"
    echo ""
    print_line

    read -p "  请选择 [0-5]: " choice
    case $choice in
        1) systemctl start frps; info "服务已启动"; sleep 1; menu_service ;;
        2) systemctl stop frps; info "服务已停止"; sleep 1; menu_service ;;
        3) systemctl restart frps; info "服务已重启"; sleep 1; menu_service ;;
        4) systemctl status frps; echo ""; read -p "  按回车返回..."; menu_service ;;
        5) journalctl -u frps -f --no-pager ;;
        0) menu_main ;;
        *) menu_service ;;
    esac
}

# ===================== 菜单: 生成 frpc 配置 =====================
menu_generate_frpc() {
    clear_screen
    title "  生成 frpc 配置"
    print_line
    echo ""
    echo -e "  ${BOLD}[1]${NC} ${GREEN}基础配置${NC} - SSH + Web 代理"
    echo -e "  ${BOLD}[2]${NC} ${GREEN}immich 配置${NC} - 完整 immich 代理"
    echo -e "  ${BOLD}[3]${NC} ${GREEN}全协议模板${NC} - 所有支持的协议"
    echo -e "  ${BOLD}[4]${NC} ${GREEN}Docker 部署${NC} - frpc Docker 命令"
    echo -e "  ${BOLD}[0]${NC} 返回主菜单"
    echo ""
    print_line

    read -p "  请选择 [0-4]: " choice
    case $choice in
        1) frpc_generate_basic ;;
        2) frpc_generate_immich ;;
        3) frpc_generate_all ;;
        4) frpc_generate_docker ;;
        0) menu_main ;;
        *) menu_generate_frpc ;;
    esac
}

# ===================== frpc 生成: 基础配置 =====================
frpc_generate_basic() {
    clear_screen
    title "  frpc 基础配置"
    print_line

    local public_ip=$(get_public_ip)

    cat << FRPCEOF

  # ============================================
  # frpc 基础配置 - 保存为 /etc/frp/frpc.toml
  # ============================================

  serverAddr = "${public_ip}"
  serverPort = ${BIND_PORT}
  auth.method = "token"
  auth.token = "${AUTH_TOKEN}"

  transport.poolCount = 10
  transport.tcpMux = true
  transport.heartbeatInterval = 10
  transport.heartbeatTimeout = 300

  log.to = "/var/log/frp/frpc.log"
  log.level = "info"
  log.maxDays = 30

  # ============================================
  # 代理配置示例
  # ============================================

  # SSH 远程连接
  [[proxies]]
  name = "ssh"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 22
  remotePort = 6000

  # Web 服务
  [[proxies]]
  name = "web"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 80
  remotePort = 8000

  # HTTPS 服务
  [[proxies]]
  name = "https"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 443
  remotePort = 8443

FRPCEOF

    echo ""
    print_line
    echo ""
    echo -e "  ${BOLD}一键部署命令:${NC}"
    echo ""
    echo "  # 1. 安装 frpc"
    echo "  wget -qO- https://github.com/fatedier/frp/releases/download/v${FRPS_VERSION}/frp_${FRPS_VERSION}_linux_\$(uname -m).tar.gz | tar xz -C /tmp"
    echo "  cp /tmp/frp_${FRPS_VERSION}_linux_\$(uname -m)/frpc /usr/local/bin/"
    echo ""
    echo "  # 2. 保存配置"
    echo "  mkdir -p /etc/frp /var/log/frp"
    echo "  # 将上面的配置保存为 /etc/frp/frpc.toml"
    echo ""
    echo "  # 3. 启动 frpc"
    echo "  nohup frpc -c /etc/frp/frpc.toml > /dev/null 2>&1 &"
    echo ""
    print_line
    echo ""
    read -p "  按回车返回..."
    menu_generate_frpc
}

# ===================== frpc 生成: immich 配置 =====================
frpc_generate_immich() {
    clear_screen
    title "  frpc immich 配置"
    print_line

    local public_ip=$(get_public_ip)

    cat << FRPCEOF

  # ============================================
  # frpc immich 完整配置 - 保存为 /etc/frp/frpc.toml
  # ============================================

  serverAddr = "${public_ip}"
  serverPort = ${BIND_PORT}
  auth.method = "token"
  auth.token = "${AUTH_TOKEN}"

  transport.poolCount = 10
  transport.tcpMux = true
  transport.heartbeatInterval = 10
  transport.heartbeatTimeout = 300

  log.to = "/var/log/frp/frpc.log"
  log.level = "info"
  log.maxDays = 30

  # ============================================
  # immich 服务代理
  # ============================================

  # immich Web 界面
  [[proxies]]
  name = "immich-web"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 2283
  remotePort = 20080

  # immich 服务器 API
  [[proxies]]
  name = "immich-server"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 3003
  remotePort = 20003

  # immich Microservices (大文件处理)
  [[proxies]]
  name = "immich-microservices"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 3004
  remotePort = 20004

  # PostgreSQL 数据库
  [[proxies]]
  name = "immich-postgres"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 5432
  remotePort = 20532

  # Redis 缓存
  [[proxies]]
  name = "immich-redis"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 6379
  remotePort = 20637

  # SSH (可选, 方便远程管理)
  [[proxies]]
  name = "ssh"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 22
  remotePort = 6000

FRPCEOF

    echo ""
    print_line
    echo ""
    echo -e "  ${BOLD}一键部署命令:${NC}"
    echo ""
    echo "  # 1. 安装 frpc"
    echo "  wget -qO- https://github.com/fatedier/frp/releases/download/v${FRPS_VERSION}/frp_${FRPS_VERSION}_linux_\$(uname -m).tar.gz | tar xz -C /tmp"
    echo "  cp /tmp/frp_${FRPS_VERSION}_linux_\$(uname -m)/frpc /usr/local/bin/"
    echo ""
    echo "  # 2. 保存配置"
    echo "  mkdir -p /etc/frp /var/log/frp"
    echo "  # 将上面的配置保存为 /etc/frp/frpc.toml"
    echo ""
    echo "  # 3. 创建 systemd 服务"
    echo "  cat > /etc/systemd/system/frpc.service << 'EOF"
    echo "  [Unit]"
    echo "  Description=frpc service"
    echo "  After=network.target"
    echo "  [Service]"
    echo "  Type=simple"
    echo "  ExecStart=/usr/local/bin/frpc -c /etc/frp/frpc.toml"
    echo "  Restart=on-failure"
    echo "  RestartSec=5"
    echo "  [Install]"
    echo "  WantedBy=multi-user.target"
    echo "  EOF"
    echo ""
    echo "  # 4. 启动 frpc"
    echo "  systemctl daemon-reload"
    echo "  systemctl enable frpc"
    echo "  systemctl start frpc"
    echo ""
    print_line
    echo ""
    read -p "  按回车返回..."
    menu_generate_frpc
}

# ===================== frpc 生成: 全协议模板 =====================
frpc_generate_all() {
    clear_screen
    title "  frpc 全协议配置模板"
    print_line

    local public_ip=$(get_public_ip)

    cat << FRPCEOF

  # ============================================
  # frpc 全协议配置模板 - 保存为 /etc/frp/frpc.toml
  # ============================================

  serverAddr = "${public_ip}"
  serverPort = ${BIND_PORT}
  auth.method = "token"
  auth.token = "${AUTH_TOKEN}"

  transport.poolCount = 10
  transport.tcpMux = true
  transport.heartbeatInterval = 10
  transport.heartbeatTimeout = 300

  log.to = "/var/log/frp/frpc.log"
  log.level = "info"
  log.maxDays = 30

  # ============================================
  # TCP 代理 (默认)
  # ============================================

  [[proxies]]
  name = "ssh"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 22
  remotePort = 6000

  [[proxies]]
  name = "rdp"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 3389
  remotePort = 33389

  # ============================================
  # UDP 代理
  # ============================================

  [[proxies]]
  name = "dns"
  type = "udp"
  localIP = "127.0.0.1"
  localPort = 53
  remotePort = 5353

  # ============================================
  # HTTP 代理 (域名访问)
  # ============================================

  [[proxies]]
  name = "web-http"
  type = "http"
  localIP = "127.0.0.1"
  localPort = 80
  customDomains = ["www.example.com"]

  # ============================================
  # HTTPS 代理 (域名访问)
  # ============================================

  [[proxies]]
  name = "web-https"
  type = "https"
  localIP = "127.0.0.1"
  localPort = 443
  customDomains = ["www.example.com"]

  # ============================================
  # STCP 安全代理 (需要密钥配对)
  # ============================================

  # 服务端 (提供服务)
  [[proxies]]
  name = "secret-ssh"
  type = "stcp"
  localIP = "127.0.0.1"
  localPort = 22
  secretKey = "your-secret-key-here"

  # 客户端 (访问服务, 在另一台机器配置)
  # [[proxies]]
  # name = "secret-ssh-reader"
  # type = "stcp"
  # role = "visitor"
  # serverName = "secret-ssh"
  # secretKey = "your-secret-key-here"
  # bindAddr = "127.0.0.1"
  # bindPort = 6000

  # ============================================
  # SUDP 安全 UDP 代理
  # ============================================

  [[proxies]]
  name = "secret-game"
  type = "sudp"
  localIP = "127.0.0.1"
  localPort = 7777
  secretKey = "your-game-key-here"

  # ============================================
  # XTCP P2P 打洞 (无需服务器带宽)
  # ============================================

  [[proxies]]
  name = "p2p-ssh"
  type = "xtcp"
  localIP = "127.0.0.1"
  localPort = 22
  secretKey = "your-p2p-key-here"

  # ============================================
  # TCPMux 多路复用
  # ============================================

  [[proxies]]
  name = "tcpmux-web"
  type = "tcpmux"
  localIP = "127.0.0.1"
  localPort = 80
  multiplexer = "httpconnect"
  customDomains = ["mux.example.com"]

  # ============================================
  # SOCKS5 代理
  # ============================================

  [[proxies]]
  name = "socks5"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 1080
  remotePort = 10800

  # ============================================
  # HTTP 代理 (浏览器代理)
  # ============================================

  [[proxies]]
  name = "http-proxy"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 8080
  remotePort = 18080

  # ============================================
  # 数据库代理
  # ============================================

  # MySQL
  [[proxies]]
  name = "mysql"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 3306
  remotePort = 13306

  # PostgreSQL
  [[proxies]]
  name = "postgres"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 5432
  remotePort = 15432

  # Redis
  [[proxies]]
  name = "redis"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 6379
  remotePort = 16379

  # MongoDB
  [[proxies]]
  name = "mongodb"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 27017
  remotePort = 27017

  # ============================================
  # Web 服务
  # ============================================

  # Nginx/Apache
  [[proxies]]
  name = "nginx"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 80
  remotePort = 10080

  # ============================================
  # 内网穿透 (远程桌面)
  # ============================================

  # Windows RDP
  [[proxies]]
  name = "windows-rdp"
  type = "tcp"
  localIP = "192.168.1.100"
  localPort = 3389
  remotePort = 23389

  # VNC
  [[proxies]]
  name = "vnc"
  type = "tcp"
  localIP = "192.168.1.100"
  localPort = 5900
  remotePort = 15900

  # ============================================
  # 游戏服务
  # ============================================

  # Minecraft
  [[proxies]]
  name = "minecraft"
  type = "tcp"
  localIP = "127.0.0.1"
  localPort = 25565
  remotePort = 25565

FRPCEOF

    echo ""
    print_line
    echo ""
    read -p "  按回车返回..."
    menu_generate_frpc
}

# ===================== frpc 生成: Docker 部署 =====================
frpc_generate_docker() {
    clear_screen
    title "  frpc Docker 部署"
    print_line

    local public_ip=$(get_public_ip)
    local arch=$(detect_arch)

    cat << FRPCEOF

  # ============================================
  # frpc Docker 部署命令 (v${FRPS_VERSION})
  # ============================================

  # 1. 创建配置目录
  mkdir -p /etc/frp /var/log/frp

  # 2. 保存配置文件 (选择上面生成的配置)
  # 将配置保存为 /etc/frp/frpc.toml

  # 3. Docker 部署命令 (amd64)
  docker run -d \\
    --name frpc \\
    --restart unless-stopped \\
    --network host \\
    -v /etc/frp/frpc.toml:/etc/frp/frpc.toml \\
    -v /var/log/frp:/var/log/frp \\
    snowdreamtech/frpc:${FRPS_VERSION}

  # 4. 查看日志
  docker logs -f frpc

  # 5. 重启 frpc
  docker restart frpc

  # 6. 停止 frpc
  docker stop frpc

  # 7. 删除 frpc
  docker stop frpc && docker rm frpc

  # ============================================
  # Docker Compose 部署
  # ============================================

  # 创建 docker-compose.yml
  cat > docker-compose.yml << 'EOF'
  version: '3'
  services:
    frpc:
      image: snowdreamtech/frpc:${FRPS_VERSION}
      container_name: frpc
      restart: unless-stopped
      network_mode: host
      volumes:
        - /etc/frp/frpc.toml:/etc/frp/frpc.toml
        - /var/log/frp:/var/log/frp
  EOF

  # 启动
  docker-compose up -d

  # 查看日志
  docker-compose logs -f

  # ============================================
  # 注意事项
  # ============================================

  # 1. 确保 frps 服务端已启动
  # 2. 确保 frpc.toml 配置正确
  # 3. 确保服务器防火墙已放行相关端口
  # 4. 使用 --network host 模式, frpc 可以直接访问宿主机服务

FRPCEOF

    echo ""
    print_line
    echo ""
    read -p "  按回车返回..."
    menu_generate_frpc
}

# ===================== 菜单: 卸载 =====================
menu_uninstall() {
    clear_screen
    title "  卸载 frps"
    print_line
    echo ""
    warn "此操作将清除所有 frps 相关配置和文件!"
    echo ""
    read -p "  确认卸载? [y/N]: " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        cleanup_old_install
        rm -f "$FRPS_BIN"
        echo ""
        info "frps 已卸载"
    else
        info "已取消卸载"
    fi
    echo ""
    read -p "  按回车返回主菜单..."
    menu_main
}

# ===================== 菜单: 部署 =====================
menu_deploy() {
    clear_screen
    title "  确认部署配置"
    print_line
    echo ""
    print_config "frps 监听端口" "$BIND_PORT" "$DEFAULT_BIND_PORT"
    print_config "Dashboard 端口" "$DASHBOARD_PORT" "$DEFAULT_DASHBOARD_PORT"
    print_config "Dashboard 用户" "$DASHBOARD_USER" "$DEFAULT_DASHBOARD_USER"
    print_config "Dashboard 密码" "$DASHBOARD_PASS" "$DEFAULT_DASHBOARD_PASS"
    print_config "认证 Token" "$AUTH_TOKEN" "$DEFAULT_AUTH_TOKEN"
    print_config "HTTP 代理端口" "$VHOST_HTTP_PORT" "$DEFAULT_VHOST_HTTP_PORT"
    print_config "HTTPS 代理端口" "$VHOST_HTTPS_PORT" "$DEFAULT_VHOST_HTTPS_PORT"
    echo ""
    print_line
    echo ""
    read -p "  确认部署? [Y/n]: " confirm
    if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
        menu_main
        return
    fi

    do_deploy
}

# ===================== 执行部署 =====================
do_deploy() {
    clear_screen
    title "  开始部署 frps..."
    echo ""

    local arch=$(detect_arch)
    local mem_mb=$(detect_memory_mb)
    local cpu_cores=$(detect_cpu_cores)

    info "系统: ${arch} | ${mem_mb}MB | ${cpu_cores}核"
    echo ""

    # 清理旧安装
    cleanup_old_install

    # 安装依赖
    install_deps

    # 安装 frps
    if [ -f "$FRPS_BIN" ]; then
        local local_version=$("$FRPS_BIN" --version 2>/dev/null || echo "unknown")
        if [ "$local_version" = "$FRPS_VERSION" ]; then
            info "frps ${FRPS_VERSION} 已安装"
        else
            info "更新 frps: ${local_version} → ${FRPS_VERSION}"
            install_frps "$FRPS_VERSION" "$arch"
        fi
    else
        install_frps "$FRPS_VERSION" "$arch"
    fi

    # 应用 sysctl
    info "应用网络调优..."
    apply_sysctl "$mem_mb" "$cpu_cores"

    # 写入配置
    info "写入 frps 配置..."
    write_frps_config

    # 创建 systemd 服务
    info "创建 systemd 服务..."
    create_service

    # 启动服务
    info "启动 frps 服务..."
    systemctl daemon-reload
    systemctl enable frps
    systemctl start frps

    sleep 2

    if systemctl is-active --quiet frps; then
        local public_ip=$(get_public_ip)
        echo ""
        echo -e "${GREEN}"
        echo "  ╔══════════════════════════════════════════════════════════╗"
        echo "  ║                 部署成功!                               ║"
        echo "  ╚══════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo ""
        echo -e "  ${BOLD}服务器信息${NC}"
        echo -e "  公网IP:     ${GREEN}${public_ip}${NC}"
        echo -e "  版本:       ${GREEN}${FRPS_VERSION}${NC}"
        echo -e "  架构:       ${GREEN}${arch}${NC}"
        echo ""
        echo -e "  ${BOLD}frps 配置${NC}"
        echo -e "  监听端口:   ${GREEN}${BIND_PORT}${NC}"
        echo -e "  Dashboard:  ${GREEN}http://${public_ip}:${DASHBOARD_PORT}${NC}"
        echo -e "  用户名:     ${GREEN}${DASHBOARD_USER}${NC}"
        echo -e "  密码:       ${GREEN}${DASHBOARD_PASS}${NC}"
        echo ""
        echo -e "  ${BOLD}frpc 配置${NC}"
        echo -e "  serverAddr = ${GREEN}${public_ip}${NC}"
        echo -e "  serverPort = ${GREEN}${BIND_PORT}${NC}"
        echo -e "  auth.token = ${GREEN}${AUTH_TOKEN}${NC}"
        echo ""
        echo -e "  ${BOLD}管理命令${NC}"
        echo -e "  systemctl start frps    # 启动"
        echo -e "  systemctl stop frps     # 停止"
        echo -e "  systemctl restart frps  # 重启"
        echo -e "  systemctl status frps   # 状态"
        echo -e "  journalctl -u frps -f   # 日志"
        echo ""
    else
        error "frps 启动失败"
        echo ""
        hint "查看日志: journalctl -u frps -n 50"
    fi

    echo ""
    read -p "  按回车返回主菜单..."
    menu_main
}

# ===================== 帮助信息 =====================
show_help() {
    clear_screen
    title "  帮助信息"
    print_line
    echo ""
    echo -e "  ${BOLD}用法:${NC}"
    echo "  bash deploy_frps.sh          # 交互式菜单"
    echo "  bash deploy_frps.sh -h       # 显示帮助"
    echo ""
    echo -e "  ${BOLD}功能:${NC}"
    echo "  - 自动检测系统架构和内存"
    echo "  - 动态调整网络参数"
    echo "  - 支持修改端口、用户名、密码"
    echo "  - 100GB 大文件传输优化"
    echo ""
    echo -e "  ${BOLD}端口说明:${NC}"
    echo "  7000  - frps 主端口"
    echo "  7500  - Dashboard"
    echo "  8080  - HTTP 代理"
    echo "  8443  - HTTPS 代理"
    echo ""
    print_line
    echo ""
    exit 0
}

# ===================== 入口 =====================
case "${1:-}" in
    -h|--help) show_help ;;
esac

check_root
menu_main
