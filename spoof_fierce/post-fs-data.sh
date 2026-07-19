#!/system/bin/sh
# Spoof Fierce v2.0.0 — Boot-time props (Zygisk fallback)
# Zygisk handles per-game spoof; this sets system-wide props at boot
MODDIR=${0%/*}
LOG="/data/local/tmp/spoof_fierce.log"
DIS="/data/local/tmp/spoof_fierce_disable"
ACTIVE="/data/local/tmp/spoof_fierce_active"
RP="/data/adb/ksu/bin/resetprop"
CONFIG="$MODDIR/SpoofFierce.json"
WEBROOT="$MODDIR/webroot"

[ -f "$DIS" ] && exit 0

# Capture REAL device info BEFORE spoof (for WebUI "About Phone")
REAL_FILE="$WEBROOT/real_device.json"
if [ ! -f "$REAL_FILE" ]; then
    R_MKT=$(getprop ro.product.marketname 2>/dev/null)
    R_MODEL=$(getprop ro.product.model 2>/dev/null)
    R_BRAND=$(getprop ro.product.brand 2>/dev/null)
    R_DEV=$(getprop ro.product.device 2>/dev/null)
    R_BOARD=$(getprop ro.product.board 2>/dev/null)
    R_CHIP=$(getprop ro.hardware.chipname 2>/dev/null)
    [ -z "$R_CHIP" ] && R_CHIP=$(getprop ro.board.platform 2>/dev/null)
    R_AND=$(getprop ro.build.version.release 2>/dev/null)
    R_SDK=$(getprop ro.build.version.sdk 2>/dev/null)
    R_BUILD=$(getprop ro.build.display.id 2>/dev/null)
    R_PATCH=$(getprop ro.build.version.security_patch 2>/dev/null)
    R_FP=$(getprop ro.build.fingerprint 2>/dev/null)
    R_KERNEL=$(uname -r 2>/dev/null)
    cat > "$REAL_FILE" << EOR
{"marketname":"$R_MKT","model":"$R_MODEL","brand":"$R_BRAND","device":"$R_DEV","board":"$R_BOARD","chip":"$R_CHIP","android":"$R_AND","sdk":"$R_SDK","build":"$R_BUILD","patch":"$R_PATCH","fingerprint":"$R_FP","kernel":"$R_KERNEL"}
EOR
    chmod 644 "$REAL_FILE" 2>/dev/null
fi

# Wait for resetprop
T=0
while [ ! -x "$RP" ]; do sleep 1; T=$((T + 1)); [ "$T" -gt 30 ] && exit 0; done

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }
log "=== Spoof Fierce v2.0.0 (Zygisk) ==="

# Simple JSON parser for shell (no jq dependency)
json_val() {
    local json="$1" key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/"
}
json_int() {
    local json="$1" key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*[0-9]*" | head -1 | sed "s/.*:\([0-9]*\)/\1/"
}

# Read config
if [ -f "$CONFIG" ]; then
    RAW=$(cat "$CONFIG" | tr -d '\n\r')
else
    log "ERROR: Config not found: $CONFIG"
    exit 1
fi

MODEL=$(json_val "$RAW" "model")
BRAND=$(json_val "$RAW" "brand")
MFR=$(json_val "$RAW" "manufacturer")
DEV=$(json_val "$RAW" "device")
PRODUCT=$(json_val "$RAW" "product")
FP=$(json_val "$RAW" "fingerprint")
BOARD=$(json_val "$RAW" "board")
HW=$(json_val "$RAW" "hardware")
MKTNAME=$(json_val "$RAW" "marketname")
ANDROID=$(json_val "$RAW" "android_version")
SDK=$(json_int "$RAW" "sdk_int")
FPS=$(json_int "$RAW" "fps")

[ -z "$FPS" ] && FPS=120
[ -z "$MKTNAME" ] && MKTNAME="$MODEL"

# Apply system-wide props as Zygisk fallback
$RP ro.product.model "$MODEL"
$RP ro.product.brand "$BRAND"
$RP ro.product.manufacturer "$MFR"
$RP ro.product.device "$DEV"
$RP ro.product.name "${PRODUCT:-$BRAND}"
$RP ro.product.board "$BOARD"
$RP ro.product.marketname "$MKTNAME"

# Spoof ro.board.platform — safe at boot (unlike ro.hardware)
# HOK checks this to whitelist chipset for 120 FPS
$RP ro.board.platform "$BOARD"

# NEVER spoof ro.hardware or ro.hardware.chipname at boot!
# Display HAL reads these to init display driver → blank screen on MediaTek
# Only safe at runtime (Zygisk per-game) or service.sh (after boot_completed)

# Build fingerprint
if [ -z "$FP" ]; then
    ANDROID=$(getprop ro.build.version.release)
    BUILDID=$(echo "$(getprop ro.build.display.id)" | awk '{print $1}')
    BUILDNUM=$(getprop ro.build.version.incremental)
    FP="$BRAND/$DEV/$DEV:$ANDROID/$BUILDID/$BUILDNUM:user/release-keys"
fi
$RP ro.build.fingerprint "$FP"

# FPS override + master switch
$RP ro.surface_flinger.game_default_frame_rate_override "$FPS"
$RP ro.surface_flinger.enable_frame_rate_override true
$RP debug.graphics.game_default_frame_rate_disabled false
$RP debug.graphics.game_default_frame_rate.disabled false
$RP debug.sf.frame_rate_multiple_threshold 0

# NEVER spoof ro.product.vendor.* / ro.product.odm.* / ro.product.system.*
# Vendor props control radio/RIL — changing them = signal loss

echo "active" > "$ACTIVE"

# Sync to WebUI
if [ -d "$WEBROOT" ]; then
    cp "$MODDIR/SpoofFierce.json" "$WEBROOT/SpoofFierce.json" 2>/dev/null
    cp "$LOG" "$WEBROOT/log" 2>/dev/null
    chmod 644 "$WEBROOT/SpoofFierce.json" "$WEBROOT/log" 2>/dev/null
fi

log "System props: model=$MODEL brand=$BRAND board=$BOARD fps=$FPS"
