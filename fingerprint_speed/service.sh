#!/system/bin/sh

LOG=/data/local/tmp/fingerprint_speed.log
exec 1>>"$LOG" 2>&1

log_msg() {
    echo "[service] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_msg "Starting fingerprint_speed v1.0.0 service"

# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

log_msg "Boot completed, verifying props"

PROPS="persist.sys.fp.quick_unlock
persist.sys.fp.one_tap_unlock
persist.sys.fp.wakeup
persist.vendor.fp.quick_unlock
persist.vendor.fp.wakeup
ro.vendor.fingerprint.quick_unlock
persist.sys.biometrics.unlock
persist.sys.fp.unlock.delay
persist.vendor.fp.unlock.delay
persist.sys.fp.success_vib
persist.vendor.fp.standalone"

for prop in $PROPS; do
    val=$(getprop "$prop")
    if [ "$val" = "1" ] || [ "$val" = "0" ]; then
        log_msg "OK $prop=$val"
    else
        log_msg "MISS $prop=$val (re-applying)"
        resetprop "$prop" 1
    fi
done

log_msg "fingerprint_speed service done"
