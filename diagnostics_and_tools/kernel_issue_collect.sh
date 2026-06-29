#!/system/bin/sh
# Kernel Issue Diagnostic Script for MT6768 LCM 0d Driver Hang
# Collects all data needed for kernel bug report

OUTDIR="/data/local/tmp/kernel_issue_$(date '+%Y%m%d_%H%M%S')"
mkdir -p "$OUTDIR"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "===== COLLECTING KERNEL ISSUE DATA ====="
log "Output directory: $OUTDIR"

# ============================================================
# 1. DEVICE INFO
# ============================================================
log "[1/8] Device info..."
{
    echo "=== DEVICE ==="
    getprop ro.product.model
    getprop ro.product.board
    getprop ro.hardware.chipname
    getprop ro.board.platform
    getprop ro.build.display.id
    getprop ro.build.version.release
    getprop ro.build.version.sdk
    getprop ro.build.fingerprint
    getprop ro.product.cpu.abi
    getprop ro.kernel.qemu
    echo ""
    echo "=== KERNEL ==="
    uname -a
    cat /proc/version
    echo ""
    echo "=== BOOT TIME ==="
    cat /proc/uptime
    cat /proc/loadavg
} > "$OUTDIR/device_info.txt" 2>&1

# ============================================================
# 2. FULL DMESG (kernel ring buffer)
# ============================================================
log "[2/8] Full dmesg..."
dmesg > "$OUTDIR/dmesg_full.txt" 2>&1

# Filter for display/LCM related
dmesg | grep -iE "lcm|dsi|panel|display|mdss|drm|fb|disp|commit|underrun|0d|esd|tearing|fence|vsync" > "$OUTDIR/dmesg_display.txt" 2>&1

# Filter for charging/PMIC
dmesg | grep -iE "chg|charge|syv|pmic|mt6358|battery|thermal|temp" > "$OUTDIR/dmesg_charging.txt" 2>&1

# Filter for errors/bugs
dmesg | grep -iE "error|bug|warn|fault|panic|oops|hung|timeout|deadlock|stuck" > "$OUTDIR/dmesg_errors.txt" 2>&1

# Filter for MMC/SD
dmesg | grep -iE "mmc|sd|block|emmc" > "$OUTDIR/dmesg_storage.txt" 2>&1

# ============================================================
# 3. D-STATE PROCESSES + STACK TRACES
# ============================================================
log "[3/8] D-state processes..."
{
    echo "=== D-STATE PROCESSES ==="
    ps -A -o PID,STAT,WCHAN,TIME,COMM | grep D
    echo ""
    echo "=== D-STATE COUNT ==="
    ps -A -o stat | grep -c D
    echo ""
    echo "=== STACK TRACES (D-state) ==="
    for pid in $(ps -A -o PID,STAT | grep D | awk '{print $1}'); do
        echo "--- PID $pid ---"
        cat /proc/$pid/wchan 2>/dev/null
        cat /proc/$pid/stack 2>/dev/null
        cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' '
        echo ""
        echo ""
    done
} > "$OUTDIR/dstate_procs.txt" 2>&1

# ============================================================
# 4. DISPLAY DRIVER STATE
# ============================================================
log "[4/8] Display driver state..."
{
    echo "=== FRAMEBUFFER ==="
    cat /sys/class/graphics/fb0/modes 2>/dev/null
    cat /sys/class/graphics/fb0/status 2>/dev/null
    echo ""
    echo "=== PANEL INFO ==="
    cat /sys/class/graphics/fb0/panel_info 2>/dev/null
    echo ""
    echo "=== DISPLAY SYSFS ==="
    find /sys/class/graphics/fb0/ -type f 2>/dev/null | while read f; do
        VAL=$(cat "$f" 2>/dev/null)
        [ -n "$VAL" ] && echo "$f: $VAL"
    done
    echo ""
    echo "=== DSI PANEL ==="
    find /sys/devices/platform/soc/ -name "*dsi*" -type d 2>/dev/null | while read d; do
        echo "Dir: $d"
        ls "$d" 2>/dev/null
    done
    echo ""
    echo "=== DRM STATUS ==="
    cat /sys/class/drm/card0/device/status 2>/dev/null
    find /sys/class/drm/ -name "status" -exec sh -c 'echo "$1: $(cat "$1")"' _ {} \; 2>/dev/null
} > "$OUTDIR/display_state.txt" 2>&1

