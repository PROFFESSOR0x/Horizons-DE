#!/bin/bash
if pgrep -x "caelestia" > /dev/null; then
    killall caelestia
    sleep 0.4
    quickshell -c illogical-impulse &
else
    killall quickshell
    sleep 0.4
    caelestia shell -d &
fi
