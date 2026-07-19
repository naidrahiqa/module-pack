#!/system/bin/sh
# Media Playback Fix - post-fs-data.sh
# Redmi 10 (selene) MT6768 - LineageOS 20
# Early boot: set media properties via resetprop

MODDIR=${0%/*}
LOGFILE=/data/local/tmp/media_fix.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [post-fs-data] $1" >> "$LOGFILE"
}

log_msg "=== Media Playback Fix v1.0.0 - post-fs-data ==="

# Enable hardware video codecs
resetprop media.omxcodec.service.enabled true
log_msg "Set media.omxcodec.service.enabled=true"

resetprop media.swcodec.service.enabled true
log_msg "Set media.swcodec.service.enabled=true"

resetprop vendor.media.omxcodec.service.enabled true
log_msg "Set vendor.media.omxcodec.service.enabled=true"

# Media buffer sizes for smoother playback
resetprop ro.media.max_threads 8
log_msg "Set ro.media.max_threads=8"

resetprop ro.media.audio_threads 4
log_msg "Set ro.media.audio_threads=4"

resetprop ro.media.video.max_threads 8
log_msg "Set ro.media.video.max_threads=8"

resetprop ro.media.video.decoder_timeout 30000
log_msg "Set ro.media.video.decoder_timeout=30000"

# Hardware acceleration
resetprop media.stagefright.ccodec 1
log_msg "Set media.stagefright.ccodec=1"

# Codec2 service
resetprop vendor.media.codec2.service.enabled true
log_msg "Set vendor.media.codec2.service.enabled=true"

# Media codec priority - prefer hardware
resetprop debug.media.codec priority hardware
log_msg "Set debug.media.codec=priority hardware"

# SurfaceFlinger frame pacing for smoother playback
resetprop debug.sf.latch_unsignaled 1
log_msg "Set debug.sf.latch_unsignaled=1"

log_msg "=== post-fs-data complete ==="
