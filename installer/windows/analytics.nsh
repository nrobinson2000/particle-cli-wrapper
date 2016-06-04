; Send analytics to Segment during installation
;
; Setup:
; Base64 encode your Segment source write key followed by :
; Example: Write key=abc123 => encode abc123: => YWJjMTIzOg==
;
; Usage:
; In the installer call
; ${Track} "My event"
;
; or
;
; ${TrackWithProperties} "Important event"
; 	Push "Status"
; 	Push "Success"
; ${TrackEnd}

; Segment write key: p8DuwER9oRds1CTfL6FJrbYETYA1grCw
; Base64 encoded:
!define SEGMENT_AUTH "cDhEdXdFUjlvUmRzMUNUZkw2RkpyYllFVFlBMWdyQ3c6"

; Base URL of the Segment API
!define SEGMENT_API_BASE "https://api.segment.io/v1"

!include "GetWindowsVersion.nsh"

!define TRACK_END_ARGS "/endarguments"

!macro GetUserSID VAR
	nsExec::ExecToStack "whoami /user /nh"
	Pop ${VAR} ; exit code of the executable
	Pop ${VAR}
!macroend

!macro DefineTrack un
;FIXME: remove print statements
Function ${un}Track
	; Clear Event JSON
	nsJSON::Set /tree Event /value "{}"

	;DetailPrint "Track called"
	; Properties
	${Do}
		Pop $1
		Pop $0
		;DetailPrint "Property $0=$1"
		StrCmp $1 "${TRACK_END_ARGS}" setEventName
		nsJSON::Set /tree Event "properties" "$0" /value '"$1"'
	${Loop}
setEventName:
	;DetailPrint "Event $0"
	; Last item on the stack was the event name
	nsJSON::Set /tree Event "event" /value '"$0"'

	; OS version
	${GetWindowsVersion} $2
	${If} ${RunningX64}
		StrCpy $3 "64 bit"
	${Else}
		StrCpy $3 "32 bit"
	${EndIf}
	;DetailPrint "Windows $2 ($3)"
	nsJSON::Set /tree Event "context" "os" "name" /value '"Windows"'
	nsJSON::Set /tree Event "context" "os" "version" /value '"$2 ($3)"'

	; Get anonymous user ID
	!insertmacro GetUserSID $4
	nsJSON::Quote "$4"
	Pop $4
	;DetailPrint "SID $4"
	nsJSON::Set /tree Event "anonymousId" /value '$4'

	; Convert properties to JSON
	nsJSON::Serialize /tree Event
	Pop $0
	;DetailPrint "Request body $0"
	GetTempFileName $1
	inetc::post "$0" /SILENT /HEADER "Content-Type: application/json$\nAuthorization: basic ${SEGMENT_AUTH}" "${SEGMENT_API_BASE}/track" $1 /end
FunctionEnd
!macroend

!define TrackWithProperties "!insertmacro TrackWithProperties"
!define TrackEnd "!insertmacro TrackEnd"

!macro Track EVENT
	Push "${EVENT}"
	Push "${TRACK_END_ARGS}"
	!ifdef __UNINSTALL__
		Call un.Track
	!else
		Call Track
	!endif
!macroend
!define Track "!insertmacro Track"

!macro TrackWithProperties EVENT
	Push "${EVENT}"
	Push "${TRACK_END_ARGS}"
!macroend
!macro TrackEnd
	!ifdef __UNINSTALL__
		Call un.Track
	!else
		Call Track
	!endif
!macroend


; Make Track available for installer and uninstaller
!insertmacro DefineTrack ""
!insertmacro DefineTrack "un."

