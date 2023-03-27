:: You should run this as admin, I believe. You will need to reboot.

@echo off
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "AllowInsecureGuestAuth" /t REG_DWORD /d "1" /f
echo AllowInsecureGuestAuth has been set to 1
pause
