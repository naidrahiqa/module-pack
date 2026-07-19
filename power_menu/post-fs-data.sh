#!/system/bin/sh
# Power Menu — post-fs-data.sh
# Early boot: set power menu properties via resetprop

MODDIR=${0%/*}

# Advanced reboot menu (long-press power menu)
resetprop persist.sys.power_menu.advanced_reboot 1

# Screenshot option in power menu
resetprop persist.sys.power_menu.screenshot 1

# Airplane mode toggle
resetprop persist.sys.power_menu.airplane 1

# Reboot option
resetprop persist.sys.power_menu.reboot 1

# Shutdown option
resetprop persist.sys.power_menu.shutdown 1

# Lock screen option
resetprop persist.sys.power_menu.lock 1

# Emergency SOS option
resetprop persist.sys.power_menu.emergency 1

# User switching option
resetprop persist.sys.power_menu.users 1

# Advanced config flag
resetprop ro.config.power_menu.advanced 1

# Enable advanced reboot in settings (recovery + bootloader)
resetprop persist.sys.advance_reboot 1
resetprop persist.sys.enable_reboot_menu 1
