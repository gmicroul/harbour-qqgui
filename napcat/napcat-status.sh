#!/usr/bin/env bash
# ============================================================================
# napcat-status.sh — NapCat 部署状态一键自检
# 在宿主上运行：bash napcat-status.sh [容器名]
# 检查：进程实例数 / 三个端口 / 机器人在线状态 / HTTP花名册API / WebUI token / 最近错误
# ============================================================================
set -uo pipefail
CONTAINER="${1:-${NAPCAT_CONTAINER:-fedora44}}"
APP="/opt/QQ/resources/app"
LOG="/tmp/napcat.log"

ok(){ printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
bad(){ printf '  \033[1;31m✗ %s\033[0m\n' "$*"; }
info(){ printf '  \033[1;34m·\033[0m %s\n' "$*"; }

command -v distrobox >/dev/null 2>&1 || { echo "✗ 宿主缺少 distrobox"; exit 1; }
dx(){ distrobox enter "$CONTAINER" -- bash -c "$1" 2>/dev/null; }

echo "═══════ NapCat 状态自检 [$CONTAINER] ═══════"

# 1 进程实例数（正常应为 1 棵进程树）
N=$(dx "pgrep -fc 'qq --no-sandbox' 2>/dev/null") ; N=${N:-0}
if [ "$N" -ge 2 ] && [ "$N" -le 5 ]; then ok "QQ 实例：1 个（$N 个相关进程）"
elif [ "$N" -gt 5 ]; then bad "QQ 相关进程多达 $N 个 —— 可能存在僵尸多实例！运行清场后重启"
else bad "QQ 未运行 —— 先启动：distrobox enter $CONTAINER -- bash 启动命令"; fi

# 2 端口
for spec in "3001:WebSocket(事件推送)" "3000:HttpApi(花名册/收发)" "6099:WebUI(登录管理)"; do
  P="${spec%%:*}"; NAME="${spec#*:}"
  if dx "ss -ltn 2>/dev/null | grep -q ':$P'"; then ok "端口 $P 已监听 —— $NAME"
  else bad "端口 $P 未监听 —— $NAME"; fi
done

# 3 WS 在线状态
echo "  ── 机器人状态 ──"
R=$(dx "python3 - <<'PY'
import socket,base64,os,json,struct,time
try:
    s=socket.create_connection(('127.0.0.1',3001),4)
    k=base64.b64encode(os.urandom(16)).decode()
    s.sendall((f\"GET / HTTP/1.1\r\nHost: x\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: {k}\r\nSec-WebSocket-Version: 13\r\n\r\n\").encode())
    b=b''
    while b'\r\n\r\n' not in b: b+=s.recv(4096)
    def send_text(p):
        d=p.encode();m=os.urandom(4);h=b'\x81';l=len(d)
        if l<126: h+=bytes([0x80|l])
        else: h+=bytes([0x80|126])+struct.pack('>H',l)
        s.sendall(h+m+bytes(c^m[i%4] for i,c in enumerate(d)))
    def recv_msg():
        h=b''
        while len(h)<2:
            c=s.recv(2-len(h))
            if not c: raise EOFError
            h+=c
        ln=h[1]&0x7f
        if ln==126:
            e=b''
            while len(e)<2: e+=s.recv(2-len(e))
            ln=struct.unpack('>H',e)[0]
        elif ln==127:
            e=b''
            while len(e)<8: e+=s.recv(8-len(e))
            ln=struct.unpack('>Q',e)[0]
        d=b''
        while len(d)<ln:
            c=s.recv(ln-len(d))
            if not c: break
            d+=c
        return d
    send_text(json.dumps({'action':'get_status','echo':'v'}))
    deadline=time.time()+8; got=None
    while time.time()<deadline:
        s.settimeout(max(.2,deadline-time.time()))
        try: d=recv_msg()
        except socket.timeout: break
        try: m=json.loads(d.decode('utf-8'))
        except Exception: continue
        if m.get('echo')=='v': got=m.get('data'); break
    print(json.dumps(got,ensure_ascii=False) if got else 'NO_REPLY')
except Exception as e:
    print('CONN_FAIL')
PY")
case "$R" in
  *'"online": true'*) ok "机器人在线：$R" ;;
  *online*) bad "WS 有响应但账号离线：$R —— 需重新扫码或检查其他设备抢登" ;;
  NO_REPLY) bad "WS 无 API 响应（端口通但无数据）——查看日志 $LOG" ;;
  *) bad "无法连接 :3001 —— QQ 可能没起来" ;;
esac

# 4 HTTP 花名册 API
F=$(dx "curl -s -m 6 'http://127.0.0.1:3000/get_friend_list' | head -c 40" 2>/dev/null)
case "$F" in
  *'"status":"ok"'*|*retcode*) ok "HTTP 花名册 API 正常（返回好友数据）" ;;
  "") bad "HTTP :3000 无响应 —— 花名册会卡住，检查 onebot11 配置里 httpServers" ;;
  *) info "HTTP 返回异常内容：$F" ;;
esac

# 5 WebUI token
T=$(dx "python3 -c \"import json;print(json.load(open('$APP/config/webui.json')).get('token',''))\"" 2>/dev/null)
[ -n "$T" ] && info "WebUI token = $T （app 设置页 webuiToken 填这个）" || bad "读不到 webui.json 的 token"

# 6 最近错误
E=$(dx "grep -aE 'error|Error' $LOG 2>/dev/null | tr -d '\000' | tail -2")
[ -n "$E" ] && info "最近日志错误行：
      $(echo "$E" | sed 's/^/      /')"
echo "═══════════════════════════════════"
