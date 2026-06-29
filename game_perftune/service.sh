#!/system/bin/sh
# Game PerfTune v1.1.0 — Game detection daemon
# GPU boost + network latency + CPU pinning (big core)
# CPU governor/freq handled by encore module — DO NOT TOUCH
LOG="/data/local/tmp/game_perftune.log"
MODDIR="/data/adb/modules/game_perftune"
GAME_STATE="/data/local/tmp/game_perftune_state"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

# ============================================
# WAIT FOR BOOT
# ============================================
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do sleep 2; done
sleep 8

[ -f "/data/local/tmp/game_perftune_disable" ] && exit 0

log "=== Game PerfTune v1.1.0 (daemon) ==="

# ============================================
# GAME PACKAGE LIST
# ============================================
GAMES="com.mobile.legends com.levelinfinite.sgameGlobal com.tencent.tmgp.sgame com.tencent.ig com.pubg.mobile com.garena.game.codm com.miHoYo.GenshinImpact com.supercell.clashofclans com.supercell.brawlstars com.activision.callofduty.warzone com.epicgames.fortnite com.dts.freefireth com.dts.freefiremax com.riotgames.league.wildrift com.ea.gp.apexlegendsmobilefps com.levelinfinite.honkaisrail com.HoYoverse.Nap com.miHoYo.TearGod com.papegames.infinitynikki com.proximabeta.mf.uamo com.supercell.clashroyale com.kiloo.subwaysurf com.sybo.subway2 com.firsttouchgames.dls7 com.firsttouchgames.dls8"

# ============================================
# SAVE ORIGINAL GPU STATE (first run only)
# ============================================
if [ ! -f "$GAME_STATE" ]; then
    ORIG_GPU_BOOST=$(cat /sys/module/ged/parameters/gpu_cust_boost_freq 2>/dev/null)
    ORIG_GPU_UPPER=$(cat /sys/module/ged/parameters/gpu_cust_upbound_freq 2>/dev/null)
    ORIG_TCP_LL=$(cat /proc/sys/net/ipv4/tcp_low_latency 2>/dev/null)
    ORIG_TCP_SSAI=$(cat /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null)
    echo "${ORIG_GPU_BOOST:-0}|${ORIG_GPU_UPPER:-0}|${ORIG_TCP_LL:-0}|${ORIG_TCP_SSAI:-1}" > "$GAME_STATE"
    log "Saved original: GPU_BOOST=${ORIG_GPU_BOOST:-0} GPU_UPPER=${ORIG_GPU_UPPER:-0} TCP_LL=${ORIG_TCP_LL:-0}"
fi

O_STATE=$(cat "$GAME_STATE" 2>/dev/null)
O_GPU_BOOST=$(echo "$O_STATE" | cut -d'|' -f1)
O_GPU_UPPER=$(echo "$O_STATE" | cut -d'|' -f2)
O_TCP_LL=$(echo "$O_STATE" | cut -d'|' -f3)
O_TCP_SSAI=$(echo "$O_STATE" | cut -d'|' -f4)

# ============================================
# BOOST FUNCTIONS
# ============================================
GAME_RUNNING=0

apply_boost() {
    log "GAME DETECTED — applying boost"

    # GPU: force max boost freq via GED
    echo 900000 > /sys/module/ged/parameters/gpu_cust_boost_freq 2>/dev/null
    echo 900000 > /sys/module/ged/parameters/gpu_cust_upbound_freq 2>/dev/null
    echo 1 > /sys/module/ged/parameters/ged_boost_enable 2>/dev/null
    echo 1 > /sys/module/ged/parameters/gx_game_mode 2>/dev/null
    log "GPU: boost=900000 upbound=900000 gx_game_mode=1"

    # CPU: pin game processes to big cores (A75 = cores 6-7)
    # cpuset "f" = big cores only
    for pid_dir in /proc/[0-9]*; do
        pid=$(basename "$pid_dir") 2>/dev/null
        [ -z "$pid" ] && continue
        echo "$pid" | grep -qE '^[0-9]+$' || continue
        comm=$(cat "$pid_dir/comm" 2>/dev/null)
        [ -z "$comm" ] && continue
        for g in $GAMES; do
            SHORT=$(echo "$g" | sed 's/.*\.//')
            echo "$comm" | grep -qi "$SHORT" 2>/dev/null && {
                echo "f" > "$pid_dir/cpuset" 2>/dev/null
                log "Pinned PID $pid ($comm) → big cores"
                break
            }
        done
    done

    # Network: aggressive low latency
    echo 1 > /proc/sys/net/ipv4/tcp_low_latency 2>/dev/null
    echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null
    echo 1 > /proc/sys/net/ipv4/tcp_no_metrics_save 2>/dev/null
    log "Network: tcp_low_latency=1 tcp_slow_start=0"

    # Notification
    cmd notification post -t 'Game PerfTune' '' "Game detected — boost ON (GPU+Net+Pin)" > /dev/null 2>&1 &

    GAME_RUNNING=1
}

restore_default() {
    log "GAME CLOSED — restoring defaults"

    # GPU: restore original
    echo "$O_GPU_BOOST" > /sys/module/ged/parameters/gpu_cust_boost_freq 2>/dev/null
    echo "$O_GPU_UPPER" > /sys/module/ged/parameters/gpu_cust_upbound_freq 2>/dev/null
    echo 0 > /sys/module/ged/parameters/gx_game_mode 2>/dev/null

    # Restore all CPUs to full cpuset
    echo "0-7" > /dev/cpuset/foreground/cpus 2>/dev/null
    echo "0-7" > /dev/cpuset/top-app/cpus 2>/dev/null

    # Network: restore
    echo "$O_TCP_LL" > /proc/sys/net/ipv4/tcp_low_latency 2>/dev/null
    echo "$O_TCP_SSAI" > /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null

    cmd notification post -t 'Game PerfTune' '' "Game closed — defaults restored" > /dev/null 2>&1 &

    GAME_RUNNING=0
}

# ============================================
# DETECTION LOOP
# ============================================
log "Daemon started, polling every 3s"

while true; do
    [ -f "/data/local/tmp/game_perftune_disable" ] && {
        [ "$GAME_RUNNING" -eq 1 ] && restore_default
        log "Disable flag found, daemon stopping"
        exit 0
    }

    FOCUS=$(dumpsys window | grep -i "mCurrentFocus" | head -1 | sed 's/.*{[^ ]* [^ ]* \([^}]*\)}.*/\1/' | sed 's/\/.*//')
    [ -z "$FOCUS" ] && FOCUS=$(dumpsys activity activities | grep -i "mResumedActivity" | head -1 | sed 's/.*{[^ ]* [^ ]* \([^}]*\)}.*/\1/' | sed 's/\/.*//')

    IS_GAME=0
    if [ -n "$FOCUS" ]; then
        for g in $GAMES; do
            [ "$FOCUS" = "$g" ] && { IS_GAME=1; break; }
        done
    fi

    if [ "$IS_GAME" -eq 1 ] && [ "$GAME_RUNNING" -eq 0 ]; then
        apply_boost
    elif [ "$IS_GAME" -eq 0 ] && [ "$GAME_RUNNING" -eq 1 ]; then
        restore_default
    fi

    sleep 3
done
