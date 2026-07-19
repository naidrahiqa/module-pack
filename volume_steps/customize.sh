#!/system/bin/sh
# Volume Steps Enhancer - customize.sh
# Naidrahiqa - v1.0.0

ui_print "- Volume Steps Enhancer v1.0.0"
ui_print "- By Naidrahiqa"
ui_print "- Increasing volume steps for finer audio control"
ui_print "- Media: 30 steps"
ui_print "- Ring/Alarm/Notification/System/Voice: 15 steps"
ui_print "- Bluetooth: 30 steps"
ui_print ""
ui_print "- Installing..."

# Ensure post-fs-data.sh and service.sh are executable
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- Done! Reboot to apply."
