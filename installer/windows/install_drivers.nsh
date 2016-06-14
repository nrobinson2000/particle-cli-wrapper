; Driver installation command
!define PNPUTIL "pnputil.exe"

; Install USB Driver with wdi-simple
;
; wdi-simple.exe
;
; -n, --name <name>          set the device name
; -f, --inf <name>           set the inf name
; -m, --manufacturer <name>  set the manufacturer name
; -v, --vid <id>             set the vendor ID (VID)
; -p, --pid <id>             set the product ID (PID)
; -i, --iid <id>             set the interface ID (MI)
; -t, --type <driver_type>   set the driver to install
;                            (0=WinUSB, 1=libusb0, 2=libusbK, 3=custom)
; -d, --dest <dir>           set the extraction directory
; -x, --extract              extract files only (don't install)
; -c, --cert <certname>      install certificate <certname> from the
;                            embedded user files as a trusted publisher
;     --stealth-cert         installs certificate above without prompting
; -s, --silent               silent mode
; -b, --progressbar=[HWND]   display a progress bar during install
;                            an optional HWND can be specified
; -l, --log                  set log level (0 = debug, 4 = none)
; -h, --help                 display usage

!macro ExtractWDISimple
	File "/oname=$TEMP\wdi-simple.exe" "wdi-simple.exe"
!macroend

!macro InstallDFUDriver DEV VID PID
	DetailPrint "Installing DFU driver for ${DEV}"
	nsExec::ExecToLog '"$TEMP\wdi-simple.exe" --name "${DEV} DFU Mode" --vid ${VID} --pid ${PID} --type 2'
	Pop $0 ; Return value
	${If} $0 <> 0
		DetailPrint "Driver installation failed."
		DetailPrint "Please click Install if a Windows Security popup opens asking to trust the libusbK driver."
		Abort
	${EndIf}
!macroend

!macro InstallParticleCert
	DetailPrint "Installing Particle certificate"
	File "trustcertregister.exe"
	nsExec::ExecToLog "trustcertregister.exe"
!macroend

!macro ExtractSerialDrivers DIR
	File /r "${DIR}"
!macroend

!macro InstallSerialDriver DEV INF
	DetailPrint "Installing serial driver for ${DEV}"
	${DisableX64FSRedirection}
	nsExec::ExecToLog "${PNPUTIL} -i -a ${INF}.inf"
	Pop $0 ; Return value
	${If} $0 <> 0
		DetailPrint "Driver installation failed."
	${EndIf}
	${EnableX64FSRedirection}
!macroend

