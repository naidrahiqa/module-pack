#!/system/bin/sh
# Media Playback Fix - service.sh
# Redmi 10 (selene) MT6768 - LineageOS 20
# Runtime: verify properties and log status

MODDIR=${0%/*}
LOGFILE=/data/local/tmp/media_fix.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [service] $1" >> "$LOGFILE"
}

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
sleep 5

log_msg "=== Media Playback Fix v1.0.0 - service ==="
log_msg "Boot completed, verifying properties..."

# Verify properties are set
check_prop() {
    val=$(getprop "$1")
    if [ "$val" = "$2" ]; then
        log_msg "OK: $1=$val"
    else
        log_msg "WARN: $1 expected=$2 got=$val"
        resetprop "$1" "$2"
        log_msg "RESET: $1=$2"
    fi
}

check_prop "media.omxcodec.service.enabled" "true"
check_prop "media.swcodec.service.enabled" "true"
check_prop "vendor.media.omxcodec.service.enabled" "true"
check_prop "ro.media.max_threads" "8"
check_prop "ro.media.audio_threads" "4"
check_prop "media.stagefright.ccodec" "1"
check_prop "ro.media.video.max_threads" "8"
check_prop "ro.media.video.decoder_timeout" "30000"

log_msg "=== service complete ==="
