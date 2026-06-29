#!/system/bin/sh
echo "=== Searching /data/adb/modules ==="
grep -rn "ntfs" /data/adb/modules/ 2>/dev/null

echo "=== Searching /system/etc ==="
grep -rn "ntfs" /system/etc/ 2>/dev/null

echo "=== Searching /vendor/etc ==="
grep -rn "ntfs" /vendor/etc/ 2>/dev/null
