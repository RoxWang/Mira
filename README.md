# Mira — 极简本地视频播放器

**不是软件，是一个网页。** 视频永远在你自己硬盘上，不上传、不联网、不留副本。

👉 **直接用，不用下载：https://roxwang.github.io/Mira/**

---

## 怎么用（一句话）

打开上面的链接 → 点「打开视频」选文件（或直接把视频拖进页面）→ 看完关掉，下次自动接着播。手机、电脑、平板都一样。

## 四种方式，挑一个最合适的

| 你的情况 | 用这个 | 怎么弄 |
|---|---|---|
| **大多数人** | **网页版**（上面的链接） | 直接打开，啥都不用装，永远最新 |
| 想有个桌面图标、不占空间 | 浏览器「安装为应用」 | 打开链接 → 浏览器菜单 → 安装此站点为应用（和网页同一套，无下载） |
| **Mac 用户**，想要双击视频直接播 / 整季自动连 / 断网也行 | **Mira.app**（仅 macOS） | 下 `Mira-1.0.zip` → 解压得到 `Mira.app` → 拖进「应用程序」 |
| 想随身带一个文件 / **Windows·Linux 离线用** | **独立 HTML**（全平台） | 下 `Mira-standalone.html` → **双击用浏览器打开** → 点「打开视频」选文件就能看 |

> **独立 HTML 是什么**：就是播放器本身存成的一个单文件，和网页是同一套，只是落在你硬盘上、断网也能用。它不是一个安装包，下载后双击即可，更新就重新下一份。

下载都在 [Releases](https://github.com/RoxWang/Mira/releases)。

## Mac 端已实测（真机跑通）

在 App 或网页 Mac 端里选默认浏览器 → 下次双击开视频就真用那个浏览器（Chrome / Safari / 恢复默认都验证过）。
下拉顺序固定为：**系统默认 → ① 谷歌 → ② Edge → ③ Safari → ④ 火狐 → 其余**。
注意：网页端的选择**只对 macOS 的 Mira.app 生效**；非 Mac 设备只存本地，不会真改系统打开方式。

---
Mira is a browser-based local video player. Open https://roxwang.github.io/Mira/ in any browser on Windows, macOS, iOS or Android, pick a local video, and it plays — no upload, no network, no cache. License: MIT
