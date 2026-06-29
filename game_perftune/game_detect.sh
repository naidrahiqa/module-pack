#!/system/bin/sh
# Game PerfTune v1.0.0 — Manual game detection helper
# Usage: sh game_detect.sh [start|stop|status|add <pkg>|remove <pkg>|list]
LOG="/data/local/tmp/game_perftune.log"
MODDIR="/data/adb/modules/game_perftune"
GAMES_FILE="$MODDIR/games.conf"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

# Initialize games.conf from default list if not exists
init_games() {
    if [ ! -f "$GAMES_FILE" ]; then
        cat > "$GAMES_FILE" << 'EOF'
com.mobile.legends
com.levelinfinite.sgameGlobal
com.tencent.tmgp.sgame
com.tencent.ig
com.pubg.mobile
com.garena.game.codm
com.miHoYo.GenshinImpact
com.supercell.clashofclans
com.supercell.brawlstars
com.activision.callofduty.warzone
com.epicgames.fortnite
com.dts.freefireth
com.dts.freefiremax
com.riotgames.league.wildrift
com.ea.gp.apexlegendsmobilefps
com.levelinfinite.honkaisrail
com.HoYoverse.Nap
com.miHoYo.TearGod
com.papegames.infinitynikki
com.proximabeta.mf.uamo
com.supercell.clashroyale
com.kiloo.subwaysurf
com.sybo.subway2
com.firsttouchgames.dls7
com.firsttouchgames.dls8
EOF
        log "Initialized games.conf with default list"
    fi
}

case "$1" in
    start)
        log "Manual start requested"
        # Trigger service.sh
        sh /data/adb/modules/game_perftune/service.sh &
        echo "Game PerfTune daemon started"
        ;;
    stop)
        log "Manual stop requested"
        touch /data/local/tmp/game_perftune_disable
        echo "Game PerfTune stopped (disable flag set)"
        echo "Remove flag to re-enable: rm /data/local/tmp/game_perftune_disable"
        ;;
    status)
        if [ -f "/data/local/tmp/game_perftune_active" ]; then
            echo "=== Game PerfTune Status ==="
            echo "State: ACTIVE"
            echo "Game running: $(cat /data/local/tmp/game_perftune_state 2>/dev/null | head -1)"
            echo ""
            echo "CPU Info:"
            echo "  A55 governor: $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null)"
            echo "  A75 governor: $(cat /sys/devices/system/cpu/cpufreq/policy6/scaling_governor 2>/dev/null)"
            echo "  A55 freq: $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq 2>/dev/null)"
            echo "  A75 freq: $(cat /sys/devices/system/cpu/cpufreq/policy6/scaling_cur_freq 2>/dev/null)"
            echo ""
            echo "GPU Info:"
            for gpufreq in /sys/class/devfreq/mtk-dvfsrc-devfreq /sys/class/devfreq/gpufreq; do
                [ -d "$gpufreq" ] && {
                    echo "  Current: $(cat "$gpufreq/cur_freq" 2>/dev/null)"
                    echo "  Max: $(cat "$gpufreq/max_freq" 2>/dev/null)"
                    echo "  Governor: $(cat "$gpufreq/governor" 2>/dev/null)"
                }
            done
            echo ""
            echo "Game packages: $(wc -l < "$GAMES_FILE" 2>/dev/null)"
        else
            echo "Game PerfTune: NOT ACTIVE"
            echo "Reboot or run: sh game_detect.sh start"
        fi
        ;;
    add)
        init_games
        [ -z "$2" ] && { echo "Usage: sh game_detect.sh add <package.name>"; exit 1; }
        grep -q "^$2$" "$GAMES_FILE" 2>/dev/null && {
            echo "$2 already in game list"
            exit 0
        }
        echo "$2" >> "$GAMES_FILE"
        log "Added game: $2"
        echo "Added: $2"
        echo "Restart daemon to apply: sh game_detect.sh stop && sh game_detect.sh start"
        ;;
    remove)
        init_games
        [ -z "$2" ] && { echo "Usage: sh game_detect.sh remove <package.name>"; exit 1; }
        grep -q "^$2$" "$GAMES_FILE" 2>/dev/null || {
            echo "$2 not found in game list"
            exit 1
        }
        sed -i "/^$2$/d" "$GAMES_FILE"
        log "Removed game: $2"
        echo "Removed: $2"
        echo "Restart daemon to apply: sh game_detect.sh stop && sh game_detect.sh start"
        ;;
    list)
        init_games
        echo "=== Game List ==="
        nl "$GAMES_FILE"
        ;;
    *)
        echo "Game PerfTune v1.0.0 — Manual Control"
        echo ""
        echo "Usage: sh game_detect.sh <command>"
        echo ""
        echo "Commands:"
        echo "  start              Start the game detection daemon"
        echo "  stop               Stop the daemon (set disable flag)"
        echo "  status             Show current boost status"
        echo "  add <package>      Add a game to the list"
        echo "  remove <package>   Remove a game from the list"
        echo "  list               Show all tracked games"
        ;;
esac
