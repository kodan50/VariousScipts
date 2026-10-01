:: You should run this as admin, I believe. You will need to reboot.

@echo off
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLinkedConnections" /t REG_DWORD /d "1" /f
echo EnableLinkedConnections has been set to 1
pause
