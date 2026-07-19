#!/system/bin/sh

LOG=/data/local/tmp/fingerprint_speed.log
exec 1>>"$LOG" 2>&1

log_msg() {
    echo "[post-fs-data] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_msg "Starting fingerprint_speed v1.0.0"

resetprop persist.sys.fp.quick_unlock 1
resetprop persist.sys.fp.one_tap_unlock 1
resetprop persist.sys.fp.wakeup 1
resetprop persist.vendor.fp.quick_unlock 1
resetprop persist.vendor.fp.wakeup 1
resetprop ro.vendor.fingerprint.quick_unlock 1
resetprop persist.sys.biometrics.unlock 1
resetprop persist.sys.fp.unlock.delay 0
resetprop persist.vendor.fp.unlock.delay 0
resetprop persist.sys.fp.success_vib 1
resetprop persist.vendor.fp.standalone 1

log_msg "Props set successfully"
