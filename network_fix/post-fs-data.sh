#!/system/bin/sh
# Network Optimization - Early Boot
# Author: Naidrahiqa
# Version: v1.0.0

MODDIR=${0%/*}
LOG=/data/local/tmp/network_fix.log

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG
}

log "=== Network Optimization v1.0.0 (post-fs-data) ==="

# TCP buffer sizes via resetprop
resetprop net.tcp.buffersize.default "4096,87380,262144,4096,87380,262144"
resetprop net.tcp.buffersize.wifi "524288,1048576,2097152,262144,524288,1048576"
resetprop net.tcp.buffersize.lte "524288,1048576,2097152,262144,524288,1048576"

# DNS servers
resetprop net.dns1 8.8.8.8
resetprop net.dns2 8.8.4.4

# TCP optimization flags
resetprop net.ipv4.tcp_fastopen 3
resetprop net.ipv4.tcp_syncookies 1
resetprop net.ipv4.tcp_timestamps 1
resetprop net.ipv4.tcp_sack 1

log "TCP buffer and DNS properties set"
