@echo off
::add Admin.Privs(script)
wmic UserAccount set PasswordExpires=False
