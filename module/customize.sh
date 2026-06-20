# customize.sh - sourced by the Magisk/KernelSU/APatch installer at install time.
#
# This module does NOT build a systemless overlay tree. The actual silencing is
# done by post-fs-data.sh on every boot via mount --bind, because magic-mount
# does not reliably overlay the separate /product partition on KernelSU (see
# post-fs-data.sh). Install time only validates the clip and previews which
# files will be silenced, so the user gets immediate feedback.

SKIPUNZIP=0
. "$MODPATH/sound_paths.sh"
SILENT="$MODPATH/silent.ogg"

# Guard the original 0-byte failure mode: a missing or empty source clip would
# bind broken audio that crashes SystemUI / breaks screenshots on Android 13+.
[ -s "$SILENT" ] || abort "! silent.ogg missing or empty -- aborting to avoid the 0-byte crash bug"

ui_print "- Scanning for shutter/screenshot sound files"
found=0
for d in $SSCAM_DIRS; do
  [ -d "$d" ] || continue
  for s in $SSCAM_SOUNDS; do
    if [ -f "$d/$s" ]; then
      ui_print "  will silence: $d/$s"
      found=$((found + 1))
    fi
  done
done

if [ "$found" -eq 0 ]; then
  ui_print "! No known sound files found on any partition."
  ui_print "! Your build may name them differently -- run the README diagnostic"
  ui_print "! and report back so the filename/partition lists can be extended."
else
  ui_print "- Found $found sound file(s); post-fs-data.sh will bind a silent"
  ui_print "  clip over them on every boot."
fi

# The boot script and the clip it binds must be present and readable at boot.
set_perm "$MODPATH/silent.ogg"      0 0 0644
set_perm "$MODPATH/sound_paths.sh"  0 0 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755

ui_print "- Reboot to apply."
