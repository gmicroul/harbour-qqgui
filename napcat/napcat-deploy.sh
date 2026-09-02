#!/usr/bin/env bash
# ============================================================================
# napcat-deploy.sh — 全新环境 NapCat 一键部署（v2 终极版，一次跑通设计）
#
# 本脚本吸收了实际部署中踩过的所有坑，内置以下保障：
#   [1] QQ号作为参数传入 → 启动前就把 OneBot11 配置写到【两处】可能的生效路径
#       （~/.config/QQ/NapCat/config 与 /opt/QQ/resources/app/config），
#       登录完成即桥接就绪，无需登录后二次重启触发风控
#   [2] 清场/启动逻辑全部走独立脚本文件执行，杜绝 pkill 自匹配导致的
#       僵尸实例叠加（多实例互抢登录态 = "当前账号已登录"死循环）
#   [3] WebUI token 只认运行实例真实生成的 /opt/QQ/resources/app/config/webui.json
#   [4] NapCat 版本默认锁定 v4.18.19（可 NAPCAT_VERSION 覆盖），下载直连 GitHub
#       失败可传代理参数走代理，且复用容器内已有完整 zip
#   [5] 幂等：重复运行安全；若检测到已在线(:3001)直接报告成功退出
#   [6] 二维码同步到宿主并轮询日志直到登录成功；检测到"账号已在其他设备登录"
#       时给出精确处置指引
#
# 用法（宿主终端）：
#   bash napcat-deploy.sh <QQ号>                    # 必填：机器人QQ号
#   bash napcat-deploy.sh <QQ号> fedora44           # 指定容器名
#   bash napcat-deploy.sh <QQ号> fedora44 http://IP:7897   # GitHub代理
#   bash napcat-deploy.sh <QQ号> fedora44 "" --install-service   # 加装开机自启
# 环境变量：NAPCAT_PROXY=... NAPCAT_VERSION=v4.18.19 NAPCAT_CONTAINER=...
# ============================================================================
set -uo pipefail

UIN="${1:?用法: bash napcat-deploy.sh <QQ号> [容器名] [代理] [--install-service]}"
UIN="${UIN%% *}"
[[ "$UIN" =~ ^[0-9]{6,12}$ ]] || { echo "✗ QQ号格式不对: $1" >&2; exit 1; }
CONTAINER="${2:-${NAPCAT_CONTAINER:-fedora44}}"
PROXY="${3:-${NAPCAT_PROXY:-}}"
INSTALL_SERVICE="${4:-}"
NC_VER="${NAPCAT_VERSION:-v4.18.19}"
QR_OUT="${NAPCAT_QR_OUT:-$HOME/napcat-qrcode.png}"
XDISP=88                       # 固定显示号保持设备指纹稳定，重启不掉登录
APP="/opt/QQ/resources/app"
LOG="/tmp/napcat.log"
REMOTE="$HOME/.cache/npd-remote.sh"

say(){ printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m➜\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
dx(){ distrobox enter "$CONTAINER" -- bash -c "$1"; }

# ======================= 内嵌远端多阶段脚本 =======================
mkdir -p "$(dirname "$REMOTE")"
cat > "$REMOTE" <<'RMT'
#!/usr/bin/env bash
# 用法: npd-remote.sh <stage> <uin> <app> <log> <xdisp> [proxy] [ver]
set -uo pipefail
STAGE="${1:-}"; UIN="${2:-}"; APP="${3:-}"; LOG="${4:-}"; XD="${5:-88}"
PROXY="${6:-}"; NC_VER="${7:-v4.18.19}"
[ -n "$STAGE" ] || { echo "usage: remote <stage> ..."; exit 1; }

hard_clean(){
  # 独立函数：按多种特征杀干净所有 QQ/Xvfb 实例（本脚本自身cmdline不含这些词）
  for pat in 'xvfb-run' '/opt/QQ/qq' 'qq --no-sandbox' 'NodeService' 'Xvfb :'; do
    for pid in $(pgrep -f "$pat" 2>/dev/null); do
      [ "$pid" != "$$" ] && kill -9 "$pid" 2>/dev/null
    done
  done
  rm -f "/tmp/.X${XD}-lock" "/tmp/.X11-unix/X${XD}" 2>/dev/null
  sleep 2
  local left=0 c
  for pat in 'qq --no-sandbox' 'Xvfb :'; do
    c=$(pgrep -fc "$pat" 2>/dev/null); c=${c:-0}
    left=$((left + c))
  done
  echo "REMAIN=$left"
}

launch_one(){
  cd "$APP" || exit 51
  local QB="qq"; command -v qq >/dev/null 2>&1 || QB="/opt/QQ/qq"
  nohup xvfb-run -n "$XD" -f /tmp/qq-xauth "$QB" --no-sandbox --disable-gpu \
      >> "$LOG" 2>&1 &
  sleep 8
  pgrep -f '/opt[/]QQ/qq' >/dev/null && echo LAUNCH_OK || { echo LAUNCH_FAIL; tail -15 "$LOG"; }
}

case "$STAGE" in

deps)
  command -v unzip    >/dev/null 2>&1 || sudo -n dnf install -y unzip || exit 11
  command -v xvfb-run >/dev/null 2>&1 || sudo -n dnf install -y xorg-x11-server-Xvfb || exit 12
  echo DEPS_OK ;;

