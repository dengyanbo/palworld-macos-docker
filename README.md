# 幻兽帕鲁 (Palworld) 专用服务器 — macOS 一键搭建（Docker）

在 **macOS（含 Apple 芯片 M1/M2/M3/M4）** 上用 Docker 一键搭建 Palworld 专用服务器。
容器内部通过 **steamcmd** 安装服务端，使用成熟社区镜像
[`thijsvanloef/palworld-server-docker`](https://github.com/thijsvanloef/palworld-server-docker)。

> 说明：Palworld 官方专用服务器只有 Windows / Linux 版本，**没有 macOS 原生版本**，
> 因此不能在 macOS 上直接用 steamcmd 运行。Docker 是 macOS 上的可行方案。
> 本镜像为多架构镜像，其 **arm64 变体内置 Box64**，可在 Apple 芯片上原生运行，无需 Rosetta。

## 前置条件

- 已安装并启动 **Docker Desktop**（菜单栏出现鲸鱼图标且状态为 Running）
- 文件目录包含：`docker-compose.yml`、`.env`、`setup.sh`

## 一键使用

```bash
# 1) 进入文件所在目录
cd palworld-macos

# 2) （重要）编辑 .env，修改两个密码
#    SERVER_PASSWORD / ADMIN_PASSWORD
nano .env

# 3) 赋予执行权限并一键启动
chmod +x setup.sh
./setup.sh
```

首次启动会通过 steamcmd 下载服务端，可能需要数分钟。用 `./setup.sh logs`
查看进度，日志出现 `Running Palworld dedicated server` 即就绪。

## 管理命令

| 命令 | 作用 |
| --- | --- |
| `./setup.sh` 或 `./setup.sh setup` | 首次安装并启动 |
| `./setup.sh start` | 启动 |
| `./setup.sh stop` | 停止 |
| `./setup.sh restart` | 重启 |
| `./setup.sh update` | 拉取最新镜像并重建 |
| `./setup.sh logs` | 实时日志（Ctrl+C 退出） |
| `./setup.sh status` | 查看容器/健康状态 |
| `./setup.sh backup` | 立即手动备份 |

## 连接服务器

- 局域网：`<你的Mac局域网IP>:8211`
- 本机：`127.0.0.1:8211`
- 在游戏里选择「加入多人游戏（专用服务器）」，输入地址与 `SERVER_PASSWORD`。

## 端口

| 端口 | 协议 | 用途 |
| --- | --- | --- |
| 8211 | UDP | 游戏端口（外网联机需在路由器转发此端口） |
| 27015 | UDP | 查询端口（社区服列表，可选） |
| 8212 | TCP | REST API（仅本机，**勿对公网转发**） |
| 25575 | TCP | RCON（默认关闭） |

外网联机：在路由器把 **UDP 8211** 端口转发到你的 Mac 局域网 IP；如运营商为
NAT，可考虑使用 frp / Tailscale 等内网穿透方案。

## 数据与备份

- 存档与服务端文件持久化在 `./palworld/` 目录。
- 默认每天 0 点自动备份（见 `.env` 的 `BACKUP_ENABLED` / `BACKUP_CRON_EXPRESSION`）。

## 常见问题

- **服务端频繁崩溃（Apple 芯片）**：在 `.env` 调高 Box64 稳定性参数，例如
  `BOX64_DYNAREC_STRONGMEM=3`、`BOX64_DYNAREC_BIGBLOCK=0`，然后 `./setup.sh restart`。
- **想用 amd64 + Rosetta**：在 `docker-compose.yml` 取消 `platform: linux/amd64`
  注释，并在 Docker Desktop 设置里开启 Rosetta 模拟，再 `./setup.sh restart`。
- **Docker 未运行**：脚本会提示先打开 Docker Desktop 并等待其完全启动。
- **修改配置不生效**：改完 `.env` 后执行 `./setup.sh restart`。

## 安全提示

- 务必修改 `.env` 中的 `SERVER_PASSWORD` 与 `ADMIN_PASSWORD`。
- 不要把 REST API(8212) 或 RCON(25575) 端口转发到公网。
