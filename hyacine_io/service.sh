#!/system/bin/sh
# Hyacine IO v1.1.0 - Runtime I/O + storage + USB hotplug
# Merged from hyacine-io + customrom-fix (SD card scan)

LOG="/data/local/tmp/hyacine_io.log"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

wv() {
    [ -w "$1" ] || return 1
    echo "$2" > "$1" 2>/dev/null
    [ "$(cat "$1" 2>/dev/null)" = "$2" ] && return 0
    return 1
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done

log "=== Hyacine IO v1.1.0 Active ==="

# NOTE: FUSE passthrough handled in post-fs-data only.
# Toggling at runtime causes storage disconnect → apps lose media access.

# Read-ahead
for bdi in /sys/class/bdi/*; do
    N=$(basename "$bdi"); M="${N%%:*}"
    case "$M" in 179|8) wv "$bdi/read_ahead_kb" 1024 "read_ahead $N";; esac
done

# Block queue
for dev in /sys/block/mmcblk* /sys/block/sd*; do
    [ ! -d "$dev" ] && continue
    DN=$(basename "$dev"); case "$DN" in mmcblk*boot*|mmcblk*rpmb) continue;; esac
    wv "$dev/queue/nr_requests" 128 "queue $DN nr_requests"
    wv "$dev/queue/nomerges" 0 "queue $DN nomerges"
    wv "$dev/queue/add_random" 0 "queue $DN add_random"
done

# SD card media scan (from customrom-fix)
for vol in /storage/*; do
    [ -d "$vol" ] || continue
    VN=$(basename "$vol")
    case "$VN" in emulated|self|selfPrimary|primary_physical) continue;; esac
    [ -d "/mnt/media_rw/$VN" ] || continue
    am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///storage/$VN" -p com.android.providers.media.module 2>/dev/null
    am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///storage/$VN" -p com.android.providers.media 2>/dev/null
    log "SD card scanned: $VN"
    break
done

# USB hotplug (check every 300s, not 60s — save battery)
LAST_USB=0
while true; do
    sleep 300
    USB=0
    for dev in /sys/block/sd*; do [ -d "$dev" ] && USB=$((USB + 1)); done
    if [ "$USB" -gt "$LAST_USB" ] && [ "$LAST_USB" -gt 0 ]; then
        log "USB detected ($LAST_USB -> $USB)"
        am broadcast -a android.intent.action.MEDIA_MOUNTED -d file:///storage/emulated/0 -p com.android.providers.media.module --user 0 >/dev/null 2>&1
        am broadcast -a android.intent.action.MEDIA_MOUNTED -d file:///storage/emulated/0 -p com.android.providers.media --user 0 >/dev/null 2>&1
    fi
    LAST_USB=$USB
done
