# Mira — 极简本地视频播放器

**核心是一个网页，网页版不用安装。** 视频始终留在你本地，不上传、不经过网络、也不留副本。

👉 **直接用，不用下载：https://roxwang.github.io/Mira/**

📖 想看图文步骤：[Mira · 怎么用](https://roxwang.github.io/Mira/help.html)

---

## 怎么用（一句话）

打开上面的链接 → 点「打开视频」选文件（或直接把视频拖进页面）→ 播放进度、设置和载入过的字幕都存在这台设备当前这个浏览器里。**网页版下次打开要重新选一次同一个文件**（浏览器安全限制），选完就自动跳回上次看到的地方。只有下面的 Mac App（仅 macOS）支持关掉再开直接续播，以及用视频文件直接打开。

## 四种方式，挑最适合你的

| 方式 | 适合谁 | 核心点（✓ 优点 / ✗ 注意） |
|---|---|---|
| **网页版**（上面的链接） | 所有人，首选 | ✓ 打开就用、不用装、有网时刷新就是最新版、电脑 / 手机 / 平板的主流浏览器都能开 ／ ✗ 首次要联网（之后页面会存一份离线缓存，可离线）；刷新后要重新选一次视频文件 |
| 浏览器「安装为应用」 | 想有桌面图标、不占空间 | ✓ 和网页同一套，变成独立窗口 ／ ✗ 本质还是网页，首次要联网（之后可离线），不能双击视频文件直接开 |
| **Mac App**（仅 macOS） | Mac 用户，要双击直开 / 整季自动连 / 断网 | ✓ 设为默认后，常见格式双击视频就播、整季自动连、能离线 ／ ✗ 仅 macOS；首次打开会被 macOS 拦一下，点「仍要打开」即可 |
| **独立 HTML**（桌面系统） | Windows / Linux / macOS 想**断网**用、或想随身带一个文件 | ✓ 就一个文件、**断网也能用**、跨系统 ／ ✗ 要手动下载、手动选文件、更新需重新下 |

⚠️ 四种里只有 **Mac App** 首次打开会被 macOS 弹窗拦一下（没上架 App Store），其余三种不会弹窗。

> **关于格式：** 能不能播取决于你的浏览器，Mira 只是把文件交给它。实测 mp4 / mov / mkv / webm 能播，avi / flv 不能播；rmvb / wmv 这类老格式通常也不被浏览器支持。打不开时会弹「这个视频打不开」的提示，不会黑屏卡住。

## 怎么弄（每一步）

> **去 Releases 后只下这两个，别的（Source code 那两个）是源码、普通人不用管：**
> - `Mira-1.0.zip` = Mac App（Mac 用户下这个）
> - `Mira-standalone.html` = 离线单文件播放器（Windows / Linux / macOS 想断网的下这个）

1. **网页版**：直接打开最上面的链接，完事。
2. **浏览器「安装为应用」**：打开链接 → 浏览器右上角菜单（Chrome / Edge 点 `⋮`）→「安装此站点为应用 / Install」→ 桌面出现图标。
3. **Mac App**：① 点 [Releases](https://github.com/RoxWang/Mira/releases) → ② 点 `Mira-1.0.zip` 下载 → ③ 双击解压得到 `Mira.app` → ④ 拖进「应用程序」文件夹（首次打开若被 macOS 拦，去「系统设置 → 隐私与安全性」点「仍要打开」）。
   > ⚠️ **电脑上只留一份 `Mira.app`。** 升级时先把旧的拖进废纸篓再放新的，别让两份同时存在 —— 否则右键「打开方式」里会出现两个 Mira（一个带版本号、一个不带）。压缩包里只有一份 App。如果已经出现两个，把旧的那份删掉、清空废纸篓即可。
   > ⚠️ **解压请用 macOS 自带的归档实用工具双击 zip。** 压缩包里那些 `._` 开头的文件存着脚本的代码签名属性；命令行 `unzip` 不还原它们，部分第三方解压工具也不还原，App 会被系统判定「已损坏」。
4. **独立 HTML（断网 / 随身版）**：去 [Releases](https://github.com/RoxWang/Mira/releases) 下载 `Mira-standalone.html` → 双击（用默认浏览器打开）→ 点「打开视频」选文件就能看，断网也行。

---
Mira is a browser-based local video player. Open https://roxwang.github.io/Mira/ in a modern browser on Windows, macOS, iOS or Android, pick a local video, and it plays — your video is never uploaded or copied. The page needs internet on first visit and is then cached for offline use. Which formats play depends on your browser. License: MIT
