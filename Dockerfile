# ============================================================
# frps-panel 多架构 Docker 镜像
# 构建: docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t acallsh/frps-panel:latest --push .
# ============================================================

# ---- Stage 1: 构建 Vue 前端 ----
FROM node:18-alpine AS frontend-builder

WORKDIR /app/web/frps
COPY web/frps/package*.json ./
RUN npm install --force

COPY web/frps/ ./
RUN npm run build:ci

# ---- Stage 2: 构建 Go 后端 ----
FROM golang:1.23-alpine AS backend-builder

RUN apk add --no-cache git make gcc musl-dev

WORKDIR /app

# 先复制依赖文件，利用 Docker 缓存
COPY go.mod go.sum ./
RUN go mod download

# 复制源码
COPY . .

# 复制前端构建产物到静态目录
COPY --from=frontend-builder /app/web/frps/dist ./web/frps/dist

# 构建参数
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG VERSION=dev
ARG BUILD_TIME=unknown

# ARM 变体处理
RUN if [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v7" ]; then \
        export GOARM=7; \
    elif [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v5" ]; then \
        export GOARM=5; \
    fi

# 编译
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} \
    go build -trimpath -ldflags="-s -w \
    -X github.com/xxl6097/go-frp-panel/pkg.AppVersion=${VERSION} \
    -X github.com/xxl6097/go-frp-panel/pkg.BuildTime=${BUILD_TIME}" \
    -o /app/frps-panel ./cmd/server

# ---- Stage 3: 运行时镜像 ----
FROM alpine:3.20

LABEL org.opencontainers.image.title="frps-panel"
LABEL org.opencontainers.image.description="frps Web 管理面板 — 监控、优化、带宽管理"
LABEL org.opencontainers.image.source="https://github.com/attychen/immich-frps"
LABEL org.opencontainers.image.vendor="acallsh"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache ca-certificates tzdata curl && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# 创建必要目录
RUN mkdir -p /etc/frp /var/log/frp /app/clients

COPY --from=backend-builder /app/frps-panel /usr/local/bin/frps-panel
COPY frps.toml /etc/frp/frps.toml

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:7500/api/health || exit 1

EXPOSE 7000 7500 8080 8443

VOLUME ["/etc/frp", "/var/log/frp"]

ENTRYPOINT ["frps-panel"]
CMD ["server", "-c", "/etc/frp/frps.toml"]
