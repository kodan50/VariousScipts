@echo off
::I don't remember where I got this from, but I do know I ran into a situation where I needed a way to time and date from an if statement.
::This just happened to work nicely.
::You can tweak what you actually need by removing parts of unique that you don't need.

for /f "tokens=2-8 delims=/:. " %%A in ("%date%:%time: =0%") do set "UNIQUE=%%C%%A%%B%%D%%E%%F%%G"
::%%C=Year
::%%A=Month
::%%B=Day
::%%D=Hour(24)
::%%E=Minute
::%%F=Second
::%%G=decisecond

echo.%date% %time%
echo.%UNIQUE%
echo Note that the decisecond of unique will be behind the echo'd out time by however many CPU cycles it takes to perform the FOR loop and skip over the remarked text above.
echo This is normal and expected.
pause
