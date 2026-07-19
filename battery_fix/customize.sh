#!/system/bin/sh
# Battery Optimization — customize.sh
# KSU/Magisk installer UI

ui_print ""
ui_print "╔══════════════════════════════════╗"
ui_print "║   Battery Optimization v1.0.0    ║"
ui_print "╚══════════════════════════════════╝"
ui_print ""
ui_print "Installing Battery Optimization module..."
ui_print ""
ui_print "Features:"
ui_print "  - Doze mode optimization"
ui_print "  - Wakelock management"
ui_print "  - Power save tuning"
ui_print "  - CPU governor optimization"
ui_print ""
ui_print "Device: Redmi 10 (selene) MT6768"
ui_print "ROM: LineageOS 20 (Android 13)"
ui_print ""
ui_print "Setting permissions..."
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755
ui_print "Done!"
ui_print ""
