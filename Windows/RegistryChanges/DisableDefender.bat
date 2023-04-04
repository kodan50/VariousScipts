:: Git.Admin()

:: This works in 10, and might work in 11. Probably shouldn't test fate, though.

rem Let's see what version of Windows we are running.
setlocal
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j

:: I used to have a script that was a bit more effective, but Windows Defender deleted my script with no way to retrieve it from quarantine, so whatever Microsoft, you win. Here is my substandard script that might not get deleted by Defender.
if "%version%" == "10.0" 
echo Disabling Windows Defender
%windir%\System32\reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f > nul
%windir%\System32\reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f > nul
echo Attempting to disable Malicious Software Removal Tool.
%windir%\System32\reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\MRT" /v DontOfferThroughWUAU /t REG_DWORD /d 1 /f > nul
echo Complete! Please install a grown-up antivirus before Defender throws another temper tantrum and turns itself back on.
)
