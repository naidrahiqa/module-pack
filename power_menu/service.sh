#!/system/bin/sh
# Power Menu — service.sh
# Runtime: wait for boot, apply settings, log status

MODDIR=${0%/*}
LOGFILE=/data/local/tmp/power_menu.log

log_msg() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1
done

log_msg "boot_completed=1 — applying power menu settings"

# Verify properties are set
for prop in \
  persist.sys.power_menu.advanced_reboot \
  persist.sys.power_menu.screenshot \
  persist.sys.power_menu.airplane \
  persist.sys.power_menu.reboot \
  persist.sys.power_menu.shutdown \
  persist.sys.power_menu.lock \
  persist.sys.power_menu.emergency \
  persist.sys.power_menu.users \
  ro.config.power_menu.advanced; do
  val=$(getprop "$prop")
  log_msg "$prop=$val"
done

# Ensure advanced reboot is active
if [ "$(getprop persist.sys.advance_reboot)" != "1" ]; then
  resetprop persist.sys.advance_reboot 1
  log_msg "re-applied persist.sys.advance_reboot=1"
fi

if [ "$(getprop persist.sys.enable_reboot_menu)" != "1" ]; then
  resetprop persist.sys.enable_reboot_menu 1
  log_msg "re-applied persist.sys.enable_reboot_menu=1"
fi

log_msg "power_menu module loaded successfully"
