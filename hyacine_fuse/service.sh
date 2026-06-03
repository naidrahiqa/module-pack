#!/system/bin/sh
# Hyacine Fuse - I/O Optimization Only
LOGFILE="/data/local/tmp/hyacine_fuse.log"

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 10; done

# MASALAH 4 FIX: Hapus MediaProvider boost & media scan (Sudah di-handle Waguri My Bini)
log "Hyacine Fuse: Optimizing I/O read-ahead..."

# Tingkatkan read-ahead untuk performa storage
for bdi in /sys/class/bdi/*; do
    [ -f "$bdi/read_ahead_kb" ] && echo 2048 > "$bdi/read_ahead_kb" 2>/dev/null
done

log "I/O Optimization complete. Storage visibility handled by Waguri My Bini."
