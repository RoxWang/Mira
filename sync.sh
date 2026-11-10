#!/bin/zsh
# Mira 全端同步 —— 一条命令把「代码 → 网页 → 两个 App → 发布包 → GitHub → Releases」推平。
#
# 【唯一真源】docs/index.html
#   GitHub Pages 实际服务的就是这一份。其它所有副本都从它派生：
#     src/view.html                       开发副本
#     docs/Mira-standalone.html           离线单文件（Releases 下载件）
#     docs/sw.js                          网页版离线缓存脚本
#     dist/Mira.app/.../view.html         项目内的 App 包
#     ~/Documents/Mira.app/.../view.html  你自己在用的那份 App
#     docs/Mira-<版本>.zip                发布包（由上面那个 App 现打）
#   改代码先动 src/view.html，再用 --from-src 把它提升为真源，一次推平所有端。
#
# 【为什么同步绝不会打断正在看视频的人】
#   GitHub Pages 是静态托管：push 只是把服务器上的文件换掉，不会往已经打开的
#   标签页推任何东西。页面里没有 location.reload / 轮询 / meta refresh；
#   service worker 只在页面加载那一刻注册一次，且已去掉 clients.claim()，
#   不会接管正在放片的标签页。所以观众那边的画面、进度、字幕原封不动，
#   只有他自己刷新或新开页面才会拿到新版 —— 这正是要的行为。
#   进度记忆存在浏览器 localStorage（mira.pos / mira.cur / mira.fres），
#   就算刷新也在；只是网页版受浏览器安全限制，刷新后要重新选一次本地视频文件。
#
# 【为什么 App 打开是 file:/// 而不是 github 网址】
#   视频在你硬盘上，远端网页读不到；App 要能断网用。每次开视频由 castgen.pl
#   把「本地路径 + 播放列表 + 字幕」烧进一份临时页（$TMPDIR/Mira/play-<时间戳>.html），
#   Chrome 打开的是这个本机文件。能统一的是代码，不是网址 —— 这份脚本干的就是这件事。
#
# 用法：
#   ./sync.sh --from-src     # 改完 src/view.html 跑这条；默认全端（含 GitHub 仓库 + Releases）
#   ./sync.sh                # 以真源为准，全端同步
#   ./sync.sh --local        # 只同步本机，不出网（大改前想先自己看一眼时用）
#   ./sync.sh --no-release   # 推仓库，但不覆盖 Releases 附件
#   MIRA_MSG="改了什么" ./sync.sh --from-src
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
TRUTH="$ROOT/docs/index.html"
SRC="$ROOT/src/view.html"
SW_SRC="$ROOT/src/sw.js"
SW_DOC="$ROOT/docs/sw.js"
APP_LOCAL="${MIRA_LOCAL_APP:-$HOME/Documents/Mira.app}"
APP_DIST="$ROOT/dist/Mira.app"
REPO="${MIRA_REPO:-RoxWang/Mira}"
TAG="${MIRA_TAG:-v1.0}"
MSG="${MIRA_MSG:-fix: 同步 Mira 全部端}"

FROM_SRC=0
PUSH=1
RELEASE=1
for a in "$@"; do
  case "$a" in
    --from-src)   FROM_SRC=1 ;;
    --push)       PUSH=1 ;;
    --local)      PUSH=0; RELEASE=0 ;;
    --no-release) RELEASE=0 ;;
    *) echo "未知参数：$a"; echo "用法：./sync.sh [--from-src] [--local] [--no-release]"; exit 1 ;;
  esac
done

REPORT=()
note() { REPORT+=("$1"); echo "$1"; }

[[ -f "$TRUTH" ]]  || { echo "找不到真源 $TRUTH"; exit 1; }
[[ -f "$SW_SRC" ]] || { echo "找不到 $SW_SRC"; exit 1; }

# ── 1. 真源 ──
if (( FROM_SRC )); then
  [[ -f "$SRC" ]] || { echo "找不到 $SRC"; exit 1; }
  /bin/cp -f "$SRC" "$TRUTH"
  note "[真源] src/view.html → docs/index.html（GitHub 基准已更新）"
else
  A=$(md5 -q "$TRUTH")
  B=$(md5 -q "$SRC" 2>/dev/null || echo "")
  if [[ -n "$B" && "$A" != "$B" ]]; then
    echo "❌ docs/index.html 与 src/view.html 不一致。加 --from-src 让 src 成为真源。"
    exit 1
  fi
  note "[真源] docs/index.html（保持不动）"
