#!/system/bin/sh
# Volume Steps Enhancer - service.sh
# Naidrahiqa - v1.0.0

LOG="/data/local/tmp/volume_steps.log"

log() {
    echo "[service] $*" >> "$LOG"
}

log "Waiting for boot_completed"

# Wait for boot to finish
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

log "Boot completed. Verifying volume step props"

# Verify all props
verify_prop() {
    local prop="$1"
    local expected="$2"
    local got
    got=$(getprop "$prop")
    if [ "$got" = "$expected" ]; then
        log "OK $prop=$got"
    else
        log "MISMATCH $prop expected $expected got $got"
        # Retry resetprop for any mismatches
        resetprop "$prop" "$expected"
        got=$(getprop "$prop")
        if [ "$got" = "$expected" ]; then
            log "FIXED $prop=$got"
        else
            log "STILL FAILED $prop=$got"
        fi
    fi
}

verify_prop "ro.config.media_vol_steps" "30"
verify_prop "ro.config.alarm_vol_steps" "15"
verify_prop "ro.config.ring_vol_steps" "15"
verify_prop "ro.config.notification_vol_steps" "15"
verify_prop "ro.config.system_vol_steps" "15"
verify_prop "ro.config.voice_vol_steps" "15"
verify_prop "ro.config.bt_vol_steps" "30"
verify_prop "ro.config.vc_call_vol_steps" "15"
verify_prop "persist.sys.volume_steps" "30"
verify_prop "persist.vendor.audio.volume.steps" "30"

log "Volume steps verification complete"
