#!/system/bin/sh
# Multi Audio Play — service.sh
# Runtime configuration

MODDIR=${0%/*}

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
sleep 5

# Copy modified audio policy configuration
AUDIO_POLICY_SRC="$MODDIR/vendor/etc/audio_policy_configuration.xml"
AUDIO_POLICY_DST="/vendor/etc/audio_policy_configuration.xml"

if [ -f "$AUDIO_POLICY_SRC" ]; then
    # Backup original
    if [ ! -f "$AUDIO_POLICY_DST.bak" ]; then
        cp "$AUDIO_POLICY_DST" "$AUDIO_POLICY_DST.bak"
    fi
    
    # Mount overlay and copy
    mount -o rw,remount /vendor 2>/dev/null
    cp "$AUDIO_POLICY_SRC" "$AUDIO_POLICY_DST"
    mount -o ro,remount /vendor 2>/dev/null
    
    # Restart audioserver to apply changes
    stop audioserver
    sleep 2
    start audioserver
fi