fi

# ── 2. 本机文件副本（含网页版离线缓存脚本，缺了它线上 sw.js 会 404）──
/bin/cp -f "$TRUTH"  "$SRC"
/bin/cp -f "$TRUTH"  "$ROOT/docs/Mira-standalone.html"
/bin/cp -f "$SW_SRC" "$SW_DOC"
note "[本机文件] src/view.html · docs/Mira-standalone.html · docs/sw.js 已对齐"

# ── 3. 两个 App：页面 + 启动脚本 + 配置一起对齐，再重签 ──
PKG_APP=""
for APP in "$APP_DIST" "$APP_LOCAL"; do
  [[ -d "$APP/Contents/Resources" ]] || { note "[本机 App] 跳过（不存在）：$APP"; continue; }
  /bin/cp -f "$TRUTH"                "$APP/Contents/Resources/view.html"
  /bin/cp -f "$ROOT/src/castgen.pl"  "$APP/Contents/Resources/castgen.pl"
  /bin/cp -f "$ROOT/src/reel-launch" "$APP/Contents/MacOS/reel-launch"
  /bin/cp -f "$ROOT/src/Info.plist"  "$APP/Contents/Info.plist"
  /bin/chmod +x "$APP/Contents/Resources/castgen.pl" "$APP/Contents/MacOS/reel-launch"
  xattr -cr "$APP" 2>/dev/null || true
  codesign --force --deep -s - "$APP" >/dev/null 2>&1
  codesign -v "$APP"
  note "[本机 App] $APP 已同步 + 重签"
  PKG_APP="$APP"
done

# ── 4. 发布包：只有 App 内容真的变了才重打 ──
#    zip 里带文件时间戳，无脑重打会产生一个「内容没变、字节却不同」的新包，
#    进而每次都去无谓覆盖 GitHub 上的公开附件。先比对包内四个文件。
VER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/src/Info.plist" 2>/dev/null || echo 1.0)"
OUT="$ROOT/docs/Mira-$VER.zip"
NEED_ZIP=1
if [[ -f "$OUT" && -n "$PKG_APP" ]]; then
  zv=$(unzip -p "$OUT" "Mira.app/Contents/Resources/view.html" 2>/dev/null | md5 -q || true)
  zc=$(unzip -p "$OUT" "Mira.app/Contents/Resources/castgen.pl" 2>/dev/null | md5 -q || true)
  zr=$(unzip -p "$OUT" "Mira.app/Contents/MacOS/reel-launch"     2>/dev/null | md5 -q || true)
  zi=$(unzip -p "$OUT" "Mira.app/Contents/Info.plist"             2>/dev/null | md5 -q || true)
  if [[ "$zv" == "$(md5 -q "$TRUTH")" &&
        "$zc" == "$(md5 -q "$ROOT/src/castgen.pl")" &&
        "$zr" == "$(md5 -q "$ROOT/src/reel-launch")" &&
        "$zi" == "$(md5 -q "$ROOT/src/Info.plist")" ]]; then
    NEED_ZIP=0
  fi
fi
#   包里若混进 ._ 开头的 AppleDouble 垃圾（旧版 ditto 默认会带），别人用
#   Windows / Linux 解压会看到一堆莫名其妙的伴生文件 —— 一并强制重打成干净包。
if [[ -f "$OUT" ]] && unzip -Z1 "$OUT" 2>/dev/null | grep -q '/\._'; then
  NEED_ZIP=1
fi
if (( NEED_ZIP )); then
  [[ -n "$PKG_APP" ]] || { echo "没有可用的 App 包，无法重打发布包"; exit 1; }
  # --norsrc --noextattr：不带资源分支 / 扩展属性，zip 里只有一个干净的 Mira.app
  ditto -c -k --keepParent --norsrc --noextattr "$PKG_APP" "$OUT"
  note "[发布包] $OUT 已重打（$(du -h "$OUT" | cut -f1)，单一 App、无 AppleDouble）"
else
  note "[发布包] $OUT 内容未变，跳过重打"
fi

# ── 5. GitHub 仓库（push 后 Pages 自动构建）──
if (( PUSH )); then
  cd "$ROOT"
  git add -A
  if git diff --cached --quiet; then
    note "[GitHub 仓库] 没有新改动，跳过提交"
  else
    git commit -m "$MSG"
    git push origin main
    note "[GitHub 仓库] main 已推送（Pages 自动构建）"
  fi
