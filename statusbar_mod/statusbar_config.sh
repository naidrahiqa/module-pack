#!/system/bin/sh
# Status Bar Customizer - Configuration Script
# Run this script to customize your status bar
# Usage: sh /data/adb/modules/statusbar_mod/statusbar_config.sh
# Device: Redmi 10 (selene) MT6768 - LineageOS 20

MODDIR="/data/adb/modules/statusbar_mod"
CONFIG_FILE="$MODDIR/user_config.sh"
LOGFILE=/data/local/tmp/statusbar_mod.log

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [config] $1" >> $LOGFILE
}

print_header() {
    echo "========================================"
    echo "   Status Bar Customizer v1.0.0"
    echo "   Redmi 10 (selene) - LineageOS 20"
    echo "========================================"
    echo ""
}

print_menu() {
    echo "--- Main Menu ---"
    echo "1) Toggle Icons"
    echo "2) Icon Style"
    echo "3) Carrier Name"
    echo "4) Clock Format"
    echo "5) Battery Percentage"
    echo "6) Apply Changes"
    echo "7) Show Current Config"
    echo "0) Exit"
    echo ""
}

print_icon_menu() {
    echo "--- Icon Toggle Menu ---"
    echo "1) Clock:       $SB_CLOCK"
    echo "2) Battery:     $SB_BATTERY"
    echo "3) Signal:      $SB_SIGNAL"
    echo "4) WiFi:        $SB_WIFI"
    echo "5) Bluetooth:   $SB_BLUETOOTH"
    echo "6) NFC:         $SB_NFC"
    echo "7) Alarm:       $SB_ALARM"
    echo "8) Hotspot:     $SB_HOTSPOT"
    echo "9) Volume:      $SB_VOLUME"
    echo "10) Headset:    $SB_HEADSET"
    echo "0) Back"
    echo ""
}

print_style_menu() {
    echo "--- Icon Style Menu ---"
    echo "1) Minimal"
    echo "2) Outlined"
    echo "3) Filled (default)"
    echo "0) Back"
    echo ""
}

toggle_value() {
    if [ "$1" = "1" ]; then
        echo "0"
    else
        echo "1"
    fi
}

load_config() {
    # Defaults
    SB_CLOCK=1
    SB_BATTERY=1
    SB_SIGNAL=1
    SB_WIFI=1
    SB_BLUETOOTH=1
    SB_NFC=1
    SB_ALARM=1
    SB_HOTSPOT=1
    SB_VOLUME=1
    SB_HEADSET=1
    SB_ICON_STYLE=2
    SB_CARRIER=0
    SB_CLOCK_FORMAT=1
    SB_BATTERY_PCT=1

    # Load user config if exists
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"
        log_msg "Loaded user config from $CONFIG_FILE"
    fi
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# Status Bar Customizer - User Configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')

SB_CLOCK=$SB_CLOCK
SB_BATTERY=$SB_BATTERY
SB_SIGNAL=$SB_SIGNAL
SB_WIFI=$SB_WIFI
SB_BLUETOOTH=$SB_BLUETOOTH
SB_NFC=$SB_NFC
SB_ALARM=$SB_ALARM
SB_HOTSPOT=$SB_HOTSPOT
SB_VOLUME=$SB_VOLUME
SB_HEADSET=$SB_HEADSET
SB_ICON_STYLE=$SB_ICON_STYLE
SB_CARRIER=$SB_CARRIER
SB_CLOCK_FORMAT=$SB_CLOCK_FORMAT
SB_BATTERY_PCT=$SB_BATTERY_PCT
EOF
    log_msg "Saved config to $CONFIG_FILE"
    echo "Configuration saved!"
}

apply_changes() {
    echo "Applying changes..."
    save_config
    
    # Apply via resetprop
    resetprop persist.sys.statusbar.clock "$SB_CLOCK"
    resetprop persist.sys.statusbar.battery "$SB_BATTERY"
    resetprop persist.sys.statusbar.signal "$SB_SIGNAL"
    resetprop persist.sys.statusbar.wifi "$SB_WIFI"
    resetprop persist.sys.statusbar.bluetooth "$SB_BLUETOOTH"
    resetprop persist.sys.statusbar.nfc "$SB_NFC"
    resetprop persist.sys.statusbar.alarm "$SB_ALARM"
    resetprop persist.sys.statusbar.hotspot "$SB_HOTSPOT"
    resetprop persist.sys.statusbar.volume "$SB_VOLUME"
    resetprop persist.sys.statusbar.headset "$SB_HEADSET"
    resetprop persist.sys.statusbar.iconstyle "$SB_ICON_STYLE"
    resetprop persist.sys.statusbar.carrier "$SB_CARRIER"
    resetprop persist.sys.statusbar.clockformat "$SB_CLOCK_FORMAT"
    resetprop persist.sys.statusbar.batterypct "$SB_BATTERY_PCT"
    
    # Apply runtime settings
    settings put secure status_bar_clock "$SB_CLOCK_FORMAT"
    settings put secure status_bar_battery_percentage "$SB_BATTERY_PCT"
    settings put secure show_carrier_name "$SB_CARRIER"
    
    log_msg "Applied all changes via config"
    echo "Changes applied! Some changes may need SystemUI restart."
    echo "Run: killall com.android.systemui"
}

