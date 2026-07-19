#!/system/bin/sh
# Storage Permission Fix - service.sh
# Runtime verification and permission granting for Telegram
# For Redmi 10 (selene) MT6768 on LineageOS 20

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/storage_fix.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [service] $1" >> "$LOGFILE"
}

log "=== service.sh v1.0.0 starting ==="

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
log "Boot completed, proceeding with permission setup"

# Verify properties are set correctly
SCOPE_VAL=$(getprop storage_scoped_access)
if [ "$SCOPE_VAL" = "false" ]; then
    log "OK: storage_scoped_access is false"
else
    log "WARN: storage_scoped_access is '$SCOPE_VAL', resetting..."
    resetprop storage_scoped_access false
fi

FUSE_VAL=$(getprop persist.fuse_sdcard)
if [ "$FUSE_VAL" = "false" ]; then
    log "OK: persist.fuse_sdcard is false"
else
    log "WARN: persist.fuse_sdcard is '$FUSE_VAL', resetting..."
    resetprop persist.fuse_sdcard false
fi

# Grant storage permissions to Telegram
TELEGRAM_PKG="org.telegram.messenger"
if pm list packages | grep -q "$TELEGRAM_PKG"; then
    log "Telegram found, granting storage permissions..."
    
    # Grant READ_EXTERNAL_STORAGE
    pm grant "$TELEGRAM_PKG" android.permission.READ_EXTERNAL_STORAGE 2>/dev/null
    log "Granted READ_EXTERNAL_STORAGE to $TELEGRAM_PKG"
    
    # Grant WRITE_EXTERNAL_STORAGE
    pm grant "$TELEGRAM_PKG" android.permission.WRITE_EXTERNAL_STORAGE 2>/dev/null
    log "Granted WRITE_EXTERNAL_STORAGE to $TELEGRAM_PKG"
    
    # Grant MANAGE_EXTERNAL_STORAGE
    appops set "$TELEGRAM_PKG" MANAGE_EXTERNAL_STORAGE allow 2>/dev/null
    log "Granted MANAGE_EXTERNAL_STORAGE via appops to $TELEGRAM_PKG"
    
    # Grant STORAGE for scoped access
    appops set "$TELEGRAM_PKG" STORAGE allow 2>/dev/null
    log "Granted STORAGE appops to $TELEGRAM_PKG"
else
    log "Telegram not installed, skipping Telegram-specific grants"
fi

# Verify internal storage is accessible
if [ -d "/sdcard/Download" ]; then
    log "OK: /sdcard/Download is accessible"
else
    log "WARN: /sdcard/Download not found"
fi

if [ -d "/storage/emulated/0" ]; then
    log "OK: /storage/emulated/0 is accessible"
else
    log "WARN: /storage/emulated/0 not found"
fi

# Test write access
TEST_FILE="/sdcard/Download/.storage_fix_test"
echo "test" > "$TEST_FILE" 2>/dev/null
if [ -f "$TEST_FILE" ]; then
    log "OK: Write test to internal storage passed"
    rm -f "$TEST_FILE"
else
    log "WARN: Write test to internal storage failed"
fi

log "=== service.sh completed ==="
