@echo off

::Let's set the variable we want to work with.
set test=SomeTextGoesHere
echo Our test variable has been set.
echo %test%
echo.

::First off, We can get the first part of the variable. This will give us the word "Some", since these are the first four letters of the var.
echo First Four Characters.
echo %test:~0,4%
echo.

::We can also skip the first four and just echo the rest.
echo Skip the first four, echo the rest.
echo %test:~4%
echo.

:: Next we skip first four, echo four, then ignore rest
echo Skip Four, Echo Four, Skip the rest
echo %test:~4,4%
echo.

:: Starts at the end of the variable and counts backwards.
echo Count backwards four. Echo those four characters.
echo %test:~-4%
echo.

:: Starts at the end, skips the first 8 letters, then starts showing letters, stop at the fourth letter counting backwards.
echo Counts backwards 8 letters, echos until it reaches the fourth letter, then stops.
echo %test:~-8,-4%
echo.

:: You can pull parts of a variable into any command using this same structure.
echo Simple IF function.
if "%test:~-8,-4%"=="Goes" echo IF just checked if the specified part of the variable matches a string. You are seeing this because it worked.
::Of course, if it didn't match, it works as well.
if not "%test:~-8,-4%"=="Here" echo IF just checked if the specified part of the variable does not match a string. You are seeing this because it worked.
echo.

::You can use numbers in the same way. Let's say we change our var to some kind of combination of numbers and letters.
set test=We are using the random number 34.
echo We've changed our variable to a new string.
echo %test%
echo.

::We are going to grab the number 3 to work with.
::We are goong to perform simple math on this number.
set /a Number=%test:~31,1%+16
echo We have taken the number %test:~31,1% and added 16. We put that into a var and the new number is %Number%.
echo.

::We don't have to set a different variable if we want to do math. We can run the math on the same var and have it change the var to the number we want.
::We just loose the rest of the contents of that variable. This is just showing that the same structure works in different ways.
set /a test=%test:~31,1%+16
echo We have permanently changed our test var to the value %test%.

pause
