#!/bin/zsh
# 本地预览 —— 上线前的最后一道闸门。
#
# 为什么要它：网址是「推上去就生效」的，一上传，所有打开 https://roxwang.github.io/Mira/
# 的人立刻就是新版本。改坏了没地方回滚给观众看。所以流程固定成：
#   改 src/view.html → ./preview.sh → 你在这台机器上看 → 你说可以 → 才上线。
#
# 用法：./preview.sh          （默认 8760 端口）
#       ./preview.sh 8800     （端口被占了就换一个）
# 停掉：⌃C

set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/src"
PORT="${1:-8760}"
DIR="${TMPDIR:-/tmp}/mira-preview"

[[ -f "$SRC/view.html" ]] || { print -u2 "找不到 $SRC/view.html"; exit 1; }

/bin/mkdir -p "$DIR"
/bin/cp -f "$SRC/view.html" "$DIR/index.html"
[[ -f "$SRC/sw.js" ]] && /bin/cp -f "$SRC/sw.js" "$DIR/sw.js"
# 预览目录里永远只放「这一次要上线的那几个文件」，
# 所以看到的就是观众将来看到的，不多一个也不少一个。

IP="127.0.0.1"
print ""
print "  预览地址：  http://$IP:$PORT/"
print "  只在这台机器上能打开 · 按 ⌃C 停止"
print ""

cd "$DIR" || exit 1
exec python3 -m http.server "$PORT" --bind "$IP"
