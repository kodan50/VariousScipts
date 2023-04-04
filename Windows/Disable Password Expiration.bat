@echo off
::add Admin.Privs(script)

::First code attempt to disable passsword expiration
wmic UserAccount set PasswordExpires=False

::Second code attempt to disable passsword expiration
net accounts /MaxPWAge:unlimited
