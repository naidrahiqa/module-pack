#!/system/bin/sh
# Spoof Fierce v2.0.0 - API wrapper (calls native binary)
MODDIR="/data/adb/modules/spoof_fierce"
NATIVE="$MODDIR/bin/spoof_api"

if [ -x "$NATIVE" ]; then
    exec "$NATIVE" "$@"
else
    # Fallback: shell-only mode (legacy)
    echo "ERROR: Native API binary not found at $NATIVE" >&2
    exit 1
fi
