:: First step is to get admin privs. I hate doing things without admin permissions, because I hate being told no. If you don't like running scripts as admin, you are free to write your own.
rem git.Admin-Access()

:: Second step would be to choose a folder that contains all the recovered files we want to go through.
rem git.folder-locale()

:: Third step is going to be setting options. I only know of adding "min file size" and deleting everything that is _smaller_ than "min file size"
rem git.min-file-size()
rem if /i MinSize GTR 1 set /a DelSize=%MinSize%-1

:: Fourth step is going to be to remove empy files within this directory and all sub directories, as well as any file smaller than size specified above.
rem for /r %F in (*) do @if %~zF==0 del "%F"
rem for /r %F in (*) do @if %~zF==%MinSize% del "%F"
