#!/system/bin/sh
# Touch Sensitivity Fix - post-fs-data.sh
# Early boot: set touch properties via resetprop

MODDIR=${0%/*}
LOG=/data/local/tmp/touch_fix.log

log_msg() {
    echo "[$(date)] $1" >> $LOG
}

log_msg "=== Touch Fix v1.0.0 (post-fs-data) ==="

# Touch sensitivity and input tuning
resetprop persist.sys.touch.touchsize 10
resetprop persist.sys.touch.edgefilter 0
resetprop persist.sys.touch.glove.mode 0
resetprop persist.sys.touch.palm.reject 1
resetprop persist.vendor.touch.touchpoint 1
resetprop persist.vendor.touch.edgefilter 0
resetprop ro.vendor.touch.touchsize 10
resetprop persist.sys.inputboost 1

# Touch boost
resetprop ro.vendor.perfservice.enable 1
resetprop persist.sys.touchboost 1
resetprop ro.vendor.touchpanel.touch_game_mode 1

# Touch sampling rate (higher = smoother)
resetprop persist.vendor.touch.sample_rate 180
resetprop persist.vendor.touch.game_mode 1

# Touch report rate
resetprop persist.vendor.touch.report_rate 167
resetprop ro.vendor.inputtouch.jitterfilter 0

# Reduce input latency
resetprop ro.input.noisy 0
resetprop persist.sys.inputboost.sf 1

log_msg "Touch properties applied"
