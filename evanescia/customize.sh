#!/system/bin/sh
# Evanescia Memory — KernelSU Module Installer
# Author: Naidrahiqa

ui_print ""
ui_print "╔══════════════════════════════════════════════╗"
ui_print "║          EVANESCIA MEMORY v1.1.0            ║"
ui_print "║    VM Tuning · ZRAM · Memory Pressure       ║"
ui_print "╚══════════════════════════════════════════════╝"
ui_print ""

ui_print "▸ Checking device compatibility..."

RAM=$(awk '/MemTotal/{printf "%d", $2/1024}' /proc/meminfo)
if [ "$RAM" -lt 4000 ]; then
    ui_print "✗ Minimum 4GB RAM required (detected: ${RAM}MB)"
    abort "Aborted."
fi
ui_print "  ✓ RAM: ${RAM}MB"

ui_print "▸ Setting permissions..."
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
[ -f "$MODPATH/sepolicy.rule" ] && set_perm "$MODPATH/sepolicy.rule" 0 0 0644

ui_print ""
ui_print "▸ Configuring system parameters..."
ui_print "  • VM: swappiness=40, dirty_ratio=15, vfs_cache=80"
ui_print "  • ZRAM: zstd algorithm, ncpu/2 compression threads"
ui_print "  • I/O: mq-deadline scheduler for eMMC"
ui_print "  • Memory: compact every 60min, drop_caches on critical"
ui_print ""
ui_print "▸ To disable: touch /data/local/tmp/evanescia_disable"
ui_print ""
ui_print "✓ Installation complete."
