#!/system/bin/sh
# Font Swap v1.0.0 - Runtime font monitor
# Waits for boot, applies font optimizations

MODDIR=${0%/*}
LOG="/data/local/tmp/font_swap.log"
DIS="/data/local/tmp/font_swap_disable"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

# Wait for boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
sleep 10

[ -f "$DIS" ] && { log "Disabled."; exit 0; }

log "=== Font Swap Runtime v1.0.0 ==="

# Read saved config
CFG_SCALE=$(cat "$MODDIR/font_scale.conf" 2>/dev/null)
CFG_SCALE=${CFG_SCALE:-1.0}
CUSTOM_FONT=$(cat "$MODDIR/font_path.conf" 2>/dev/null)

# Verify font_scale is still applied
CUR_SCALE=$(getprop ro.config.font_scale 2>/dev/null)
if [ "$CUR_SCALE" != "$CFG_SCALE" ]; then
    resetprop ro.config.font_scale "$CFG_SCALE"
    log "Re-applied font_scale=$CFG_SCALE (was $CUR_SCALE)"
fi

# Verify font flipping
CUR_FLIP=$(getprop persist.sys.font.flipping 2>/dev/null)
if [ "$CUR_FLIP" != "1" ]; then
    resetprop persist.sys.font.flipping 1
    log "Re-applied font_flipping=1"
fi

# Verify rendering
CUR_REND=$(getprop persist.sys.font_rendering 2>/dev/null)
if [ "$CUR_REND" != "1" ]; then
    resetprop persist.sys.font_rendering 1
    log "Re-applied font_rendering=1"
fi

# Verify HWUI cache
CUR_HWUI=$(getprop debug.hwui.font_cache 2>/dev/null)
if [ "$CUR_HWUI" != "1" ]; then
    resetprop debug.hwui.font_cache 1
    log "Re-applied hwui.font_cache=1"
fi

# Verify custom font path
if [ -n "$CUSTOM_FONT" ] && [ -f "$CUSTOM_FONT" ]; then
    CUR_FONT=$(getprop persist.sys.font.custom 2>/dev/null)
    if [ "$CUR_FONT" != "$CUSTOM_FONT" ]; then
        resetprop persist.sys.font.custom "$CUSTOM_FONT"
        log "Re-applied font.custom=$CUSTOM_FONT"
    fi
fi

log "=== Runtime done ==="
