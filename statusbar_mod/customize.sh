#!/system/bin/sh
# Status Bar Customizer - customize.sh
# KSU/Magisk Module Installer
# Device: Redmi 10 (selene) MT6768 - LineageOS 20

ZIPFILE=$1
MODPATH=$2
TMPDIR=$3

# Print banner
ui_print "========================================"
ui_print "   Status Bar Customizer v1.0.0"
ui_print "   Redmi 10 (selene) - LineageOS 20"
ui_print "========================================"
ui_print ""

# Check Android version
ANDROID=$(getprop ro.build.version.sdk)
if [ "$ANDROID" -lt 33 ]; then
    ui_print "! This module requires Android 13 (SDK 33)+"
    ui_print "! Your device: SDK $ANDROID"
    abort "! Installation aborted"
fi

# Check device
DEVICE=$(getprop ro.product.device)
ui_print "- Device: $DEVICE"
ui_print "- Android SDK: $ANDROID"
ui_print ""

# Check if LineageOS
if grep -q "lineage" /system/build.prop 2>/dev/null; then
    ui_print "- LineageOS detected, proceeding..."
else
    ui_print "! Warning: LineageOS not detected"
    ui_print "! Module may not work correctly on other ROMs"
fi

ui_print ""

# Set permissions
ui_print "- Setting permissions..."
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/statusbar_config.sh 0 0 0755

# Create default config if not exists
if [ ! -f "$MODPATH/user_config.sh" ]; then
    cat > "$MODPATH/user_config.sh" << 'EOF'
# Status Bar Customizer - User Configuration
# Edit this file or run statusbar_config.sh to customize

SB_CLOCK=1
SB_BATTERY=1
SB_SIGNAL=1
SB_WIFI=1
SB_BLUETOOTH=1
SB_NFC=1
SB_ALARM=1
SB_HOTSPOT=1
SB_VOLUME=1
SB_HEADSET=1
SB_ICON_STYLE=2
SB_CARRIER=0
SB_CLOCK_FORMAT=1
SB_BATTERY_PCT=1
EOF
    ui_print "- Created default configuration"
fi

ui_print ""
ui_print "- Installation complete!"
ui_print ""
ui_print "Usage:"
ui_print "  - Edit config: sh /data/adb/modules/statusbar_mod/statusbar_config.sh"
ui_print "  - Logs: cat /data/local/tmp/statusbar_mod.log"
ui_print ""
ui_print "- Reboot to apply changes"
ui_print "========================================"
ui_print ""
