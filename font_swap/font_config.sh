#!/system/bin/sh
# Font Swap v1.0.0 — Font selection script
# Usage: sh font_config.sh <command> [args]
#
# Commands:
#   list                          List available font profiles
#   apply <profile>               Apply a font profile
#   restore                       Restore default font
#   set-scale <value>             Set font scale (0.85–1.3)
#   custom <path>                 Use a custom font file
#   status                        Show current font config

MODDIR="/data/adb/modules/font_swap"
LOG="/data/local/tmp/font_swap.log"
FONT_DIR="$MODDIR/fonts"
CONF_DIR="$MODDIR"

# Available font profiles
# Each profile is a directory under fonts/ containing:
#   Roboto-Regular.ttf, Roboto-Bold.ttf, etc.
PROFILES="default google roboto slab mono rounded condensed"

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

list_fonts() {
    echo "=== Available Font Profiles ==="
    echo ""
    echo "  default      — Stock Roboto (Android default)"
    echo "  google       — Google Sans (Pixel style)"
    echo "  roboto       — Roboto with condensed numerals"
    echo "  slab         — Roboto Slab (serif)"
    echo "  mono         — Roboto Mono (monospace)"
    echo "  rounded      — Google Sans Rounded"
    echo "  condensed    — Roboto Condensed"
    echo ""
    # Check for custom fonts directory
    if [ -d "$FONT_DIR/custom" ]; then
        echo "  Custom fonts in $FONT_DIR/custom/:"
        for f in "$FONT_DIR/custom"/*.ttf "$FONT_DIR/custom"/*.otf; do
            [ -f "$f" ] && echo "    $(basename "$f")"
        done
    fi
}

apply_profile() {
    PROFILE="$1"
    [ -z "$PROFILE" ] && { echo "Usage: sh font_config.sh apply <profile>"; exit 1; }

    log "Applying profile: $PROFILE"

    case "$PROFILE" in
        default)
            # Remove custom font overrides
            resetprop --delete persist.sys.font.custom 2>/dev/null
            resetprop ro.config.font_scale 1.0
            echo "1.0" > "$CONF_DIR/font_scale.conf"
            log "Restored default font"
            echo "✓ Default font restored"
            ;;
        google|roboto|slab|mono|rounded|condensed)
            # Verify font files exist for this profile
            PDIR="$FONT_DIR/$PROFILE"
            if [ ! -d "$PDIR" ]; then
                echo "✗ Font profile '$PROFILE' not found at $PDIR"
                echo "  Place font files in: $PDIR/"
                log "Profile dir missing: $PDIR"
                exit 1
            fi

            # Use first available font file as primary
            PRIMARY=""
            for f in "$PDIR"/*.ttf "$PDIR"/*.otf; do
                [ -f "$f" ] && { PRIMARY="$f"; break; }
            done

            if [ -z "$PRIMARY" ]; then
                echo "✗ No font files found in $PDIR"
                exit 1
            fi

            resetprop persist.sys.font.custom "$PRIMARY"
            echo "$PRIMARY" > "$CONF_DIR/font_path.conf"
            log "Set font=$PRIMARY"
            echo "✓ Applied: $PROFILE ($PRIMARY)"
            ;;
        *)
            # Check if it's a direct path to a font file
            if [ -f "$PROFILE" ]; then
                resetprop persist.sys.font.custom "$PROFILE"
                echo "$PROFILE" > "$CONF_DIR/font_path.conf"
                log "Set custom font=$PROFILE"
                echo "✓ Custom font applied: $PROFILE"
            else
                echo "✗ Unknown profile: $PROFILE"
                echo "  Run: sh font_config.sh list"
                exit 1
            fi
            ;;
    esac

    echo "  Restart apps or reboot for full effect."
}

restore_font() {
    log "Restoring default font"
    resetprop --delete persist.sys.font.custom 2>/dev/null
    resetprop ro.config.font_scale 1.0
    echo "1.0" > "$CONF_DIR/font_scale.conf"
    rm -f "$CONF_DIR/font_path.conf"
    echo "✓ Default font restored. Reboot recommended."
}

set_scale() {
    SCALE="$1"
    [ -z "$SCALE" ] && { echo "Usage: sh font_config.sh set-scale <0.85-1.3>"; exit 1; }

    # Validate range
    case "$SCALE" in
        0.85|0.9|0.95|1.0|1.05|1.1|1.15|1.2|1.25|1.3)
            resetprop ro.config.font_scale "$SCALE"
            echo "$SCALE" > "$CONF_DIR/font_scale.conf"
            log "Set font_scale=$SCALE"
            echo "✓ Font scale set to $SCALE"
            ;;
        *)
            echo "✗ Invalid scale: $SCALE (must be 0.85–1.3)"
            exit 1
            ;;
    esac
}

set_custom() {
    PATH_FONT="$1"
    [ -z "$PATH_FONT" ] && { echo "Usage: sh font_config.sh custom <path/to/font.ttf>"; exit 1; }

    if [ ! -f "$PATH_FONT" ]; then
        echo "✗ Font file not found: $PATH_FONT"
        exit 1
    fi

    resetprop persist.sys.font.custom "$PATH_FONT"
    echo "$PATH_FONT" > "$CONF_DIR/font_path.conf"
    log "Set custom font=$PATH_FONT"
    echo "✓ Custom font applied: $PATH_FONT"
}

show_status() {
    echo "=== Font Swap Status ==="
    echo ""
    SCALE=$(cat "$CONF_DIR/font_scale.conf" 2>/dev/null)
    SCALE=${SCALE:-1.0}
    FONT=$(cat "$CONF_DIR/font_path.conf" 2>/dev/null)
    FLIP=$(getprop persist.sys.font.flipping 2>/dev/null)
    REND=$(getprop persist.sys.font_rendering 2>/dev/null)
    HWUI=$(getprop debug.hwui.font_cache 2>/dev/null)

    echo "  Font scale:   $SCALE"
    echo "  Custom font:  ${FONT:-<default>}"
    echo "  Flipping:     ${FLIP:-0}"
    echo "  Rendering:    ${REND:-0}"
    echo "  HWUI cache:   ${HWUI:-0}"
    echo ""
    echo "  Active font:  $(getprop persist.sys.font.custom 2>/dev/null || echo '<system default>')"
}

case "$1" in
    list)       list_fonts ;;
    apply)      apply_profile "$2" ;;
    restore)    restore_font ;;
    set-scale)  set_scale "$2" ;;
    custom)     set_custom "$2" ;;
    status)     show_status ;;
    *)
        echo "Font Swap v1.0.0 — Font Configuration"
        echo ""
        echo "Usage: sh font_config.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  list                List available font profiles"
        echo "  apply <profile>     Apply a font profile"
        echo "  restore             Restore default font"
        echo "  set-scale <value>   Set font scale (0.85–1.3)"
        echo "  custom <path>       Use a custom .ttf/.otf file"
        echo "  status              Show current configuration"
        ;;
esac
