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

# KernelSU module-hiding caveat. If the root manager UNMOUNTS modules from apps
# (KernelSU "Umount modules" / susfs auto_try_umount), the overlay never reaches
# System UI and the sound keeps playing. There is no supported command to
# exclude a single app, so warn loudly with the one-time manual step. We only
# warn on KernelSU ($KSU is set by the KernelSU installer) when hiding looks on.
if [ "$KSU" = "true" ]; then
  hiding=0
  grep -q '^auto_try_umount=1' /data/adb/susfs4ksu/config.sh 2>/dev/null && hiding=1
  for kb in ksud /data/adb/ksud; do
    command -v "$kb" >/dev/null 2>&1 || [ -x "$kb" ] || continue
    "$kb" feature get kernel_umount 2>/dev/null | grep -qi 'enabled\|: 1' && hiding=1
    break
  done
  if [ "$hiding" = "1" ]; then
    ui_print " "
    ui_print "!! KernelSU module-hiding (Umount modules / susfs) is ACTIVE."
    ui_print "!! The overlay will NOT reach System UI, so the screenshot/shutter"
    ui_print "!! sound will KEEP playing until you do this ONE-TIME step:"
    ui_print "!!   1. Open the KernelSU(-Next) app -> app list"
    ui_print "!!   2. Enable 'show system apps'"
    ui_print "!!   3. Open 'System UI' (com.android.systemui)"
    ui_print "!!   4. Turn OFF 'Umount modules' for it"
    ui_print "!!   5. Reboot"
    ui_print "!! This is persistent and keeps root-hiding for your other apps."
    ui_print "!! Details: see the README 'Why the sound may still play' section."
    ui_print " "
  fi
fi

ui_print "- Reboot to apply."
