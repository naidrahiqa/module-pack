#!/system/bin/sh
# Touch Sensitivity Fix - customize.sh
# KSU module installer

SKIPUNZIP=1

ui_print "====================================="
ui_print "  Touch Sensitivity Fix v1.0.0"
ui_print "  for Redmi 10 (selene) MT6768"
ui_print "====================================="
ui_print ""
ui_print "- Optimizing touch properties..."
ui_print "- Improving touch sensitivity..."
ui_print "- Reducing input latency..."
ui_print ""

# Extract module files
ui_print "- Extracting module files..."
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

# Set permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- Module installed successfully!"
ui_print ""
ui_print "Reboot to apply changes."
ui_print ""
