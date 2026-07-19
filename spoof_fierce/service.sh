#!/system/bin/sh
# Spoof Fierce v2.0.0 — Runtime verify (Zygisk)
# Re-applies props if ROM resets them; Zygisk handles per-game spoof
LOG="/data/local/tmp/spoof_fierce.log"
RP="/data/adb/ksu/bin/resetprop"
MODDIR="/data/adb/modules/spoof_fierce"
CONFIG="$MODDIR/SpoofFierce.json"
WEBROOT="$MODDIR/webroot"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do sleep 2; done
sleep 5

# Simple JSON parser for shell
json_val() {
    local json="$1" key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/"
}
json_int() {
    local json="$1" key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*[0-9]*" | head -1 | sed "s/.*:\([0-9]*\)/\1/"
}

# Read config
if [ ! -f "$CONFIG" ]; then
    log "ERROR: Config not found"
    exit 1
fi
RAW=$(cat "$CONFIG" | tr -d '\n\r')

TARGET_MODEL=$(json_val "$RAW" "model")
TARGET_BRAND=$(json_val "$RAW" "brand")
TARGET_MFR=$(json_val "$RAW" "manufacturer")
TARGET_DEV=$(json_val "$RAW" "device")
TARGET_BOARD=$(json_val "$RAW" "board")
TARGET_HW=$(json_val "$RAW" "hardware")
TARGET_MKTNAME=$(json_val "$RAW" "marketname")
TARGET_FPS=$(json_int "$RAW" "fps")
TARGET_FPS=${TARGET_FPS:-120}
TARGET_MKTNAME=${TARGET_MKTNAME:-$TARGET_MODEL}

# Verify and re-apply if ROM reset props
CURRENT=$(getprop ro.product.model)
CURRENT_HW=$(getprop ro.hardware)
if [ "$CURRENT" != "$TARGET_MODEL" ] || { [ -n "$TARGET_HW" ] && [ "$CURRENT_HW" != "$TARGET_HW" ]; }; then
    log "WARN: Model=$CURRENT, re-applying"
    $RP ro.product.model "$TARGET_MODEL"
    $RP ro.product.brand "$TARGET_BRAND"
    $RP ro.product.manufacturer "$TARGET_MFR"
    $RP ro.product.device "$TARGET_DEV"
    $RP ro.product.board "$TARGET_BOARD"
    $RP ro.product.marketname "$TARGET_MKTNAME"

    # Hardware + platform (safe here — boot_completed, display already initialized)
    [ -n "$TARGET_HW" ] && $RP ro.hardware "$TARGET_HW"
    [ -n "$TARGET_BOARD" ] && $RP ro.board.platform "$TARGET_BOARD"

    # Rebuild fingerprint
    ANDROID=$(getprop ro.build.version.release)
    BUILDID=$(echo "$(getprop ro.build.display.id)" | awk '{print $1}')
    BUILDNUM=$(getprop ro.build.version.incremental)
    FP="$TARGET_BRAND/$TARGET_DEV/$TARGET_DEV:$ANDROID/$BUILDID/$BUILDNUM:user/release-keys"
    $RP ro.build.fingerprint "$FP"

    $RP ro.surface_flinger.game_default_frame_rate_override "$TARGET_FPS"
    $RP ro.surface_flinger.enable_frame_rate_override true
    $RP debug.graphics.game_default_frame_rate_disabled false
    $RP debug.graphics.game_default_frame_rate.disabled false
    $RP debug.sf.frame_rate_multiple_threshold 0

    # NEVER spoof ro.product.vendor.* / ro.product.odm.* / ro.product.system.*
    # Vendor props control radio/RIL — changing them = signal loss
    log "Re-applied: $TARGET_MODEL ($TARGET_BOARD) FPS=$TARGET_FPS"
fi

log "Verify: model=$(getprop ro.product.model) hw=$(getprop ro.hardware) platform=$(getprop ro.board.platform) fps=$(getprop ro.surface_flinger.game_default_frame_rate_override)"

# Generate WebUI data at boot
sh "$MODDIR/api.sh" status 2>/dev/null
timeout 10 sh "$MODDIR/api.sh" scan 2>/dev/null
log "WebUI data generated"
