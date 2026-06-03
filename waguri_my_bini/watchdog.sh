#!/system/bin/sh
# Waguri v2.3 - Hang Watchdog (Redmi 12 Hardened)
# Runs in background, detects & kills hung/ANR'd apps dynamically

LOGFILE="/data/local/tmp/waguri_watchdog.log"
INTERVAL=60

log() {
    local msg="[WATCHDOG] $(date '+%m-%d %H:%M:%S') $*"
    echo "$msg" >> "$LOGFILE"
}

is_zombie() {
    local pid=$1
    local stat=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $3}')
    [ "$stat" = "Z" ] && return 0
    return 1
}

is_uninterruptible() {
    local pid=$1
    local stat=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $3}')
    [ "$stat" = "D" ] && return 0
    return 1
}

get_process_name() {
    local pid=$1
    cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' | awk '{print $1}'
}

# MASALAH 3 FIX: Fungsi clean_stuck() yang lebih cerdas (Hardened v2.3)
clean_stuck() {
    local count=0
    
    # 1. Baca /proc/stat SATU KALI untuk akurasi
    local cpu_stat=$(grep "cpu " /proc/stat | head -n 1)
    
    # Parse nilai dari baris yang sama
    local iowait_val=$(echo "$cpu_stat" | awk '{print $6}')
    local total_val=$(echo "$cpu_stat" | awk '{for(i=2;i<=8;i++) sum+=$i; print sum}')
    
    local iowait_pct=$((iowait_val * 100 / total_val))
    
    if [ "$iowait_pct" -gt 40 ]; then
        log "SKIP: System IOWait is too high ($iowait_pct%). Storage is busy."
        return
    fi

    for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
        if is_uninterruptible "$pid"; then
            local wchan=$(cat /proc/$pid/wchan 2>/dev/null)
            local name=$(get_process_name $pid)

            # Whitelist Kritis
            case "$name" in
                installd|vold|keystore2|gatekeeperd|*PackageManager*|com.android.vending|com.google.android.gms*|*setupwizard*|system_server|surfaceflinger)
                    continue ;;
            esac

            # Threshold diperpanjang ke 90 detik
            local start_time=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $22}')
            local uptime=$(cat /proc/uptime 2>/dev/null | awk '{print $1}' | cut -d. -f1)
            
            if [ ! -z "$start_time" ] && [ ! -z "$uptime" ]; then
                local elapsed=$((uptime - start_time))
                if [ "$elapsed" -gt 90 ]; then
                    log "STUCK DETECTED: $name (PID: $pid) | wchan: $wchan | Elapsed: ${elapsed}s | IOWait: ${iowait_pct}%"
                    kill -9 "$pid" 2>/dev/null
                    count=$((count + 1))
                fi
            fi
        fi
    done
    [ "$count" -gt 0 ] && log "Watchdog: Killed $count long-stuck processes."
}

clean_zombies() {
    local count=0
    local pids=$(ps -A -o PID,STAT 2>/dev/null | grep " Z " | awk '{print $1}')
    for pid in $pids; do
        kill -9 "$pid" 2>/dev/null
        count=$((count + 1))
    done
    [ "$count" -gt 0 ] && log "Zombies killed: $count"
}

log "Watchdog started (PID: $$)"
while true; do
    sleep $INTERVAL
    clean_zombies
    clean_stuck
done
