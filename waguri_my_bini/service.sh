#!/system/bin/sh
# Waguri My Bini - Master Stability Service
MODDIR=${0%/*}
LOGFILE="/data/local/tmp/waguri_bini_service.log"
DISABLE_FLAG="/data/local/tmp/waguri_bini_disable"

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

wait_boot() {
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
}

# Tunggu boot selesai
wait_boot

# Exit jika flag disable aktif dari post-fs-data
[ -f "$DISABLE_FLAG" ] && exit 0

log "Waguri My Bini Service Active"

# MASALAH 4 FIX: Koordinasi MediaProvider Boost
# Tunggu sampai MediaProvider benar-benar running sebelum di-boost
MAX_RETRY=10
RETRY=0
while [ $RETRY -lt $MAX_RETRY ]; do
    MP_PID=$(pidof com.android.providers.media.module)
    if [ ! -z "$MP_PID" ]; then
        log "MediaProvider found (PID: $MP_PID). Boosting OOM..."
        echo -1000 > /proc/$MP_PID/oom_score_adj
        break
    fi
    RETRY=$((RETRY + 1))
    sleep 5
done

# Trigger Media Scan satu kali secara resmi
sleep 5
am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard >/dev/null 2>&1
log "Final Media Scan triggered."

# Reset boot tracker karena boot sukses
rm -f /data/local/tmp/waguri_bini_boot_attempts
log "Boot tracker reset. System stable."

# Jalankan watchdog pendukung
nohup sh "$MODDIR/watchdog.sh" >/dev/null 2>&1 &
