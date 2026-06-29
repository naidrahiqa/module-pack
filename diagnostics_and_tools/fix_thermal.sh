#!/system/bin/sh
# Fix thermal zones disabled by X_THERMAL

LOGFILE="/data/local/tmp/fix_thermal.log"

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

log "===== FIXING THERMAL ZONES ====="

# Re-enable all thermal zones
COUNT=0
for zone in /sys/class/thermal/thermal_zone*/mode; do
    [ -f "$zone" ] || continue
    BEFORE=$(cat "$zone" 2>/dev/null)
    if [ "$BEFORE" = "disabled" ] || [ "$BEFORE" = "0" ]; then
        echo "enabled" > "$zone" 2>/dev/null || echo "1" > "$zone" 2>/dev/null
        AFTER=$(cat "$zone" 2>/dev/null)
        log "zone: $BEFORE -> $AFTER"
        COUNT=$((COUNT + 1))
    fi
done
log "Re-enabled $COUNT thermal zone(s)"

# Restart thermal services
log "Starting thermal services..."
start thermal 2>/dev/null
start thermal_manager 2>/dev/null
start thermalloadalgod 2>/dev/null

# Verify
sleep 2
log "=== VERIFICATION ==="
for svc in thermal thermal_manager thermalloadalgod mi_thermald; do
    STATUS=$(getprop init.svc.$svc 2>/dev/null)
    log "  init.svc.$svc = $STATUS"
done

for zone in /sys/class/thermal/thermal_zone*/mode; do
    [ -f "$zone" ] || continue
    log "  $zone = $(cat $zone 2>/dev/null)"
done

log "===== DONE ====="
