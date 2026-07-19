#!/system/bin/sh
# Power Menu — customize.sh
# KSU installer script

ZIPFILE=$2
OUTFD=$3

ui_print() {
  echo -e "ui_print $1\nui_print" >> /proc/self/fd/$OUTFD
}

ui_print "========================================="
ui_print "  Extended Power Menu v1.0.0"
ui_print "  Author: Naidrahiqa"
ui_print "========================================="
ui_print ""
ui_print "- Installing power menu properties..."
ui_print "- Advanced reboot menu enabled"
ui_print "- Screenshot, airplane, reboot, shutdown"
ui_print "- Lock, emergency, user switch"
ui_print ""
ui_print "Installation complete."
ui_print "Reboot to apply changes."
