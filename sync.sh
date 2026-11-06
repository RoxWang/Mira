#!/bin/zsh
# Mira 单一真源同步 —— 消灭「本机 App 和 GitHub 显示不一样」的版本漂移。
#
# 【真源】docs/index.html
#   这是 GitHub Pages 实际服务的那一份，也就是「以 GitHub 上的为基准」的落点。
#   其它所有副本都从它派生：
#     docs/Mira-standalone.html          离线单文件（Releases 下载件）
#     dist/Mira.app/.../view.html        项目内的 App 包
#     ~/Documents/Mira.app/.../view.html 你自己在用的那份 App
#     docs/Mira-1.0.zip                  发布包（由上面那个 App 现打）
#   改代码时先动 src/view.html，再用 --from-src 把它提升为真源，一次推平所有端。
#
# 【为什么 App 不能直接加载 GitHub 网址】
#   视频文件在你硬盘上，远端网页读不到；App 要能断网用；每次开视频还得由
#   castgen.pl 把「本地路径 + 播放列表 + 字幕」烧进一份临时页
#   （$TMPDIR/Mira/play-<时间戳>.html），Chrome 打开的是这个本机临时文件，
#   所以地址栏永远是 file:///var/folders/... 而不是 github 网址 —— 这是设计，不是 bug。
#   能统一的是「代码」，不是「网址」，这份脚本就是干这件事的。
#
# 用法：
#   ./sync.sh                  # 以 docs/index.html 为真源，同步全部本机副本 + 重签 + 重打 zip
#   ./sync.sh --from-src       # 开发用：先把 src/view.html 提升为真源，再同步
#   ./sync.sh --push           # 同步完再 commit + push 到 GitHub
#   ./sync.sh --from-src --push
#   MIRA_MSG="改了什么" ./sync.sh --from-src --push
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
TRUTH="$ROOT/docs/index.html"
SRC="$ROOT/src/view.html"
APP_LOCAL="${MIRA_LOCAL_APP:-$HOME/Documents/Mira.app}"
APP_DIST="$ROOT/dist/Mira.app"
MSG="${MIRA_MSG:-fix: 同步播放器页面到所有端}"

FROM_SRC=0
PUSH=0
for a in "$@"; do
  case "$a" in
    --from-src) FROM_SRC=1 ;;
    --push)     PUSH=1 ;;
    *) echo "未知参数：$a"; echo "用法：./sync.sh [--from-src] [--push]"; exit 1 ;;
  esac
done

[[ -f "$TRUTH" ]] || { echo "找不到真源 $TRUTH"; exit 1; }

if (( FROM_SRC )); then
  [[ -f "$SRC" ]] || { echo "找不到 $SRC"; exit 1; }
  /bin/cp -f "$SRC" "$TRUTH"
  echo "[真源] src/view.html → docs/index.html（GitHub 基准已更新）"
fi

# 真源与开发副本必须一致，不然下次谁改谁就是隐性分叉
A=$(md5 -q "$TRUTH")
B=$(md5 -q "$SRC" 2>/dev/null || echo "")
if [[ -n "$B" && "$A" != "$B" ]]; then
  echo "❌ docs/index.html 与 src/view.html 不一致。"
  echo "   要么加 --from-src 让 src 成为真源，要么先把真源同步回 src。"
  exit 1
fi
/bin/cp -f "$TRUTH" "$SRC"
echo "[开发副本] src/view.html 已对齐真源"

# ── GitHub 网页端的另一份下载件 ──
/bin/cp -f "$TRUTH" "$ROOT/docs/Mira-standalone.html"
echo "[GitHub 网页端] docs/Mira-standalone.html 已同步"

# ── 本机两个 App 包：同步页面 + 重签（改了包内文件不重签会被 Gatekeeper 判损坏）──
PKG_APP=""
for APP in "$APP_DIST" "$APP_LOCAL"; do
  [[ -d "$APP/Contents/Resources" ]] || { echo "  跳过（不存在）：$APP"; continue; }
  /bin/cp -f "$TRUTH" "$APP/Contents/Resources/view.html"
  # App 包里的启动脚本 / 页面生成器 / 配置也一起对齐 src，避免「页面是新的、脚本是旧的」
  /bin/cp -f "$ROOT/src/castgen.pl"   "$APP/Contents/Resources/castgen.pl"
  /bin/cp -f "$ROOT/src/reel-launch"  "$APP/Contents/MacOS/reel-launch"
  /bin/cp -f "$ROOT/src/Info.plist"   "$APP/Contents/Info.plist"
  /bin/chmod +x "$APP/Contents/Resources/castgen.pl" "$APP/Contents/MacOS/reel-launch"
  xattr -cr "$APP" 2>/dev/null || true
  codesign --force --deep -s - "$APP" >/dev/null 2>&1
  codesign -v "$APP"
  echo "[本机 App] $APP 已同步 + 重签名"
  PKG_APP="$APP"
done

# ── 发布包：用刚同步好的 App 现打 ──
if [[ -n "$PKG_APP" ]]; then
  VER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PKG_APP/Contents/Info.plist" 2>/dev/null || echo 1.0)"
  OUT="$ROOT/docs/Mira-$VER.zip"
  ditto -c -k --keepParent "$PKG_APP" "$OUT"
  echo "[GitHub 发布包] $OUT（$(du -h "$OUT" | cut -f1)）"
fi

echo "本机所有副本 md5：$(md5 -q "$TRUTH")"

# ── 推 GitHub（仓库 + 之后 Pages 自动构建）──
if (( PUSH )); then
  cd "$ROOT"
  VER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PKG_APP/Contents/Info.plist" 2>/dev/null || echo 1.0)"
  git add docs/index.html docs/Mira-standalone.html "docs/Mira-$VER.zip" \
          src/view.html src/castgen.pl sync.sh
  if git diff --cached --quiet; then
    echo "[GitHub 仓库] 没有新改动，跳过提交"
  else
    git commit -m "$MSG"
    git push origin main
    echo "[GitHub 仓库] 已推送 main"
  fi
fi

echo "完成。网页版由 GitHub Pages 自动构建，通常几分钟后生效。"
