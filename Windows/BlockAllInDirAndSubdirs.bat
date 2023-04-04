@echo off

::This batch file will allow you to add all exe files within a folder and its subfolder to the Windows Firewall and set to block incoming and outgoing traffic.
::Do note that programs with escalated permissions may change firewall settings on their own, so for whatever reason you may need this, do not rely on it!
::I use this to set Steam to offline mode for a development virtual machine, so it won't update and break my development box. Your Mileage May Vary.
::If you change action=block to action=allow, you can perform the opposite and force allow all exe files to access the outside world unchecked.
::You probably shouldn't do that.
::Run this as an admin.

setlocal enableextensions 
cd /d "%~dp0"

for /R %%a in (*.exe) do (
netsh advfirewall firewall add rule name="Blocked with Batchfile %%a" dir=out program="%%a" action=block
netsh advfirewall firewall add rule name="Blocked with Batchfile %%a" dir=in program="%%a" action=block
)
