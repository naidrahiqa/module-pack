#!/system/bin/sh
# Castorice Thermal - Smart Charging for fire
LOGFILE="/data/local/tmp/castorice_thermal.log"

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

# MASALAH 6 FIX: Discovery Path Dinamis untuk G88
discover_charger_path() {
    # Urutan prioritas path untuk Helio G88
    local candidates="
        /sys/class/power_supply/battery
        /sys/devices/platform/charger
        /sys/class/power_supply/mtk-master-charger
        /sys/class/power_supply/charger
    "
    for path in $candidates; do
        if [ -d "$path" ] && [ -f "$path/constant_charge_current" ]; then
            echo "$path"
            return
        fi
    done
}

fix_charging() {
    local CHG=$(discover_charger_path)
    [ -z "$CHG" ] && { log "ERROR: Charger path not found."; return; }

    log "Applying charging tweaks to: $CHG"
    
    # MASALAH 5 FIX: Arus aman untuk 18W (Spec Redmi 12)
    # 3.6A adalah batas aman agar PMIC tidak overheat/throttle ke 5W
    echo 3600000 > "$CHG/constant_charge_current" 2>/dev/null
    echo 3600000 > "$CHG/input_current_limit" 2>/dev/null
    
    # 18W Max Wattage
    [ -f "$CHG/pdc_max_watt" ] && echo 18000000 > "$CHG/pdc_max_watt" 2>/dev/null

    # MTK Specific Toggle
    [ -f "$CHG/fast_chg_en" ] && echo 1 > "$CHG/fast_chg_en" 2>/dev/null
    
    # Xiaomi Fast Charge Props
    setprop persist.vendor.charge.fastcharge 1
}

# Tunggu boot selesai
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 15; done

# Loop interval 60 detik (Sesuai rekomendasi audit agar tidak stress)
while true; do
    fix_charging
    sleep 60
done
