@echo off

:: Not that admin is needed in personal files, but depending on what you are trying to nuke into orbit, you may need an upgrade to your permissions.

for /f "delims=" %%d in ('dir /s /b /ad ^| sort /r') do rd "%%d"
