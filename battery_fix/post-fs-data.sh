#!/system/bin/sh
# Battery Optimization — post-fs-data.sh
# Apply battery properties at early boot

MODDIR=${0%/*}

# Doze parameters
resetprop persist.deviceidle.controller-idle 1
resetprop persist.deviceidle.light.idle_timeout 7200000
resetprop persist.deviceidle.deep.idle_timeout 86400000
resetprop persist.deviceidle.light.maxidle 7200000
resetprop persist.deviceidle.deep.maxidle 86400000
resetprop persist.deviceidle.light.step_ratio 0.05
resetprop persist.deviceidle.deep.step_ratio 0.01

# Wakelock management
resetprop persist.sys.wakelock.whitelist ""
resetprop persist.sys.disable_wakelock 1
resetprop persist.sys.alarm.wakeup 0
resetprop persist.sys.alarm.allow_while_idle 0

# Power save
resetprop persist.sys.powersave 1
resetprop persist.sys.auto_power_save 1
resetprop persist.vendor.power.savings.mode 1

# Network optimization during doze
resetprop persist.sys.doze.nearby 0
resetprop persist.sys.doze.slow_heartbeat 1

# Sensor batching
resetprop persist.vendor.sensor.batching 1
resetprop persist.vendor.sensor.operation_mode 1
