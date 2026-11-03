#!/bin/zsh
# 把本机的 Mira.app 打成发布用 zip（Mira-<version>.zip）
# 用法：./pack.sh            （默认打包 /Users/roxwang/Documents/Mira/Mira.app）
#       MIRA_APP=/path/to/Mira.app ./pack.sh
set -e
APP="${MIRA_APP:-/Users/roxwang/Documents/Mira/Mira.app}"
VER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist" 2>/dev/null || echo 1.0)"
OUT="docs/Mira-$VER.zip"   # 直接进 docs/，落地页(index.html)和 Release 都用这一个 zip
[ -d "$APP" ] || { echo "找不到 $APP"; exit 1; }
/usr/bin/ditto -c -k --keepParent "$APP" "$OUT"
echo "已生成 $OUT ($(du -h "$OUT" | cut -f1))"
