; Living Dream DSH v2.7.8 - Inno Setup Offline Installer
; Bundles Node.js, Python, Git for offline installation
; Compile: iscc.exe installer-v2-offline.iss
; Requires deps/ directory with node-*.msi, python-*.exe, Git-*.exe

#define MyAppName "Living Dream DSH"
#define MyAppVersion "2.7.8"
#define MyAppPublisher "alllllllllli"
#define MyAppURL "https://github.com/alllllllllli/Living-Dream-DSH"

[Setup]
AppId={{A7E4F8B2-3C9D-4E5F-A1B6-8D2E7F4C9A0B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={userappdata}\Living-Dream-DSH
DefaultGroupName={#MyAppName}
LicenseFile=LICENSE
OutputDir=.
OutputBaseFilename=Living-Dream-DSH-v{#MyAppVersion}-Offline-Setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\install.bat
UninstallDisplayName={#MyAppName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
DisableReadyPage=yes
LanguageDetectionMethod=uilanguage
ShowLanguageDialog=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
; Repo files (exclude .git, __pycache__, build artifacts)
Source: "*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: ".git,__pycache__,*.exe,*.sfx,deps,installer*.iss"
; Bundled dependencies — extracted to {app}\deps
Source: "deps\*"; DestDir: "{app}\deps"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\scripts\start-dsh.bat"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Run]
; 1. Run setup.ps1 (offline mode, visible shell, blocks until done)
Filename: "powershell.exe"; \
    Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\setup.ps1"" -InstallDir ""{app}"" -Offline -DepSource ""{app}\deps"""; \
    Flags: shellexec waituntilterminated; \
    Description: "Installing Living Dream DSH (offline)..."

; 2. "Add DeepSeek Harness to desktop" checkbox on finish page
Filename: "powershell.exe"; \
    Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\scripts\create-dsh-shortcut.ps1"" -AppDir ""{app}"""; \
    Flags: postinstall nowait shellexec hidewizard; \
    Description: "Add DeepSeek Harness to desktop"; \
    Check: DshDetected

[Code]
function DshDetected(): Boolean;
var
  TmpFile: String;
begin
  TmpFile := ExpandConstant('{app}\scripts\detected-dsh-path.txt');
  Result := FileExists(TmpFile);
end;