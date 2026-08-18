; Living Dream DSH - Inno Setup Installer Script
; Inno Setup 6.7+ required
; Compile: iscc.exe installer.iss

#define MyAppName "Living Dream DSH"
#define MyAppVersion "2.0.0"
#define MyAppPublisher "alllllllllli"
#define MyAppURL "https://github.com/alllllllllli/Living-Dream-DSH"
#define MyAppExeName "install.bat"

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
OutputBaseFilename=Living-Dream-DSH-v{#MyAppVersion}-Setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
SetupIconFile=
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
; Exclude .git, __pycache__, and the offline SFX from the installer
Source: "*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: ".git,__pycache__,*.exe,*.sfx"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\install.bat"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\install.bat"; Tasks: desktopicon

[Run]
; After extraction, run install-gui.ps1 via install.bat
Filename: "{app}\install.bat"; \
    Description: "Run Living Dream DSH Installer"; \
    Flags: shellexec waituntilterminated runascurrentuser postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// Custom wizard page: show note about API keys after install
var
  InfoPage: TOutputMsgWizardPage;

procedure InitializeWizard;
begin
  InfoPage := CreateOutputMsgPage(wpFinished,
    'Setup Complete',
    'Living Dream DSH has been installed successfully.',
    'The installer will now run to complete the setup.' + #13#10 + #13#10 +
    'After installation, you need to fill in your API keys in the DSH settings.' + #13#10 +
    'Please refer to the README.md for configuration instructions.' + #13#10 + #13#10 +
    'GitHub: https://github.com/alllllllllli/Living-Dream-DSH');
end;
