SKIPUNZIP=1

ui_print "**********************************************"
ui_print "         _   _                      _         "
ui_print "        | | | |_   _  __ _  ___(_)_ __   ___ "
ui_print "        | |_| | | | |/ _' |/ __| | '_ \ / _ \\"
ui_print "        |  _  | |_| | (_| | (__| | | | |  __/"
ui_print "        |_| |_|\__, |\__,_|\___|_|_| |_|\___|"
ui_print "               |___/                          "
ui_print "             STORAGE & FUSE FIX               "
ui_print "**********************************************"
ui_print "  Identity: HYACINE FUSE                      "
ui_print "  Version: v1.0                               "
ui_print "  Focus: File Visibility & Open Fix           "
ui_print "**********************************************"

# Install files
ui_print "- Extracting module files..."
unzip -o "$ZIPFILE" 'service.sh' 'module.prop' -d "$MODPATH" >&2

set_permission "$MODPATH/service.sh" 0 0 0755

ui_print "- Storage I/O read-ahead optimized (2048KB)."
ui_print "- FUSE performance stability applied."
ui_print "- Storage invisibility handled by Master Service."
