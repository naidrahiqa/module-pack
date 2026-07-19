#!/system/bin/sh
# Network Optimization - Runtime
# Author: Naidrahiqa
# Version: v1.0.0

MODDIR=${0%/*}
LOG=/data/local/tmp/network_fix.log

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG
}

log "=== Network Optimization v1.0.0 (service.sh) ==="

# Wait for boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 5
done
sleep 10
log "Boot completed"

# Apply /proc/sys/net optimizations

# TCP FastOpen: client + server
echo 3 > /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null
log "tcp_fastopen=$(cat /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null)"

# SYN cookies protection
echo 1 > /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null
log "tcp_syncookies=$(cat /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null)"

# TCP timestamps
echo 1 > /proc/sys/net/ipv4/tcp_timestamps 2>/dev/null
log "tcp_timestamps=$(cat /proc/sys/net/ipv4/tcp_timestamps 2>/dev/null)"

# TCP SACK
echo 1 > /proc/sys/net/ipv4/tcp_sack 2>/dev/null
log "tcp_sack=$(cat /proc/sys/net/ipv4/tcp_sack 2>/dev/null)"

# TCP window scaling
echo 1 > /proc/sys/net/ipv4/tcp_window_scaling 2>/dev/null
log "tcp_window_scaling=$(cat /proc/sys/net/ipv4/tcp_window_scaling 2>/dev/null)"

# TCP keepalive time (600s = 10 min)
echo 600 > /proc/sys/net/ipv4/tcp_keepalive_time 2>/dev/null
log "tcp_keepalive_time=$(cat /proc/sys/net/ipv4/tcp_keepalive_time 2>/dev/null)"

# TCP keepalive probes
echo 6 > /proc/sys/net/ipv4/tcp_keepalive_probes 2>/dev/null
log "tcp_keepalive_probes=$(cat /proc/sys/net/ipv4/tcp_keepalive_probes 2>/dev/null)"

# TCP keepalive interval
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_intvl 2>/dev/null
log "tcp_keepalive_intvl=$(cat /proc/sys/net/ipv4/tcp_keepalive_intvl 2>/dev/null)"

# TCP max SYN backlog
echo 4096 > /proc/sys/net/ipv4/tcp_max_syn_backlog 2>/dev/null
log "tcp_max_syn_backlog=$(cat /proc/sys/net/ipv4/tcp_max_syn_backlog 2>/dev/null)"

# TCP fin timeout
echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout 2>/dev/null
log "tcp_fin_timeout=$(cat /proc/sys/net/ipv4/tcp_fin_timeout 2>/dev/null)"

# TCP reuse
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse 2>/dev/null
log "tcp_tw_reuse=$(cat /proc/sys/net/ipv4/tcp_tw_reuse 2>/dev/null)"

# TCP slow start after idle
echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null
log "tcp_slow_start_after_idle=$(cat /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null)"

# Increase network device backlog
echo 5000 > /proc/sys/net/core/netdev_max_backlog 2>/dev/null
log "netdev_max_backlog=$(cat /proc/sys/net/core/netdev_max_backlog 2>/dev/null)"

# Increase socket buffer size
echo 262144 > /proc/sys/net/core/rmem_max 2>/dev/null
echo 262144 > /proc/sys/net/core/wmem_max 2>/dev/null
log "rmem_max=$(cat /proc/sys/net/core/rmem_max 2>/dev/null)"
log "wmem_max=$(cat /proc/sys/net/core/wmem_max 2>/dev/null)"

# DNS cache TTL
resetprop net.dns.cache.expiry 3600
log "DNS cache TTL set to 3600"

# Verify TCP buffer properties
log "buffersize.default=$(getprop net.tcp.buffersize.default)"
log "buffersize.wifi=$(getprop net.tcp.buffersize.wifi)"
log "buffersize.lte=$(getprop net.tcp.buffersize.lte)"
log "dns1=$(getprop net.dns1)"
log "dns2=$(getprop net.dns2)"

log "=== All network optimizations applied ==="
