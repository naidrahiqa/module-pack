#!/system/bin/sh
# Storage Permission Fix - post-fs-data.sh
# Disables scoped storage restrictions and grants legacy storage access
# For Redmi 10 (selene) MT6768 on LineageOS 20

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/storage_fix.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [post-fs-data] $1" >> "$LOGFILE"
}

log "=== Storage Permission Fix v1.0.0 starting ==="

# Disable scoped storage enforcement
resetprop storage_scoped_access false
log "Set storage_scoped_access=false"

# Disable FUSE for SD card
resetprop persist.fuse_sdcard false
log "Set persist.fuse_sdcard=false"

# Enable entropy for crypto
resetprop ro.crypto.entropy true
log "Set ro.crypto.entropy=true"

# Disable vold decrypt
resetprop vold.decrypt 0
log "Set vold.decrypt=0"

# Disable adoptable storage
resetprop vold.has_adoptable 0
log "Set vold.has_adoptable=0"

# Additional storage props for legacy access
resetprop persist.sys.dalvik.vm.lib.2 libart.so
resetprop ro.vold.primary_physical 1
resetprop persist.sys.usb.config mtp,adb
resetprop persist.sys.storage.unicast true

# Grant legacy storage to all apps
resetprop persist.sys.unrestricted.storage true
log "Granted legacy unrestricted storage access"

# Disable FUSE passthrough for internal storage stability
resetprop persist.sys.fuse.passthrough.enable false
log "Disabled FUSE passthrough"

log "=== post-fs-data.sh completed ==="
