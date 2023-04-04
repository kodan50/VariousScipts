:: Run in safe mode with networking.
if not "%SAFEBOOT_OPTION%"=="NETWORK" goto NoSafe

:: Since we need internet, let's see if we can stop Windows Update.
:: Safe mode means update shouldn't be running, but I don't trust Microsoft to not screw this up.
net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver
:: The following lines can attempt to rename the software distribution folder which is supposed to help solve this update issue, but I don't want to risk it breaking anything.
:: Remove the remark to use this, and is at your own risk.
rem attrib -s -h -r C:\Windows\SoftwareDistribution
rem cd /d C:\Windows
rem rename SoftwareDistribution SoftwareDistribution.old


:: I've added the echo command to automatically say yes when Powershell asks for use input. It should be noted that not all of the commands needed this...

:: We need to enable running scripts before we can use the module.
echo y | powershell -inputformat none -outputformat none -Command set-executionpolicy remotesigned

::Now, we will install the module. If we don't use both, everything falls apart. I don't know why or care why.
echo y | powershell -inputformat none -outputformat none -Command Install-Module -Name PSWindowsUpdate
echo y | powershell -inputformat none -outputformat none -Command Install-Module PSWindowsUpdate

::Next, we need to "import" the module. Is this like installing? I think this is like installing.
echo y | powershell -inputformat none -outputformat none -Command Import-Module PSWindowsUpdate

::Add the offending KB article to some block list.
echo y | powershell -inputformat none -outputformat none -Command Hide-WindowsUpdate -KBArticleID 5016616
echo y | powershell -inputformat none -outputformat none -Command Hide-WindowsUpdate -KBArticleID 5016688

goto end

:nosafe
echo Not booted in safe mode with networking. Boot into safe mode with networking.
pause
goto end

:end