download)
  if [ -f /tmp/NapCat.Shell.zip ] && unzip -tq /tmp/NapCat.Shell.zip >/dev/null 2>&1; then
    echo "DOWNLOAD_OK via cached"; exit 0
  fi
  if [ "$NC_VER" = "latest" ]; then
    REL="NapNeko/NapCatQQ/releases/latest/download/NapCat.Shell.zip"
  else
    REL="NapNeko/NapCatQQ/releases/download/${NC_VER}/NapCat.Shell.zip"
  fi
  ok=""
  for m in "https://github.com/"; do
    echo "[try] ${m}"
    rm -f /tmp/NapCat.Shell.zip
    curl -fsSL -m 600 --retry 1 --connect-timeout 15 "${m}${REL}" \
         -o /tmp/NapCat.Shell.zip \
      && unzip -tq /tmp/NapCat.Shell.zip >/dev/null 2>&1 && { ok="$m"; break; }
  done
  if [ -z "$ok" ] && [ -n "$PROXY" ]; then
    rm -f /tmp/NapCat.Shell.zip
    curl -fsSL -m 900 --retry 1 -x "$PROXY" "https://github.com/${REL}" \
         -o /tmp/NapCat.Shell.zip \
      && unzip -tq /tmp/NapCat.Shell.zip >/dev/null 2>&1 && ok="proxy:$PROXY"
  fi
  [ -n "$ok" ] || { echo DOWNLOAD_FAILED; exit 21; }
  echo "DOWNLOAD_OK via ${ok}" ;;

install)
  [ -x /opt/QQ/qq ] || { echo NO_QQ; exit 31; }
  [ -f "$APP/package.json.orig" ] || sudo -n cp "$APP/package.json" "$APP/package.json.orig" || exit 32
  sudo -n cp "$APP/package.json" "$APP/package.json.bak.$(date +%Y%m%d%H%M%S)"
  ls -1t "$APP"/package.json.bak.* 2>/dev/null | tail -n +4 | xargs -r rm -f
  sudo -n unzip -oq /tmp/NapCat.Shell.zip -d "$APP" || exit 33
  sudo -n chown -R "$(id -u):$(id -g)" "$APP" 2>/dev/null
  rm -f /tmp/NapCat.Shell.zip
  cd "$APP" || exit 35
  python3 - <<'PY'
import json
p=json.load(open("package.json"))
p["main"]="./napcat.mjs"
json.dump(p,open("package.json","w"),indent=2)
print("[patched] main =",p["main"])
PY
  grep -q '"main": *"\./napcat\.mjs"' package.json || { echo PATCH_FAILED; exit 36; }
  [ -f "$APP/napcat.mjs" ] || [ -f "$APP/napcat/napcat.mjs" ] || { echo NO_NAPCAT_MJS; exit 34; }
  [ -f "$APP/napcat.mjs" ] || sed -i 's#"./napcat.mjs"#"./napcat/napcat.mjs"#' "$APP/package.json"
  echo INSTALL_OK ;;

