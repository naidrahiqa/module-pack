#!/system/bin/sh
# Display Color Tuning — KernelSU Module Installer
# Author: Naidrahiqa

ui_print ""
ui_print "╔══════════════════════════════════════════════╗"
ui_print "║       DISPLAY COLOR TUNING v1.0.0           ║"
ui_print "║   Screen Color · Calibration · Night Mode    ║"
ui_print "╚══════════════════════════════════════════════╝"
ui_print ""

ui_print "▸ Setting permissions..."
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
[ -f "$MODPATH/sepolicy.rule" ] && set_perm "$MODPATH/sepolicy.rule" 0 0 0644
[ -f "$MODPATH/system.prop" ] && set_perm "$MODPATH/system.prop" 0 0 0644

ui_print "▸ Display configuration:"
ui_print "  • Color calibration: enabled"
ui_print "  • Color mode: enabled"
ui_print "  • Night mode: enabled"
ui_print "  • Saturation: 1.0"
ui_print "  • Contrast: 1.0"
ui_print "  • HW composition: GPU"
ui_print "  • Color matrix: enabled"
ui_print ""
ui_print "▸ Device: Redmi 10 (selene) MT6768"
ui_print "▸ ROM: LineageOS 20 (Android 13)"
ui_print ""
ui_print "✓ Installation complete."
