#!/system/bin/sh
# Waguri My Bini - Boot Protection Logic
MODDIR=${0%/*}

# MASALAH 1 FIX: Menggunakan path unik untuk menghindari konflik dengan modul lain
TRACKER="/data/local/tmp/waguri_bini_boot_attempts"
DISABLE_FLAG="/data/local/tmp/waguri_bini_disable"
LOGFILE="/data/local/tmp/waguri_bini_boot.log"

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

# Reset tracker jika boot berhasil (dicek di service.sh nanti)
# Tapi di sini kita hitung attempt-nya
if [ ! -f "$TRACKER" ]; then
    echo "1" > "$TRACKER"
else
    ATTEMPTS=$(cat "$TRACKER")
    ATTEMPTS=$((ATTEMPTS + 1))
    echo "$ATTEMPTS" > "$TRACKER"
    log "Boot attempt: $ATTEMPTS"

    if [ "$ATTEMPTS" -gt 3 ]; then
        log "CRITICAL: Bootloop detected. Disabling module functions."
        touch "$DISABLE_FLAG"
        # Buat file disable untuk Magisk agar modul tidak load di boot berikutnya
        touch "$MODDIR/disable"
        exit 0
    fi
fi

# Fungsi pencegahan crash sistem dasar
resetprop persist.device_config.global_flags.rescue_party_enabled false
resetprop persist.sys.disable_rescue true
