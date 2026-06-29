#!/system/bin/sh
# Evanescia v1.0.0 - VM tuning + ZRAM + I/O scheduler
# post-fs-data.sh: early boot, set before zygote

MODDIR=${0%/*}
LOG="/data/local/tmp/evanescia.log"
DIS="/data/local/tmp/evanescia_disable"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

wv() {
    [ -w "$1" ] || return 1
    echo "$2" > "$1" 2>/dev/null
    local rv=$(cat "$1" 2>/dev/null)
    [ "$rv" = "$2" ] && { log "  $3: OK"; return 0; }
    log "  $3: FAIL"; return 1
}

[ -f "$DIS" ] && { log "Disabled."; exit 0; }

log "=== Evanescia Memory v1.1.0 ==="

# RAM detection
TOTAL_KB=$(awk '/^MemTotal:/{print $2}' /proc/meminfo); TOTAL_KB=${TOTAL_KB:-0}
TOTAL_MB=$((TOTAL_KB / 1024))

# Tuning values — conservative to avoid reclaim storms
# min_free: 8GB=24MB, 6GB=20MB, 4GB=16MB (stock Android ~18MB)
# extra_free: fraction of min_free, NOT additive with min_free
SW=40; DR=15; DBR=5; VP=80; MFK=24576; EFK=4096
if [ "$TOTAL_MB" -lt 4096 ]; then
    SW=60; MFK=16384; EFK=2048
elif [ "$TOTAL_MB" -lt 6144 ]; then
    MFK=20480; EFK=3072
fi

# Phase 1: VM
log "--- VM ---"
wv /proc/sys/vm/swappiness "$SW" "swappiness"
wv /proc/sys/vm/dirty_ratio "$DR" "dirty_ratio"
wv /proc/sys/vm/dirty_background_ratio "$DBR" "dirty_bg_ratio"
wv /proc/sys/vm/vfs_cache_pressure "$VP" "vfs_cache_pressure"
wv /proc/sys/vm/min_free_kbytes "$MFK" "min_free_kbytes"
wv /proc/sys/vm/extra_free_kbytes "$EFK" "extra_free_kbytes"
wv /proc/sys/vm/page-cluster 0 "page-cluster"

# Phase 2: ZRAM
log "--- ZRAM ---"
ZD=$(ls /sys/block/ 2>/dev/null | grep "^zram" | head -1)
if [ -n "$ZD" ] && [ -f "/sys/block/$ZD/comp_algorithm" ]; then
    ALGO=$(cat "/sys/block/$ZD/comp_algorithm" 2>/dev/null)
    USED=$(awk '{print $1}' "/sys/block/$ZD/mm_stat" 2>/dev/null)
    USED=${USED:-0}
    if [ "$USED" -gt 0 ] 2>/dev/null; then
        CUR=$(echo "$ALGO" | grep -oE '\[[^]]+\]' | tr -d '[]')
        log "  $ZD in use ($USED bytes) — algo: $CUR (locked)"
    else
        echo "$ALGO" | grep -q "zstd" && echo zstd > "/sys/block/$ZD/comp_algorithm" 2>/dev/null && log "  $ZD: zstd"
        NCPU=$(grep -c ^processor /proc/cpuinfo 2>/dev/null); NCPU=${NCPU:-4}
        STREAMS=$((NCPU / 2)); [ "$STREAMS" -lt 1 ] && STREAMS=1
        echo "$STREAMS" > "/sys/block/$ZD/max_comp_streams" 2>/dev/null
        log "  $ZD streams: $STREAMS"
    fi
fi

# Phase 3: I/O scheduler
log "--- I/O ---"
for dev in /sys/block/mmcblk*; do
    [ ! -d "$dev" ] && continue
    DN=$(basename "$dev"); case "$DN" in mmcblk*boot*|mmcblk*rpmb) continue;; esac
    SF="$dev/queue/scheduler"; [ ! -f "$SF" ] && continue
    grep -q "mq-deadline" "$SF" 2>/dev/null && ! grep -q "\[mq-deadline\]" "$SF" 2>/dev/null && echo mq-deadline > "$SF" 2>/dev/null
done

# Re-lock 1x (fight ROM init overrides, skip 3x to save boot time)
# No sleep needed — ROM init hasn't overwritten yet at this point
wv /proc/sys/vm/swappiness "$SW" "relock swappiness"
wv /proc/sys/vm/vfs_cache_pressure "$VP" "relock vfs_cache_pressure"
wv /proc/sys/vm/page-cluster 0 "relock page-cluster"

log "=== post-fs-data done ==="
