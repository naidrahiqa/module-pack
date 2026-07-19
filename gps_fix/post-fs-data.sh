#!/system/bin/sh
# GPS Fix - Early Boot Properties
# Author: Naidrahiqa

MODDIR=${0%/*}
LOG=/data/local/tmp/gps_fix.log

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG
}

log "=== GPS Fix v1.0.0 starting (post-fs-data) ==="

# Multi-constellation enable
resetprop persist.gps.glonass.enable 1
resetprop persist.gps.beidou.enable 1
resetprop persist.gps.galileo.enable 1

# QSS and Solomon
resetprop persist.gps.qss.enable 1
resetprop persist.gps.solomon.enable 1

# Location mode
resetprop persist.location.mode high_accuracy
resetprop ro.location.gps NLP

# Force enable GPS
resetprop gps.force_enable true

# Vendor GPS tuning for MT6768
resetprop persist.vendor.gps.gps_ref_location 1
resetprop persist.vendor.gps.gps_rst_mode 1

# Minimum GPS update interval (500ms)
resetprop persist.gps.update_interval 500

# GPS isolation
resetprop persist.vendor.gps.gps_isolation 1

# Navigation mode for satellite
resetprop persist.vendor.gps.navigation.mode 1

log "GPS properties applied successfully"
