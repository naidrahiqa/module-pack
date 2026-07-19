#!/system/bin/sh
# Speaker Boost v1.0.0 — Early boot audio props
# Single pass — no duplicate loops

set_prop() {
    resetprop -n "$1" "$2" 2>/dev/null
}

set_prop persist.vendor.audio.speaker.boost 8
set_prop persist.vendor.audio.headset.boost 6
set_prop persist.vendor.audio.volume.boost 1
set_prop persist.vendor.audio.volume.steps 15
set_prop persist.vendor.audio.voice.volume 1
set_prop persist.vendor.audio.ring.volume 1
set_prop persist.vendor.audio.notification.volume 1
set_prop persist.vendor.audio.alarm.volume 1
set_prop persist.vendor.audio.system.volume 1
set_prop persist.vendor.audio.bt.volume 1
set_prop ro.vendor.audio.speaker.boost 8
set_prop persist.vendor.audio.fluence.voicerec 1
set_prop persist.vendor.audio.fluence.speaker 1
set_prop persist.vendor.audio.hifi false
