param(
  [string]$PackageName = "full-windows-x64",
  [switch]$DownloadBassIfMissing
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$FlutterPath = "C:\src\flutter\bin"
$GitPath = "C:\Program Files\Git\cmd"
if (Test-Path $FlutterPath) {
  $env:Path = "$FlutterPath;$GitPath;$env:Path"
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

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  & $Command @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code $LASTEXITCODE`: $Command $($Arguments -join ' ')"
  }
}

Push-Location $Root
try {
  if (Test-Path -LiteralPath $MainWindowsBuild) {
    Remove-Item -LiteralPath $MainWindowsBuild -Recurse -Force
  }
  Invoke-Checked flutter pub get
  Invoke-Checked flutter build windows --release

  Push-Location $LyricRoot
  try {
    if (Test-Path -LiteralPath $LyricWindowsBuild) {
      Remove-Item -LiteralPath $LyricWindowsBuild -Recurse -Force
    }
    Invoke-Checked flutter pub get
    Invoke-Checked flutter build windows --release
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
    Remove-Item -LiteralPath $Target -Recurse -Force
  }

  Copy-Item -LiteralPath $MainRelease -Destination $Target -Recurse -Force
  New-Item -ItemType Directory -Force -Path (Join-Path $Target "desktop_lyric") | Out-Null
  Copy-Item -Path (Join-Path $LyricRelease "*") -Destination (Join-Path $Target "desktop_lyric") -Recurse -Force
  New-Item -ItemType Directory -Force -Path (Join-Path $Target "BASS") | Out-Null
  Copy-Item -Path (Join-Path $BassSource "*.dll") -Destination (Join-Path $Target "BASS") -Force

  Write-Host "Packaged release: $Target"
} finally {
  Pop-Location
}
