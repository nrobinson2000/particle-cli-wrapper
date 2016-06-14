; Particle Driver installer script

;--------------------------------
; General

; Name and file
!define PRODUCT_NAME "Particle USB Drivers"
!define SHORT_NAME "ParticleDrivers"
Name "${PRODUCT_NAME}"
OutFile "ParticleDriversSetup.exe"
!define MUI_ICON "assets\particle.ico"

; Request admin privileges for Windows Vista
RequestExecutionLevel admin

; Show command line with details of the installation
ShowInstDetails show

; Sign installer
; Make sure environment contains key_secret when launching MakeNSIS.exe
!finalize 'sign.bat "%1"'

;--------------------------------
; Dependencies

; Modern UI
!include "MUI2.nsh"

; Architecture detection
!include "x64.nsh"

!include "install_drivers.nsh"

;--------------------------------
; Installer pages

; Welcome page
!define MUI_WELCOMEFINISHPAGE_BITMAP "assets\particle.bmp"
!define MUI_WELCOMEPAGE_TITLE "Install the ${PRODUCT_NAME}"
!define /file MUI_WELCOMEPAGE_TEXT "welcome_drivers.txt" 
!insertmacro MUI_PAGE_WELCOME

; Open source licenses
!insertmacro MUI_PAGE_LICENSE "licenses_drivers.txt"

; Installation details page
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section "Drivers"
	Call InstallSerialDrivers
	Call InstallDFUDrivers
SectionEnd

Function InstallSerialDrivers
    SetOutPath $TEMP
	!insertmacro ExtractSerialDrivers "serial_drivers"
	!insertmacro InstallSerialDriver "Core" "serial_drivers\spark_core"
	!insertmacro InstallSerialDriver "Photon" "serial_drivers\photon"
	!insertmacro InstallSerialDriver "P1" "serial_drivers\P1"
	!insertmacro InstallSerialDriver "Electron" "serial_drivers\electron"
FunctionEnd

Function InstallDFUDrivers
	!insertmacro ExtractWDISimple

	!insertmacro InstallDFUDriver "Core" "0x1D50" "0x607F"
	!insertmacro InstallDFUDriver "Photon" "0x2B04" "0xD006" 
	!insertmacro InstallDFUDriver "P1" "0x2B04" "0xD008" 
	!insertmacro InstallDFUDriver "Electron" "0x2B04" "0xD00A" 
FunctionEnd
