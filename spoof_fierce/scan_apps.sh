#!/system/bin/sh
# Spoof Fierce v1.0.0 - App Scanner
# Generates apps_full.json with package, name, icon

MODDIR="/data/adb/modules/spoof_fierce"
WEBROOT="$MODDIR/webroot"
ICONDIR="$WEBROOT/icons"
OUT="$WEBROOT/apps_full.json"

mkdir -p "$ICONDIR"

echo "[" > "$OUT"
FIRST=1

pm list packages -3 2>/dev/null | sed 's/package://' | sort | while read pkg; do
    # Get APK path
    APK=$(pm path "$pkg" 2>/dev/null | head -1 | sed 's/package://')
    [ -z "$APK" ] || [ ! -f "$APK" ] && continue

    # Get app label via dumpsys (fast, cached)
    LABEL=$(dumpsys package "$pkg" 2>/dev/null | grep -A2 "Application Label" | tail -1 | sed 's/^[[:space:]]*//')
    [ -z "$LABEL" ] && LABEL=$(echo "$pkg" | awk -F'.' '{print $NF}' | sed 's/./\U&/')

    # Try extract icon (res/drawable-hdpi/icon.png or similar)
    ICONNAME=$(echo "$pkg" | tr '.' '_')
    ICONFILE="$ICONDIR/$ICONNAME.png"
    if [ ! -f "$ICONFILE" ]; then
        # Try common icon paths
        TMPDIR="/data/local/tmp/_icon_tmp"
        mkdir -p "$TMPDIR"
        unzip -o -q "$APK" "res/drawable-hdpi/icon.png" -d "$TMPDIR" 2>/dev/null
        if [ -f "$TMPDIR/res/drawable-hdpi/icon.png" ]; then
            cp "$TMPDIR/res/drawable-hdpi/icon.png" "$ICONFILE" 2>/dev/null
        else
            # Try mipmap
            unzip -o -q "$APK" "res/mipmap-hdpi*/icon.png" -d "$TMPDIR" 2>/dev/null
            MIPMAP=$(find "$TMPDIR/res" -name "icon.png" 2>/dev/null | head -1)
            [ -n "$MIPMAP" ] && cp "$MIPMAP" "$ICONFILE" 2>/dev/null
        fi
        rm -rf "$TMPDIR"
    fi

    # Write JSON entry
    if [ "$FIRST" -eq 1 ]; then
        FIRST=0
    else
        echo "," >> "$OUT"
    fi
    HASICON="false"
    [ -f "$ICONFILE" ] && HASICON="true"
    echo "{\"pkg\":\"$pkg\",\"name\":\"$LABEL\",\"icon\":$HASICON}" >> "$OUT"
done

echo "]" >> "$OUT"
chmod 644 "$OUT"
echo "OK|$(grep -c '"pkg"' "$OUT" 2>/dev/null || echo 0)"
