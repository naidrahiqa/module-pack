#!/system/bin/sh
# Game PerfTune v1.1.0 — Boot-time base tuning
# Only sets TCP buffers + GPU base. Everything else handled by other modules.
MODDIR=${0%/*}
LOG="/data/local/tmp/game_perftune.log"
DIS="/data/local/tmp/game_perftune_disable"

[ -f "$DIS" ] && exit 0

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }
log "=== Game PerfTune v1.1.0 (post-fs-data) ==="

# ============================================
# GPU — GED base enable (safe, no conflict)
# ============================================
echo 1 > /sys/module/ged/parameters/ged_boost_enable 2>/dev/null
log "GPU: ged_boost_enable=1"

# ============================================
# MEMORY — DO NOT TOUCH (evanescia handles)
# I/O — DO NOT TOUCH (evanescia + hyacine_io handles)
# CPU GOVERNOR — DO NOT TOUCH (encore handles)
# ============================================

# ============================================
# NETWORK (base — always on)
# ============================================
echo "4096 87380 6291456" > /proc/sys/net/ipv4/tcp_rmem 2>/dev/null
echo "4096 65536 6291456" > /proc/sys/net/ipv4/tcp_wmem 2>/dev/null
echo "65536 131072 262144" > /proc/sys/net/core/rmem_max 2>/dev/null
echo "65536 131072 262144" > /proc/sys/net/core/wmem_max 2>/dev/null
log "TCP buffers tuned"

echo "active" > /data/local/tmp/game_perftune_active
log "Base tuning applied"
