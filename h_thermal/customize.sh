#!/system/bin/sh
# H-Thermal — KernelSU Module Installer
# Author: Naidrahiqa

ui_print ""
ui_print "╔══════════════════════════════════════════════╗"
ui_print "║            H-THERMAL v1.1.0                 ║"
ui_print "║   Thermal Disable · PPM Unlock · Zones       ║"
ui_print "╚══════════════════════════════════════════════╝"
ui_print ""

ui_print "▸ Setting permissions..."
set_perm "$MODPATH/service.sh" 0 0 0755
[ -f "$MODPATH/post-fs-data.sh" ] && set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
[ -f "$MODPATH/sepolicy.rule" ] && set_perm "$MODPATH/sepolicy.rule" 0 0 0644

ui_print "▸ Thermal control:"
ui_print "  • PPM policies 3-8: disabled (CPU unlock)"
ui_print "  • Thermal zones: disabled + locked"
ui_print "  • Thermal services: stopped"
ui_print "  • GPU throttling: disabled"
ui_print ""
ui_print "▸ Compatible with evanescia memory module"
ui_print ""
ui_print "✓ Installation complete."
