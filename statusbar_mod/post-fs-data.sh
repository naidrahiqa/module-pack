#!/system/bin/sh
# Status Bar Customizer - post-fs-data.sh
# Early boot: Apply status bar properties via resetprop
# Device: Redmi 10 (selene) MT6768 - LineageOS 20

MODDIR=${0%/*}
LOGFILE=/data/local/tmp/statusbar_mod.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [post-fs-data] $1" >> $LOGFILE
}

log_msg "=== Status Bar Customizer v1.0.0 starting ==="

# Read config file if exists
CONFIG_FILE="$MODDIR/statusbar_config.sh"
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
    log_msg "Loaded config from $CONFIG_FILE"
fi

# Apply status bar icon enable/disable properties
resetprop persist.sys.statusbar.clock "${SB_CLOCK:-1}"
resetprop persist.sys.statusbar.battery "${SB_BATTERY:-1}"
resetprop persist.sys.statusbar.signal "${SB_SIGNAL:-1}"
resetprop persist.sys.statusbar.wifi "${SB_WIFI:-1}"
resetprop persist.sys.statusbar.bluetooth "${SB_BLUETOOTH:-1}"
resetprop persist.sys.statusbar.nfc "${SB_NFC:-1}"
resetprop persist.sys.statusbar.alarm "${SB_ALARM:-1}"
resetprop persist.sys.statusbar.hotspot "${SB_HOTSPOT:-1}"
resetprop persist.sys.statusbar.volume "${SB_VOLUME:-1}"
resetprop persist.sys.statusbar.headset "${SB_HEADSET:-1}"

# Icon style (0=minimal, 1=outlined, 2=filled)
resetprop persist.sys.statusbar.iconstyle "${SB_ICON_STYLE:-2}"

# Carrier name
resetprop persist.sys.statusbar.carrier "${SB_CARRIER:-0}"

# Clock format (0=12h, 1=24h)
resetprop persist.sys.statusbar.clockformat "${SB_CLOCK_FORMAT:-1}"

# Battery percentage
resetprop persist.sys.statusbar.batterypct "${SB_BATTERY_PCT:-1}"

log_msg "Applied all status bar properties"
log_msg "=== post-fs-data complete ==="
