#!/system/bin/sh
# Multi Audio Play — customize.sh

# Install module files
ui_print "- Installing Multi Audio Play..."

# Copy audio policy configuration
if [ -f "$MODPATH/system/etc/audio_policy_configuration.xml" ]; then
    ui_print "- Audio policy configuration ready"
fi

ui_print "- Multi Audio Play installed!"
ui_print "- Reboot to apply changes"
ui_print "- To uninstall: delete module and reboot"
