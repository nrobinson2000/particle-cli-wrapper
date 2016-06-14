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

; Don't request admin privileges
RequestExecutionLevel user

; Show command line with details of the installation
ShowInstDetails show

; Registry Entry for environment
; All users:
;!define Environ 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
; Current user only:
!define Environ 'HKCU "Environment"'

; Registry entry for uninstaller
!define UNINSTALL_REG 'HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${SHORT_NAME}"'

; Text to display when the installation is done
CompletedText 'Run "particle setup" in the command line to start using the Particle CLI'

; Sign installer
; Make sure environment contains key_secret when launching MakeNSIS.exe
!finalize 'sign.bat "%1"'

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

; Select what to install
InstType "Full"
!insertmacro MUI_PAGE_COMPONENTS

; Installation details page
!insertmacro MUI_PAGE_INSTFILES

; Uninstall confirm page
!insertmacro MUI_UNPAGE_CONFIRM
; Uninstallation details page
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section "CLI" CLI_SECTION
	SectionIn 1 3
    SetOutPath $INSTDIR
	Call DownloadCLIManifest
	Call DownloadCLIWrapper
	Call RunCLIWrapper
	Call InstallDFU
	Call AddCLIToPath
SectionEnd

Section "USB drivers" DRIVERS_SECTION
	SectionIn 1 3
	Call InstallDrivers
SectionEnd

Section "-Create uninstaller"
    WriteRegStr ${UNINSTALL_REG} "DisplayName" "${PRODUCT_NAME}"
    WriteRegStr ${UNINSTALL_REG} "Publisher" "${COMPANY_NAME}"
    WriteRegStr ${UNINSTALL_REG} "UninstallString" '"$INSTDIR\Uninstall.exe"'
    WriteRegDWORD ${UNINSTALL_REG} "NoModify" 1
    WriteRegDWORD ${UNINSTALL_REG} "NoRepair" 1

	WriteUninstaller "$INSTDIR\Uninstall.exe"
	DetailPrint ""
SectionEnd


LangString DESC_CLI ${LANG_ENGLISH} "Particle command-line interface. Add to PATH. Run as particle in the command line"
LangString DESC_DRIVERS ${LANG_ENGLISH} "Drivers for USB serial and Device Firmware Update (DFU). Needs admin priviledges."

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${CLI_SECTION} $(DESC_CLI)
  !insertmacro MUI_DESCRIPTION_TEXT ${DRIVERS_SECTION} $(DESC_DRIVERS)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Uninstaller Sections

Section "Uninstall"
	${Track} "Uninstall"
	RMDir /r /REBOOTOK "$INSTDIR"

    DeleteRegKey ${UNINSTALL_REG}

	Push "${BINDIR}"
	Call un.RemoveFromPath
SectionEnd

;--------------------------------
; Installer logic

Function DownloadCLIManifest
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
FunctionEnd

Function DownloadCLIWrapper
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
FunctionEnd

Function RunCLIWrapper
	DetailPrint "Downloading and installing CLI dependencies. This may take several minutes..."

	; CLI will install Node and all modules needed
	nsExec::ExecToLog "${BINDIR}\${EXE}"
FunctionEnd

Function InstallDFU
    File /r "bin"
FunctionEnd

Function AddCLIToPath
	DetailPrint "Adding CLI to path"
	Push "${BINDIR}"
	Call AddToPath
FunctionEnd

Function InstallDrivers
	File "/oname=$TEMP\ParticleDriversSetup.exe" "ParticleDriversSetup.exe"
	DetailPrint "Installing USB drivers"
	# Install drivers in silent mode
	ExecShell "" "$TEMP\ParticleDriversSetup.exe" "/S"
FunctionEnd

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
