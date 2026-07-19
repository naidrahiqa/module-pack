#!/system/bin/sh
# UI Enhancement v1.0.0 — Thin launcher for native daemon
LOG="/data/local/tmp/ui_enhance.log"
MODDIR="/data/adb/modules/ui_enhance"
NATIVE="$MODDIR/bin/ui_daemon"
DIS="/data/local/tmp/ui_enhance_disable"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do sleep 2; done
sleep 8

[ -f "$DIS" ] && { log "Disabled."; exit 0; }

if [ -x "$NATIVE" ]; then
    log "Starting native daemon..."
    exec "$NATIVE"
else
    log "ERROR: Native binary not found at $NATIVE"
    log "Falling back to shell mode"
    log "=== UI Enhancement Runtime v1.0.0 ==="
    resetprop WindowManager_animation_scale 1.0
    resetprop WindowManager_transition_animation_scale 1.0
    resetprop WindowManager_duration_scale 1.0
    resetprop ro.config.animation_scale 1.0
    resetprop persist.sys.animation_scale 1.0
    resetprop persist.sys.ui.hw true
    resetprop debug.hwui.renderer skiagl
    resetprop debug.hwui.show_dirty_regions false
    resetprop ro.config.disable_hw_accel false
    resetprop ro.surface_flinger.max_frame_buffer_acquired_buffers 3
    resetprop ro.surface_flinger.running_without_sync_framework false
    resetprop ro.surface_flinger.use_hwc_for_vsync true
    resetprop viewpointer.debug.display_raw_orientation true
    log "Shell fallback done"
fi
