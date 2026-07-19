#!/system/bin/sh
# WiFi Signal Boost - service.sh
# Runtime WiFi optimizations after boot

MODDIR=${0%/*}
LOGFILE=/data/local/tmp/wifi_boost.log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

log "WiFi Boost service started"

# Wait for boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
sleep 5

log "Boot completed, applying WiFi runtime optimizations"

# --- WiFi TX power tuning ---
if [ -d /proc/net/wlan ]; then
    log "WiFi proc found, checking settings"
fi

# --- Enable WiFi low latency mode for gaming ---
setprop persist.vendor.wifi.low.latency 1
log "Low latency mode enabled"

# --- Optimize WiFi scan behavior ---
setprop persist.vendor.wifi.supplicant.scan_interval 15
setprop persist.vendor.wifi.pm.mode 1
log "Scan interval optimized"

# --- WiFi Direct / P2P ---
setprop persist.vendor.wifi.direct.dbus 1
setprop persist.vendor.wifi.p2p_statistics 1
log "WiFi Direct enabled"

# --- WFD (Miracast) ---
setprop persist.vendor.wifi.WFD.enabled 1
setprop persist.vendor.wifi.wfd.video.format 7
setprop persist.vendor.wifi.wfd.video.islands 1
log "WFD enabled"

# --- WiFi concurrency ---
setprop persist.vendor.wifi.concurrency.sta 2
setprop persist.vendor.wifi.concurrency.sap 2
setprop persist.vendor.wifi.concurrency.p2p 2
log "WiFi concurrency settings applied"

# --- MT6631 specific: power and signal ---
resetprop persist.vendor.wifi.connsys.dedicated.memory 1
resetprop persist.vendor.wifi.ax.bfmr 1
resetprop persist.vendor.wifi.ar 1
log "MT6631 chip optimizations applied"

# --- Disable WiFi batch scan (saves power) ---
setprop persist.vendor.wifi.batchescan.enable 0
log "Batch scan disabled"

log "WiFi Boost service finished"
