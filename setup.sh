#!/usr/bin/env bash
# =====================================================================
#  幻兽帕鲁 (Palworld) 专用服务器 —— macOS 一键管理脚本
#  用法:
#    ./setup.sh            首次安装并启动（默认）
#    ./setup.sh start      启动服务器
#    ./setup.sh stop       停止服务器
#    ./setup.sh restart    重启服务器
#    ./setup.sh update     拉取最新镜像并重建
#    ./setup.sh logs       实时查看日志（Ctrl+C 退出）
#    ./setup.sh status     查看容器与健康状态
#    ./setup.sh backup     立即手动备份存档
# =====================================================================
set -euo pipefail

# 切换到脚本所在目录，保证相对路径正确
cd "$(dirname "$0")"

SERVICE="palworld"
DATA_DIR="./palworld"

# ---------- 彩色输出 ----------
c_info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
c_ok()    { printf '\033[1;32m[ OK ]\033[0m  %s\n' "$*"; }
c_warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
c_err()   { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; }

# ---------- docker compose 命令探测 ----------
detect_compose() {
  if docker compose version >/dev/null 2>&1; then
    DC="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    DC="docker-compose"
  else
    c_err "未找到 docker compose。请安装并启动 Docker Desktop 后重试。"
    exit 1
  fi
}

# ---------- 前置检查 ----------
preflight() {
  if ! command -v docker >/dev/null 2>&1; then
    c_err "未检测到 docker 命令。请先安装 Docker Desktop: https://www.docker.com/products/docker-desktop/"
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    c_err "Docker 守护进程未运行。请先打开 Docker Desktop，待其完全启动后再运行本脚本。"
    exit 1
  fi
  detect_compose

  local arch
  arch="$(uname -m)"
  case "$arch" in
    arm64|aarch64)
      c_info "检测到 Apple/ARM64 芯片：将使用内置 Box64 的 arm64 镜像原生运行（推荐）。"
      c_info "若日后服务端频繁崩溃，可在 .env 中调高 BOX64_DYNAREC_STRONGMEM 等参数。"
      ;;
    x86_64|amd64)
      c_info "检测到 x86_64 芯片：使用原生 amd64 镜像。"
      ;;
    *)
      c_warn "未知架构 ($arch)，仍将尝试启动。"
      ;;
  esac
}

# ---------- 密码安全检查 ----------
check_passwords() {
  if [ ! -f .env ]; then
    c_err "缺少 .env 文件，请确认与 docker-compose.yml 在同一目录。"
    exit 1
  fi
  if grep -q 'CHANGE_ME' .env; then
    c_warn "检测到 .env 中仍是默认占位密码 (CHANGE_ME...)。"
    c_warn "强烈建议先编辑 .env 修改 SERVER_PASSWORD 与 ADMIN_PASSWORD。"
    printf '是否仍要继续启动? [y/N] '
    read -r ans
    case "$ans" in
      y|Y) c_warn "已选择继续，请尽快修改密码。" ;;
      *)   c_info "已取消。修改 .env 后再次运行 ./setup.sh 即可。"; exit 0 ;;
    esac
  fi
}

# ---------- 打印连接信息 ----------
print_connection_info() {
  local ip
  ip="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo '<本机IP>')"
  echo
  c_ok  "服务器已启动！"
  echo  "  局域网连接地址 : ${ip}:8211"
  echo  "  本机连接地址   : 127.0.0.1:8211"
  echo  "  外网联机       : 需在路由器把 UDP 8211 端口转发到本机 ${ip}"
  echo  "  存档目录       : ${DATA_DIR}"
  echo
  c_info "首次启动会通过 steamcmd 下载服务端，可能需要数分钟。"
  c_info "用 './setup.sh logs' 查看进度，出现 'Running Palworld dedicated server' 即就绪。"
}

# ---------- 子命令 ----------
cmd_setup() {
  preflight
  check_passwords
  mkdir -p "$DATA_DIR"
  c_info "拉取最新镜像..."
  $DC pull
  c_info "启动容器..."
  $DC up -d
  print_connection_info
}

cmd_start()   { detect_compose; $DC up -d; c_ok "已启动。"; }
cmd_stop()    { detect_compose; $DC down; c_ok "已停止。"; }
cmd_restart() { detect_compose; $DC restart; c_ok "已重启。"; }
cmd_update()  { detect_compose; $DC pull && $DC up -d; c_ok "已更新并重建。"; }
cmd_logs()    { detect_compose; $DC logs -f --tail=100 "$SERVICE"; }
cmd_status()  { detect_compose; $DC ps; }
cmd_backup()  { detect_compose; $DC exec "$SERVICE" backup; c_ok "备份已触发（见存档目录的 backups）。"; }

main() {
  local action="${1:-setup}"
  case "$action" in
    setup|"")  cmd_setup ;;
    start)     cmd_start ;;
    stop)      cmd_stop ;;
    restart)   cmd_restart ;;
    update)    cmd_update ;;
    logs)      cmd_logs ;;
    status)    cmd_status ;;
    backup)    cmd_backup ;;
    -h|--help|help)
      grep -E '^#( |=)' "$0" | sed 's/^# \{0,1\}//'
      ;;
    *)
      c_err "未知命令: $action"
      echo "可用命令: setup | start | stop | restart | update | logs | status | backup"
      exit 1
      ;;
  esac
}

main "$@"
