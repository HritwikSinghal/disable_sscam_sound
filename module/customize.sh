# customize.sh - sourced by Magisk/KernelSU/APatch installer
# Overlays a short SILENT clip over every camera/screenshot UI sound that
# actually exists on this device, at the correct partition-mapped module path.

SKIPUNZIP=0
SILENT="$MODPATH/silent.ogg"

# Guard the original 0-byte failure mode: a missing or empty source clip would
# write broken overlays that crash SystemUI / break screenshots on Android 13+.
# Aborting cleanly is far better than installing a silently broken module.
[ -s "$SILENT" ] || abort "! silent.ogg missing or empty -- aborting to avoid the 0-byte crash bug"

# UI sound filenames to silence.
# Core AOSP/Pixel set (camera_click.ogg is the framework shutter sound, hardcoded
# in config_cameraShutterSound -> /product/media/audio/ui/camera_click.ogg):
#   camera_click.ogg camera_focus.ogg VideoRecord.ogg VideoStop.ogg
# NOTE: on Android 13+ the screenshot sound is NO LONGER camera_click.ogg -- it is
# a separate asset, often baked into SystemUI.apk (res/raw). A loose-file overlay
# cannot silence an in-APK screenshot sound; ScreenCapture.ogg/Screenshot.ogg
# below are best-effort for builds that still keep it as a loose file.
# The remaining names are OEM variants (Samsung/OnePlus); all are guarded by
# [ -f ] so they are safe no-ops on devices that lack them.
SOUNDS="camera_click.ogg camera_focus.ogg VideoRecord.ogg VideoStop.ogg \
camera_click_short.ogg Shutter.ogg Shutter01.ogg camera_shutter.ogg \
ScreenCapture.ogg Screenshot.ogg"

# Real partitions/dirs modern Android keeps UI audio in. Both the canonical
# .../media/audio/ui dir and the flatter .../media/audio dir are scanned, plus
# /odm for OEMs that ship UI audio there. All are guarded by [ -d ].
DIRS="\
/system/media/audio/ui /system/media/audio \
/system/product/media/audio/ui /system/product/media/audio \
/product/media/audio/ui /product/media/audio \
/system/system_ext/media/audio/ui /system/system_ext/media/audio \
/system_ext/media/audio/ui /system_ext/media/audio \
/system/vendor/media/audio/ui /system/vendor/media/audio \
/vendor/media/audio/ui /vendor/media/audio \
/odm/media/audio/ui /odm/media/audio \
/system/odm/media/audio/ui /system/odm/media/audio"

ui_print "- Scanning for shutter/screenshot sound files"
found=0
for d in $DIRS; do
  [ -d "$d" ] || continue
  # Map the real dir to the module's overlay path.
  case "$d" in
    /system/*)     mp="system/${d#/system/}" ;;
    /product/*)    mp="system/product/${d#/product/}" ;;
    /system_ext/*) mp="system/system_ext/${d#/system_ext/}" ;;
    /vendor/*)     mp="system/vendor/${d#/vendor/}" ;;
    /odm/*)        mp="system/odm/${d#/odm/}" ;;
    *) continue ;;
  esac
  for s in $SOUNDS; do
    if [ -f "$d/$s" ]; then
      mkdir -p "$MODPATH/$mp"
      cp -f "$SILENT" "$MODPATH/$mp/$s" || abort "! failed to write overlay $mp/$s"
      ui_print "  overlay: $d/$s"
      found=$((found + 1))
    fi
  done
done

# Tidy: remove the source asset so it is not left in the live module tree.
rm -f "$SILENT"

if [ "$found" -eq 0 ]; then
  ui_print "! No known sound files found - your build may bake them into an APK."
  ui_print "! Run the diagnostic 'find' command and report back so we can target it."
else
  ui_print "- Silenced $found sound file(s). Reboot to apply."
  # Only meaningful when overlays were actually written.
  set_perm_recursive "$MODPATH/system" 0 0 0755 0644
fi