seedcfg)
  # 关键防坑：把 OneBot11 配置写入两处可能的生效路径
  CFGDIR="$HOME/.config/QQ/NapCat/config"
  mkdir -p "$CFGDIR" "$APP/config"
  write_cfg(){ cat > "$1" <<JSON
{
  "network": {
    "websocketServers": [{
      "name": "Bridge",
      "enable": true,
      "host": "0.0.0.0",
      "port": 3001,
      "enableForcePushEvent": true,
      "messagePostFormat": "array",
      "reportSelfMessage": true,
      "token": "",
      "debug": false,
      "heartInterval": 30000
    }],
    "httpServers": [{
      "name": "HttpApi",
      "enable": true,
      "host": "0.0.0.0",
      "port": 3000,
      "enableCors": true,
      "messagePostFormat": "array",
      "token": "",
      "debug": false
    }]
  },
  "musicSignUrl": "",
  "enableLocalFile2Url": false,
  "parseMultMsg": false
}
JSON
  }
  write_cfg "$CFGDIR/onebot11_${UIN}.json"
  write_cfg "$APP/config/onebot11_${UIN}.json"
  echo "SEED_OK home=$CFGDIR app=$APP/config" ;;

setautologin)
  WP="$APP/config/webui.json"
  [ -f "$WP" ] && python3 - "$WP" "$UIN" <<'PY'
import json,sys
p,uin=sys.argv[1],sys.argv[2]
try:
    d=json.load(open(p))
except Exception:
    sys.exit(0)
if d.get("autoLoginAccount")!=uin:
    d["autoLoginAccount"]=uin
    json.dump(d,open(p,"w"),indent=4)
print("AUTOLOGIN_SET",uin)
PY
  echo AUTOLOGIN_DONE ;;

clean)
  hard_clean ;;

start)
  hard_clean >/dev/null
  > "$LOG"
  launch_one ;;
esac
RMT

# ============================ 主流程 ============================
command -v distrobox >/dev/null 2>&1 || die "宿主缺少 distrobox"
distrobox list 2>/dev/null | grep -qw "$CONTAINER" \
  || die "容器 $CONTAINER 不存在。先创建：distrobox create -n $CONTAINER -i fedora:44"

chmod +x "$REMOTE"
RS(){ distrobox enter "$CONTAINER" -- bash "$REMOTE" "$@"; }

CHOME=$(dx 'echo $HOME') || die "无法进入容器"
say "容器内HOME = $CHOME"

# ---- 快速路径：已经在线就直接成功 ----
if dx "ss -ltn 2>/dev/null | grep -q ':3001'" 2>/dev/null; then
  TOKEN=$(dx "python3 -c \"import json;print(json.load(open('$APP/config/webui.json')).get('token',''))\"" 2>/dev/null)
  say "检测到 :3001 已在监听 —— 部署早已完成，无需重复操作"
  say "WebUI token = ${TOKEN:-未知}；桥接应用填 ws://127.0.0.1:3001 即可"
  exit 0
fi

say "[1/8] 容器内 QQ 与 sudo 免密检查 ..."
dx "test -x /opt/QQ/qq" || die "容器内没有 /opt/QQ/qq，请先安装官方 LinuxQQ：https://im.qq.com/linuxqq/"
dx "sudo -n true" 2>/dev/null || die "容器内 sudo 无法免密。先手动处理：distrobox enter $CONTAINER 后配置 NOPASSWD"

say "[2/8] 依赖 (unzip / Xvfb) ..."
OUT=$(RS deps "$UIN" "$APP" "$LOG" "$XDISP") || die "依赖安装失败($OUT)"
say "$OUT"

say "[3/8] 停掉旧实例（含僵尸进程清场）..."
OUT=$(RS clean "$UIN" "$APP" "$LOG" "$XDISP") || true
echo "$OUT"
echo "$OUT" | grep -q 'REMAIN=0' || die "仍有残留进程，手动检查：distrobox enter $CONTAINER -- pgrep -af qq"

say "[4/8] 下载 NapCat.Shell.zip ($NC_VER) ..."
OUT=$(RS download "$UIN" "$APP" "$LOG" "$XDISP" "$PROXY" "$NC_VER") || die "下载失败：$OUT"
say "$OUT"

say "[5/8] 解压注入 + 备份原入口 ..."
OUT=$(RS install "$UIN" "$APP" "$LOG" "$XDISP") || die "安装失败：$OUT"
echo "$OUT"

say "[6/8] 预写 OneBot11 配置到两处生效路径 (uin=$UIN) ..."
OUT=$(RS seedcfg "$UIN" "$APP" "$LOG" "$XDISP") || die "$OUT"
say "$OUT"

say "[7/8] 启动并等待扫码登录（二维码 → $QR_OUT）..."
OUT=$(RS start "$UIN" "$APP" "$LOG" "$XDISP") || true
echo "$OUT" | grep -q LAUNCH_OK || die "启动失败：$OUT"

