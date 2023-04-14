:: We are going to start by getting admin privs. I hate doing things without admin permissions, because I hate being told no. If you don't like running scripts as admin, you are free to write your own.
rem git.Admin-Access()

:: Next, we would want to choose a folder that contains all the recovered files we want to go through.
rem git.folder-locale()

:: We should be setting options. I only know of adding "min file size" and deleting everything that is _smaller_ than "min file size"
rem git.min-file-size()
rem if /i MinSize GTR 1 set /a DelSize=%MinSize%-1

:: We can remove files we know are trash.
rem FOR /F delims&= %%A IN ('dir/s/b/ah thumbs.db') DO del "%%A"

:: Fourth step is going to be to remove empy files within this directory and all sub directories, as well as any file smaller than size specified above.
rem for /r %F in (*) do @if %~zF==0 del "%F"
rem for /r %F in (*) do @if %~zF==%MinSize% del "%F"

:: At some point, we can delete empty folders.
rem FOR /F delims^= %%B IN ('DIR/AD/B/S^|SORT/R') DO RD "%%B"
