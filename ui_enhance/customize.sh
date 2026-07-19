#!/system/bin/sh
# UI Enhancement — KernelSU Module Installer
# Author: Naidrahiqa

ui_print ""
ui_print "╔══════════════════════════════════════════════╗"
ui_print "║          UI ENHANCEMENT v1.0.0              ║"
ui_print "║    Animations · HW Rendering · SF Config     ║"
ui_print "╚══════════════════════════════════════════════╝"
ui_print ""
ui_print "▸ Setting permissions..."
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "▸ Configuring UI tweaks..."
ui_print "  • Animation scales: 1.0x"
ui_print "  • HW rendering: skiagl"
ui_print "  • SurfaceFlinger: optimized"
ui_print "  • Display: raw orientation enabled"
ui_print ""
ui_print "▸ To disable: touch /data/local/tmp/ui_enhance_disable"
ui_print ""
ui_print "✓ Installation complete."
