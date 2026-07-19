#!/system/bin/sh
# Kairitsu Safe v1.2.0 - Watchdog (D-state monitor)
# Optimized: reduced subprocess spawning, timeout on slow ops

LOG="/data/local/tmp/waguri_watchdog.log"
INTERVAL=180

log() { echo "[WATCHDOG] $(date '+%m-%d %H:%M:%S') $*" >> "$LOG"; }

while true; do
    sleep $INTERVAL

    # Clean zombies + D-state in one ps call (avoids double fork)
    PS_OUT=$(timeout 5 ps -A -o PID,STAT,TIME 2>/dev/null) || continue

    # Kill zombies (log only — kill -9 on zombies is no-op, but signals parent)
    ZC=0
    echo "$PS_OUT" | awk '$2=="Z"{print $1}' | while read -r pid; do
        kill -9 "$pid" 2>/dev/null
        ZC=$((ZC + 1))
    done

    # Skip D-state check if CPU/IOWait high (single awk, no subshell)
    SKIP=$(awk '/^some/{split($2,a," ");if(a[1]+0>50)print 1}' /proc/pressure/cpu 2>/dev/null)
    [ "$SKIP" = "1" ] && continue

    # D-state check — use temp file to avoid subshell variable loss
    UP=$(awk '{printf "%d",$1}' /proc/uptime 2>/dev/null); UP=${UP:-0}
    DC_FILE=$(mktemp /data/local/tmp/waguri_dc_XXXXXX 2>/dev/null)
    echo "0" > "$DC_FILE"
    echo "$PS_OUT" | awk '$2=="D"&&$1+0>=2000{print $1}' | while read -r pid; do
        NAME=$(timeout 1 cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' | awk '{print $1}')
        case "$NAME" in *launcher*|*systemui*|*system_server*|*magisk*) continue;; esac
        ST=$(timeout 1 awk '{print $22}' /proc/$pid/stat 2>/dev/null)
        if [ -n "$ST" ] && [ $((UP - ST)) -gt 300 ]; then
            DC=$(cat "$DC_FILE")
            echo $((DC + 1)) > "$DC_FILE"
        fi
    done
    DC=$(cat "$DC_FILE" 2>/dev/null); DC=${DC:-0}
    rm -f "$DC_FILE"
    [ "$DC" -gt 0 ] && log "D-state: $DC processes"
done
