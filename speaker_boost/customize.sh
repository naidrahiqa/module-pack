#!/system/bin/sh
# Speaker Boost — KernelSU Module Installer
# Author: Naidrahiqa

ui_print ""
ui_print "╔══════════════════════════════════════════════╗"
ui_print "║        SPEAKER VOLUME BOOST v1.0.0          ║"
ui_print "║   Speaker · Headset · Volume Steps · Fluence ║"
ui_print "╚══════════════════════════════════════════════╝"
ui_print ""

ui_print "▸ Setting permissions..."
set_perm "$MODPATH/service.sh" 0 0 0755
[ -f "$MODPATH/post-fs-data.sh" ] && set_perm "$MODPATH/post-fs-data.sh" 0 0 0755

ui_print "▸ Audio boost configuration:"
ui_print "  • Speaker boost: level 8"
ui_print "  • Headset boost: level 6"
ui_print "  • Volume steps: 15 (finer control)"
ui_print "  • Fluence voice recording: enabled"
ui_print "  • HiFi: disabled (compat mode)"
ui_print ""
ui_print "▸ Target: Redmi 10 (selene) MT6768"
ui_print "▸ ROM: LineageOS 20 (Android 13)"
ui_print ""
ui_print "✓ Installation complete."
