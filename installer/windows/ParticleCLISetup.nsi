; Particle CLI installer script

;--------------------------------
; General

; Name and file
!define PRODUCT_NAME "Particle CLI"
!define SHORT_NAME "ParticleCLI"
Name "${PRODUCT_NAME}"
OutFile "ParticleCLISetup.exe"
!define COMPANY_NAME "Particle Industries, Inc"
!define MUI_ICON "assets\particle.ico"

; Installation directory
InstallDir "$LOCALAPPDATA\particle"
!define BINDIR "$INSTDIR\bin"

; CLI Executable
!define EXE "particle.exe"

; File with latest CLI build
!define ManifestURL "https://binaries.particle.io/cli/master/manifest.json"

; Request admin privileges for Windows Vista
RequestExecutionLevel admin

; Show command line with details of the installation
ShowInstDetails show

; Registry Entry for environment
; All users:
;!define Environ 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
; Current user only:
!define Environ 'HKCU "Environment"'

; Text to display when the installation is done
CompletedText 'Run "particle setup" in the command line to start using the Particle CLI'

;--------------------------------
; Dependencies

; Add JSON and download plugins
!addplugindir /x86-ansi Plugins/x86-ansi
!addplugindir /x86-unicode Plugins/x86-unicode
; Modern UI
!include "MUI2.nsh"
; Architecture detection
!include "x64.nsh"
!include "TextFunc.nsh"
!include "LogicLib.nsh"

!include "utils.nsh"
!include "install_drivers.nsh"
!include "analytics.nsh"

; Don't show a certain operation in the details
!macro EchoOff
	SetDetailsPrint none
!macroend
!macro EchoOn
	SetDetailsPrint both
!macroend
!define EchoOff "!insertmacro EchoOff"
!define EchoOn "!insertmacro EchoOn"

; Extract the URL of the CLI build tin $BuildUrl for a certain architecture
!macro GetBuildUrl ARCH
	nsJSON::Get /tree Manifest "builds" "windows" "${ARCH}" "url" /end
	Pop $R0
	StrCpy "$BuildUrl" "$R0"
!macroend

;--------------------------------
; Installer pages

; Welcome page
!define MUI_WELCOMEFINISHPAGE_BITMAP "assets\particle.bmp"
!define MUI_WELCOMEPAGE_TITLE "Install the ${PRODUCT_NAME}"
!define /file MUI_WELCOMEPAGE_TEXT "welcome.txt" 
!insertmacro MUI_PAGE_WELCOME

; Open source licenses
!insertmacro MUI_PAGE_LICENSE "licenses.txt"

; Installation details page
!insertmacro MUI_PAGE_INSTFILES

; Uninstall confirm page
!insertmacro MUI_UNPAGE_CONFIRM
; Uninstallation details page
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section "Begin installation"
    SetOutPath $INSTDIR
SectionEnd

Section "Download CLI wrapper manifest"
	Var /GLOBAL ManifestFile
	Var /GLOBAL BuildUrl

	; Download and parse JSON manifest file
	DetailPrint "Downloading build information"
	GetTempFileName "$ManifestFile"
	inetc::get /RESUME "" /CAPTION "Downloading build information" "${ManifestURL}" "$ManifestFile" /END
	Pop $0
	StrCmp $0 "OK" parseManifest
	Abort

parseManifest:
	nsJSON::Set /tree Manifest /file "$ManifestFile"
	${If} ${RunningX64}
		!insertmacro GetBuildUrl "amd64"
	${Else}
		!insertmacro GetBuildUrl "386"
	${EndIf}

	${EchoOff}
		Delete "$ManifestFile"
	${EchoOn}
SectionEnd

Section "Download CLI wrapper"
	; Track start of installation process (do it after the manifest is
	; fetched in order to track installs with internet only)
	${Track} "Install Start"

	Var /GLOBAL WrapperFile
	GetTempFileName "$WrapperFile"
	CreateDirectory "${BINDIR}"

	; Download executable to a temp file
	DetailPrint "Downloading CLI executable"
	inetc::get /RESUME "" /CAPTION "Downloading CLI executable" "$BuildUrl" "$WrapperFile" /END
	Pop $0
	StrCmp $0 "OK" moveWrapper
	Abort

moveWrapper:
	; Move wrapper to the final folder
	${EchoOff}
		IfFileExists "${BINDIR}\${EXE}" 0 +2
			Delete "${BINDIR}\${EXE}"
	${EchoOn}
	Rename "$WrapperFile" "${BINDIR}\${EXE}"
SectionEnd

Section "Run CLI wrapper once"
	DetailPrint "Downloading and installing CLI dependencies. This may take several minutes..."

	; CLI will install Node and all modules needed
	nsExec::ExecToLog "${BINDIR}\${EXE}"
SectionEnd

Section "Install DFU"
    File /r "bin"
SectionEnd

Section "Add CLI to path"
	DetailPrint "Adding CLI to path"
	Push "${BINDIR}"
	Call AddToPath
SectionEnd

Section "Install DFU drivers"
	!insertmacro ExtractWDISimple

	!insertmacro InstallDriver "Core" "0x1D50" "0x607F"
	!insertmacro InstallDriver "Photon" "0x2B04" "0xD006" 
	!insertmacro InstallDriver "P1" "0x2B04" "0xD008" 
	!insertmacro InstallDriver "Electron" "0x2B04" "0xD00A" 
SectionEnd

Section "Create uninstaller"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${SHORT_NAME}" "DisplayName" "${PRODUCT_NAME}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${SHORT_NAME}" "Publisher" "${COMPANY_NAME}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${SHORT_NAME}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${SHORT_NAME}" "NoModify" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${SHORT_NAME}" "NoRepair" 1

	WriteUninstaller "$INSTDIR\Uninstall.exe"
	DetailPrint ""
SectionEnd

;--------------------------------
; Uninstaller Section

Section "Uninstall"
	${Track} "Uninstall"
	RMDir /r /REBOOTOK "$INSTDIR"

	Delete "$INSTDIR\Uninstall.exe"

    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${SHORT_NAME}"

	Push "${BINDIR}"
	Call un.RemoveFromPath
SectionEnd

Function .onInstFailed
	${TrackWithProperties} "Install Done"
		Push "Status"
		Push "Failed"
	${TrackEnd}
FunctionEnd

Function .onInstSuccess
	${TrackWithProperties} "Install Done"
		Push "Status"
		Push "Success"
	${TrackEnd}
FunctionEnd
