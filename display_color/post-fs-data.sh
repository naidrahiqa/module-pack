#!/system/bin/sh
# Display Color Tuning v1.0.0 — Early boot display props
# post-fs-data.sh

MODDIR=${0%/*}
LOG="/data/local/tmp/display_color.log"

log() { echo "[$(date '+%m-%d %H:%M:%S')] [post-fs-data] $*" >> "$LOG"; }

log "=== Display Color Tuning v1.0.0 ==="

resetprop persist.sys.display.calibration 1
resetprop persist.sys.display.color_mode 1
resetprop persist.sys.display.night_mode 1
resetprop persist.sys.display.saturation 1.0
resetprop persist.sys.display.contrast 1.0
resetprop persist.sys.display.brightness 1
resetprop ro.vendor.display.calibration 1
resetprop ro.vendor.display.color_enhance 1
resetprop persist.vendor.color.matrix 1
resetprop persist.sys.sf.color_mode 1
resetprop persist.sys.display.hardware_brightness 1
resetprop debug.sf.hw 1
resetprop debug.composition.type gpu
resetprop ro.surface_flinger.max_frame_buffer_acquired_buffers 3

log "Properties set"

log "=== post-fs-data done ==="
