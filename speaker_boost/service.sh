#!/system/bin/sh
# Speaker Boost v1.0.0 — Runtime audio volume optimization
# Redmi 10 (selene) MT6768 — LineageOS 20

MODDIR=${0%/*}
LOG="/data/local/tmp/speaker_boost.log"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

wait_until_login() {
  while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 3; done
  test_file="/storage/emulated/0/Android/.PERMISSION_TEST"
  true >"$test_file"
  while [ ! -f "$test_file" ]; do true >"$test_file"; sleep 1; done
  rm -rf "$test_file"
}

wait_until_login

log "=== Speaker Boost v1.0.0 ==="

# Verify props
OK=0; FAIL=0
for p in \
    persist.vendor.audio.speaker.boost=8 \
    persist.vendor.audio.headset.boost=6 \
    persist.vendor.audio.volume.boost=1 \
    persist.vendor.audio.volume.steps=15 \
    persist.vendor.audio.voice.volume=1 \
    persist.vendor.audio.ring.volume=1 \
    persist.vendor.audio.notification.volume=1 \
    persist.vendor.audio.alarm.volume=1 \
    persist.vendor.audio.system.volume=1 \
    persist.vendor.audio.bt.volume=1 \
    ro.vendor.audio.speaker.boost=8 \
    persist.vendor.audio.fluence.voicerec=1 \
    persist.vendor.audio.fluence.speaker=1 \
    persist.vendor.audio.hifi=false; do

    name="${p%%=*}"
    expected="${p#*=}"
    actual=$(getprop "$name" 2>/dev/null)

    if [ "$actual" = "$expected" ]; then
        OK=$((OK + 1))
    else
        FAIL=$((FAIL + 1))
        log "MISMATCH: $name = $actual (expected $expected)"
        # Retry once
        resetprop -n "$name" "$expected" 2>/dev/null
    fi
done

log "Props verified: $OK ok, $FAIL fixed/$FAIL failed"
log "=== Speaker Boost active ==="

cmd notification post -t 'Speaker Boost' '' "Speaker Boost v1.0.0 active" > /dev/null 2>&1 &
