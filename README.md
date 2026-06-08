# Border Player

Border Player 是一个面向 Windows 桌面的本地音乐播放器。

本项目是基于开源项目 **Coriander Player** 的二次修改版本，并在其基础上进行了界面、交互、启动体验、发布包和 Windows 桌面使用体验等方面的调整。

上游项目：

https://github.com/Ferry-200/coriander_player

## 项目说明

Border Player 保留了 Coriander Player 的核心能力，并围绕 Windows 桌面场景做了进一步整理和修改。当前仓库包含主播放器源码、桌面歌词辅助程序、Rust 原生模块、Windows 构建配置以及发布包所需的运行文件组织方式。

主要功能包括：

- 本地音乐曲库管理
- 艺术家、专辑、文件夹和歌单浏览
- 播放列表与随机播放
- 歌词显示与歌词源选择（本地/在线，支持 LRC、QRC、KRC）
- 桌面歌词（独立窗口，支持锁定、颜色自定义）
- 播放页歌曲信息弹窗（标题、艺术家、专辑、时长、比特率、采样率、位深、大小、格式）
- 右键菜单（艺术家、专辑、下一首播放、添加到歌单、详细信息）
- 按名称排序时右侧字母索引栏（A-Z 快速跳转）
- 播放状态记忆（歌曲、列表、进度，下次启动自动恢复）
- WASAPI 独占模式（bit-perfect 输出，适合外接 DAC）
- 播放模式、随机、音量等设置持久保存
- Windows 桌面窗口、快捷键和启动体验优化
- 基于封面取色的现代化界面

## 技术栈

- Flutter
- Dart
- Rust
- flutter_rust_bridge
- Windows desktop
- BASS 音频运行库

## 下载

推荐普通用户下载 Release 页面中的安装包：

https://github.com/tingzhouhuige/Border-Player/releases

发布页通常会提供两种包：

- `BorderPlayerSetup-*.exe`：标准 Windows 安装包，可选择安装位置，会创建快捷方式和卸载入口。
- `BorderPlayer-windows-x64-*.zip`：绿色便携版，解压后运行 `border_player.exe`。

## 版本更新

### v1.0.6

- 修复播放列表弹窗下方超出窗口边界的问题，弹窗位置自动适配窗口大小。
- 优化滚动条显示，主页列表、设置页、详情页和侧边栏的滚动条与内容分离，不再与歌曲项重叠。
- 移除所有鼠标悬停提示（Tooltip），界面更加简洁美观。

### v1.0.5

- 优化左上角品牌标识显示，减少小尺寸图标锯齿，并清理无用图标预览资源。
- 文件夹管理弹窗新增“扫描音乐”，可选择本地文件夹并立即扫描入库，同时自动加入文件夹目录。
- 左侧边栏在窗口高度较低时支持上下滚动。
- 设置页新增听歌统计，支持周、月、年、总四种统计范围；仅显示已有播放次数的歌曲，并按次数从高到低排序。
- 歌曲播放累计达到总时长 75% 后记一次播放次数，未达到不计入统计。
- 优化播放页小屏布局：播放列表改为底部按钮弹窗，右侧切换控件仅保留封面和歌词切换，封面居中并调整四周留白。
- 优化播放页小屏标题栏返回按钮与歌曲名的间距。

## 构建

推荐本地环境：

- Flutter stable，启用 Windows 桌面支持
- Visual Studio Build Tools，安装 Desktop development with C++ 工作负载
- Git
- Rust 工具链

一键构建完整发布包（包含主程序、桌面歌词、BASS 运行库）：

```powershell
.\tools\build_windows_release.ps1
```

输出目录：`release_packages\full-windows-x64`

指定版本发布目录示例：

```powershell
.\tools\build_windows_release.ps1 -PackageName v1.0.5
```

如果 BASS DLL 缺失，加 `-DownloadBassIfMissing` 参数会自动下载：

```powershell
.\tools\build_windows_release.ps1 -DownloadBassIfMissing
```

也可以用 `build.bat` 快速编译主程序和桌面歌词（不打包）。

单独构建主程序：

```powershell
flutter pub get
flutter build windows --release
```

构建完成后，主程序位于：

```text
build\windows\x64\runner\Release\border_player.exe
```

注意：仅 `flutter build windows` 不会构建桌面歌词辅助程序，也不会包含 BASS 运行库。发布时请使用打包脚本或手动将 `desktop_lyric\build\windows\x64\runner\Release` 和 `third_party\bass\windows\x64` 目录一并打包。

## 开源协议

本项目遵循 GNU General Public License v3.0。

由于 Border Player 是基于 GPLv3 项目 Coriander Player 的二次修改版本，发布二进制包时也需要遵守 GPLv3 要求，包括保留许可证文本、保留上游版权和许可声明，并提供对应版本的源代码。

更多说明见：

- `LICENSE`
- `FORK_NOTICE.md`

## 上游声明

Border Player 是 Coriander Player 的修改版本：

https://github.com/Ferry-200/coriander_player

感谢上游项目作者和相关开源依赖的工作。