# ============================================================
# 5. CHARGING IC STATE
# ============================================================
log "[5/8] Charging IC state..."
{
    echo "=== POWER SUPPLY ==="
    for ps_dir in /sys/class/power_supply/*/; do
        NAME=$(basename "$ps_dir")
        echo "--- $NAME ---"
        for f in "$ps_dir"*; do
            [ -f "$f" ] || continue
            FNAME=$(basename "$f")
            case "$FNAME" in
                uevent|type) continue ;;
            esac
            VAL=$(cat "$f" 2>/dev/null)
            [ -n "$VAL" ] && echo "  $FNAME: $VAL"
        done
    done
    echo ""
    echo "=== SYV690 CHARGING IC REGISTERS ==="
    dmesg | grep "SYV690" | tail -5
    echo ""
    echo "=== PMIC REGISTERS ==="
    dmesg | grep "mt6358" | tail -10
} > "$OUTDIR/charging_state.txt" 2>&1

# ============================================================
# 6. THERMAL STATE
# ============================================================
log "[6/8] Thermal state..."
{
    echo "=== THERMAL ZONES ==="
    for zone in /sys/class/thermal/thermal_zone*/; do
        NAME=$(cat "$zone/type" 2>/dev/null)
        TEMP=$(cat "$zone/temp" 2>/dev/null)
        MODE=$(cat "$zone/mode" 2>/dev/null)
        echo "  $NAME: temp=$TEMP mode=$MODE"
    done
    echo ""
    echo "=== THERMAL SERVICES ==="
    for svc in thermal thermal_manager thermalloadalgod mi_thermald; do
        echo "  init.svc.$svc = $(getprop init.svc.$svc)"
    done
    echo ""
    echo "=== CPU FREQUENCIES ==="
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/; do
        CPU_NAME=$(basename $(dirname "$cpu"))
        FREQ=$(cat "$cpu/scaling_cur_freq" 2>/dev/null)
        GOV=$(cat "$cpu/scaling_governor" 2>/dev/null)
        MAX=$(cat "$cpu/scaling_max_freq" 2>/dev/null)
        echo "  $CPU_NAME: cur=$FREQ gov=$GOV max=$MAX"
    done
} > "$OUTDIR/thermal_state.txt" 2>&1

# ============================================================
# 7. MEMORY + VM STATE
# ============================================================
log "[7/8] Memory state..."
{
    echo "=== MEMINFO ==="
    cat /proc/meminfo
    echo ""
    echo "=== VM STATS ==="
    cat /proc/vmstat | grep -E "pgfault|pgmajfault|pswpin|pswpout|pgalloc|pgfree|oom_kill|allocstall"
    echo ""
    echo "=== SLAB INFO ==="
    cat /proc/slabinfo | head -20
    echo ""
    echo "=== ZONE INFO ==="
    cat /proc/zoneinfo | grep -A2 "nr_free_pages|min\|low\|high" | head -30
} > "$OUTDIR/memory_state.txt" 2>&1

# ============================================================
# 8. MODULE INFO
# ============================================================
log "[8/8] Module info..."
{
    echo "=== KERNEL MODULES ==="
    lsmod 2>/dev/null
    echo ""
    echo "=== INSTALLED MODULES ==="
    ls /data/adb/modules/
    echo ""
    echo "=== FILESYSTEMS ==="
    cat /proc/filesystems
    echo ""
    echo "=== MOUNTS ==="
    mount | grep -v "proc\|sys\|cgroup"
    echo ""
    echo "=== BLOCK DEVICES ==="
    ls /sys/block/
    echo ""
    echo "=== PARTITIONS ==="
    cat /proc/partitions
} > "$OUTDIR/system_state.txt" 2>&1

# ============================================================
# COMPRESS
# ============================================================
log "Compressing..."
cd /data/local/tmp
tar -czf "kernel_issue_$(date '+%Y%m%d_%H%M%S').tar.gz" -C /data/local/tmp "$(basename $OUTDIR)" 2>/dev/null

log "===== DONE ====="
log "Files collected in: $OUTDIR"
ls -la "$OUTDIR"
