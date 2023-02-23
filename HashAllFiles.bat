@echo off

:: This code is being kept because it took a lot of work to get it to work, just to abandon it for a different approach. This can generate a hash of a file and store that hash, along with the file name, into a single file. It can then read back the hash table using a colon as the delimiter.
:: This batch will be rewritten to behave differently when I have the brain space to do so, and a new batch will be uploaded here when that is done.

:: Staging. Or cleanup.

if exist hash.tbl del hash.tbl

:: We are going to generate a list of files to work with.
dir/b/s/a-d Source > FileList.txt

:: Next, we need to work out how to hash each file in the file list.
:: This FOR loop does something nifty I need to upload in my batch scripts separately, and that is the ability to subtract a variable string from another.
:: In this case, we subtract the contents of %CD% from FilePath, giving us the relative file path, instead of the absolute file path.
setlocal enabledelayedexpansion
for /f "delims=" %%a in (FileList.txt) do (
    FOR /F "tokens=*" %%G IN ('certutil -hashfile "%%a" SHA256 ^| find /i /v "certutil" ^| find /v " "') DO SET "var=%%G"
	set FilePath=%%a
	set RelativePath=!FilePath:%CD%\=!
    echo !RelativePath!:!var! >> hash.tbl
)
endlocal


:: Now we can load the hash table and spit it out in a nice way. This allows us to manipulate as we need.

setlocal EnableDelayedExpansion

for /f "tokens=1,* delims=:" %%a in (hash.tbl) do (
    set "path=%%a"
    set "hash=%%b"
    echo File: !path!
    echo Hash: !hash!
    echo.
)

endlocal

:end
