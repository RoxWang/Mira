#!/bin/zsh
# 把本机的 Mira.app 重新打包成发布用的 zip（Mira-<版本>.zip）
#
# 这是「改 App」的最后一步：把仓库 src/ 里的东西同步进 app 包 → 重新签名 → 打成 zip。
# App 的行为（main.applescript、reel-launch、castgen.pl）和页面（view.html）都在 src/，
# 图标和 Assets.car 不在仓库里，所以这里是在**已有的 app 包**上打补丁，不是从零编译。
#
# 用法：
#   ./pack.sh                              # 自动找 ~/Applications / /Applications 里的 Mira.app
#   MIRA_APP=/path/to/Mira.app ./pack.sh   # 指定 app
#   OUT=~/Desktop/test.zip ./pack.sh       # 只试不覆盖发布件
set -e
SRC="$(cd "$(dirname "$0")" && pwd)/src"

# ── 找 app ──
APP="${MIRA_APP:-}"
if [[ -z "$APP" ]]; then
  for p in "$HOME/Applications/Mira.app" "/Applications/Mira.app" "$HOME/Documents/Mira/Mira.app"; do
    [[ -d "$p" ]] && { APP="$p"; break; }
  done
fi
[[ -n "$APP" && -d "$APP" ]] || {
  echo "找不到 Mira.app。"
  echo "这个脚本是给已有的 app 打补丁的（图标和 Assets.car 不在这份仓库里）。"
  echo "请把装好的 Mira.app 路径传进来：MIRA_APP=/path/to/Mira.app ./pack.sh"
  exit 1
}
echo "目标 app：$APP"

R="$APP/Contents/Resources"
M="$APP/Contents/MacOS"
[[ -d "$R" && -d "$M" ]] || { echo "这个不是完整的 app 包（缺 Contents/Resources 或 Contents/MacOS）"; exit 1; }

# ── 同步源码进包 ──
cp -f "$SRC/view.html"    "$R/view.html"
cp -f "$SRC/castgen.pl"   "$R/castgen.pl"
cp -f "$SRC/Info.plist"   "$APP/Contents/Info.plist"
cp -f "$SRC/reel-launch"  "$M/reel-launch"
chmod +x "$R/castgen.pl" "$M/reel-launch"
echo "已同步：view.html / castgen.pl / reel-launch / Info.plist"

# ── 重签名（ad-hoc，和原来一致）──
# 改了包内文件，原来的资源封印就对不上了；不重签，Gatekeeper 会说「已损坏」。
xattr -cr "$APP" 2>/dev/null || true
codesign --force --deep -s - "$APP" >/dev/null 2>&1
codesign -v "$APP" || { echo "签名校验失败"; exit 1; }
echo "已重新签名（ad-hoc），校验通过"

# ── 打包 ──
VER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || echo 1.0)"
OUT="${OUT:-$(cd "$(dirname "$0")" && pwd)/docs/Mira-$VER.zip}"
mkdir -p "$(dirname "$OUT")"
ditto -c -k --keepParent "$APP" "$OUT"
echo "已生成 $OUT（$(du -h "$OUT" | cut -f1)）"
