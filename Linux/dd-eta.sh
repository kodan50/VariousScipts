#!/usr/bin/env bash

SRC="$1"
DST="$2"

if [[ -z "$SRC" || -z "$DST" ]]; then
    echo "Usage: $0 /dev/source /dev/destination"
    exit 1
fi

TOTAL_BYTES=$(blockdev --getsize64 "$SRC")
echo "Total bytes: $TOTAL_BYTES"

# Run dd in background
dd if="$SRC" of="$DST" bs=4M status=progress &
DDPID=$!

# Poll dd every second
while kill -0 "$DDPID" 2>/dev/null; do
    # Send USR1 to force dd to print a progress line
    kill -USR1 "$DDPID" 2>/dev/null
    sleep 1

    # Grab the latest progress line from dd's stderr
    PROGRESS=$(grep -o '[0-9]\+ bytes' /proc/$DDPID/fd/2 | tail -n1 | awk '{print $1}')

    if [[ -n "$PROGRESS" ]]; then
        BYTES=$PROGRESS
        SPEED=$(grep -o '[0-9.]\+ MB/s' /proc/$DDPID/fd/2 | tail -n1 | awk '{print $1}')

        # Convert MB/s to bytes/s
        SPEED_BYTES=$(awk -v m="$SPEED" 'BEGIN {print m * 1024 * 1024}')

        REMAINING=$(awk -v t="$TOTAL_BYTES" -v b="$BYTES" -v s="$SPEED_BYTES" \
            'BEGIN { if (s > 0) print (t - b) / s; else print -1 }')

        echo "Copied: $BYTES / $TOTAL_BYTES | ETA: ${REMAINING}s"
    fi
done

wait "$DDPID"
echo "Done."
