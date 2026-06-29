#!/system/bin/sh
# Emergency thermal + storage fix

LOGFILE="/data/local/tmp/fix_now.log"
log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"; }

log "===== EMERGENCY FIX ====="

# 1. Re-enable ALL thermal zones
log "--- Thermal Zones ---"
COUNT=0
for zone in /sys/class/thermal/thermal_zone*/mode; do
    [ -f "$zone" ] || continue
    BEFORE=$(cat "$zone" 2>/dev/null)
    if [ "$BEFORE" = "disabled" ] || [ "$BEFORE" = "0" ]; then
        echo "enabled" > "$zone" 2>/dev/null || echo "1" > "$zone" 2>/dev/null
        AFTER=$(cat "$zone" 2>/dev/null)
        log "  $zone: $BEFORE -> $AFTER"
        COUNT=$((COUNT + 1))
    fi
done
log "Re-enabled $COUNT thermal zone(s)"

# 2. Unlock thermal zone files (undo chmod 000)
for f in /sys/devices/virtual/thermal/thermal_zone*/mode; do
    [ -f "$f" ] && chmod 644 "$f" 2>/dev/null
done

# 3. Start thermal services
log "--- Thermal Services ---"
start thermal 2>/dev/null
start thermal_manager 2>/dev/null
start thermalloadalgod 2>/dev/null
sleep 1

for svc in thermal thermal_manager thermalloadalgod mi_thermald; do
    STATUS=$(getprop init.svc.$svc 2>/dev/null)
    log "  init.svc.$svc = $STATUS"
done

# 4. Kill stuck FUSE daemon if any
log "--- Storage ---"
FUSE_PID=$(pidof sdcardfs 2>/dev/null || pidof fuse 2>/dev/null)
if [ -n "$FUSE_PID" ]; then
    log "  FUSE daemon PID: $FUSE_PID (alive)"
else
    log "  No FUSE daemon found"
fi

# 5. Verify thermal readings
log "--- Temperature Check ---"
for zone in /sys/class/thermal/thermal_zone*/temp; do
    [ -f "$zone" ] || continue
    TEMP=$(cat "$zone" 2>/dev/null)
    if [ -n "$TEMP" ] && [ "$TEMP" != "0" ] && [ "$TEMP" != "-274000" ]; then
        TYPE=$(echo "$zone" | sed 's|/temp||')
        log "  $TYPE = $TEMP"
        break
    fi
done

# 6. Check SD card
log "--- SD Card ---"
if [ -b /dev/block/mmcblk1 ]; then
    SECTORS=$(cat /sys/block/mmcblk1/size 2>/dev/null)
    SIZE_MB=$((SECTORS / 2048))
    log "  /dev/block/mmcblk1 exists, ~${SIZE_MB}MB"
else
    log "  /dev/block/mmcblk1 NOT FOUND"
fi

mount | grep mmcblk1 > /dev/null 2>&1 && log "  SD card mounted" || log "  SD card NOT mounted"

# 7. Current load
log "--- Load ---"
log "  $(cat /proc/loadavg)"

log "===== DONE ====="
log "REBOOT RECOMMENDED after this fix"
