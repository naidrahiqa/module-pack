#!/system/bin/sh
# Status Bar Customizer - service.sh
# Runtime: Apply status bar tweaks after boot
# Device: Redmi 10 (selene) MT6768 - LineageOS 20

MODDIR=${0%/*}
LOGFILE=/data/local/tmp/statusbar_mod.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [service] $1" >> $LOGFILE
}

log_msg "=== Status Bar Customizer v1.0.0 service starting ==="

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
sleep 3

log_msg "Boot completed, applying runtime tweaks"

# Read config file if exists
CONFIG_FILE="$MODDIR/statusbar_config.sh"
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
    log_msg "Loaded config from $CONFIG_FILE"
fi

# Apply LineageOS-specific status bar tweaks via settings
# Clock position and format
if [ "${SB_CLOCK:-1}" = "1" ]; then
    settings put secure status_bar_clock "${SB_CLOCK_FORMAT:-1}"
    log_msg "Clock enabled (format=${SB_CLOCK_FORMAT:-1})"
else
    settings put secure status_bar_clock 0
    log_msg "Clock disabled"
fi

# Battery style (0=portrait, 1=landscape, 2=circle, 3=hidden)
settings put secure status_bar_battery_style 2
log_msg "Battery style set to circle"

# Battery percentage
if [ "${SB_BATTERY_PCT:-1}" = "1" ]; then
    settings put secure status_bar_battery_percentage 1
    log_msg "Battery percentage enabled"
else
    settings put secure status_bar_battery_percentage 0
    log_msg "Battery percentage disabled"
fi

# Network speed display
settings put secure status_bar_network_speed 1
log_msg "Network speed display enabled"

# VoLTE icon
settings put secure status_bar_volte_icon 1
log_msg "VoLTE icon enabled"

# Apply carrier name setting
if [ "${SB_CARRIER:-0}" = "1" ]; then
    settings put global mobile_data 1
    settings put secure show_carrier_name 1
    log_msg "Carrier name display enabled"
else
    settings put secure show_carrier_name 0
    log_msg "Carrier name display disabled"
fi

# Custom icon overlays via SystemUI tuner if available
if [ -d "/system/priv-app/SystemUI" ]; then
    log_msg "SystemUI found, applying icon overlays"
    
    # Disable notifications on lockscreen (optional)
    # settings put secure lock_screen_allow_private_notifications 0
    
    # Quick settings columns
    settings put secure sysui_qs_cols 3
    settings put secure sysui_qs_rows 3
fi

# Verify properties were set
CLOCK_VAL=$(getprop persist.sys.statusbar.clock)
BATTERY_VAL=$(getprop persist.sys.statusbar.battery)
STYLE_VAL=$(getprop persist.sys.statusbar.iconstyle)

log_msg "Verification - clock=$CLOCK_VAL battery=$BATTERY_VAL style=$STYLE_VAL"
log_msg "=== service.sh complete ==="
