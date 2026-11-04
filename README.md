# Mira — 极简本地视频播放器

**不是软件，是一个网页。** 视频永远在你自己硬盘上，不上传、不联网、不留副本。

👉 **直接用，不用下载：https://roxwang.github.io/Mira/**

---

## 怎么用（一句话）

打开上面的链接 → 点「打开视频」选文件（或直接把视频拖进页面）→ 看完关掉，下次自动接着播。手机、电脑、平板都一样。

## 四种方式，挑最适合你的

| 方式 | 适合谁 | 核心点（✓ 优点 / ✗ 注意） |
|---|---|---|
| **网页版**（上面的链接） | 所有人，首选 | ✓ 打开就用、不用装、永远最新、全平台 ／ ✗ 首次要联网（之后浏览器会缓存，可离线） |
| 浏览器「安装为应用」 | 想有桌面图标、不占空间 | ✓ 和网页同一套，变成独立窗口 ／ ✗ 本质还是网页，要联网，不能双击视频文件直接开 |
| **Mac App**（仅 macOS） | Mac 用户，要双击直开 / 整季自动连 / 断网 | ✓ 双击视频就播、整季自动连、可设默认播放器、能离线 ／ ✗ 仅 macOS；首次打开会被 macOS 拦一下，点「仍要打开」即可 |
| **独立 HTML**（全平台） | Windows / Linux 想**断网**用、或想随身带一个文件 | ✓ 就一个文件、**断网也能用**、跨平台 ／ ✗ 要手动下载、手动选文件、更新需重新下 |

⚠️ 四种里只有 **Mac App** 首次打开会被 macOS 弹窗拦一下（没上架 App Store），其余三种不会弹窗。

## 怎么弄（每一步）

> **去 Releases 后只下这两个，别的（Source code 那两个）是源码、普通人不用管：**
> - `Mira-1.0.zip` = Mac App（Mac 用户下这个）
> - `Mira-standalone.html` = 离线单文件播放器（Windows / Linux / 想断网的下这个）

1. **网页版**：直接打开最上面的链接，完事。
2. **浏览器「安装为应用」**：打开链接 → 浏览器右上角菜单（Chrome / Edge 点 `⋮`）→「安装此站点为应用 / Install」→ 桌面出现图标。
3. **Mac App**：① 点 [Releases](https://github.com/RoxWang/Mira/releases) → ② 点 `Mira-1.0.zip` 下载 → ③ 双击解压得到 `Mira.app` → ④ 拖进「应用程序」文件夹（首次打开若被 macOS 拦，去「系统设置 → 隐私与安全性」点「仍要打开」）。
4. **独立 HTML（断网 / 随身版）**：去 [Releases](https://github.com/RoxWang/Mira/releases) 下载 `Mira-standalone.html` → 双击（用默认浏览器打开）→ 点「打开视频」选文件就能看，断网也行。

---
Mira is a browser-based local video player. Open https://roxwang.github.io/Mira/ in any browser on Windows, macOS, iOS or Android, pick a local video, and it plays — no upload, no network, no cache. License: MIT
