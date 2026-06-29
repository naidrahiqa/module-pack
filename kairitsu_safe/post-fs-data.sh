#!/system/bin/sh
# Kairitsu Safe v1.1.0 - Bootloop detection
# post-fs-data.sh: timestamp-based bootloop detection

MODDIR=${0%/*}
TRACKER="/data/local/tmp/kairitsu_boot_attempts"
DISABLE_FLAG="/data/local/tmp/kairitsu_disable"
LOGFILE="/data/local/tmp/kairitsu_boot.log"

# Wait for /data (max 10s)
T=0
while [ ! -d "/data/local/tmp" ] || [ ! -w "/data/local/tmp" ]; do
    sleep 2
    T=$((T + 2))
    [ "$T" -gt 10 ] && { touch "$MODDIR/disable"; exit 0; }
done

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"; }

VAL=$(cat "$TRACKER" 2>/dev/null)
NOW=$(date +%s)

if [ -z "$VAL" ]; then
    echo "$NOW" > "$TRACKER"
    log "First boot at $NOW"
elif echo "$VAL" | grep -qE '^OK:[0-9]+$'; then
    echo "$NOW" > "$TRACKER"
    log "Previous OK. Reset at $NOW"
elif echo "$VAL" | grep -qE '^[0-9]+$'; then
    DELTA=$((NOW - VAL))
    if [ "$DELTA" -lt 60 ]; then
        ATTEMPTS=$(ls -1 /data/local/tmp/kairitsu_loop_* 2>/dev/null | wc -l)
        ATTEMPTS=$((ATTEMPTS + 1))
        touch "/data/local/tmp/kairitsu_loop_$NOW"
        log "Bootloop (delta=${DELTA}s) attempt #$ATTEMPTS"
        [ "$ATTEMPTS" -gt 3 ] && { log "CRITICAL: >3x bootloop. Disabling."; touch "$MODDIR/disable"; exit 0; }
    else
        echo "$NOW" > "$TRACKER"
        log "Normal boot (delta=${DELTA}s)"
    fi
fi