show_config() {
    echo "--- Current Configuration ---"
    echo "Clock:          $SB_CLOCK"
    echo "Battery:        $SB_BATTERY"
    echo "Signal:         $SB_SIGNAL"
    echo "WiFi:           $SB_WIFI"
    echo "Bluetooth:      $SB_BLUETOOTH"
    echo "NFC:            $SB_NFC"
    echo "Alarm:          $SB_ALARM"
    echo "Hotspot:        $SB_HOTSPOT"
    echo "Volume:         $SB_VOLUME"
    echo "Headset:        $SB_HEADSET"
    
    case "$SB_ICON_STYLE" in
        0) echo "Icon Style:     Minimal" ;;
        1) echo "Icon Style:     Outlined" ;;
        2) echo "Icon Style:     Filled" ;;
        *) echo "Icon Style:     Unknown ($SB_ICON_STYLE)" ;;
    esac
    
    echo "Carrier Name:   $SB_CARRIER"
    
    if [ "$SB_CLOCK_FORMAT" = "1" ]; then
        echo "Clock Format:   24h"
    else
        echo "Clock Format:   12h"
    fi
    
    echo "Battery %:      $SB_BATTERY_PCT"
    echo "-----------------------------"
}

# Main loop
load_config

while true; do
    print_header
    print_menu
    printf "Select option: "
    read choice
    
    case "$choice" in
        1)
            while true; do
                print_icon_menu
                printf "Toggle which icon (0=back): "
                read icon_choice
                case "$icon_choice" in
                    1) SB_CLOCK=$(toggle_value "$SB_CLOCK") ;;
                    2) SB_BATTERY=$(toggle_value "$SB_BATTERY") ;;
                    3) SB_SIGNAL=$(toggle_value "$SB_SIGNAL") ;;
                    4) SB_WIFI=$(toggle_value "$SB_WIFI") ;;
                    5) SB_BLUETOOTH=$(toggle_value "$SB_BLUETOOTH") ;;
                    6) SB_NFC=$(toggle_value "$SB_NFC") ;;
                    7) SB_ALARM=$(toggle_value "$SB_ALARM") ;;
                    8) SB_HOTSPOT=$(toggle_value "$SB_HOTSPOT") ;;
                    9) SB_VOLUME=$(toggle_value "$SB_VOLUME") ;;
                    10) SB_HEADSET=$(toggle_value "$SB_HEADSET") ;;
                    0) break ;;
                    *) echo "Invalid option" ;;
                esac
            done
            ;;
        2)
            print_style_menu
            printf "Select style (0=back): "
            read style_choice
            case "$style_choice" in
                1) SB_ICON_STYLE=0 ;;
                2) SB_ICON_STYLE=1 ;;
                3) SB_ICON_STYLE=2 ;;
                0) ;;
                *) echo "Invalid option" ;;
            esac
            ;;
        3)
            if [ "$SB_CARRIER" = "1" ]; then
                SB_CARRIER=0
                echo "Carrier name disabled"
            else
                SB_CARRIER=1
                echo "Carrier name enabled"
            fi
            ;;
        4)
            if [ "$SB_CLOCK_FORMAT" = "1" ]; then
                SB_CLOCK_FORMAT=0
                echo "Clock format set to 12h"
            else
                SB_CLOCK_FORMAT=1
                echo "Clock format set to 24h"
            fi
            ;;
        5)
            if [ "$SB_BATTERY_PCT" = "1" ]; then
                SB_BATTERY_PCT=0
                echo "Battery percentage disabled"
            else
                SB_BATTERY_PCT=1
                echo "Battery percentage enabled"
            fi
            ;;
        6) apply_changes ;;
        7) show_config ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    
    printf "\nPress Enter to continue..."
    read dummy
done
