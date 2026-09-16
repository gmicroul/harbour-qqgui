# NapCat 一键部署包（QQ 桥接 · distrobox 容器版）

在全新的 distrobox Fedora 容器（里面已经装好官方 LinuxQQ）里，一条命令部署 NapCat，走 OneBot11 协议（WebSocket + HTTP）作为 harbour-qqcat 等 QQ 桥接 App 的后端。

这个包是从新机实战里磨出来的：部署时踩过的每个坑，都写成了脚本里的自动防护。目标是"一条命令、扫一次码、一次跑通"。

## 包里有什么

| 文件 | 用途 |
|------|------|
| `napcat-deploy.sh` | 一键部署主脚本：装依赖、下载、注入、预写配置、扫码、验证，全包了 |
| `napcat-status.sh` | 部署后/日常自检：进程、三个端口、在线状态、花名册 API、token、最近错误 |
| `harbour-qqcat-1.0.0-1.aarch64.rpm` | QQ 桥接 App（宿主机装：`zypper in ./xxx.rpm` 或 `pkcon`） |
| `README.md` | 本文档 |

App 安装：

```
devel-su zypper in ./harbour-qqcat-1.0.0-1.aarch64.rpm
```

前端：`https://openrepos.net/sites/default/files/packages/19652/harbour-qqcat-1.0.0-1.aarch64.rpm`

后端：`https://openrepos.net/sites/default/files/packages/19652/new-deployment-qqcat.tar_.gz_.rpm`
（参考快速开始在宿主机装：单独下载后先改名为 `new-deployment-qqcat.tar.gz`，再解压，把两个 sh 文件放到宿主机。）

> 依赖容器里先部署好 NapCat——建议先跑 `napcat-deploy.sh` 再装 App，体验最好。

## 环境要求

- **宿主机**：SailfishOS 或其它带 distrobox 的 Linux
- **容器**：Fedora（distrobox 创建），已装官方 LinuxQQ（存在 `/opt/QQ/qq`）
- 容器内 `defaultuser` 可免密 sudo（distrobox 默认配置就行）
- 手机 QQ 上登录着机器人要用的那个 QQ 号（用来扫码授权）

## 快速开始

```bash
# 0. 把整个目录拷到新机宿主，比如 ~/new-deployment-qqcat/

# 1. 容器没起来的话先拉一下
distrobox enter fedora44 -- true

# 2. 一键部署（QQ 号换成你自己的）
cd ~/new-deployment-qqcat
bash napcat-deploy.sh <你的QQ号>

# 3. 按提示用手机 QQ 扫描 ~/napcat-qrcode.png 并点授权确认

# 4. 自检
bash napcat-status.sh
```

看到 `✓ 登录成功！` 和最终摘要里的三个 ✓ 就算成了。

## napcat-deploy.sh 参数

```
bash napcat-deploy.sh <QQ号> [容器名] [GitHub代理] [--install-service]
```

| 参数 | 说明 | 默认 |
|------|------|------|
| `<QQ号>` | 必填。机器人账号，预写 OneBot 配置要用 | — |
| `[容器名]` | distrobox 容器名 | `fedora44` |
| `[代理]` | GitHub 下载代理，如 `http://<代理IP>:<端口>` | 直连 |
| `--install-service` | 顺便装 systemd 用户服务，开机自启 | 不装 |

环境变量：`NAPCAT_CONTAINER` / `NAPCAT_PROXY` / `NAPCAT_VERSION`（默认锁定 `v4.18.19`，可设 `latest` 或任意 tag）/ `NAPCAT_QR_OUT`（二维码落盘路径）。

## 脚本会自动做的事

- 检查容器内 QQ、sudo 免密，安装 unzip / Xvfb
- 彻底清场（含僵尸实例），校验 `REMAIN=0`
- 下载 NapCat.Shell.zip（复用容器里已有的完整 zip；直连失败可走代理）
- 备份原始 `package.json` → `.orig`，解压注入，改 `"main": "./napcat.mjs"`
- 把 OneBot11 配置同时写进两处生效路径：
  - `~/.config/QQ/NapCat/config/onebot11_<QQ号>.json`
  - `/opt/QQ/resources/app/config/onebot11_<QQ号>.json`
  - 两处都含 WebSocket(:3001) 和 HttpApi(:3000) —— 缺一不可
- 启动（固定 xvfb 显示号 `:88`，保持设备指纹稳定不掉登录），同步二维码到宿主
- 轮询日志等登录成功；如果检测到"账号已在其他设备登录"，给出精确处置指引
- 验证 :3001 监听 → 设置 `autoLoginAccount` → 打印 WebUI token 和桥接三项

## 部署完成后：桥接 App 配置

harbour-qqcat 设置页填三项（脚本结束时也会打印）：

```
wsUrl      = ws://127.0.0.1:3001
webuiBase  = http://127.0.0.1:6099
webuiToken = <脚本打印的 token>
```

token 由 NapCat 首次启动随机生成，放在容器内 `/opt/QQ/resources/app/config/webui.json`。**认准这份**——容器里可能有别的旧副本，别抄错。

## 状态自检

```bash
bash napcat-status.sh            # 默认容器
bash napcat-status.sh mycontainer
```

逐项输出：进程实例数、三个端口、`get_status` 在线状态、花名册 API 实测、token、最近错误行。

