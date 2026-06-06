param(
  [string]$PackageName = "full-windows-x64",
  [switch]$DownloadBassIfMissing
)

$Script = Join-Path $PSScriptRoot "package_windows_release.ps1"
& $Script -PackageName $PackageName -DownloadBassIfMissing:$DownloadBassIfMissing
