#!/system/bin/sh
# Evanescia v1.0.0 - Memory monitor (runtime)
# Monitors memory pressure, enforces VM tuning

MODDIR=${0%/*}
LOG="/data/local/tmp/evanescia.log"
DIS="/data/local/tmp/evanescia_disable"
INTERVAL=600

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

wv() {
    [ -w "$1" ] || return 1
    echo "$2" > "$1" 2>/dev/null
    [ "$(cat "$1" 2>/dev/null)" = "$2" ] && return 0
    return 1
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
sleep 10

[ -f "$DIS" ] && { log "Disabled."; exit 0; }

log "=== Evanescia Runtime v1.1.0 ==="

# Detect RAM once
TOTAL_KB=$(awk '/^MemTotal:/{print $2}' /proc/meminfo); TOTAL_KB=${TOTAL_KB:-0}
TOTAL_MB=$((TOTAL_KB / 1024))
SW=40; VP=80; MFK=24576; EFK=4096
if [ "$TOTAL_MB" -lt 4096 ]; then
    SW=60; MFK=16384; EFK=2048
elif [ "$TOTAL_MB" -lt 6144 ]; then
    MFK=20480; EFK=3072
fi

RED_TS=0; YEL_TS=0; CYCLE=0

while true; do
    sleep "$INTERVAL"

    # Enforce VM (only if changed)
    CUR=$(cat /proc/sys/vm/swappiness 2>/dev/null); [ "$CUR" != "$SW" ] && wv /proc/sys/vm/swappiness "$SW" "swappiness"
    CUR=$(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null); [ "$CUR" != "$VP" ] && wv /proc/sys/vm/vfs_cache_pressure "$VP" "vfs_cache_pressure"
    CUR=$(cat /proc/sys/vm/min_free_kbytes 2>/dev/null); [ "$CUR" != "$MFK" ] && wv /proc/sys/vm/min_free_kbytes "$MFK" "min_free_kbytes"
    CUR=$(cat /proc/sys/vm/extra_free_kbytes 2>/dev/null); [ "$CUR" != "$EFK" ] && wv /proc/sys/vm/extra_free_kbytes "$EFK" "extra_free_kbytes"

    # Memory check
    AVAIL=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo); AVAIL=${AVAIL:-0}
    AVAIL_PCT=$((AVAIL * 100 / TOTAL_KB))
    NOW=$(date +%s)

    if [ "$AVAIL_PCT" -lt 5 ] && [ $((NOW - RED_TS)) -gt 900 ]; then
        log "RED: ${AVAIL_PCT}% — drop_caches (conservative)"
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null
        RED_TS=$NOW
    elif [ "$AVAIL_PCT" -lt 10 ] && [ $((NOW - YEL_TS)) -gt 1200 ]; then
        log "YELLOW: ${AVAIL_PCT}%"
        YEL_TS=$NOW
    fi

    # Compact every 6 cycles (60 min) — only under real pressure
    # compact_memory is expensive on eMMC; avoid unless critical
    CYCLE=$((CYCLE + 1))
    if [ "$CYCLE" -ge 6 ]; then
        CYCLE=0
        LOAD=$(awk '{print int($1)}' /proc/loadavg 2>/dev/null); LOAD=${LOAD:-0}
        PSI=$(awk -F'avg10=' '/^full/{split($2,a," ");printf "%d",a[1]}' /proc/pressure/memory 2>/dev/null); PSI=${PSI:-0}
        [ "$LOAD" -le 3 ] && [ "$PSI" -gt 10 ] && echo 1 > /proc/sys/vm/compact_memory 2>/dev/null
    fi
done
