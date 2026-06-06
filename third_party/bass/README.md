# BASS Runtime

This directory stores the Windows x64 BASS runtime DLLs required by Border Player at runtime.

The app loads these files from `BASS\` next to `border_player.exe`, so the Windows packaging script copies `third_party\bass\windows\x64\*.dll` into the release package.

Source and license information:

- BASS and add-ons are provided by UN4SEEN.
- Review the BASS licensing terms before publishing or redistributing release builds.

To restore missing DLLs locally, run:

```powershell
.\tools\build_windows_release.ps1 -DownloadBassIfMissing
```
