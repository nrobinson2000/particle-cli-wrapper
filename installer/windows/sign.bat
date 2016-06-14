if [%1] == [] goto noexec
if [%key_secret%] == [] goto nokey
if [%SIGNTOOL_PATH%] == [] set SIGNTOOL_PATH=c:\WinDDK\7600.16385.1\bin\amd64

"%SIGNTOOL_PATH%\signtool.exe" sign /v /f particle-code-signing-cert.p12 /p %key_secret% /tr http://tsa.starfieldtech.com %1
goto done

:nokey
echo Set the code signing certificate decryption key in the environment variable key_secret
goto done

:noexec
echo Specify an exe file to sign
goto done

:done
