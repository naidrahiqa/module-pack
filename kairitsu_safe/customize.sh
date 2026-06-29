#!/system/bin/sh
# Kairitsu Safe — KernelSU Module Installer
# Author: Naidrahiqa

ui_print ""
ui_print "╔══════════════════════════════════════════════╗"
ui_print "║          KAIRITSU SAFE v1.1.0               ║"
ui_print "║   Crash Prevention · Watchdog · Bootloop     ║"
ui_print "╚══════════════════════════════════════════════╝"
ui_print ""

ui_print "▸ Setting permissions..."
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/watchdog.sh" 0 0 0755
[ -f "$MODPATH/sepolicy.rule" ] && set_perm "$MODPATH/sepolicy.rule" 0 0 0644

ui_print "▸ Safety features:"
ui_print "  • Rescue Party: disabled"
ui_print "  • MediaProvider: broadcast with fixed URI"
ui_print "  • Memory monitor: 120s interval (log-only)"
ui_print "  • Watchdog: D-state monitor (180s)"
ui_print "  • Bootloop protection: 3x auto-disable"
ui_print ""
ui_print "✓ Installation complete."
