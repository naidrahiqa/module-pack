#!/system/bin/sh
# Display Color Tuning v1.0.0 — Runtime verification
# service.sh

LOG="/data/local/tmp/display_color.log"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done

log "=== Display Color Tuning v1.0.0 Active ==="

PROPS="persist.sys.display.calibration persist.sys.display.color_mode persist.sys.display.night_mode persist.sys.display.saturation persist.sys.display.contrast persist.sys.display.brightness ro.vendor.display.calibration ro.vendor.display.color_enhance persist.vendor.color.matrix persist.sys.sf.color_mode persist.sys.display.hardware_brightness debug.sf.hw debug.composition.type ro.surface_flinger.max_frame_buffer_acquired_buffers"

for p in $PROPS; do
    val=$(getprop "$p" 2>/dev/null)
    if [ -n "$val" ]; then
        log "  $p = $val (OK)"
    else
        log "  $p = (empty) — reapplying"
        case "$p" in
            persist.sys.display.calibration) resetprop "$p" 1 ;;
            persist.sys.display.color_mode) resetprop "$p" 1 ;;
            persist.sys.display.night_mode) resetprop "$p" 1 ;;
            persist.sys.display.saturation) resetprop "$p" 1.0 ;;
            persist.sys.display.contrast) resetprop "$p" 1.0 ;;
            persist.sys.display.brightness) resetprop "$p" 1 ;;
            ro.vendor.display.calibration) resetprop "$p" 1 ;;
            ro.vendor.display.color_enhance) resetprop "$p" 1 ;;
            persist.vendor.color.matrix) resetprop "$p" 1 ;;
            persist.sys.sf.color_mode) resetprop "$p" 1 ;;
            persist.sys.display.hardware_brightness) resetprop "$p" 1 ;;
            debug.sf.hw) resetprop "$p" 1 ;;
            debug.composition.type) resetprop "$p" gpu ;;
            ro.surface_flinger.max_frame_buffer_acquired_buffers) resetprop "$p" 3 ;;
        esac
    fi
done

log "=== service.sh done ==="
