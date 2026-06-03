#!/system/bin/sh
# Castorice Thermal - Smart Fast Charge for Helio G88
LOGFILE="/data/local/tmp/castorice_thermal.log"

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

# MASALAH 3 FIX: Discovery loop untuk mencari path charger yang valid
search_charger() {
    CHG_PATHS="/sys/class/power_supply/mtk-master-charger /sys/devices/platform/charger /sys/class/power_supply/charger /sys/devices/platform/mt6357-charger.0"
    for path in $CHG_PATHS; do
        if [ -d "$path" ]; then
            echo "$path"
            return
        fi
    done
}

fix_charging() {
    local BASE_PATH=$(search_charger)
    if [ -z "$BASE_PATH" ]; then
        log "ERROR: No valid charger path found. Skipping fast charge fix."
        return
    fi

    log "Valid charger path found: $BASE_PATH"
    
    # Reset Cooling Devices secara aman (Jangan terlalu sering)
    for cd in /sys/class/thermal/cooling_device*; do
        [ -f "$cd/cur_state" ] && echo 0 > "$cd/cur_state" 2>/dev/null
    done

    # Force Charge Limits
    [ -f "$BASE_PATH/constant_charge_current" ] && echo 5000000 > "$BASE_PATH/constant_charge_current" 2>/dev/null
    [ -f "$BASE_PATH/input_current_limit" ] && echo 3000000 > "$BASE_PATH/input_current_limit" 2>/dev/null
    
    # Xiaomi Fast Charge Props
    setprop persist.vendor.charge.fastcharge 1
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 15; done

log "Castorice Thermal Active"

# Loop dengan interval lebih manusiawi agar Battery IC tidak stress
while true; do
    fix_charging
    # MASALAH 3 FIX: Interval diperlambat ke 60 detik
    sleep 60
done
