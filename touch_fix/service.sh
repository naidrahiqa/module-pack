#!/system/bin/sh
# Touch Sensitivity Fix - service.sh
# Runtime: wait for boot, apply optimizations, monitor

MODDIR=${0%/*}
LOG=/data/local/tmp/touch_fix.log

log_msg() {
    echo "[$(date)] $1" >> $LOG
}

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done
sleep 10

log_msg "=== Touch Fix v1.0.0 (service) ==="
log_msg "Boot completed, applying runtime optimizations"

# Verify touch properties
TS=$(getprop persist.sys.touch.touchsize)
EF=$(getprop persist.sys.touch.edgefilter)
PR=$(getprop persist.sys.touch.palm.reject)
IB=$(getprop persist.sys.inputboost)
log_msg "Verify: touchsize=$TS edgefilter=$EF palm.reject=$PR inputboost=$IB"

# Re-apply if any got lost
if [ "$TS" != "10" ] || [ "$EF" != "0" ]; then
    resetprop persist.sys.touch.touchsize 10
    resetprop persist.sys.touch.edgefilter 0
    resetprop persist.sys.touch.glove.mode 0
    resetprop persist.sys.touch.palm.reject 1
    resetprop persist.vendor.touch.touchpoint 1
    resetprop persist.vendor.touch.edgefilter 0
    resetprop ro.vendor.touch.touchsize 10
    resetprop persist.sys.inputboost 1
    log_msg "Re-applied missing touch properties"
fi

# SELinux-friendly touch node tuning (MT6768 / selene)
for node in /proc/touchpanel/gesture_info \
             /sys/class/input/input*/enable_gesture \
             /sys/devices/platform/touchpanel.0/*; do
    if [ -f "$node" ] && [ -w "$node" ]; then
        log_msg "Touch node: $node (read-only check)"
    fi
done

# Disable edge noise filter via sysfs if accessible
for tp in /sys/devices/platform/touchpanel.*/edge_filter; do
    if [ -f "$tp" ] && [ -w "$tp" ]; then
        echo "0" > "$tp" 2>/dev/null
        log_msg "Disabled edge filter: $tp"
    fi
done

# Ensure touch boost stays on
resetprop ro.vendor.perfservice.enable 1
resetprop persist.sys.touchboost 1

log_msg "Runtime optimizations complete"
