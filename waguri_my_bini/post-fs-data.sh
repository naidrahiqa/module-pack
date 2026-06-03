#!/system/bin/sh
# Waguri My Bini - Stable Boot Protection
MODDIR=${0%/*}

# MASALAH 4 FIX: Proteksi Akses /data
TRACKER="/data/local/tmp/waguri_bini_boot_attempts"
DISABLE_FLAG="/data/local/tmp/waguri_bini_disable"
LOGFILE="/data/local/tmp/waguri_bini_boot.log"

# Tunggu folder /data siap pakai (max 10 detik)
timeout=0
while [ ! -d "/data/local/tmp" ] || [ ! -w "/data/local/tmp" ]; do
    sleep 1
    timeout=$((timeout + 1))
    if [ $timeout -gt 10 ]; then
        # Jika /data tidak siap, jangan paksa tracker tapi tetap jalankan modul
        exit 0
    fi
done

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

# Logika Tracker Unik
if [ ! -f "$TRACKER" ]; then
    echo "1" > "$TRACKER"
else
    ATTEMPTS=$(cat "$TRACKER")
    ATTEMPTS=$((ATTEMPTS + 1))
    echo "$ATTEMPTS" > "$TRACKER"
    log "Boot attempt: $ATTEMPTS"

    if [ "$ATTEMPTS" -gt 3 ]; then
        log "CRITICAL: Bootloop detected. Disabling module."
        touch "$MODDIR/disable"
        exit 0
    fi
fi

# Basic ROM Bug Fixes
resetprop persist.device_config.global_flags.rescue_party_enabled false
resetprop persist.sys.disable_rescue true
