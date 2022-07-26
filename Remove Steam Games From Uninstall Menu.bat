@echo off
::Provided valve has not changed how Steam games are installed, this will output all Steam games into a file then remove the corresponding uninstall entries.
::I don't usually have to uninstall the game and if I ever do, I can do it from the Steam program.
::I don't know if this will break anything, use with caution.
::Run as an admin.

reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | FIND "Steam App" > RegOut.txt

for /f "delims=" %%a in ('type RegOut.txt') do (
REG DELETE  "%%a" /f
)

del RegOut.txt
