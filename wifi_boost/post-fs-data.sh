#!/system/bin/sh
# WiFi Signal Boost - post-fs-data.sh
# Early boot WiFi property optimization

MODDIR=${0%/*}

# --- WiFi Signal & Scan Optimization ---
resetprop persist.vendor.wifi.optimized 1
resetprop persist.vendor.wifi.patch 1
resetprop persist.vendor.wifi.framework.scan.interval 15000
resetprop persist.vendor.wifi.hotspot.scan.interval 10000
resetprop ro.vendor.wifi.wifi_chip MT6631
resetprop persist.vendor.wifi.WFD.enabled 1
resetprop persist.vendor.wifi.direct.dbus 1
resetprop persist.vendor.wifi.connsys.dedicated.memory 1

# --- WiFi Performance ---
resetprop persist.vendor.wifi.tx.chainmask 3
resetprop persist.vendor.wifi.rx.chainmask 3
resetprop persist.vendor.wifi.rssi.poll.interval 3000
resetprop persist.vendor.wifi.band_steering 1
resetprop persist.vendor.wifi.ampdu 1
resetprop persist.vendor.wifi.amsdu 1

# --- WiFi Power Save Disable (for better signal) ---
resetprop persist.vendor.wifi.no.power.save 1

# --- WiFi country code (ID = Indonesia) ---
resetprop persist.vendor.wifi.country.code ID

# --- WiFi roaming ---
resetprop persist.vendor.wifi.roam.scan.max 5
resetprop persist.vendor.wifi.roam.trigger -75
resetprop persist.vendor.wifi.roam.delta 20
