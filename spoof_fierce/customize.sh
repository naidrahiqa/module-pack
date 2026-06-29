#!/system/bin/sh
# Spoof Fierce v1.0.0 — Zygisk Module Installer
# Author: Naidrahiqa

ui_print ""
ui_print "╔══════════════════════════════════════════════╗"
ui_print "║        SPOOF FIERCE v1.0.0 (Zygisk)        ║"
ui_print "║   Universal Device Spoof · FPS Unlock        ║"
ui_print "╚══════════════════════════════════════════════╝"
ui_print ""

# ============================================
# Check Zygisk requirement
# ============================================
ui_print "▸ Checking Zygisk..."
ZYGISK_OK=0

# KernelSU Next has Zygisk built-in
if [ -d /data/adb/ksu ] || [ -f /data/adb/ksu/bin/ksud ]; then
    ui_print "  KernelSU detected"
    ZYGISK_OK=1
fi

# Magisk Zygisk
if [ -f /data/adb/magisk ]; then
    ZYGISK_PROP=$(getprop persist.sys.zygisk.enabled 2>/dev/null)
    if [ "$ZYGISK_PROP" = "true" ]; then
        ui_print "  Magisk Zygisk enabled"
        ZYGISK_OK=1
    fi
fi

if [ "$ZYGISK_OK" -eq 0 ]; then
    ui_print ""
    ui_print "  ⚠ Zygisk not detected!"
    ui_print "  Enable Zygisk in your root manager first."
    ui_print ""
    abort "Zygisk required."
fi

# ============================================
# Detect device (universal)
# ============================================
ui_print "▸ Detecting device..."
CHIP=$(getprop ro.hardware.chipname 2>/dev/null)
[ -z "$CHIP" ] && CHIP=$(getprop ro.hardware 2>/dev/null)
MODEL=$(getprop ro.product.model 2>/dev/null)
BRAND=$(getprop ro.product.brand 2>/dev/null)
RAM_KB=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
RAM_MB=$((RAM_KB / 1024))

ui_print "  Chip: $CHIP"
ui_print "  Model: $MODEL"
ui_print "  Brand: $BRAND"
ui_print "  RAM: ${RAM_MB}MB"

IS_MTK=0
echo "$CHIP" | grep -qi "mt" && IS_MTK=1
[ "$IS_MTK" -eq 1 ] && ui_print "  Platform: MediaTek" || ui_print "  Platform: Qualcomm/Other"
ui_print ""

# ============================================
# Install native library
# ============================================
ui_print "▸ Installing native library..."

ABI=$(getprop ro.product.cpu.abi 2>/dev/null)
ui_print "  ABI: $ABI"

# Check for prebuilt .so in lib/{abi}/
HAS_PREBUILT=0
if [ -f "$MODPATH/lib/$ABI/libspoof_fierce.so" ]; then
    HAS_PREBUILT=1
    ui_print "  ✓ Prebuilt found: lib/$ABI/libspoof_fierce.so"
fi

# Check for prebuilt .so in prebuilt/{abi}/
if [ "$HAS_PREBUILT" -eq 0 ] && [ -f "$MODPATH/prebuilt/$ABI/libspoof_fierce.so" ]; then
    mkdir -p "$MODPATH/lib/$ABI"
    cp "$MODPATH/prebuilt/$ABI/libspoof_fierce.so" "$MODPATH/lib/$ABI/"
    HAS_PREBUILT=1
    ui_print "  ✓ Prebuilt found: prebuilt/$ABI/libspoof_fierce.so"
fi

# Try to build with NDK if no prebuilt
if [ "$HAS_PREBUILT" -eq 0 ]; then
    ui_print "  No prebuilt found, trying NDK build..."
    
    NDK_DIR=""
    for d in \
        "$ANDROID_NDK_HOME" \
        "$ANDROID_SDK/ndk"/* \
        /opt/android-ndk* \
        /usr/local/lib/android/ndk/* \
        /data/adb/modules/*/ndk; do
        [ -d "$d" ] && NDK_DIR="$d" && break
    done

    if [ -n "$NDK_DIR" ]; then
        TOOLCHAIN=""
        case "$ABI" in
            arm64-v8a) TOOLCHAIN="aarch64-linux-android" ;;
            armeabi-v7a) TOOLCHAIN="armv7a-linux-androideabi" ;;
        esac

        CC=$(ls "$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64/bin/$TOOLCHAIN"*-clang++ 2>/dev/null | head -1)
        if [ -n "$CC" ]; then
            mkdir -p "$MODPATH/lib/$ABI"
            "$CC" \
                -std=c++17 -O2 -flto -DNDEBUG \
                -I "$MODPATH/src" \
                -shared -fPIC -o "$MODPATH/lib/$ABI/libspoof_fierce.so" \
                "$MODPATH/src/spoof_module.cpp" \
                -llog -landroid
            if [ -f "$MODPATH/lib/$ABI/libspoof_fierce.so" ]; then
                HAS_PREBUILT=1
                ui_print "  ✓ Built with NDK"
            fi
        fi
    fi
fi

# Safety: if no .so, module still works via resetprop fallback
if [ "$HAS_PREBUILT" -eq 0 ]; then
    ui_print ""
    ui_print "  ⚠ Native library not found!"
    ui_print "  Module will use resetprop fallback."
    ui_print "  For full Zygisk hook, build with Termux:"
    ui_print "    bash build-termux.sh"
    ui_print ""
fi

# Clean up build artifacts (keep src for Termux rebuild)
rm -rf "$MODPATH/build" "$MODPATH/prebuilt" 2>/dev/null

# ============================================
# Set permissions
# ============================================
ui_print "▸ Setting permissions..."
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
[ -f "$MODPATH/api.sh" ] && set_perm "$MODPATH/api.sh" 0 0 0755
[ -d "$MODPATH/webroot" ] && chmod -R 755 "$MODPATH/webroot" 2>/dev/null

# Set .so permissions
for lib in "$MODPATH"/lib/*/libspoof_fierce.so; do
    [ -f "$lib" ] && set_perm "$lib" 0 0 0644
done

# ============================================
# Print summary
# ============================================
ui_print ""
ui_print "▸ Config: SpoofFierce.json"
ui_print "  Edit to add/remove games or change device profile"
ui_print ""
ui_print "▸ Supported games:"
ui_print "  • Mobile Legends (com.mobile.legends)"
ui_print "  • Honor of Kings (com.levelinfinite.sgameGlobal)"
ui_print "  • Honor of Kings CN (com.tencent.tmgp.sgame)"
ui_print ""
ui_print "✓ Spoof Fierce v1.0.0 installed."
ui_print "  Reboot to activate."
