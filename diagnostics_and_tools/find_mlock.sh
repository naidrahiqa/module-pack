#!/system/bin/sh
for f in /proc/[0-9]*/status; do
    res=$(grep Mlocked "$f" 2>/dev/null)
    if [ -n "$res" ] && ! echo "$res" | grep -q "0 kB"; then
        pid=$(echo "$f" | cut -d'/' -f3)
        name=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ')
        [ -z "$name" ] && name=$(awk '/^Name:/{print $2}' "$f")
        echo "PID $pid ($name): $res"
    fi
done
