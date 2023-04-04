@echo off
::add Admin.Privs(script)

::The following is supposed to set all password expirations to false.
wmic UserAccount set PasswordExpires=False
