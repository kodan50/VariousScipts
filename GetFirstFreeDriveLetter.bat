@echo off

::This is a gangster way to get the first free drive letter to use in a batch file. There are better ways to do it, but if nothing else, this could be a compatibility reliant solution.
::I had to use this a long time ago before I found a more elegant solution, but I am posting it here in case it can be useful.

for %%a in (Z Y X W V U T S R Q P O N M L K J I H G F E D C) do CD %%a: 1>> nul 2>&1 & if errorlevel 1 set freedrive=%%a:
echo %freedrive%
pause
