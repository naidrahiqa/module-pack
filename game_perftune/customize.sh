#!/system/bin/sh
# Game PerfTune — KernelSU Module Installer
# Author: Naidrahiqa

ui_print ""
ui_print "╔══════════════════════════════════════════════╗"
ui_print "║          GAME PERFTUNE v1.0.0                ║"
ui_print "║   CPU Governor · GPU Boost · Net · I/O       ║"
ui_print "╚══════════════════════════════════════════════╝"
ui_print ""

ui_print "▸ Setting permissions..."
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/game_detect.sh" 0 0 0755
[ -f "$MODPATH/sepolicy.rule" ] && set_perm "$MODPATH/sepolicy.rule" 0 0 0644

# Detect chipset
CHIP=$(getprop ro.hardware.chipname 2>/dev/null)
[ -z "$CHIP" ] && CHIP=$(getprop ro.hardware 2>/dev/null)
ui_print "▸ Chipset: $CHIP"

# Detect RAM
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_MB=$((RAM_KB / 1024))
ui_print "▸ RAM: ${RAM_MB}MB"

ui_print ""
ui_print "▸ Tuning targets:"
ui_print "  • GPU: Mali-G52 MC2 (Mediatek)"
ui_print "  • CPU: Cortex-A75 + Cortex-A55"
ui_print "  • Network: TCP/latency optimize"
ui_print "  • I/O: bfq scheduler + game priority"
ui_print ""
ui_print "✓ Installation complete."
ui_print "  Reboot to activate. Game detection runs at boot."
