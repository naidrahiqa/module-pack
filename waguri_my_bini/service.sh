#!/system/bin/sh
# Waguri My Bini - Master Stability Service v2.4 (Insurgent)
MODDIR=${0%/*}
LOGFILE="/data/local/tmp/waguri_bini_service.log"
DISABLE_FLAG="/data/local/tmp/waguri_bini_disable"

log() {
    echo "[WAGURI-MY-BINI] $(date '+%H:%M:%S') $*" >> "$LOGFILE"
}

wait_boot() {
    log "Waiting for boot to complete..."
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
    log "Boot completed. Waiting 10s for system stabilization..."
    sleep 10
}

# BUG 2 FIX: Robust MediaProvider discovery & boost
fix_storage_bug() {
    log "Starting MediaProvider boost flow..."
    local MP_PID=""
    local RETRY=0
    # 30 retries x 5s = 150 seconds (2.5 minutes)
    while [ $RETRY -lt 30 ] && [ -z "$MP_PID" ]; do
        MP_PID=$(pidof com.android.providers.media.module com.google.android.providers.media.module 2>/dev/null | awk '{print $1}')
        
        # Fallback search via ps
        if [ -z "$MP_PID" ]; then
            MP_PID=$(ps -A -o PID,NAME 2>/dev/null | grep "providers.media" | awk '{print $1}' | head -n 1)
        fi
        
        if [ -z "$MP_PID" ]; then
            sleep 5
            RETRY=$((RETRY + 1))
        fi
    done

    if [ -n "$MP_PID" ]; then
        echo -1000 > /proc/$MP_PID/oom_score_adj 2>/dev/null
        log "MediaProvider boosted (PID: $MP_PID)"
        
        # Trigger media scan to refresh gallery/storage invisibility
        am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard >/dev/null 2>&1
        log "Media scan triggered."
    else
        log "WARNING: MediaProvider not found after 30 attempts (150 detik)."
    fi
    log "MediaProvider boost flow finished."
}

# BUG 1 FIX: Triple-prong approach to disable Rescue Party
fix_crashes() {
    log "Starting Crash Prevention flow..."
    
    # 1. via resetprop (Magisk)
    resetprop persist.device_config.global_flags.rescue_party_enabled false
    resetprop persist.sys.disable_rescue true
    
    # 2. via settings database
    settings put global device_config/global_flags/rescue_party_enabled false 2>/dev/null
    settings put global crash_loop_remedy_enabled 0 2>/dev/null
    
    # Verification
    local rp_status=$(getprop persist.device_config.global_flags.rescue_party_enabled)
    log "Rescue Party status: $rp_status (Expected: false)"
    log "Crash Prevention flow finished."
}

# --- MAIN EXECUTION FLOW ---
wait_boot

# Exit jika flag disable aktif dari post-fs-data
if [ -f "$DISABLE_FLAG" ]; then
    log "Module disabled via flag. Exiting."
    exit 0
fi

log "===== Master Service v2.4 Active ====="

# Jalankan fix secara eksplisit
fix_crashes
fix_storage_bug

# Reset boot tracker karena boot sukses
rm -f /data/local/tmp/waguri_bini_boot_attempts
log "Boot tracker reset. System stable."

# Jalankan watchdog pendukung dengan absolute path
log "Starting Watchdog..."
nohup sh "$MODDIR/watchdog.sh" >/dev/null 2>&1 &

log "Master Service tasks finished."
