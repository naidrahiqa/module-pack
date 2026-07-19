#!/system/bin/sh
# Font Swap v1.0.0 - Early boot font properties
# Sets font-related props via resetprop before zygote

MODDIR=${0%/*}
LOG="/data/local/tmp/font_swap.log"
DIS="/data/local/tmp/font_swap_disable"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

[ -f "$DIS" ] && { log "Disabled."; exit 0; }

log "=== Font Swap v1.0.0 ==="

# Font flipping — allows runtime font switching
resetprop persist.sys.font.flipping 1
log "persist.sys.font.flipping=1"

# Font scale — 1.0 = default, range 0.85–1.3
CFG_SCALE=$(cat "$MODDIR/font_scale.conf" 2>/dev/null)
CFG_SCALE=${CFG_SCALE:-1.0}
resetprop ro.config.font_scale "$CFG_SCALE"
log "ro.config.font_scale=$CFG_SCALE"

# Font rendering optimization
resetprop persist.sys.font_rendering 1
log "persist.sys.font_rendering=1"

# HWUI font cache
resetprop debug.hwui.font_cache 1
log "debug.hwui.font_cache=1"

# Custom font path (set by font_config.sh)
CUSTOM_FONT=$(cat "$MODDIR/font_path.conf" 2>/dev/null)
if [ -n "$CUSTOM_FONT" ] && [ -f "$CUSTOM_FONT" ]; then
    resetprop persist.sys.font.custom "$CUSTOM_FONT"
    log "persist.sys.font.custom=$CUSTOM_FONT"
fi

log "=== post-fs-data done ==="
