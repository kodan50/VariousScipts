#!/bin/bash

# Hardcoded IDs for safety, but could be variables
SRC="/dev/disk/by-id/usb-SOURCE"
DEST="/dev/disk/by-id/usb-DESTINATION"

# 1. Condition Checks
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if [ ! -b "$SRC" ] || [ ! -b "$DEST" ]; then
    echo "Error: Source or Destination device not found."
    exit 1
fi

# 2. Get Capacity
size=$(blockdev --getsize64 "$SRC")
echo "Total size to copy: $size bytes"

# 3. Start dd in background
# status=progress is available in GNU coreutils 8.24+
dd if="$SRC" of="$DEST" bs=4M status=progress conv=fsync
