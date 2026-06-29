#!/system/bin/sh
# Spoof Fierce v1.0.0 - Backend for WebUI
MODDIR="/data/adb/modules/spoof_fierce"
CONFIG="$MODDIR/SpoofFierce.json"
WEBROOT="$MODDIR/webroot"
LOG="/data/local/tmp/spoof_fierce.log"
RP="/data/adb/ksu/bin/resetprop"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

json_val() { echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/"; }
json_int() { echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*[0-9]*" | head -1 | sed "s/.*:\([0-9]*\)/\1/"; }

extract_pkgs() {
    echo "$1" | tr -d '\n\r' | sed -n 's/.*"packages"[[:space:]]*:[[:space:]]*\[\(.*\)\].*/\1/p' | tr ',' '\n' | grep -o '"[^"]*"' | tr '\n' ',' | sed 's/,$//'
}

ACTION="$1"
ARG="$2"

case "$ACTION" in

status)
    RAW=$(cat "$CONFIG" 2>/dev/null)
    if [ -f /data/local/tmp/spoof_fierce_active ]; then ACTIVE="true"; else ACTIVE="false"; fi
    MODEL=$(json_val "$RAW" "model"); BRAND=$(json_val "$RAW" "brand")
    MFR=$(json_val "$RAW" "manufacturer"); DEV=$(json_val "$RAW" "device")
    BOARD=$(json_val "$RAW" "board"); FPS=$(json_int "$RAW" "fps")
    MKT=$(json_val "$RAW" "marketname"); HW=$(json_val "$RAW" "hardware")
    FP=$(json_val "$RAW" "fingerprint"); ANDROID=$(json_val "$RAW" "android_version")
    PKGS=$(extract_pkgs "$RAW")

    # Read real device info (captured before spoof in post-fs-data.sh)
    REAL=$(cat "$WEBROOT/real_device.json" 2>/dev/null || echo '{}')

    cat > "$WEBROOT/status.json" << EOJSON
{"active":$ACTIVE,"model":"$MODEL","brand":"$BRAND","manufacturer":"$MFR","device":"$DEV","board":"$BOARD","fps":$FPS,"marketname":"$MKT","hardware":"$HW","fingerprint":"$FP","android":"$ANDROID","packages":[$PKGS],"real":$REAL}
EOJSON
    chmod 644 "$WEBROOT/status.json"
    ;;

scan)
    OUT="$WEBROOT/apps.json"
    echo "[" > "$OUT"
    FIRST=1
    pm list packages -3 2>/dev/null | sed 's/package://' | sort | while read pkg; do
        [ -z "$pkg" ] && continue
        # Convert package name to readable label: remove common prefixes, dots to spaces, capitalize
        LABEL=$(echo "$pkg" | sed 's/^com\.//;s/^org\.//;s/^net\.//;s/^io\.//;s/^app\.//;s/^android\.//' | tr '.' ' ')
        LABEL=$(echo "$LABEL" | awk '{for(i=1;i<=NF;i++) $i= toupper(substr($i,1,1)) substr($i,2)}1')
        [ -z "$LABEL" ] && LABEL=$(echo "$pkg" | awk -F'.' '{print $NF}')
        if [ "$FIRST" -eq 1 ]; then FIRST=0; else echo "," >> "$OUT"; fi
        echo -n "{\"pkg\":\"$pkg\",\"name\":\"$LABEL\"}" >> "$OUT"
    done
    echo "]" >> "$OUT"
    chmod 644 "$OUT"
    log "Scanned apps"
    ;;