echo "   ┌────────────────────────────────────────────────┐"
echo "   │ 用【已登录该QQ号的手机QQ】扫描二维码并点授权确认 │"
echo "   │ 二维码约2分钟自动刷新，图片持续更新，过期重扫即可 │"
echo "   └────────────────────────────────────────────────┘"
DEADLINE=$((SECONDS+600)); LOGGED=""
while [ $SECONDS -lt $DEADLINE ]; do
  dx "cat /opt/QQ/resources/app/cache/qrcode.png 2>/dev/null" > "$QR_OUT.part" 2>/dev/null || true
  [ -s "$QR_OUT.part" ] && mv -f "$QR_OUT.part" "$QR_OUT"
  if dx "grep -aqE 'WebSocket服务.*已启动|Server Started|登录成功' $LOG" 2>/dev/null; then LOGGED=1; break; fi
  if dx "ss -ltn 2>/dev/null | grep -q ':3001'" 2>/dev/null; then LOGGED=1; break; fi
  if dx "grep -aq '无法重复登录' $LOG" 2>/dev/null; then
    die "检测到『账号已在其他设备登录』——请先停掉其他设备上的 NapCat/QQ桌面端（旧机: systemctl --user stop napcat），再重新运行本脚本"
  fi
  printf '.'; sleep 5
done
echo; rm -f "$QR_OUT.part"
[ -n "$LOGGED" ] || die "10分钟未检测到登录。自查：distrobox enter $CONTAINER -- tail -40 $LOG ；处理后直接重跑本脚本（幂等）"
say "登录成功！"

say "[8/8] 收尾：确认桥接口 + 自动登录设置 ..."
for i in $(seq 1 12); do
  dx "ss -ltn 2>/dev/null | grep -q ':3001'" && break
  sleep 5
done
dx "ss -ltn 2>/dev/null | grep ':3001'" >/dev/null \
  && say "OneBot WebSocket 已监听 0.0.0.0:3001" \
  || warn ":3001 未监听！大概率配置被规范化覆盖——执行：distrobox enter $CONTAINER -- bash $REMOTE seedcfg $UIN $APP $LOG $XDISP 后重启QQ"
RS setautologin "$UIN" "$APP" "$LOG" "$XDISP" >/dev/null 2>&1
TOKEN=$(dx "python3 -c \"import json;print(json.load(open('$APP/config/webui.json')).get('token',''))\"" 2>/dev/null)

cat <<SUMMARY

======================= 🎉 部署完成 ========================
机器人QQ   : $UIN （在线）
OneBot WS  : ws://127.0.0.1:3001        （无需token）
NapCat WebUI: http://127.0.0.1:6099
WebUI Token : ${TOKEN:-<见 $APP/config/webui.json>}

桥接应用(harbour-qqcat等)设置页填写：
  wsUrl      = ws://127.0.0.1:3001
  webuiBase  = http://127.0.0.1:6099
  webuiToken = 上面的 Token

可选加固（彻底免手Q验证）：
  在启动命令中给 qq 前加环境变量：
    env ACCOUNT=$UIN NAPCAT_QUICK_PASSWORD=你的QQ密码
二维码图片(可删): $QR_OUT
============================================================
SUMMARY

if [ "$INSTALL_SERVICE" = "--install-service" ]; then
  SVC="$HOME/.config/systemd/user/napcat.service"
  mkdir -p "$(dirname "$SVC")"
  cat > "$SVC" <<EOF2
[Unit]
Description=NapCat QQ bridge in distrobox ($CONTAINER)
After=default.target

[Service]
Type=simple
ExecStartPre=/usr/bin/distrobox enter $CONTAINER -- bash $REMOTE clean $UIN $APP $LOG $XDISP
ExecStart=/usr/bin/distrobox enter $CONTAINER -- bash -c 'cd $APP && exec xvfb-run -n $XDISP -f /tmp/qq-xauth qq --no-sandbox --disable-gpu -q $UIN >> $LOG 2>&1'
Restart=on-failure
RestartSec=20
StartLimitIntervalSec=300
StartLimitBurst=5

[Install]
WantedBy=default.target
EOF2
  systemctl --user daemon-reload && systemctl --user enable --now napcat.service \
    && say "开机自启已安装并启动：systemctl --user status napcat" \
    || warn "服务安装失败，检查 $SVC"
else
  warn "如需开机自启：bash $0 $UIN $CONTAINER \"$PROXY\" --install-service"
fi