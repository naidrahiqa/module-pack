#!/system/bin/sh
# Game PerfTune v2.0.0 — Thin launcher for native daemon
LOG="/data/local/tmp/game_perftune.log"
MODDIR="/data/adb/modules/game_perftune"
NATIVE="$MODDIR/bin/game_perftune"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do sleep 2; done
sleep 5

[ -f "/data/local/tmp/game_perftune_disable" ] && exit 0

if [ -x "$NATIVE" ]; then
    log "Starting native daemon..."
    exec "$NATIVE"
else
    log "ERROR: Native binary not found at $NATIVE"
    log "Falling back to shell daemon (legacy mode)"
    exec sh "$MODDIR/service_legacy.sh"
fi
