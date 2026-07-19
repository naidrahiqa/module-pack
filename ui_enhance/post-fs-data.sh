#!/system/bin/sh
# UI Enhancement v1.1.0 - Early boot UI tweaks
# post-fs-data.sh: set before zygote

MODDIR=${0%/*}
LOG="/data/local/tmp/ui_enhance.log"
DIS="/data/local/tmp/ui_enhance_disable"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

[ -f "$DIS" ] && { log "Disabled."; exit 0; }

log "=== UI Enhancement v1.0.0 ==="

# Animation scales
resetprop WindowManager_animation_scale 1.0
resetprop WindowManager_transition_animation_scale 1.0
resetprop WindowManager_duration_scale 1.0

log "Animation scales: 1.0x"

# Hardware rendering
resetprop persist.sys.ui.hw true
resetprop debug.hwui.renderer skiagl
resetprop debug.hwui.show_dirty_regions false

log "Hardware rendering: enabled (skiagl)"

# SurfaceFlinger
resetprop ro.surface_flinger.max_frame_buffer_acquired_buffers 3
resetprop ro.surface_flinger.running_without_sync_framework false
resetprop ro.surface_flinger.use_hwc_for_vsync true

log "SurfaceFlinger: configured"

# Disable HW accel issues
resetprop ro.config.disable_hw_accel false

# Display raw orientation
resetprop viewpointer.debug.display_raw_orientation true

log "=== post-fs-data done ==="