fi

# ── 6. GitHub Releases 附件：幂等，sha256 一致就跳过 ──
release_upload() {
  MIRA_TOKEN="$TOKEN" MIRA_REPO="$REPO" MIRA_TAG="$TAG" python3 - "$OUT" "$ROOT/docs/Mira-standalone.html" <<'PY'
import os, sys, json, time, hashlib, urllib.request, urllib.parse

repo, tag, token = os.environ['MIRA_REPO'], os.environ['MIRA_TAG'], os.environ['MIRA_TOKEN']
API = 'https://api.github.com'

def call(method, url, body=None, ctype=None, tries=3):
    h = {'Authorization': 'Bearer ' + token,
         'Accept': 'application/vnd.github+json',
         'User-Agent': 'Mira-sync'}
    if ctype: h['Content-Type'] = ctype
    last = None
    for i in range(tries):
        try:
            r = urllib.request.Request(url, data=body, method=method, headers=h)
            with urllib.request.urlopen(r, timeout=120) as f:
                return f.status, f.read()
        except Exception as e:
            last = e
            if i < tries - 1: time.sleep(1.5)
    raise last

_, raw = call('GET', API + '/repos/' + repo + '/releases/tags/' + tag)
rel = json.loads(raw)
upload = rel['upload_url'].split('{')[0]
assets = {a['name']: a for a in rel.get('assets', [])}

for path in sys.argv[1:]:
    name = os.path.basename(path)
    with open(path, 'rb') as f: data = f.read()
    digest = 'sha256:' + hashlib.sha256(data).hexdigest()
    old = assets.get(name)
    if old and old.get('digest') == digest:
        print('[Releases] ' + name + ' 已是最新，跳过')
        continue
    if old:
        call('DELETE', API + '/repos/' + repo + '/releases/assets/' + str(old['id']))
    ctype = 'application/zip' if name.endswith('.zip') else 'text/html'
    call('POST', upload + '?name=' + urllib.parse.quote(name), data, ctype)
    print('[Releases] ' + name + ' 已更新（' + str(len(data)) + ' bytes）')
PY
}

if (( PUSH && RELEASE )); then
  TOKEN=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill 2>/dev/null | sed -n 's/^password=//p' || true)
  if [[ -z "$TOKEN" ]]; then
    note "[GitHub Releases] ⚠️ 取不到凭证，附件未更新（仓库与网页已同步）"
  elif ! release_upload; then
    note "[GitHub Releases] ⚠️ 附件更新失败，重跑一次即可（仓库与网页已同步）"
  fi
fi

# ── 7. 本机「打开方式」去重 ──
#   macOS 把每一份 Mira.app 都注册进 Launch Services：项目里的构建副本
#   dist/Mira.app、废纸篓里删掉的旧版，都会留下记录。同名但版本不同的两条
#   在「打开方式」里就显示成「Mira (1.0)」和「Mira」，用户以为装了两份。
#   只保留日常在用那一份，其余（含已删文件的僵尸记录）一律注销。
#   ⚠️ 只动明确的构建副本 / 废纸篓路径，不碰别人装在 /Applications 里的 App。
dedupe_openwith() {
  local LSREG="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
  [[ -x "$LSREG" && -d "$APP_LOCAL" ]] || return 0
  local p n=0
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    if [[ "$p" == "$ROOT/dist/"* || "$p" == "$HOME/.Trash/"* ]]; then
      "$LSREG" -u -R "$p" 2>/dev/null || true
      n=$((n + 1))
    fi
  done < <("$LSREG" -dump 2>/dev/null |
           sed -n 's/^path:[[:space:]]*//p' |
           sed 's/ (0x[0-9a-fA-F]*)$//' |
           grep '/Mira\.app$')
  "$LSREG" -R -f "$APP_LOCAL" 2>/dev/null || true   # 留下这份强制刷新，版本键一定是最新的
  note "[本机注册] 「打开方式」只保留 $APP_LOCAL，清理 $n 条重复注册"
}
dedupe_openwith

# ── 报告 ──
echo ""
echo "──── 这一轮改在哪一端 ────"
for r in "${REPORT[@]}"; do echo "  $r"; done
echo ""
echo "真源 md5：$(md5 -q "$TRUTH")"
echo "观众侧：已打开的网页不会被强制刷新；只有自己刷新 / 新开才拿到新版。"
if (( PUSH )); then echo "网页版：GitHub Pages 自动构建，通常几分钟后生效。"; fi