add)
    [ -z "$ARG" ] && exit 1
    RAW=$(cat "$CONFIG" 2>/dev/null)
    echo "$RAW" | grep -q "\"$ARG\"" && { echo "EXISTS"; exit 0; }
    # Flatten JSON, add package to packages array
    FLAT=$(echo "$RAW" | tr -d '\n\r')
    NEW=$(echo "$FLAT" | sed 's/"packages"[[:space:]]*:[[:space:]]*\[\(.*\)\]/"packages": [\1, "'"$ARG"'"]/')
    echo "$NEW" > "$CONFIG"
    cp "$CONFIG" "$WEBROOT/SpoofFierce.json" 2>/dev/null
    log "Added: $ARG"; sh "$0" status 2>/dev/null; echo "OK"
    ;;

remove)
    [ -z "$ARG" ] && exit 1
    RAW=$(cat "$CONFIG" 2>/dev/null)
    FLAT=$(echo "$RAW" | tr -d '\n\r')
    NEW=$(echo "$FLAT" | sed 's/, *"'$ARG'"//;s/"'$ARG'" *,//;s/"'$ARG'"//')
    echo "$NEW" > "$CONFIG"
    cp "$CONFIG" "$WEBROOT/SpoofFierce.json" 2>/dev/null
    log "Removed: $ARG"; sh "$0" status 2>/dev/null; echo "OK"
    ;;

apply)
    [ -z "$ARG" ] && exit 1
    RAW=$(cat "$CONFIG" 2>/dev/null)
    M=$(json_val "$RAW" "model"); B=$(json_val "$RAW" "brand")
    MR=$(json_val "$RAW" "manufacturer"); D=$(json_val "$RAW" "device")
    BD=$(json_val "$RAW" "board"); HW=$(json_val "$RAW" "hardware")
    MK=$(json_val "$RAW" "marketname")
    F=$(json_int "$RAW" "fps"); [ -z "$F" ] && F=120
    $RP ro.product.model "$M"; $RP ro.product.brand "$B"
    $RP ro.product.manufacturer "$MR"; $RP ro.product.device "$D"
    $RP ro.product.board "$BD"; $RP ro.product.marketname "$MK"
    $RP ro.board.platform "$BD"
    [ -n "$HW" ] && $RP ro.hardware "$HW"
    ANDROID=$(getprop ro.build.version.release)
    BUILDID=$(echo "$(getprop ro.build.display.id)" | awk '{print $1}')
    BUILDNUM=$(getprop ro.build.version.incremental)
    $RP ro.build.fingerprint "$B/$D/$D:$ANDROID/$BUILDID/$BUILDNUM:user/release-keys"
    $RP ro.surface_flinger.game_default_frame_rate_override "$F"
    $RP ro.surface_flinger.enable_frame_rate_override true
    $RP debug.graphics.game_default_frame_rate_disabled false
    $RP debug.graphics.game_default_frame_rate.disabled false
    $RP debug.sf.frame_rate_multiple_threshold 0
    # NEVER spoof vendor/ODM/system props — causes signal loss
    echo "active" > /data/local/tmp/spoof_fierce_active
    log "Applied: $ARG"; echo "OK"
    ;;

set_device)
    [ -z "$ARG" ] && exit 1
    echo "$ARG" > "$CONFIG"
    cp "$CONFIG" "$WEBROOT/SpoofFierce.json" 2>/dev/null
    log "Config updated"; sh "$0" status 2>/dev/null; echo "OK"
    ;;

restore)
    for p in ro.product.model ro.product.brand ro.product.manufacturer ro.product.device ro.product.board ro.product.marketname ro.hardware ro.board.platform ro.build.fingerprint ro.surface_flinger.game_default_frame_rate_override ro.surface_flinger.enable_frame_rate_override debug.graphics.game_default_frame_rate_disabled debug.graphics.game_default_frame_rate.disabled debug.sf.frame_rate_multiple_threshold; do
        $RP --delete "$p" 2>/dev/null
    done
    rm -f /data/local/tmp/spoof_fierce_active
    log "Restored"; sh "$0" status 2>/dev/null; echo "OK"
    ;;

log)
    tail -50 "$LOG" 2>/dev/null || echo "No log"
    ;;

esac
