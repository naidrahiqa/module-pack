#!/system/bin/sh
# GPS Fix module installer
# Author: Naidrahiqa

print_banner() {
  ui_print "====================================="
  ui_print "   GPS Accuracy Fix v1.0.0          "
  ui_print "   Author: Naidrahiqa               "
  ui_print "   Device: Redmi 10 (selene)        "
  ui_print "====================================="
}

print_banner
ui_print ""
ui_print "- Installing GPS Fix module..."
ui_print "- Optimizing GPS settings for MT6768"
ui_print "- Enabling multi-constellation support"
ui_print ""
ui_print "- Setting permissions..."
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755

ui_print "- Installation complete!"
ui_print "- Reboot to apply changes"
ui_print "====================================="
