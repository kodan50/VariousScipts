@echo off

:: Git.Admin()
:init
 setlocal DisableDelayedExpansion
 set cmdInvoke=1
 set winSysFolder=System32
 set "batchPath=%~0"
 for %%k in (%0) do set batchName=%%~nk
 set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
 setlocal EnableDelayedExpansion

:getPrivileges
  if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
  ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
  ECHO args = "ELEV " >> "%vbsGetPrivileges%"
  ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
  ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
  ECHO Next >> "%vbsGetPrivileges%"

  if '%cmdInvoke%'=='1' goto InvokeCmd 

  ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
  goto ExecElevation

:InvokeCmd
  ECHO args = "/c """ + "!batchPath!" + """ " + args >> "%vbsGetPrivileges%"
  ECHO UAC.ShellExecute "%SystemRoot%\%winSysFolder%\cmd.exe", args, "", "runas", 1 >> "%vbsGetPrivileges%"

:ExecElevation
 "%SystemRoot%\%winSysFolder%\WScript.exe" "%vbsGetPrivileges%" %*
 exit

:gotPrivileges
 setlocal & cd /d %~dp0
 if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

cls
:: This will allow us to change files that should ease with disabling WSD. Probably will fail, though.
TAKEOWN /F %WINDIR%\INF\WSDPrint.Inf
ICACLS %WINDIR%\INF\WSDPrint.Inf /grant administrators:F
ren %WINDIR%\INF\WSDPrint.Inf WSDPrint.Inf.bak
TAKEOWN /F %WINDIR%\INF\WSDPrint.PNF
ICACLS %WINDIR%\INF\WSDPrint.PNF /grant administrators:F
ren %WINDIR%\INF\WSDPrint.PNF WSDPrint.PNF.bak
TAKEOWN /F %WINDIR%\INF\WSDScDrv.inf
ICACLS %WINDIR%\INF\WSDScDrv.inf /grant administrators:F
ren %WINDIR%\INF\WSDScDrv.inf WSDScDrv.inf.bak

:: Let's generate a registry file that should do the other half of the trick.
echo Windows Registry Editor Version 5.00> "%TEMP%\DisableWSD.reg"
echo.>> "%TEMP%\DisableWSD.reg"
echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WSDPrintDevice]>> "%TEMP%\DisableWSD.reg"
echo "Type"=dword:00000001>> "%TEMP%\DisableWSD.reg"
echo "Start"=dword:00000004>> "%TEMP%\DisableWSD.reg"
echo "ErrorControl"=dword:00000001>> "%TEMP%\DisableWSD.reg"
echo "Tag"=dword:00000028>> "%TEMP%\DisableWSD.reg"
echo "ImagePath"=hex(2):00,00>> "%TEMP%\DisableWSD.reg"
echo "DisplayName"="@WSDPrint.Inf,%%WSDPrintDevice.SVCDESC%%;WSD Print Support">> "%TEMP%\DisableWSD.reg"
echo "Group"="Extended Base">> "%TEMP%\DisableWSD.reg"
echo "Owners"=hex(7):00,00>> "%TEMP%\DisableWSD.reg"
echo.>> "%TEMP%\DisableWSD.reg"
echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WSDPrintDevice\Enum]>> "%TEMP%\DisableWSD.reg"
echo "Count"=dword:00000000>> "%TEMP%\DisableWSD.reg"
echo "NextInstance"=dword:00000000>> "%TEMP%\DisableWSD.reg"

:: Merge the new reg file into Windowz.

reg import "%TEMP%\DisableWSD.reg"

:: Please reboot your computer!
cls
echo Please reboot your computer.
pause > nul
