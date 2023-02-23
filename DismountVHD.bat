@echo off
:: Should work. Might not. Rewrite to fit your needs. Run as admin.
set VHD_LOC="Path\to\vhd.vhd"
echo select vdisk file=%VHD_LOC% > "%TEMP%\Diskpart.srt"
echo detach vdisk >> "%TEMP%\Diskpart.srt"

diskpart /s "%TEMP%\Diskpart.srt"
