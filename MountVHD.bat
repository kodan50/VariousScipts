@echo off

:: I started writing fancy code to make folders and create a VHD and I gave up when I realized I needed to format it and just have a VHD file already made plxkthx.
:: I also wrote this for a specific job, so you may need to change it to fit your specific needs.

:: Git.Admin()

:: We are going to determine first free drive letter. We may not need it later on, so this is vestigial.
setlocal EnableDelayedExpansion

for /f "tokens=2 delims==" %%d in ('wmic logicaldisk get caption /value ^| findstr /i /v "Caption"') do (
    set "drive=%%d"
    if not exist "!drive!\." (
        set "free_drive=!drive!"
        goto :done
    )
)

:done
echo First available drive letter: %free_drive%

:: What VHD are we working with?
set VHD_LOC="Path\to\VHD.vhd"

:: So we are going to mount our file in our hash folder.
:: The rescan requests are to fix some oddball issues I personally have with diskpart that you may not need.

echo select vdisk file="%VHD_LOC" > "%TEMP%\Diskpart.srt"
echo attach vdisk >> "%TEMP%\Diskpart.srt"
echo rescan >> "%TEMP%\Diskpart.srt"
echo rescan >> "%TEMP%\Diskpart.srt"
echo select partition 1 >> "%TEMP%\Diskpart.srt"
echo rescan >> "%TEMP%\Diskpart.srt"
echo rescan >> "%TEMP%\Diskpart.srt"
echo assign mount="%CD%\Hash\" >> "%TEMP%\Diskpart.srt"

diskpart /s "%TEMP%\Diskpart.srt"

:end
