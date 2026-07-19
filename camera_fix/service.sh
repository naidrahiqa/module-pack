#!/system/bin/sh
# Camera Quality Fix - Runtime Optimizations
# Redmi 10 (selene) MT6768 - LineageOS 20

MODDIR=${0%/*}
LOGFILE=/data/local/tmp/camera_fix.log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

log "Camera Fix v1.0.0 - service.sh starting"

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done
log "Boot completed"

# Wait for camera service
while ! pidof cameraserver >/dev/null 2>&1; do
    sleep 5
done
log "Camera server started"

# Additional runtime optimizations
# Increase camera buffer size
resetprop persist.vendor.camera.buffercount 5
log "Camera buffer count set"

# Enable ZSL (Zero Shutter Lag)
resetprop persist.vendor.camera.zsl 1
log "ZSL enabled"

# Set preview FPS
resetprop persist.vendor.camera.preview.fps 60
log "Preview FPS set to 60"

# Enable OIS if available
resetprop persist.vendor.camera.ois.enable 1
log "OIS enabled"

log "Camera Fix v1.0.0 - service.sh done"
