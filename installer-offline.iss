; Living Dream DSH - Inno Setup Offline Installer Script
; Bundles Node.js, Python, Git installers for offline installation
; Compile: iscc.exe installer-offline.iss

#define MyAppName "Living Dream DSH"
#define MyAppVersion "2.0.0"
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
LanguageDetectionMethod=uilanguage
ShowLanguageDialog=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Repo files (exclude .git, __pycache__, other installers)
Source: "*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: ".git,__pycache__,*.exe,*.sfx,*.iss"
; Offline deps — these go to {app}\deps (sibling of Living-Dream-DSH\)
Source: "deps\*"; DestDir: "{app}\deps"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\install.bat"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\install.bat"; Tasks: desktopicon

[Run]
; After extraction, run install.bat which calls install-gui.ps1
; install-gui.ps1 auto-detects deps/ folder → switches to offline mode
Filename: "{app}\install.bat"; \
    Description: "Run Living Dream DSH Offline Installer"; \
    Flags: shellexec waituntilterminated runascurrentuser postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
var
  InfoPage: TOutputMsgWizardPage;

procedure InitializeWizard;
begin
  InfoPage := CreateOutputMsgPage(wpFinished,
    'Offline Setup Complete',
    'Living Dream DSH has been installed successfully.',
    'This is an offline installer — no internet connection required.' + #13#10 + #13#10 +
    'The installer will now run to complete the setup.' + #13#10 +
    'All dependencies (Node.js, Python, Git) are bundled.' + #13#10 + #13#10 +
    'After installation, you need to fill in your API keys in the DSH settings.' + #13#10 +
    'Please refer to the README.md for configuration instructions.');
end;
