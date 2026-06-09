param(
  [string]$PackageName = "full-windows-x64",
  [switch]$DownloadBassIfMissing,
  [switch]$CleanBuild
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$FlutterPath = "C:\src\flutter\bin"
$FlutterCommand = "flutter"
$GitPath = "C:\Program Files\Git\cmd"
if (Test-Path $FlutterPath) {
  $env:Path = "$FlutterPath;$GitPath;$env:Path"
  $FlutterBat = Join-Path $FlutterPath "flutter.bat"
  if (Test-Path -LiteralPath $FlutterBat) {
    $FlutterCommand = $FlutterBat
  }
}

$MainRelease = Join-Path $Root "build\windows\x64\runner\Release"
$MainWindowsBuild = Join-Path $Root "build\windows\x64"
$LyricRoot = Join-Path $Root "desktop_lyric"
$LyricRelease = Join-Path $LyricRoot "build\windows\x64\runner\Release"
$LyricWindowsBuild = Join-Path $LyricRoot "build\windows\x64"
$ThirdPartyBassX64 = Join-Path $Root "third_party\bass\windows\x64"
$BassDownload = Join-Path $Root "build\bass_download"
$BassExtract = Join-Path $Root "build\bass_extract"
$BassX64 = Join-Path $BassExtract "x64"
$Target = Join-Path $Root "release_packages\$PackageName"
$LogPath = Join-Path $Root "release_packages\package_windows_release.last.log"
$RequiredBassDlls = @(
  "bass.dll",
  "basswasapi.dll",
  "bassape.dll",
  "bassdsd.dll",
  "bassflac.dll",
  "bassmidi.dll",
  "bassopus.dll",
  "basswv.dll"
)

$BassArchives = @(
  @{ Name = "bass.zip"; Url = "https://www.un4seen.com/files/bass24.zip" },
  @{ Name = "basswasapi24.zip"; Url = "https://www.un4seen.com/files/basswasapi24.zip" },
  @{ Name = "bassape24.zip"; Url = "https://www.un4seen.com/files/bassape24.zip" },
  @{ Name = "bassdsd24.zip"; Url = "https://www.un4seen.com/files/bassdsd24.zip" },
  @{ Name = "bassflac24.zip"; Url = "https://www.un4seen.com/files/bassflac24.zip" },
  @{ Name = "bassmidi24.zip"; Url = "https://www.un4seen.com/files/bassmidi24.zip" },
  @{ Name = "bassopus24.zip"; Url = "https://www.un4seen.com/files/bassopus24.zip" },
  @{ Name = "basswv24.zip"; Url = "https://www.un4seen.com/files/basswv24.zip" }
)

function Write-Step {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  $Line = "[{0:yyyy-MM-dd HH:mm:ss}] {1}" -f (Get-Date), $Message
  Write-Host $Line
  $LogDir = Split-Path -Parent $LogPath
  if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
  }
  Add-Content -LiteralPath $LogPath -Value $Line -Encoding UTF8
}

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  $CommandLine = "$Command $($Arguments -join ' ')".Trim()
  $StartedAt = Get-Date
  Write-Step "START $CommandLine"
  & $Command @Arguments
  $Elapsed = [int]((Get-Date) - $StartedAt).TotalSeconds
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code $LASTEXITCODE`: $Command $($Arguments -join ' ')"
  }
  Write-Step "DONE  $CommandLine (${Elapsed}s)"
}

function Remove-DirectoryIfRequested {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Label
  )

  if (-not $CleanBuild) {
    return
  }

  if (Test-Path -LiteralPath $Path) {
    Write-Step "Clean $Label build cache"
    Remove-Item -LiteralPath $Path -Recurse -Force
  }
}

function Assert-DirectoryExists {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Label
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "$Label output was not found: $Path"
  }
}

Push-Location $Root
try {
  if (Test-Path -LiteralPath $LogPath) {
    Remove-Item -LiteralPath $LogPath -Force
  }
  Write-Step "Package target: $Target"
  Remove-DirectoryIfRequested -Path $MainWindowsBuild -Label "main app"
  Invoke-Checked $FlutterCommand pub get
  Invoke-Checked $FlutterCommand build windows --release
  Assert-DirectoryExists -Path $MainRelease -Label "Main app"

  Push-Location $LyricRoot
  try {
    Remove-DirectoryIfRequested -Path $LyricWindowsBuild -Label "desktop lyric"
    Invoke-Checked $FlutterCommand pub get
    Invoke-Checked $FlutterCommand build windows --release
    Assert-DirectoryExists -Path $LyricRelease -Label "Desktop lyric"
  } finally {
    Pop-Location
  }

  $BassSource = $ThirdPartyBassX64
  $MissingBassDlls = @(
    $RequiredBassDlls | Where-Object {
      -not (Test-Path -LiteralPath (Join-Path $BassSource $_))
    }
  )

  if ($MissingBassDlls.Count -gt 0) {
    if (-not $DownloadBassIfMissing) {
      throw "Missing BASS runtime DLLs in $BassSource`: $($MissingBassDlls -join ', '). Run this script with -DownloadBassIfMissing once to restore them."
    }

    New-Item -ItemType Directory -Force -Path $BassDownload | Out-Null
    New-Item -ItemType Directory -Force -Path $BassExtract | Out-Null

    foreach ($Archive in $BassArchives) {
      $ArchivePath = Join-Path $BassDownload $Archive.Name
      if (-not (Test-Path -LiteralPath $ArchivePath)) {
        Invoke-Checked curl.exe -L -o $ArchivePath $Archive.Url
      }
      Expand-Archive -LiteralPath $ArchivePath -DestinationPath $BassExtract -Force
    }

    New-Item -ItemType Directory -Force -Path $ThirdPartyBassX64 | Out-Null
    Copy-Item -Path (Join-Path $BassX64 "*.dll") -Destination $ThirdPartyBassX64 -Force
    $BassSource = $ThirdPartyBassX64

    $MissingBassDlls = @(
      $RequiredBassDlls | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $BassSource $_))
      }
    )
    if ($MissingBassDlls.Count -gt 0) {
      throw "BASS runtime restore did not provide: $($MissingBassDlls -join ', ')"
    }
  }

  if (Test-Path -LiteralPath $Target) {
    Write-Step "Replace existing package directory"
    Remove-Item -LiteralPath $Target -Recurse -Force
  }

  Write-Step "Copy main app"
  Copy-Item -LiteralPath $MainRelease -Destination $Target -Recurse -Force
  Write-Step "Copy desktop lyric"
  New-Item -ItemType Directory -Force -Path (Join-Path $Target "desktop_lyric") | Out-Null
  Copy-Item -Path (Join-Path $LyricRelease "*") -Destination (Join-Path $Target "desktop_lyric") -Recurse -Force
  Write-Step "Copy BASS runtime"
  New-Item -ItemType Directory -Force -Path (Join-Path $Target "BASS") | Out-Null
  Copy-Item -Path (Join-Path $BassSource "*.dll") -Destination (Join-Path $Target "BASS") -Force

  Write-Step "Packaged release: $Target"
} finally {
  Pop-Location
}
