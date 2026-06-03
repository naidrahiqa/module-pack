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

# MASALAH 8 FIX: Robust MediaProvider Discovery
fix_storage_bug() {
    MAX_RETRY=10
    RETRY=0
    while [ $RETRY -lt $MAX_RETRY ]; do
        # Cek versi Google dan AOSP sekaligus
        MP_PID=$(pidof com.android.providers.media.module com.google.android.providers.media.module 2>/dev/null | awk '{print $1}')
        
        # Fallback ketiga: Wildcard search via ps
        if [ -z "$MP_PID" ]; then
            MP_PID=$(ps -A -o PID,NAME | grep "providers.media" | awk '{print $1}' | head -n 1)
        fi

        if [ ! -z "$MP_PID" ]; then
            local pkg_name=$(cat /proc/$MP_PID/cmdline | tr '\0' ' ')
            log "MediaProvider detected: $pkg_name (PID: $MP_PID). Boosting OOM..."
            echo -1000 > /proc/$MP_PID/oom_score_adj
            return
        fi
        RETRY=$((RETRY + 1))
        sleep 5
    done
    log "WARNING: MediaProvider not found after 10 attempts."
}

fix_crashes() {
    log "Disabling Rescue Party & Crash Loop Remedy..."
    resetprop persist.device_config.global_flags.rescue_party_enabled false
    resetprop persist.sys.disable_rescue true
    settings put global crash_loop_remedy_enabled 0 2>/dev/null
}

# --- MAIN ---
fix_storage_bug
fix_crashes

# Reset boot tracker karena boot sukses
rm -f /data/local/tmp/waguri_bini_boot_attempts
log "Boot tracker reset. System stable."

# Jalankan watchdog pendukung
nohup sh "$MODDIR/watchdog.sh" >/dev/null 2>&1 &
