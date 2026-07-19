#!/system/bin/sh
# Multi Audio Play — post-fs-data.sh
# Set properties before boot to enable concurrent audio

MODDIR=${0%/*}

# Disable audio focus ducking (lowering volume of other apps)
resetprop af.media.track_effects 0
resetprop persist.vendor.audio.ducking.enabled false

# Enable concurrent audio outputs
resetprop vendor.audio.concurrent.out 1
resetprop persist.vendor.audio.concurrent 1

# Allow multiple active audio tracks
resetprop vendor.audio.max.active.tracks 4
resetprop persist.vendor.audio.multitrack 1

# Disable audio focus enforcement
resetprop af.media.ducking.enabled 0
resetprop af.media.focus.force.abandon 0
