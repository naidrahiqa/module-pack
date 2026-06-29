#!/system/bin/sh
# Hyacine IO — KernelSU Module Installer
# Author: Naidrahiqa

ui_print ""
ui_print "╔══════════════════════════════════════════════╗"
ui_print "║           HYACINE IO v1.3.0                 ║"
ui_print "║   Storage I/O · FUSE · SD Card · USB        ║"
ui_print "╚══════════════════════════════════════════════╝"
ui_print ""

ui_print "▸ Setting permissions..."
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
[ -f "$MODPATH/sepolicy.rule" ] && set_perm "$MODPATH/sepolicy.rule" 0 0 0644

ui_print "▸ Storage configuration:"
ui_print "  • Read-ahead: 1024 KB for eMMC/SD"
ui_print "  • FUSE passthrough: auto-detect (SuSFS-aware)"
ui_print "  • Block queue: nr_requests=128"
ui_print "  • SD card scan: auto-remount on insert"
ui_print "  • USB hotplug: auto-mount on connect"
ui_print ""
ui_print "▸ Merged from customrom-fix v1.3.0"
ui_print ""
ui_print "✓ Installation complete."