正常标准：实例 1 个；三个端口都在监听；`online: true`；HTTP 能返回好友数据。

## 常见问题排查（症状 → 原因 → 解决）

**① app 显示「WebUI auth failed / 授权失败」**
原因：app 里填的 token 跟运行实例对不上（最常见是抄了旧配置目录里的死值）
解决：`bash napcat-status.sh` 看"WebUI token"那一行，照它填

**② 日志出现「当前账号已登录,无法重复登录」**
原因：另一台设备（旧机 NapCat / 其它桌面端）还占着这个号的 PC 会话；或者同容器起了多个 QQ 实例互抢
解决：停掉其它设备（旧机：`systemctl --user stop napcat`），确认 `napcat-status.sh` 显示实例只有 1 个，重跑 deploy 脚本

**③ 快速登录报「登录需要手Q验证」**
原因：新设备风控，腾讯要求手机 QQ 授权
解决：手机 QQ 弹出的确认框点同意即可；没弹窗或过期的话，按二维码重新扫一次
根治：启动命令给 qq 加环境变量（见下文"免验证重启"）

**④ WS 正常、消息能收，但 app 花名册一直转圈 / 卡 starting bridge**
原因：HttpApi(:3000) 没配！花名册走 HTTP 不是 WebSocket
解决：检查两处 onebot11 配置里有没有 `httpServers`(端口3000)，补上后重启 QQ。v2 脚本的 seedcfg 已自带，理论上不会再遇到

**⑤ :3001 在监听但 `get_status` 无响应**
原因：OneBot 配置被 NapCat 规范化覆盖成空服务列表
解决：把 `websocketServers`/`httpServers` 合并回 `/opt/QQ/resources/app/config/onebot11_<QQ号>.json` 后重启

**⑥ 二维码扫了没反应 / 提示过期**
二维码约 2 分钟自动刷新，`~/napcat-qrcode.png` 会持续更新，关掉图片重开再扫
扫码后注意手机上的授权确认弹窗，必须点同意

**⑦ 下载 NapCat.Shell.zip 失败**
直连 GitHub 超时很正常，传代理参数：`bash napcat-deploy.sh <QQ号> fedora44 http://IP:7897`
或者手动下载 zip 放进容器 `/tmp/NapCat.Shell.zip`，脚本检测到完整 zip 会直接复用

## 容器内文件位置速查

| 文件 | 说明 |
|------|------|
| `/opt/QQ/resources/app/package.json.orig` | 原始 QQ 入口备份（卸载还原用） |
| `/opt/QQ/resources/app/package.json` | 已改成 `"main": "./napcat.mjs"` |
| `/opt/QQ/resources/app/napcat/` + `napcat.mjs` | NapCat 本体 |
| `/opt/QQ/resources/app/config/webui.json` | ⭐ 生效的 WebUI 配置（token 在这里） |
| `/opt/QQ/resources/app/config/onebot11_<uin>.json` | ⭐ 生效的 OneBot 配置 |
| `~/.config/QQ/NapCat/config/onebot11_<uin>.json` | 同内容备份路径 |
| `/tmp/napcat.log` | 运行日志 |

## 开机自启

```bash
bash napcat-deploy.sh <QQ号> fedora44 "" --install-service
```

生成 `~/.config/systemd/user/napcat.service`：启动前自动清场防 crash-loop，固定显示号 `:88` 保持设备指纹。管理命令：

```bash
systemctl --user status napcat
systemctl --user restart napcat
systemctl --user disable napcat   # 多台设备二选一时，停用方务必 disable
```

## 免验证重启（可选加固）

新设备频繁重启会反复触发手Q验证。设置密码快速登录可以跳过：

编辑 service 的 `ExecStart`，在 `qq` 前加：

```
env ACCOUNT=<QQ号> NAPCAT_QUICK_PASSWORD=你的QQ密码
```

> ⚠️ 密码写在本机 service 文件里就好，不要提交到仓库或发给别人。

## 卸载 / 回滚

```bash
# 进容器执行
distrobox enter fedora44
cd /opt/QQ/resources/app
pkill -9 -f '/opt/QQ'                    # 停 QQ
cp package.json.orig package.json        # 还原入口
rm -rf napcat napcat.mjs loadNapCat.js   # 移除 NapCat
# config/ 下的 onebot11_*.json、webui.json 可一并删除
```

宿主机卸载自启：

```bash
systemctl --user disable --now napcat && rm ~/.config/systemd/user/napcat.service
```

## 安全提醒

- WebUI(6099) 监听所有网卡，别暴露到公网；token 泄露就改 `webui.json` 重启
- 多台设备不能同时跑同一账号的 NapCat（互踢）；迁移时先停旧机再上新机
- 分发本包前可用 `grep -nE '<你的QQ号>|token值' *` 自查一遍隐私

## 版本

**napcat-deploy.sh v2（2026-08-25）**：吸收了新机实战全部坑位
- 双路径预写 OneBot 配置（含 HttpApi:3000，修复"花名册卡住"）
- 文件式清场，杜绝 pkill 自匹配造成的僵尸实例
- token 只认运行实例；三级下载回退 + zip 缓存；幂等重跑
- must to do if can not scan to login:
  pkill -f 'qq --no-sandbox'
