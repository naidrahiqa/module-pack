#!/system/bin/sh
# Game PerfTune v2.0.0 — Boot-time base tuning
# Native binary handles TCP base. Shell fallback for compatibility.
MODDIR=${0%/*}
LOG="/data/local/tmp/game_perftune.log"
NATIVE="$MODDIR/bin/game_perftune"

[ -f "/data/local/tmp/game_perftune_disable" ] && exit 0

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }
log "=== Game PerfTune v2.0.0 (post-fs-data) ==="

echo 1 > /sys/module/ged/parameters/ged_boost_enable 2>/dev/null
log "GPU: ged_boost_enable=1"

if [ -x "$NATIVE" ]; then
    "$NATIVE" --base
else
    echo "4096 87380 6291456" > /proc/sys/net/ipv4/tcp_rmem 2>/dev/null
    echo "4096 65536 6291456" > /proc/sys/net/ipv4/tcp_wmem 2>/dev/null
    echo "65536 131072 262144" > /proc/sys/net/core/rmem_max 2>/dev/null
    echo "65536 131072 262144" > /proc/sys/net/core/wmem_max 2>/dev/null
fi
log "TCP buffers tuned"

touch /data/local/tmp/game_perftune_active
log "Base tuning applied"
