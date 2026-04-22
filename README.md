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
- 歌词显示与歌词源选择
- 桌面歌词
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

## 构建

推荐本地环境：

- Flutter stable，启用 Windows 桌面支持
- Visual Studio Build Tools，安装 Desktop development with C++ 工作负载
- Git
- Rust 工具链

构建命令：

```powershell
$env:Path='C:\src\flutter\bin;C:\Program Files\Git\cmd;' + $env:Path
flutter pub get
flutter build windows --release
```

构建完成后，主程序位于：

```text
build\windows\x64\runner\Release\border_player.exe
```

完整发布包还需要包含 Flutter release 输出、`BASS` 运行库目录，以及 `desktop_lyric` 桌面歌词辅助程序目录。

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
