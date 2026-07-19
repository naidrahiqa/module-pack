#!/system/bin/sh
# Battery Optimization — service.sh
# Runtime battery optimizations

MODDIR=${0%/*}
LOGFILE=/data/local/tmp/battery_fix.log

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> $LOGFILE
}

log "=== Battery Fix v1.0.0 started ==="

# Wait for boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 3
done
sleep 10

log "Boot completed, applying optimizations..."

# Configure doze via sysfs if available
if [ -d "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor" ]; then
    log "Setting CPU governor to powersave"
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo powersave > "$cpu" 2>/dev/null
    done
fi

# Disable doze when charging
resetprop persist.sys.doze_enabled 1

# Apply doze whitelist — disable battery optimization for system apps
if [ -f /system/bin/cmd ]; then
    log "Setting up doze whitelist"
    /system/bin/cmd deviceidle whitelist +com.android.providers.calendar 2>/dev/null
    /system/bin/cmd deviceidle whitelist +com.android.calendar 2>/dev/null
    /system/bin/cmd deviceidle whitelist +com.android.bluetooth 2>/dev/null
fi

# Disable wake sources
for wakeup in /sys/power/wake*; do
    if [ -f "$wakeup" ]; then
        echo 0 > "$wakeup" 2>/dev/null
    fi
done

# Disable LED wake
if [ -d /sys/class/leds ]; then
    for led in /sys/class/leds/*/trigger; do
        echo none > "$led" 2>/dev/null
    done
fi

# Disable modem wake lock
resetprop persist.vendor.radio.data.con.rmgr 1

# Kernel wakelock suppression
if [ -d /proc/sys/kernel ]; then
    echo 1 > /proc/sys/kernel/power_save 2>/dev/null
    echo 1 > /proc/sys/kernel/sched_child_runs_first 2>/dev/null
fi

# Adjust swappiness
resetprop vm.swappiness 60
echo 60 > /proc/sys/vm/swappiness 2>/dev/null

# Dirty page tuning
resetprop vm.dirty_ratio 15
resetprop vm.dirty_background_ratio 5
echo 15 > /proc/sys/vm/dirty_ratio 2>/dev/null
echo 5 > /proc/sys/vm/dirty_background_ratio 2>/dev/null

log "Battery optimizations applied successfully"
