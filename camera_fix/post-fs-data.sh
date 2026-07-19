#!/system/bin/sh
# Camera Quality Fix - Early Boot Properties
# Redmi 10 (selene) MT6768 - LineageOS 20

MODDIR=${0%/*}
LOGFILE=/data/local/tmp/camera_fix.log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

log "Camera Fix v1.0.0 - post-fs-data starting"

# Wait for resetprop to be available
while ! command -v resetprop >/dev/null 2>&1; do
    sleep 1
done

# HAL3 enable
resetprop persist.vendor.camera.HAL3.enable 1
log "HAL3 enabled"

# JPEG quality max
resetprop persist.vendor.camera.jpeg.quality 100
log "JPEG quality set to 100"

# EXIF data
resetprop persist.vendor.camera.exif.enable 1
log "EXIF enabled"

# Disable stats test
resetprop persist.vendor.camera.stats.test 0

# Camera context
resetprop ro.vendor.camera.cxt 1

# Disable face image processing
resetprop persist.vendor.camera.fdimgproc 0

# Disable frame memory mode
resetprop persist.vendor.camera.framememode 0

# Enable RAW capture
resetprop persist.vendor.camera.raw 1
log "RAW capture enabled"

# Auto exposure unlock
resetprop persist.vendor.camera.ae.lock 0

# Auto white balance unlock
resetprop persist.vendor.camera.awb.lock 0

log "Camera Fix v1.0.0 - post-fs-data done"
