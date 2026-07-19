#!/system/bin/sh
# Kairitsu Safe v1.2.0 - Crash prevention + memory monitor

MODDIR=${0%/*}
LOG="/data/local/tmp/kairitsu_service.log"
DIS="/data/local/tmp/kairitsu_disable"

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
sleep 5

[ -f "$DIS" ] && { log "Disabled."; exit 0; }

log "=== Kairitsu Safe v1.2.0 ==="

# Rescue Party disable
resetprop persist.device_config.global_flags.rescue_party_enabled false 2>/dev/null
resetprop persist.sys.disable_rescue true 2>/dev/null
settings put global device_config/global_flags/rescue_party_enabled false 2>/dev/null
settings put global crash_loop_remedy_enabled 0 2>/dev/null
settings put global development_settings_enabled 1 2>/dev/null
settings put secure adb_enabled 1 2>/dev/null

# Verify Rescue Party disable
RP_VAL=$(getprop persist.device_config.global_flags.rescue_party_enabled 2>/dev/null)
[ "$RP_VAL" = "false" ] && log "Rescue Party: DISABLED (verified)" || log "Rescue Party: verify failed (got: $RP_VAL)"

# Storage fix
am broadcast -a android.intent.action.MEDIA_MOUNTED -d file:///storage/emulated/0 -p com.android.providers.media.module --user 0 >/dev/null 2>&1
am broadcast -a android.intent.action.MEDIA_MOUNTED -d file:///storage/emulated/0 -p com.android.providers.media --user 0 >/dev/null 2>&1

# Mark boot OK
echo "OK:$(date +%s)" > /data/local/tmp/kairitsu_boot_attempts
rm -f /data/local/tmp/kairitsu_loop_*

# Memory monitor (background, 120s)
# NOTE: drop_caches handled by evanescia — kairitsu only logs critical pressure
(
    while true; do
        sleep 120
        TOTAL=$(awk '/^MemTotal:/{print $2}' /proc/meminfo); TOTAL=${TOTAL:-1}
        AVAIL=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo); AVAIL=${AVAIL:-0}
        PCT=$((AVAIL * 100 / TOTAL))
        PSI=$(grep "^full" /proc/pressure/memory 2>/dev/null | sed -n 's/.*avg10=\([0-9.]*\).*/\1/p' | cut -d. -f1); PSI=${PSI:-0}
        [ "$PCT" -lt 3 ] && [ "$PSI" -gt 25 ] && log "CRITICAL: mem=${PCT}% PSI=${PSI}"
    done
) &

# Watchdog
nohup sh "$MODDIR/watchdog.sh" >/dev/null 2>&1 &

log "All started."
