#!/system/bin/sh
# H-Thermal v1.1.0 - Universal thermal disable
# Auto-detects Qualcomm / MediaTek and applies appropriate paths

MODDIR=${0%/*}
LOG="/data/local/tmp/h_thermal.log"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

wait_until_login() {
  while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 3; done
  test_file="/storage/emulated/0/Android/.PERMISSION_TEST"
  true >"$test_file"
  while [ ! -f "$test_file" ]; do true >"$test_file"; sleep 1; done
  rm -rf "$test_file"
}

wait_until_login

log "=== H-Thermal v1.1.0 ==="

# Detect chipset
CHIP=$(getprop ro.hardware.chipname 2>/dev/null)
[ -z "$CHIP" ] && CHIP=$(getprop ro.hardware 2>/dev/null)
log "Chipset: $CHIP"

IS_MTK=0
IS_QCOM=0
echo "$CHIP" | grep -qi "mt" && IS_MTK=1
echo "$CHIP" | grep -qi "qcom\|snapdragon\|sdm\|sm[0-9]" && IS_QCOM=1

# Fallback detection via /proc
[ "$IS_MTK" -eq 0 ] && [ "$IS_QCOM" -eq 0 ] && {
    [ -d /proc/ppm ] && IS_MTK=1
    [ -d /sys/class/kgsl ] && IS_QCOM=1
}
log "Detected: MTK=$IS_MTK QCOM=$IS_QCOM"

# ============================================
# PHASE 1: Disable thermal zones (universal)
# ============================================
for zone in /sys/class/thermal/thermal_zone*/mode; do
    [ ! -f "$zone" ] && continue
    val=$(cat "$zone" 2>/dev/null)
    [ "$val" = "enabled" ] && echo "disabled" > "$zone" 2>/dev/null
    [ "$val" = "1" ] && echo "0" > "$zone" 2>/dev/null
done
# Verify thermal zone disable
ZD_DONE=0; ZD_FAIL=0
for zone in /sys/class/thermal/thermal_zone*/mode; do
    [ ! -f "$zone" ] && continue
    cur=$(cat "$zone" 2>/dev/null)
    [ "$cur" = "disabled" ] || [ "$cur" = "0" ] && ZD_DONE=$((ZD_DONE + 1)) || ZD_FAIL=$((ZD_FAIL + 1))
done
log "Thermal zones disabled: $ZD_DONE ok, $ZD_FAIL failed"

# ============================================
# PHASE 2: Stop thermal services (universal)
# ============================================

# Single-pass: find and stop thermal services
for prop in $(getprop | grep -iF "init.svc." | grep -i "thermal" | sed 's/.*init.svc.\([^]]*\).*/\1/'); do
    status=$(getprop "init.svc.$prop" 2>/dev/null)
    [ "$status" = "running" ] || [ "$status" = "restarting" ] && {
        stop "$prop" 2>/dev/null
        setprop "init.svc.$prop" stopped 2>/dev/null
    }
done
log "Thermal services stopped"

# Zero out thermal properties (single pass)
getprop 2>/dev/null | grep -i 'ro.*thermal' | sed 's/.*\[\(.*\)\].*/\1/' | while read -r prop; do
    [ -n "$prop" ] && resetprop -n "$prop" 0 2>/dev/null
done
log "Thermal props zeroed"

# ============================================
# PHASE 3: Platform-specific disable
# ============================================

if [ "$IS_MTK" -eq 1 ]; then
    log "Applying MediaTek thermal disable"

    # PPM policies — disable throttle policies (keep boost enabled)
    for policy in 3 4 5 6 7 8; do
        echo "$policy 0" > /proc/ppm/policy_status 2>/dev/null
    done
    # Verify PPM
    PPM_OK=$(grep -c "^3 0\|^4 0\|^5 0\|^6 0\|^7 0\|^8 0" /proc/ppm/policy_status 2>/dev/null)
    log "PPM policies disabled: $PPM_OK/6 verified"

    # Disable cci thermal
    echo 0 > /proc/ppm/policy 2>/dev/null

    # Disable mali thermal (if present)
    for f in /sys/module/mali*/parameters/*thermal*; do
        [ -f "$f" ] && echo 0 > "$f" 2>/dev/null
    done

    # Disable GPU throttling via ged (if present)
    echo 0 > /sys/module/ged/parameters/gpu_cust_boost_freq 2>/dev/null
    echo 0 > /sys/module/ged/parameters/gpu_throttling 2>/dev/null

else
    log "Applying Qualcomm thermal disable"

    # msm_thermal
    echo N > /sys/module/msm_thermal/parameters/enabled 2>/dev/null
    echo 0 > /sys/module/msm_thermal/core_control/enabled 2>/dev/null
    echo 0 > /sys/kernel/msm_thermal/enabled 2>/dev/null

    # KGSL GPU
    if [ -d /sys/class/kgsl/kgsl-3d0 ]; then
        echo '0' > /sys/class/kgsl/kgsl-3d0/throttling 2>/dev/null
        echo '1' > /sys/class/kgsl/kgsl-3d0/force_clk_on 2>/dev/null
        echo '1' > /sys/class/kgsl/kgsl-3d0/force_bus_on 2>/dev/null
        echo '1' > /sys/class/kgsl/kgsl-3d0/force_rail_on 2>/dev/null
        echo '1' > /sys/class/kgsl/kgsl-3d0/force_no_nap 2>/dev/null
        log "KGSL GPU force-on applied"
    fi
fi

# ============================================
# PHASE 4: Lock thermal files (universal)
# ============================================
for f in /sys/devices/virtual/thermal/thermal_zone*/temp /sys/devices/virtual/thermal/thermal_zone*/mode /sys/devices/virtual/thermal/thermal_zone*/policy; do
    [ -f "$f" ] && chmod 000 "$f" 2>/dev/null
done
log "Thermal files locked"

# ============================================
# PHASE 5: sched_boost off (universal)
# ============================================
echo 0 > /proc/sys/kernel/sched_boost 2>/dev/null

log "=== H-Thermal active ==="

# Notification (background, no subshell)
cmd notification post -t 'H-Thermal' '' "H-Thermal active: thermal disabled ($CHIP)" > /dev/null 2>&1 &
