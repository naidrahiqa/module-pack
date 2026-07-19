#!/system/bin/sh
# Volume Steps Enhancer - post-fs-data.sh
# Naidrahiqa - v1.0.0

LOG="/data/local/tmp/volume_steps.log"

log() {
    echo "[post-fs-data] $*" >> "$LOG"
}

log "Starting volume steps prop injection"

# Set all volume step props
set_and_verify() {
    local prop="$1"
    local val="$2"
    resetprop "$prop" "$val"
    local got
    got=$(getprop "$prop")
    if [ "$got" = "$val" ]; then
        log "OK $prop=$got"
    else
        log "FAIL $prop expected $val got $got"
    fi
}

set_and_verify "ro.config.media_vol_steps" "30"
set_and_verify "ro.config.alarm_vol_steps" "15"
set_and_verify "ro.config.ring_vol_steps" "15"
set_and_verify "ro.config.notification_vol_steps" "15"
set_and_verify "ro.config.system_vol_steps" "15"
set_and_verify "ro.config.voice_vol_steps" "15"
set_and_verify "ro.config.bt_vol_steps" "30"
set_and_verify "ro.config.vc_call_vol_steps" "15"
set_and_verify "persist.sys.volume_steps" "30"
set_and_verify "persist.vendor.audio.volume.steps" "30"

log "Volume steps prop injection complete"
