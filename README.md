# Border Player

Border Player is a Windows desktop music player fork based on an upstream GPLv3 music player project.

This repository contains the player source code, the bundled desktop lyric helper, and the Windows build configuration used for the Border Player release package.

## License

This project is distributed under the GNU General Public License v3.0. The original upstream project was also GPLv3, so modified releases must keep the same license, include the license text, and provide the corresponding source code.

See `LICENSE` and `FORK_NOTICE.md`.

## Build

Recommended local environment:

- Flutter stable 3.41.7 or newer with Windows desktop support enabled.
- Visual Studio Build Tools with the Desktop development with C++ workload.
- Git.
- Rust toolchain, because the project uses flutter_rust_bridge native code.

Build command:

```powershell
$env:Path='C:\src\flutter\bin;C:\Program Files\Git\cmd;' + $env:Path
flutter pub get
flutter build windows --release
```

The Windows executable is built as `border_player.exe`.

## Runtime Files

The release package must include the Flutter release output, the `BASS` runtime DLLs, and the `desktop_lyric` helper folder used by the player.

## Upstream Notice

Border Player is a modified version of an upstream GPLv3 project. Keep upstream copyright notices and GPLv3 license terms when publishing modified source or binary releases.
