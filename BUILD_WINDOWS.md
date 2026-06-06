# Windows Build

Use this command for release iteration builds:

```powershell
.\tools\build_windows_release.ps1
```

Output:

```text
release_packages\full-windows-x64
```

The script builds and combines:

- Main Flutter app: `border_player.exe`
- Desktop lyric helper app: `desktop_lyric\desktop_lyric.exe`
- BASS runtime DLLs from `third_party\bass\windows\x64`

Do not publish only the output of `flutter build windows --release`. That command builds the main Flutter app only, and does not include the desktop lyric helper or the BASS runtime files required by playback and lyric UI services.

If the local BASS DLLs are missing, restore them once with:

```powershell
.\tools\build_windows_release.ps1 -DownloadBassIfMissing
```

Review the BASS licensing terms before publishing or redistributing release builds.
