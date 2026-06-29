#!/system/bin/sh
# H-Thermal v1.0.0 - Zero thermal props at boot
# Single pass — no duplicate loops

getprop 2>/dev/null | grep -i 'ro.*thermal' | grep -oP '\[.*?\]' | tr -d '[]' | while read -r prop; do
    resetprop -n "$prop" 0 2>/dev/null
done
