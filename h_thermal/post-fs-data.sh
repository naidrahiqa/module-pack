#!/system/bin/sh
# H-Thermal v1.1.0 - Zero thermal props at boot
# Single pass — no duplicate loops

getprop 2>/dev/null | grep -i 'ro.*thermal' | sed 's/.*\[\(.*\)\].*/\1/' | while read -r prop; do
    [ -n "$prop" ] && resetprop -n "$prop" 0 2>/dev/null
done
