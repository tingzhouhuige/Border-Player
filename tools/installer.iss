#define MyAppName "Border Player"
#define MyAppVersion "2.0.2"
#define MyAppPublisher "tingzhouhuige"
#define MyAppURL "https://github.com/tingzhouhuige/Border-Player"
#define MyAppExeName "border_player.exe"

[Setup]
AppId={{BORDER-PLAYER-2026}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\release_packages
OutputBaseFilename=BorderPlayerSetup-v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\release_packages\v2.0.2\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  DeleteUserDataOnUninstall: Boolean;

function InitializeUninstall(): Boolean;
begin
  DeleteUserDataOnUninstall :=
    MsgBox(
      '是否同时删除 Border Player 的个人数据？' + #13#10 + #13#10 +
      '选择“否”会保留曲库、设置、歌单和听歌统计，之后安装新版本仍可继续使用这些数据。' + #13#10 +
      '选择“是”会删除这些个人数据。',
      mbConfirmation,
      MB_YESNO or MB_DEFBUTTON2
    ) = IDYES;

  Result := True;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if (CurUninstallStep = usPostUninstall) and DeleteUserDataOnUninstall then
  begin
    DelTree(ExpandConstant('{userdocs}\Border Player'), True, True, True);
    DelTree(ExpandConstant('{userdocs}\border_player'), True, True, True);
    DelTree(ExpandConstant('{userappdata}\com.example\border_player'), True, True, True);
  end;
end;






















