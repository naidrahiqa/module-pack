#!/system/bin/sh
# GPS Fix - Runtime Optimizations
# Author: Naidrahiqa

MODDIR=${0%/*}
LOG=/data/local/tmp/gps_fix.log

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG
}

# Wait for boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 3
done
sleep 5

log "=== GPS Fix v1.0.0 starting (service.sh) ==="

# Verify properties
log "Verifying GPS properties..."
log "persist.gps.glonass.enable=$(getprop persist.gps.glonass.enable)"
log "persist.gps.beidou.enable=$(getprop persist.gps.beidou.enable)"
log "persist.gps.galileo.enable=$(getprop persist.gps.galileo.enable)"
log "persist.location.mode=$(getprop persist.location.mode)"
log "gps.force_enable=$(getprop gps.force_enable)"

# Set GPS permissions
chmod 660 /sys/class/gps/gps_dbg/log_enable 2>/dev/null
chmod 660 /sys/class/gps/gps_dbg/force_enable 2>/dev/null

# Enable GPS debug log for troubleshooting
if [ -f /sys/class/gps/gps_dbg/log_enable ]; then
  echo 1 > /sys/class/gps/gps_dbg/log_enable 2>/dev/null
  log "GPS debug log enabled"
fi

# Force GPS on
if [ -f /sys/class/gps/gps_dbg/force_enable ]; then
  echo 1 > /sys/class/gps/gps_dbg/force_enable 2>/dev/null
  log "GPS force enabled"
fi

log "=== GPS Fix v1.0.0 completed ==="
