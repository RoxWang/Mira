# Mira — 极简本地视频播放器（浏览器跨平台）

> 一个跑在浏览器里的本地视频播放器。用 **Google Chrome 的内核**播放，套一层为「看剧 / 看课 / 碎片时间随手看」设计的界面：继续播放、双字幕、播放列表、触控板手势拖进度。不转码、不联网、不留缓存。
>
> **网页版全平台通用**：Windows / macOS / iPhone / iPad / Android，打开浏览器就能用，不用装任何东西。另附一个 **macOS 桌面 App**（双击即开，多一个自动扫同目录字幕的增强），Mac 用户想要更顺手可以下。

Mira is a browser-based local video player that wraps **Google Chrome's engine** as its playback core, with a clean UI built for binge-watching local shows, courses, and quick viewing. Resume, dual subtitles, playlists, trackpad scrubbing — no transcoding, no network, no cache.

Works in any browser on Windows, macOS, iPhone, iPad and Android. A macOS desktop app is also provided for users who want double-click launch and automatic subtitle discovery.

---

## 它适合谁 / Who it's for
- 在追本地剧集 / 课程视频，想要「关掉再开接着看上一集」
- 需要双字幕、自定义字幕位置 / 大小 / 颜色
- 烦了系统播放器的臃肿，想要一个干净轻量的替代品

## 两种用法 / Two ways
- **网页版（推荐，全平台）**：打开 `docs/play.html`（或部署后的网址），在浏览器里选视频 / 拖视频即可。Windows / macOS / iPhone / iPad / Android 都能用。
- **macOS 桌面 App**：下载 `Mira-1.0.zip` 解压得到 `Mira.app`，双击启动。额外支持「自动扫同目录字幕」「读取媒体信息」等浏览器做不到的能力。

## 前置要求 / Requirements
- **网页版**：一个现代浏览器（Chrome / Edge / Safari 均可）。
- **macOS App**：macOS + 本机已安装 Google Chrome（App 会调用 Chrome 内核播放）。
- 网页版不做任何本地文件扫描；App 首次选「文件夹」时 macOS 会请求文件访问权限——允许即可（仅用于读取你选的视频）。

## 使用 / Usage
- **网页版**：打开页面 → 选文件 / 拖入视频。
- **App**：双击 `Mira.app` → 主页，拖入视频 / 选文件 / 选文件夹；访达里右键视频 → 打开方式 → Mira。
- 快捷键：空格 播放/暂停 · ←/→ 快退快进（按住 → 加速）· F 全屏 · C 字幕开关 · S 加载字幕 · O 回主页 · ⌘←/⌘→ 上/下一集 · ⌘, 设置
- 触控板双指横滑 = 拖进度（距离制，慢挪精确定位；⌥ 精细模式）

## 特性 / Features
- **继续播放**：单文件按路径、文件夹按「剧名 + 第几集」记住位置，刷新 / 重开接着看
- **播放列表**：选整个文件夹或一次选多集，自动按集排序
- **双字幕**：主 / 辅独立，位置 / 大小 / 颜色 / 延迟可调；同目录字幕自动挂载并长期保存
- **画面调节**：亮度 / 对比 / 饱和 / 色相 / 旋转 / 缩放 / 比例，零缓存
- **零联网、零转码、零缓存**：视频原地播放，不做任何副本

## 原理 / How it works
Mira 的界面是一张本地 HTML 页面，用浏览器原生 `<video>` 播放；网页版由任何现代浏览器打开，macOS App 则由本机 Chrome 以**独立窗口**打开。好处：解码交给浏览器（H.264 / HEVC / AV1 等格式天然支持），界面可以像网页一样随时改，且完全离线。

The UI is a local HTML page that uses the browser's native `<video>`. The web version runs in any modern browser; the macOS app opens it in your Chrome in its own window. Decoding is delegated to the browser (H.264 / HEVC / AV1 out of the box), the UI is just web tech, and everything stays fully offline.

## 常见问题 / FAQ
- **打不开 / 双击没反应？**（App）确认装了 Chrome；若仍不行，关掉 Chrome（⌘Q）再双击一次。
- **字幕不显示？** 默认自动挂载同目录字幕；手动按 S 选择 `.srt` / `.vtt`。
- **为什么不能播 Netflix / 爱奇艺？** 那些是 DRM 加密流，浏览器套壳也解不开（非工具弱，是源被锁死）。
- **手机上能看本地视频吗？** 能。用手机浏览器打开网页版，选「文件」里存的视频即可播放（受手机浏览器支持的格式限制）。

## 许可证 / License
MIT
