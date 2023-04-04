@echo off
::You can change F: to whatever drive letter you want. You can also use a variable like %DriveLetter% if you have it assigned.
::The first FOR loop gets the stuff we need, and the second FOR loop removes the white spaces at the end of the variable added by WMIC.
::The echo command ignores the first character of the variable, and shows the next 11 characters after. I use this in a different FOR loop not covered here.
::The echo. command shouldn't be needed, but without it cmd complains about syntax, so I left it in.
::NTFS and probably a few others use larger than 11 characters for LABEL, however this was built for a purpose using ExFAT drives.
::You can change the size of the echo command to get a larger label.
FOR /f "delims=" %%A in ('wmic volume where "Driveletter like 'F:'" get label') do (
for /f "tokens=* delims=" %%B in ("%%A") do set var="%%B"
echo.
)

ECHO %var:~1,11%
pause
