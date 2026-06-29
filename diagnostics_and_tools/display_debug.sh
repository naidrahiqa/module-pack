#!/system/bin/sh
LOGFILE="/data/local/tmp/display_debug.log"
log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"; }

log "===== DISPLAY DEBUG ====="

log "--- D-state processes ---"
ps -A -o PID,STAT,WCHAN,COMM | grep D >> "$LOGFILE"

log "--- Display related ---"
cat /sys/class/graphics/fb0/status 2>/dev/null && log "fb0 status: $(cat /sys/class/graphics/fb0/status 2>/dev/null)"
cat /sys/devices/platform/soc/*.dsi.*/status 2>/dev/null && log "dsi status found"

log "--- Kernel display messages ---"
dmesg 2>/dev/null | grep -iE "lcm|dsi|panel|display|mdss|disp|0d|commit|underrun" | tail -30 >> "$LOGFILE"

log "--- Panel info ---"
for f in /sys/class/graphics/fb0/*; do
    NAME=$(basename "$f")
    case "$NAME" in
        *info*|*status*|*mode*|*panel*)
            VAL=$(cat "$f" 2>/dev/null)
            [ -n "$VAL" ] && log "  $NAME: $VAL"
            ;;
    esac
done

log "--- Display kernel module ---"
lsmod 2>/dev/null | grep -iE "msm|mdss|dsi|lcm|panel" >> "$LOGFILE"

log "===== DONE ====="
