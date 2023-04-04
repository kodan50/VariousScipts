#!/bin/bash

#We are going to put the file name and the path into a variable so wine32 can do something with it.
FileExec="$PWD/$1"

#This will filter out a filename from a general command.
#You can also change your wine prefix here to any other one.
if [ -f "$FileExec" ]; then
    WINEPREFIX=~/.wine32 wine "$FileExec"
else 
    WINEPREFIX=~/.wine32 $1
fi
