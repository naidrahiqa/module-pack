#!/system/bin/sh
# Font Swap v1.0.0 — KernelSU Module Installer
# Author: Naidrahiqa

ui_print ""
ui_print "╔══════════════════════════════════════════════╗"
ui_print "║            FONT SWAP v1.0.0                 ║"
ui_print "║      System Font Customization              ║"
ui_print "╚══════════════════════════════════════════════╝"
ui_print ""

ui_print "▸ Checking device compatibility..."

# Check Android version
API=$(getprop ro.build.version.sdk 2>/dev/null)
if [ "$API" -lt 33 ] 2>/dev/null; then
    ui_print "✗ Android 13+ required (detected API: $API)"
    abort "Aborted."
fi
ui_print "  ✓ Android API: $API"

ui_print ""
ui_print "▸ Setting permissions..."
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/font_config.sh" 0 0 0755

ui_print ""
ui_print "▸ Configuring font system..."
ui_print "  • Font flipping: enabled"
ui_print "  • Font scale: 1.0 (default)"
ui_print "  • HWUI font cache: enabled"
ui_print "  • Font rendering: optimized"

ui_print ""
ui_print "▸ Font profiles available:"
ui_print "  • default    — Stock Roboto"
ui_print "  • google     — Google Sans (Pixel)"
ui_print "  • roboto     — Roboto condensed"
ui_print "  • slab       — Roboto Slab (serif)"
ui_print "  • mono       — Roboto Mono"
ui_print "  • rounded    — Google Sans Rounded"
ui_print "  • condensed  — Roboto Condensed"

ui_print ""
ui_print "▸ How to use:"
ui_print "  sh /data/adb/modules/font_swap/font_config.sh list"
ui_print "  sh /data/adb/modules/font_swap/font_config.sh apply <profile>"
ui_print "  sh /data/adb/modules/font_swap/font_config.sh restore"
ui_print ""

ui_print "▸ To disable: touch /data/local/tmp/font_swap_disable"
ui_print ""
ui_print "✓ Installation complete."
