<div align="center">

# frps One-Click Deploy Script

**Dynamic Adaptive | Memory Optimized | Large File Transfer | Interactive Menu**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/Ac-All-Sh/immich-frps.svg)](https://github.com/Ac-All-Sh/immich-frps/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/Ac-All-Sh/immich-frps.svg)](https://github.com/Ac-All-Sh/immich-frps/issues)
![GitHub forks](https://img.shields.io/github/forks/Ac-All-Sh/immich-frps.svg)
![GitHub last commit](https://img.shields.io/github/last-commit/Ac-All-Sh/immich-frps.svg)

**[English](#english) | [中文](#chinese) | [日本語](#japanese) | [한국어](#korean)**

</div>

---

<a id="english"></a>

## English Documentation

### Features

| Feature | Description |
|---------|-------------|
| Auto Detection | Auto-detect system architecture (amd64/arm64) and memory |
| Dynamic Optimization | Auto-adjust network parameters based on memory and transfer size |
| Interactive Menu | Beautiful colorful interface, support modifying all configs |
| Multi-Protocol | Generate frpc configs, support TCP/UDP/HTTP/HTTPS/STCP/XTCP etc. |
| Docker Support | Provide Docker deployment commands |
| Flexible Config | Support modifying ports, username, password, token etc. |
| One-Click Uninstall | Clean all frps related configs |

### System Requirements

- **OS**: Debian 10/11/12, Ubuntu 20.04/22.04/24.04
- **Privileges**: root user
- **Dependencies**: curl, tar (auto-installed by script)

### Quick Start

#### 1. Download Script

```bash
# Clone with git
git clone https://github.com/Ac-All-Sh/immich-frps.git
cd immich-frps

# Or download directly
wget -O deploy_frps.sh https://raw.githubusercontent.com/Ac-All-Sh/immich-frps/main/deploy_frps.sh
```

#### 2. Run Script

```bash
# Add execute permission
chmod +x deploy_frps.sh

# Run script
sudo bash deploy_frps.sh
```

### Usage Tutorial

#### Main Menu

After running the script, you will see the main menu:

```
================================================================
           frps One-Click Deploy Script v0.69.1
           Dynamic Adaptive | Memory Optimized
           Author: Ac.All.Sh (Github)
================================================================

  System Info
  Arch: amd64 | Memory: 2048MB | CPU: 2 cores
  Transfer Size: 10GB
  ----------------------------------------------------------------

  [1] One-Click Deploy frps
      Deploy frps server with current config

  [2] Modify Config
      Modify ports, username, password, token etc.

  [3] View Config
      View all current config items

  [4] Manage Service
      Start/Stop/Restart/Status/Logs

  [5] Generate frpc Config
      Generate client config, support all protocols

  [6] Uninstall frps
      Clean all frps related configs

  [0] Exit Script
```

#### Options Explained

| Option | Function | Description |
|--------|----------|-------------|
| [1] | One-Click Deploy | Auto deploy frps server with current config |
| [2] | Modify Config | Modify ports, username, password, token, transfer size etc. |
| [3] | View Config | View all current config items and frpc config example |
| [4] | Manage Service | Start/Stop/Restart frps service, view status and logs |
| [5] | Generate frpc | Generate client config files with multiple templates |
| [6] | Uninstall | Clean all frps related configs and files |

#### Modify Config Menu

Select [2] to enter config modification menu:

```
  Modify Deploy Config
  ----------------------------------------------------------------

  frps Listen Port:    7000                    (default)
  Dashboard Port:      7500                    (default)
  Dashboard User:      admin                   (default)
  Dashboard Pass:      admin123                (default)
  Auth Token:          your_frp_token_here     (default)
  HTTP Proxy Port:     8080                    (default)
  HTTPS Proxy Port:    8443                    (default)
  Transfer Size:       10GB                    (default)

  ----------------------------------------------------------------

  [1] Modify frps Listen Port
  [2] Modify Dashboard Port
  [3] Modify Dashboard Username
  [4] Modify Dashboard Password
  [5] Modify Auth Token
  [6] Modify HTTP Proxy Port
  [7] Modify HTTPS Proxy Port
  [8] Select Transfer Size (Current: 10GB)
  [0] Return to Main Menu
```

#### Select Transfer Size

Select [8] to enter transfer size selection:

```
  Select File Transfer Size
  ----------------------------------------------------------------

  Select the file size you need to transfer, the script will
  auto-optimize network parameters

  [1] 1GB     - Small file transfer (light optimization)
  [2] 5GB     - Medium file (moderate optimization)
  [3] 10GB    - Large file transfer (default, recommended)
  [4] 50GB    - Extra large file (deep optimization)
  [5] 100GB   - Extreme transfer (maximum optimization)
  [6] Custom  - Manual input size
  [0] Return to Main Menu
```

#### Generate frpc Config

Select [5] to enter frpc config generation menu:

```
  Generate frpc Config
  ----------------------------------------------------------------

  [1] Basic Config - SSH + Web Proxy
  [2] Immich Config - Full Immich Proxy
  [3] All Protocol Template - All Supported Protocols
  [4] Docker Deploy - frpc Docker Commands
  [0] Return to Main Menu
```

#### All Protocol Template Support

| Protocol | Type | Description |
|----------|------|-------------|
| TCP | type = "tcp" | TCP Proxy (SSH, RDP etc.) |
| UDP | type = "udp" | UDP Proxy (DNS, Games etc.) |
| HTTP | type = "http" | HTTP Proxy (Domain Access) |
| HTTPS | type = "https" | HTTPS Proxy (SSL) |
| STCP | type = "stcp" | Secure TCP Proxy (Key Pair) |
| SUDP | type = "sudp" | Secure UDP Proxy |
| XTCP | type = "xtcp" | P2P Hole Punching (No Server Bandwidth) |
| TCPMux | type = "tcpmux" | TCP Multiplexing |

### Docker Deployment

#### Using Docker

```bash
# 1. Create config directory
mkdir -p /etc/frp /var/log/frp

# 2. Save config file (use config generated by script)
# Save config as /etc/frp/frpc.toml

# 3. Docker deployment
docker run -d \
  --name frpc \
  --restart unless-stopped \
  --network host \
  -v /etc/frp/frpc.toml:/etc/frp/frpc.toml \
  -v /var/log/frp:/var/log/frp \
  snowdreamtech/frpc:0.69.1

# 4. View logs
docker logs -f frpc
```

#### Using Docker Compose

```yaml
# docker-compose.yml
version: '3'
services:
  frpc:
    image: snowdreamtech/frpc:0.69.1
    container_name: frpc
    restart: unless-stopped
    network_mode: host
    volumes:
      - /etc/frp/frpc.toml:/etc/frp/frpc.toml
      - /var/log/frp:/var/log/frp
```

```bash
# Start
docker-compose up -d

# View logs
docker-compose logs -f
```

### Management Commands

```bash
# Service Management
systemctl start frps      # Start
systemctl stop frps       # Stop
systemctl restart frps    # Restart
systemctl status frps     # Status
journalctl -u frps -f     # Logs

# Config File Locations
/etc/frp/frps.toml        # frps config
/var/log/frp/frps.log     # frps logs
```

### Network Optimization Parameters

The script automatically adjusts the following parameters based on memory and transfer size:

| Parameter | 1GB | 2GB | 4GB | 8GB+ |
|-----------|-----|-----|-----|------|
| TCP Buffer | 4MB | 16MB | 32MB | 64MB |
| Conn Backlog | 32768 | 49152 | 65535 | 65535 |
| Pool Count | 200 | 500 | 1000 | 2000 |
| Max Orphans | 32768 | 131072 | 262144 | 524288 |

### FAQ

#### Q: Script execution failed?

```bash
# Check if using root user
sudo bash deploy_frps.sh

# Check network connection
curl -I https://github.com

# View detailed errors
bash -x deploy_frps.sh
```

#### Q: How to redeploy after modifying config?

```bash
# Run script again
sudo bash deploy_frps.sh

# Select [2] to modify config
# Select [1] to redeploy after modification
```

#### Q: How to uninstall frps?

```bash
# Method 1: Use script to uninstall
sudo bash deploy_frps.sh
# Select [6] to uninstall frps

# Method 2: Manual uninstall
systemctl stop frps
systemctl disable frps
rm -f /usr/local/bin/frps
rm -rf /etc/frp /var/log/frp
rm -f /etc/systemd/system/frps.service
```

### Changelog

#### v1.0.0 (2024-01-01)
- Initial release
- Interactive menu interface
- Dynamic network optimization
- Multi-protocol frpc config generation
- Docker deployment support

### Releases and Artifacts

This repository automatically checks for new frp releases every week and generates:

- **Binary Files**: frps and frpc for amd64, arm64, arm architectures
- **Docker Images**: Available on Docker Hub and GitHub Container Registry
- **Checksums**: SHA256 verification for all binaries

#### Download Binaries

```bash
# Download latest frps (amd64)
curl -fsSL https://github.com/Ac-All-Sh/immich-frps/releases/latest/download/frps_linux_amd64 -o /usr/local/bin/frps
chmod +x /usr/local/bin/frps

# Download latest frpc (amd64)
curl -fsSL https://github.com/Ac-All-Sh/immich-frps/releases/latest/download/frpc_linux_amd64 -o /usr/local/bin/frpc
chmod +x /usr/local/bin/frpc
```

#### Docker Images

```bash
# Docker Hub
docker pull acallsh/frps:latest-amd64
docker pull acallsh/frpc:latest-amd64
docker pull acallsh/frps:latest-arm64
docker pull acallsh/frpc:latest-arm64
docker pull acallsh/frps:latest-arm
docker pull acallsh/frpc:latest-arm
```

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

### Author

**Ac.All.Sh** - [GitHub](https://github.com/Ac-All-Sh)

---

<a id="chinese"></a>

## 中文文档

### 功能特性

| 功能 | 描述 |
|------|------|
| 自动检测 | 自动检测系统架构 (amd64/arm64) 和内存大小 |
| 动态优化 | 根据内存和传输大小自动调整网络参数 |
| 交互式菜单 | 美观的彩色界面，支持修改所有配置 |
| 多协议支持 | 生成 frpc 配置，支持 TCP/UDP/HTTP/HTTPS/STCP/XTCP 等 |
| Docker 支持 | 提供 Docker 部署命令 |
| 灵活配置 | 支持修改端口、用户名、密码、Token 等 |
| 一键卸载 | 清除所有 frps 相关配置 |

### 系统要求

- **操作系统**: Debian 10/11/12, Ubuntu 20.04/22.04/24.04
- **权限**: root 用户
- **依赖**: curl, tar (脚本自动安装)

### 快速开始

#### 1. 下载脚本

```bash
# 使用 git 克隆
git clone https://github.com/Ac-All-Sh/immich-frps.git
cd immich-frps

# 或直接下载
wget -O deploy_frps.sh https://raw.githubusercontent.com/Ac-All-Sh/immich-frps/main/deploy_frps.sh
```

#### 2. 运行脚本

```bash
# 添加执行权限
chmod +x deploy_frps.sh

# 运行脚本
sudo bash deploy_frps.sh
```

### 使用教程

#### 主菜单

运行脚本后，您将看到主菜单：

```
================================================================
           frps 一键部署脚本 v0.69.1
           动态自适应 | 内存优化 | 100GB传输
           Author: Ac.All.Sh (Github)
================================================================

  系统信息
  架构: amd64 | 内存: 2048MB | CPU: 2核
  传输大小: 10GB
  ----------------------------------------------------------------

  [1] 一键部署 frps
      使用当前配置部署 frps 服务端

  [2] 修改配置
      修改端口、用户名、密码、Token 等

  [3] 查看配置
      查看当前所有配置项

  [4] 管理服务
      启动/停止/重启/状态/日志

  [5] 生成 frpc 配置
      生成客户端配置文件, 支持所有协议

  [6] 卸载 frps
      清除所有 frps 相关配置

  [0] 退出脚本
```

#### 选项说明

| 选项 | 功能 | 说明 |
|------|------|------|
| [1] | 一键部署 | 使用当前配置自动部署 frps 服务端 |
| [2] | 修改配置 | 修改端口、用户名、密码、Token、传输大小等 |
| [3] | 查看配置 | 查看当前所有配置项和 frpc 配置示例 |
| [4] | 管理服务 | 启动/停止/重启 frps 服务，查看状态和日志 |
| [5] | 生成 frpc | 生成客户端配置文件，支持多种模板 |
| [6] | 卸载 | 清除所有 frps 相关配置和文件 |

#### 修改配置菜单

选择 [2] 进入配置修改菜单：

```
  修改部署配置
  ----------------------------------------------------------------

  frps 监听端口:      7000                    (默认)
  Dashboard 端口:     7500                    (默认)
  Dashboard 用户:     admin                   (默认)
  Dashboard 密码:     admin123                (默认)
  认证 Token:         your_frp_token_here     (默认)
  HTTP 代理端口:      8080                    (默认)
  HTTPS 代理端口:     8443                    (默认)
  传输大小:           10GB                    (默认)

  ----------------------------------------------------------------

  [1] 修改 frps 监听端口
  [2] 修改 Dashboard 端口
  [3] 修改 Dashboard 用户名
  [4] 修改 Dashboard 密码
  [5] 修改认证 Token
  [6] 修改 HTTP 代理端口
  [7] 修改 HTTPS 代理端口
  [8] 选择传输大小 (当前: 10GB)
  [0] 返回主菜单
```

#### 选择传输大小

选择 [8] 进入传输大小选择：

```
  选择文件传输大小
  ----------------------------------------------------------------

  选择您需要传输的文件大小, 脚本会自动优化网络参数

  [1] 1GB    - 小文件传输 (轻量优化)
  [2] 5GB    - 中等文件 (适中优化)
  [3] 10GB   - 大文件传输 (默认, 推荐)
  [4] 50GB   - 超大文件 (深度优化)
  [5] 100GB  - 极限传输 (最大优化)
  [6] 自定义 - 手动输入大小
  [0] 返回主菜单
```

#### 生成 frpc 配置

选择 [5] 进入 frpc 配置生成菜单：

```
  生成 frpc 配置
  ----------------------------------------------------------------

  [1] 基础配置 - SSH + Web 代理
  [2] immich 配置 - 完整 immich 代理
  [3] 全协议模板 - 所有支持的协议
  [4] Docker 部署 - frpc Docker 命令
  [0] 返回主菜单
```

#### 全协议模板支持

| 协议 | 类型 | 说明 |
|------|------|------|
| TCP | type = "tcp" | TCP 代理 (SSH, RDP 等) |
| UDP | type = "udp" | UDP 代理 (DNS, 游戏等) |
| HTTP | type = "http" | HTTP 代理 (域名访问) |
| HTTPS | type = "https" | HTTPS 代理 (SSL) |
| STCP | type = "stcp" | 安全 TCP 代理 (密钥配对) |
| SUDP | type = "sudp" | 安全 UDP 代理 |
| XTCP | type = "xtcp" | P2P 打洞 (无需服务器带宽) |
| TCPMux | type = "tcpmux" | TCP 多路复用 |

### Docker 部署

#### 使用 Docker

```bash
# 1. 创建配置目录
mkdir -p /etc/frp /var/log/frp

# 2. 保存配置文件 (使用脚本生成的配置)
# 将配置保存为 /etc/frp/frpc.toml

# 3. Docker 部署
docker run -d \
  --name frpc \
  --restart unless-stopped \
  --network host \
  -v /etc/frp/frpc.toml:/etc/frp/frpc.toml \
  -v /var/log/frp:/var/log/frp \
  snowdreamtech/frpc:0.69.1

# 4. 查看日志
docker logs -f frpc
```

#### 使用 Docker Compose

```yaml
# docker-compose.yml
version: '3'
services:
  frpc:
    image: snowdreamtech/frpc:0.69.1
    container_name: frpc
    restart: unless-stopped
    network_mode: host
    volumes:
      - /etc/frp/frpc.toml:/etc/frp/frpc.toml
      - /var/log/frp:/var/log/frp
```

```bash
# 启动
docker-compose up -d

# 查看日志
docker-compose logs -f
```

### 管理命令

```bash
# 服务管理
systemctl start frps      # 启动
systemctl stop frps       # 停止
systemctl restart frps    # 重启
systemctl status frps     # 状态
journalctl -u frps -f     # 日志

# 配置文件位置
/etc/frp/frps.toml        # frps 配置
/var/log/frp/frps.log     # frps 日志
```

### 网络优化参数

脚本会根据内存和传输大小自动调整以下参数：

| 参数 | 1GB | 2GB | 4GB | 8GB+ |
|------|-----|-----|-----|------|
| TCP 缓冲区 | 4MB | 16MB | 32MB | 64MB |
| 连接队列 | 32768 | 49152 | 65535 | 65535 |
| 连接池 | 200 | 500 | 1000 | 2000 |
| Max Orphans | 32768 | 131072 | 262144 | 524288 |

### 常见问题

#### Q: 脚本执行失败怎么办？

```bash
# 检查是否使用 root 用户
sudo bash deploy_frps.sh

# 检查网络连接
curl -I https://github.com

# 查看详细错误
bash -x deploy_frps.sh
```

#### Q: 如何修改配置后重新部署？

```bash
# 重新运行脚本
sudo bash deploy_frps.sh

# 选择 [2] 修改配置
# 修改完成后选择 [1] 重新部署
```

#### Q: 如何卸载 frps？

```bash
# 方法1: 使用脚本卸载
sudo bash deploy_frps.sh
# 选择 [6] 卸载 frps

# 方法2: 手动卸载
systemctl stop frps
systemctl disable frps
rm -f /usr/local/bin/frps
rm -rf /etc/frp /var/log/frp
rm -f /etc/systemd/system/frps.service
```

### 更新日志

#### v1.0.0 (2024-01-01)
- 初始版本发布
- 交互式菜单界面
- 动态网络优化
- 多协议 frpc 配置生成
- Docker 部署支持

### 发布与制品

本仓库每周自动检查 frp 新版本并生成：

- **二进制文件**: frps 和 frpc (amd64/arm64/arm)
- **Docker 镜像**: Docker Hub 和 GitHub Container Registry
- **校验和**: 所有二进制文件的 SHA256 验证

#### 下载二进制文件

```bash
# 下载最新 frps (amd64)
curl -fsSL https://github.com/Ac-All-Sh/immich-frps/releases/latest/download/frps_linux_amd64 -o /usr/local/bin/frps
chmod +x /usr/local/bin/frps

# 下载最新 frpc (amd64)
curl -fsSL https://github.com/Ac-All-Sh/immich-frps/releases/latest/download/frpc_linux_amd64 -o /usr/local/bin/frpc
chmod +x /usr/local/bin/frpc
```

#### Docker 镜像

```bash
# Docker Hub
docker pull acallsh/frps:latest-amd64
docker pull acallsh/frpc:latest-amd64

# GitHub Container Registry
docker pull ghcr.io/ac-all-sh/frps:latest-amd64
docker pull ghcr.io/ac-all-sh/frpc:latest-amd64
```

### 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

### 作者

**Ac.All.Sh** - [GitHub](https://github.com/Ac-All-Sh)

---

<a id="japanese"></a>

## 日本語ドキュメント

### 機能

| 機能 | 説明 |
|------|------|
| 自動検出 | システムアーキテクチャ (amd64/arm64) とメモリの自動検出 |
| 動的最適化 | メモリと転送サイズに基づくネットワークパラメータの自動調整 |
| インタラクティブメニュー | 美しいカラフルインターフェース、すべての設定変更をサポート |
| マルチプロトコル | frpc設定の生成、TCP/UDP/HTTP/HTTPS/STCP/XTCPなどをサポート |
| Dockerサポート | Dockerデプロイコマンドを提供 |
| 柔軟な設定 | ポート、ユーザー名、パスワード、トークンなどの変更をサポート |
| ワンクリックアンインストール | すべてのfrps関連設定をクリーン |

### システム要件

- **OS**: Debian 10/11/12, Ubuntu 20.04/22.04/24.04
- **権限**: rootユーザー
- **依存関係**: curl, tar (スクリプトが自動インストール)

### クイックスタート

#### 1. スクリプトをダウンロード

```bash
# gitでクローン
git clone https://github.com/Ac-All-Sh/immich-frps.git
cd immich-frps

# または直接ダウンロード
wget -O deploy_frps.sh https://raw.githubusercontent.com/Ac-All-Sh/immich-frps/main/deploy_frps.sh
```

#### 2. スクリプトを実行

```bash
# 実行権限を追加
chmod +x deploy_frps.sh

# スクリプトを実行
sudo bash deploy_frps.sh
```

### 使用方法チュートリアル

#### メインメニュー

スクリプト実行後、メインメニューが表示されます:

```
================================================================
           frps ワンクリックデプロイスクリプト v0.69.1
           動的適応 | メモリ最適化
           Author: Ac.All.Sh (Github)
================================================================

  システム情報
  アーキテクチャ: amd64 | メモリ: 2048MB | CPU: 2コア
  転送サイズ: 10GB
  ----------------------------------------------------------------

  [1] ワンクリックデプロイ frps
      現在の設定でfrpsサーバーをデプロイ

  [2] 設定を変更
      ポート、ユーザー名、パスワード、トークンなどを変更

  [3] 設定を表示
      現在のすべての設定項目を表示

  [4] サービス管理
      開始/停止/再起動/ステータス/ログ

  [5] frpc設定を生成
      クライアント設定ファイルを生成、すべてのプロトコルをサポート

  [6] frpsをアンインストール
      すべてのfrps関連設定をクリーン

  [0] スクリプトを終了
```

#### オプション説明

| オプション | 機能 | 説明 |
|-----------|------|------|
| [1] | ワンクリックデプロイ | 現在の設定で自動frpsサーバーデプロイ |
| [2] | 設定変更 | ポート、ユーザー名、パスワード、トークン、転送サイズなどを変更 |
| [3] | 設定表示 | 現在のすべての設定項目とfrpc設定例を表示 |
| [4] | サービス管理 | frpsサービスの開始/停止/再起動、ステータスとログの表示 |
| [5] | frpc設定生成 | 複数のテンプレートでクライアント設定ファイルを生成 |
| [6] | アンインストール | すべてのfrps関連設定とファイルをクリーン |

#### 設定変更メニュー

[2]を選択して設定変更メニューに移動:

```
  デプロイ設定を変更
  ----------------------------------------------------------------

  frpsリスニングポート:    7000                    (デフォルト)
  Dashboardポート:         7500                    (デフォルト)
  Dashboardユーザー:       admin                   (デフォルト)
  Dashboardパスワード:     admin123                (デフォルト)
  認証トークン:            your_frp_token_here     (デフォルト)
  HTTPプロキシポート:      8080                    (デフォルト)
  HTTPSプロキシポート:     8443                    (デフォルト)
  転送サイズ:              10GB                    (デフォルト)

  ----------------------------------------------------------------

  [1] frpsリスニングポートを変更
  [2] Dashboardポートを変更
  [3] Dashboardユーザー名を変更
  [4] Dashboardパスワードを変更
  [5] 認証トークンを変更
  [6] HTTPプロキシポートを変更
  [7] HTTPSプロキシポートを変更
  [8] 転送サイズを選択 (現在: 10GB)
  [0] メインメニューに戻る
```

#### 転送サイズを選択

[8]を選択して転送サイズ選択に移動:

```
  ファイル転送サイズを選択
  ----------------------------------------------------------------

  転送するファイルのサイズを選択すると、
  スクリプトがネットワークパラメータを自動最適化します

  [1] 1GB     - 小ファイル転送 (軽量最適化)
  [2] 5GB     - 中ファイル (適度な最適化)
  [3] 10GB    - 大ファイル転送 (デフォルト、推奨)
  [4] 50GB    - 超大ファイル (深い最適化)
  [5] 100GB   - 極限転送 (最大最適化)
  [6] カスタム - 手動入力
  [0] メインメニューに戻る
```

#### frpc設定を生成

[5]を選択してfrpc設定生成メニューに移動:

```
  frpc設定を生成
  ----------------------------------------------------------------

  [1] 基本設定 - SSH + Webプロキシ
  [2] Immich設定 - 完全Immichプロキシ
  [3] 全プロトコルテンプレート - サポートされているすべてのプロトコル
  [4] Dockerデプロイ - frpc Dockerコマンド
  [0] メインメニューに戻る
```

#### 全プロトコルテンプレートサポート

| プロトコル | タイプ | 説明 |
|-----------|--------|------|
| TCP | type = "tcp" | TCPプロキシ (SSH, RDPなど) |
| UDP | type = "udp" | UDPプロキシ (DNS, ゲームなど) |
| HTTP | type = "http" | HTTPプロキシ (ドメインアクセス) |
| HTTPS | type = "https" | HTTPSプロキシ (SSL) |
| STCP | type = "stcp" | セキュアTCPプロキシ (キーペア) |
| SUDP | type = "sudp" | セキュアUDPプロキシ |
| XTCP | type = "xtcp" | P2Pホールパンチング (サーバーバンド幅不要) |
| TCPMux | type = "tcpmux" | TCPマルチプレクシング |

### Dockerデプロイ

#### Dockerを使用

```bash
# 1. 設定ディレクトリを作成
mkdir -p /etc/frp /var/log/frp

# 2. 設定ファイルを保存 (スクリプトが生成した設定を使用)
# 設定を /etc/frp/frpc.toml に保存

# 3. Dockerデプロイ
docker run -d \
  --name frpc \
  --restart unless-stopped \
  --network host \
  -v /etc/frp/frpc.toml:/etc/frp/frpc.toml \
  -v /var/log/frp:/var/log/frp \
  snowdreamtech/frpc:0.69.1

# 4. ログを表示
docker logs -f frpc
```

#### Docker Composeを使用

```yaml
# docker-compose.yml
version: '3'
services:
  frpc:
    image: snowdreamtech/frpc:0.69.1
    container_name: frpc
    restart: unless-stopped
    network_mode: host
    volumes:
      - /etc/frp/frpc.toml:/etc/frp/frpc.toml
      - /var/log/frp:/var/log/frp
```

```bash
# 開始
docker-compose up -d

# ログを表示
docker-compose logs -f
```

### 管理コマンド

```bash
# サービス管理
systemctl start frps      # 開始
systemctl stop frps       # 停止
systemctl restart frps    # 再起動
systemctl status frps     # ステータス
journalctl -u frps -f     # ログ

# 設定ファイルの場所
/etc/frp/frps.toml        # frps設定
/var/log/frp/frps.log     # frpsログ
```

### ネットワーク最適化パラメータ

スクリプトはメモリと転送サイズに基づいて以下のパラメータを自動調整します:

| パラメータ | 1GB | 2GB | 4GB | 8GB+ |
|-----------|-----|-----|-----|------|
| TCPバッファ | 4MB | 16MB | 32MB | 64MB |
| 接続バックログ | 32768 | 49152 | 65535 | 65535 |
| プールカウント | 200 | 500 | 1000 | 2000 |
| Max Orphans | 32768 | 131072 | 262144 | 524288 |

### よくある質問

#### Q: スクリプトの実行に失敗した場合怎么办？

```bash
# rootユーザーで実行しているか確認
sudo bash deploy_frps.sh

# ネットワーク接続を確認
curl -I https://github.com

# 詳細なエラーを表示
bash -x deploy_frps.sh
```

#### Q: 設定を変更した後に再デプロイするにはどうすればいいですか？

```bash
# スクリプトを再実行
sudo bash deploy_frps.sh

# [2]を選択して設定を変更
# 変更後に[1]を選択して再デプロイ
```

#### Q: frpsをアンインストールするにはどうすればいいですか？

```bash
# 方法1: スクリプトでアンインストール
sudo bash deploy_frps.sh
# [6]を選択してfrpsをアンインストール

# 方法2: 手動アンインストール
systemctl stop frps
systemctl disable frps
rm -f /usr/local/bin/frps
rm -rf /etc/frp /var/log/frp
rm -f /etc/systemd/system/frps.service
```

### 変更履歴

#### v1.0.0 (2024-01-01)
- 初回リリース
- インタラクティブメニューインターフェース
- 動的ネットワーク最適化
- マルチプロトコルfrpc設定生成
- Dockerデプロイサポート

### リリースとアーティファクト

このリポジトリは毎週自動的にfrpの新しいリリースをチェックし、以下を生成します:

- **バイナリファイル**: frpsとfrpc (amd64/arm64/arm)
- **Dockerイメージ**: Docker HubとGitHub Container Registryで利用可能
- **チェックサム**: すべてのバイナリファイルのSHA256検証

#### バイナリファイルをダウンロード

```bash
# 最新のfrpsをダウンロード (amd64)
curl -fsSL https://github.com/Ac-All-Sh/immich-frps/releases/latest/download/frps_linux_amd64 -o /usr/local/bin/frps
chmod +x /usr/local/bin/frps

# 最新のfrpcをダウンロード (amd64)
curl -fsSL https://github.com/Ac-All-Sh/immich-frps/releases/latest/download/frpc_linux_amd64 -o /usr/local/bin/frpc
chmod +x /usr/local/bin/frpc
```

#### Dockerイメージ

```bash
# Docker Hub
docker pull acallsh/frps:latest-amd64
docker pull acallsh/frpc:latest-amd64

# GitHub Container Registry
docker pull ghcr.io/ac-all-sh/frps:latest-amd64
docker pull ghcr.io/ac-all-sh/frpc:latest-amd64
```

### ライセンス

このプロジェクトはMITライセンスでライセンスされています - 詳細は[LICENSE](LICENSE)ファイルを参照してください

### 開発者

**Ac.All.Sh** - [GitHub](https://github.com/Ac-All-Sh)

---

<a id="korean"></a>

## 한국어 문서

### 기능

| 기능 | 설명 |
|------|------|
| 자동 감지 | 시스템 아키텍처 (amd64/arm64) 및 메모리 자동 감지 |
| 동적 최적화 | 메모리 및 전송 크기에 따라 네트라미터 자동 조정 |
| 대화형 메뉴 | 아름다운 컬러 인터페이스, 모든 설정 수정 지원 |
| 다중 프로토콜 | frpc 설정 생성, TCP/UDP/HTTP/HTTPS/STCP/XTCP 등 지원 |
| Docker 지원 | Docker 배포 명령어 제공 |
| 유연한 설정 | 포트, 사용자명, 비밀번호, 토큰 등 수정 지원 |
| 원클릭 제거 | 모든 frps 관련 설정 정리 |

### 시스템 요구사항

- **OS**: Debian 10/11/12, Ubuntu 20.04/22.04/24.04
- **권한**: root 사용자
- **의존성**: curl, tar (스크립트가 자동 설치)

### 빠른 시작

#### 1. 스크립트 다운로드

```bash
# git으로 클론
git clone https://github.com/Ac-All-Sh/immich-frps.git
cd immich-frps

# 또는 직접 다운로드
wget -O deploy_frps.sh https://raw.githubusercontent.com/Ac-All-Sh/immich-frps/main/deploy_frps.sh
```

#### 2. 스크립트 실행

```bash
# 실행 권한 추가
chmod +x deploy_frps.sh

# 스크립트 실행
sudo bash deploy_frps.sh
```

### 사용법 튜토리얼

#### 메인 메뉴

스크립트 실행 후 메인 메뉴가 표시됩니다:

```
================================================================
           frps 원클릭 배포 스크립트 v0.69.1
           동적 적응 | 메모리 최적화
           Author: Ac.All.Sh (Github)
================================================================

  시스템 정보
  아키텍처: amd64 | 메모리: 2048MB | CPU: 2코어
  전송 크기: 10GB
  ----------------------------------------------------------------

  [1] 원클릭 배포 frps
      현재 설정으로 frps 서버 배포

  [2] 설정 수정
      포트, 사용자명, 비밀번호, 토큰 등 수정

  [3] 설정 보기
      현재 모든 설정 항목 보기

  [4] 서비스 관리
      시작/중지/재시작/상태/로그

  [5] frpc 설정 생성
      클라이언트 설정 파일 생성, 모든 프로토콜 지원

  [6] frps 제거
      모든 frps 관련 설정 정리

  [0] 스크립트 종료
```

#### 옵션 설명

| 옵션 | 기능 | 설명 |
|------|------|------|
| [1] | 원클릭 배포 | 현재 설정으로 자동 frps 서버 배포 |
| [2] | 설정 수정 | 포트, 사용자명, 비밀번호, 토큰, 전송 크기 등 수정 |
| [3] | 설정 보기 | 현재 모든 설정 항목 및 frpc 설정 예시 보기 |
| [4] | 서비스 관리 | frps 서비스 시작/중지/재시작, 상태 및 로그 보기 |
| [5] | frpc 설정 생성 | 여러 템플릿으로 클라이언트 설정 파일 생성 |
| [6] | 제거 | 모든 frps 관련 설정 및 파일 정리 |

#### 설정 수정 메뉴

[2]를 선택하여 설정 수정 메뉴로 이동:

```
  배포 설정 수정
  ----------------------------------------------------------------

  frps 리스닝 포트:    7000                    (기본값)
  Dashboard 포트:      7500                    (기본값)
  Dashboard 사용자:    admin                   (기본값)
  Dashboard 비밀번호:  admin123                (기본값)
  인증 토큰:           your_frp_token_here     (기본값)
  HTTP 프록시 포트:    8080                    (기본값)
  HTTPS 프록시 포트:   8443                    (기본값)
  전송 크기:           10GB                    (기본값)

  ----------------------------------------------------------------

  [1] frps 리스닝 포트 수정
  [2] Dashboard 포트 수정
  [3] Dashboard 사용자명 수정
  [4] Dashboard 비밀번호 수정
  [5] 인증 토큰 수정
  [6] HTTP 프록시 포트 수정
  [7] HTTPS 프록시 포트 수정
  [8] 전송 크기 선택 (현재: 10GB)
  [0] 메인 메뉴로 돌아가기
```

#### 전송 크기 선택

[8]를 선택하여 전송 크기 선택으로 이동:

```
  파일 전송 크기 선택
  ----------------------------------------------------------------

  전송할 파일 크기를 선택하면
  스크립트가 네트라미터를 자동 최적화합니다

  [1] 1GB     - 소규모 파일 전송 (경량 최적화)
  [2] 5GB     - 중간 파일 (적당한 최적화)
  [3] 10GB    - 대규모 파일 전송 (기본값, 권장)
  [4] 50GB    - 초대형 파일 (심층 최적화)
  [5] 100GB   - 극한 전송 (최대 최적화)
  [6] 사용자 정의 - 수동 입력
  [0] 메인 메뉴로 돌아가기
```

#### frpc 설정 생성

[5]를 선택하여 frpc 설정 생성 메뉴로 이동:

```
  frpc 설정 생성
  ----------------------------------------------------------------

  [1] 기본 설정 - SSH + Web 프록시
  [2] Immich 설정 - 전체 Immich 프록시
  [3] 전체 프로토콜 템플릿 - 지원되는 모든 프로토콜
  [4] Docker 배포 - frpc Docker 명령어
  [0] 메인 메뉴로 돌아가기
```

#### 전체 프로토콜 템플릿 지원

| 프로토콜 | 타입 | 설명 |
|----------|------|------|
| TCP | type = "tcp" | TCP 프록시 (SSH, RDP 등) |
| UDP | type = "udp" | UDP 프록시 (DNS, 게임 등) |
| HTTP | type = "http" | HTTP 프록시 (도메인 접근) |
| HTTPS | type = "https" | HTTPS 프록시 (SSL) |
| STCP | type = "stcp" | 안전한 TCP 프록시 (키 페어) |
| SUDP | type = "sudp" | 안전한 UDP 프록시 |
| XTCP | type = "xtcp" | P2P 홀 펀칭 (서버 대역폭 불필요) |
| TCPMux | type = "tcpmux" | TCP 멀티플렉싱 |

### Docker 배포

#### Docker 사용

```bash
# 1. 설정 디렉토리 생성
mkdir -p /etc/frp /var/log/frp

# 2. 설정 파일 저장 (스크립트가 생성한 설정 사용)
# 설정을 /etc/frp/frpc.toml로 저장

# 3. Docker 배포
docker run -d \
  --name frpc \
  --restart unless-stopped \
  --network host \
  -v /etc/frp/frpc.toml:/etc/frp/frpc.toml \
  -v /var/log/frp:/var/log/frp \
  snowdreamtech/frpc:0.69.1

# 4. 로그 보기
docker logs -f frpc
```

#### Docker Compose 사용

```yaml
# docker-compose.yml
version: '3'
services:
  frpc:
    image: snowdreamtech/frpc:0.69.1
    container_name: frpc
    restart: unless-stopped
    network_mode: host
    volumes:
      - /etc/frp/frpc.toml:/etc/frp/frpc.toml
      - /var/log/frp:/var/log/frp
```

```bash
# 시작
docker-compose up -d

# 로그 보기
docker-compose logs -f
```

### 관리 명령어

```bash
# 서비스 관리
systemctl start frps      # 시작
systemctl stop frps       # 중지
systemctl restart frps    # 재시작
systemctl status frps     # 상태
journalctl -u frps -f     # 로그

# 설정 파일 위치
/etc/frp/frps.toml        # frps 설정
/var/log/frp/frps.log     # frps 로그
```

### 네트워크 최적화 매개변수

스크립트는 메모리 및 전송 크기에 따라 다음 매개변수를 자동 조정합니다:

| 매개변수 | 1GB | 2GB | 4GB | 8GB+ |
|----------|-----|-----|-----|------|
| TCP 버퍼 | 4MB | 16MB | 32MB | 64MB |
| 연결 백로그 | 32768 | 49152 | 65535 | 65535 |
| 풀 카운트 | 200 | 500 | 1000 | 2000 |
| Max Orphans | 32768 | 131072 | 262144 | 524288 |

### 자주 묻는 질문

#### Q: 스크립트 실행이 실패하면 어떻게 하나요?

```bash
# root 사용자로 실행하는지 확인
sudo bash deploy_frps.sh

# 네트워크 연결 확인
curl -I https://github.com

# 자세한 오류 보기
bash -x deploy_frps.sh
```

#### Q: 설정을 수정한 후 다시 배포하려면 어떻게 하나요?

```bash
# 스크립트 다시 실행
sudo bash deploy_frps.sh

# [2]를 선택하여 설정 수정
# 수정 후 [1]을 선택하여 다시 배포
```

#### Q: frps를 제거하려면 어떻게 하나요?

```bash
# 방법 1: 스크립트로 제거
sudo bash deploy_frps.sh
# [6]를 선택하여 frps 제거

# 방법 2: 수동 제거
systemctl stop frps
systemctl disable frps
rm -f /usr/local/bin/frps
rm -rf /etc/frp /var/log/frp
rm -f /etc/systemd/system/frps.service
```

### 변경 로그

#### v1.0.0 (2024-01-01)
- 초기 릴리스
- 대화형 메뉴 인터페이스
- 동적 네트워크 최적화
- 다중 프로토콜 frpc 설정 생성
- Docker 배포 지원

### 릴리스 및 아티팩트

이 리포지토리는 매주 자동으로 frp의 새 릴리스를 확인하고 다음을 생성합니다:

- **바이너리 파일**: frps와 frpc (amd64/arm64/arm)
- **Docker 이미지**: Docker Hub와 GitHub Container Registry에서 사용 가능
- **체크섬**: 모든 바이너리 파일의 SHA256 검증

#### 바이너리 파일 다운로드

```bash
# 최신 frps 다운로드 (amd64)
curl -fsSL https://github.com/Ac-All-Sh/immich-frps/releases/latest/download/frps_linux_amd64 -o /usr/local/bin/frps
chmod +x /usr/local/bin/frps

# 최신 frpc 다운로드 (amd64)
curl -fsSL https://github.com/Ac-All-Sh/immich-frps/releases/latest/download/frpc_linux_amd64 -o /usr/local/bin/frpc
chmod +x /usr/local/bin/frpc
```

#### Docker 이미지

```bash
# Docker Hub
docker pull acallsh/frps:latest-amd64
docker pull acallsh/frpc:latest-amd64

# GitHub Container Registry
docker pull ghcr.io/ac-all-sh/frps:latest-amd64
docker pull ghcr.io/ac-all-sh/frpc:latest-amd64
```

### 라이선스

이 프로젝트는 MIT 라이선스로 라이선스가 부여됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요

### 개발자

**Ac.All.Sh** - [GitHub](https://github.com/Ac-All-Sh)

---

## Author

<div align="center">

![Ac.All.Sh](https://github.com/Ac-All-Sh.png?size=100)

**Ac.All.Sh** | [GitHub](https://github.com/Ac-All-Sh) | WeChat: @attychen

</div>

---

## Statistics

<div align="center">

![Star History Chart](https://api.star-history.com/svg?repos=Ac-All-Sh/immich-frps&type=Date)

</div>

---

**Ac.All.Sh** | MIT License
