#!/system/bin/sh
# Hyacine IO v1.0.0 - Early boot I/O tuning + FUSE passthrough
# post-fs-data.sh

MODDIR=${0%/*}
LOG="/data/local/tmp/hyacine_io.log"

log() { echo "[$(date '+%m-%d %H:%M:%S')] [post-fs-data] $*" >> "$LOG"; }

wv() {
    [ -w "$1" ] || return 1
    echo "$2" > "$1" 2>/dev/null
    [ "$(cat "$1" 2>/dev/null)" = "$2" ] && { log "  $3: OK"; return 0; }
    log "  $3: FAIL"; return 1
}

log "=== Hyacine IO v1.3.0 ==="

# FUSE passthrough (SuSFS-aware)
HAS_SUSFS=0
[ -d /sys/fs/susfs ] && HAS_SUSFS=1
getprop persist.sys.susfs.enable 2>/dev/null | grep -q "true" && HAS_SUSFS=1

if [ "$HAS_SUSFS" -eq 0 ]; then
    resetprop persist.sys.fuse.passthrough.enable true 2>/dev/null
    log "FUSE passthrough: ENABLED"
else
    resetprop persist.sys.fuse.passthrough.enable false 2>/dev/null
    log "FUSE passthrough: DISABLED (SuSFS present)"
fi

# Read-ahead (eMMC/SD only)
for bdi in /sys/class/bdi/*; do
    N=$(basename "$bdi"); M="${N%%:*}"
    case "$M" in 179|8) wv "$bdi/read_ahead_kb" 1024 "read_ahead $N";; esac
done

log "=== post-fs-data done ==="
