#!/system/bin/sh
# post-fs-data.sh - runs on every boot, before SystemUI/zygote start.
#
# Binds a short SILENT clip directly over every camera/screenshot UI sound that
# exists on the live partitions. We use mount --bind rather than the root
# manager's systemless overlay because magic-mount does NOT reliably reach the
# separate /product partition on KernelSU 3.2.0 + susfs (verified on a Pixel 10a,
# Android 17): /system overlays apply, /product ones silently do not, so the
# original camera_click.ogg stayed live and the screenshot/shutter kept sounding.
# An explicit bind works the same on Magisk, KernelSU, and APatch, and runs in
# the global mount namespace so the binds are visible to SystemUI.
MODDIR=${0%/*}
. "$MODDIR/sound_paths.sh"
SILENT="$MODDIR/silent.ogg"

# Never bind an empty source: a 0-byte ogg crashes SystemUI / breaks screenshots
# on Android 13+ (the original module's failure mode). Bail out silently rather
# than risk breaking the device on boot.
[ -s "$SILENT" ] || exit 0

# Give the clip a context SystemUI can read. The UI sound files are part of the
# system image (u:object_r:system_file:s0), which is broadly readable; without
# this the bound file would keep its /data/adb module context and could be denied.
chcon u:object_r:system_file:s0 "$SILENT" 2>/dev/null

for d in $SSCAM_DIRS; do
  [ -d "$d" ] || continue
  for s in $SSCAM_SOUNDS; do
    t="$d/$s"
    [ -f "$t" ] || continue
    mount --bind "$SILENT" "$t" 2>/dev/null
  done
done
