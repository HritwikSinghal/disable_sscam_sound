# customize.sh - sourced by Magisk/KernelSU/APatch installer
# Overlays a short SILENT clip over every camera/screenshot UI sound that
# actually exists on this device, at the correct partition-mapped module path.

SKIPUNZIP=0
SILENT="$MODPATH/silent.ogg"

# UI sound filenames used for camera shutter, autofocus, video, and screenshot.
# camera_click.ogg is shared by the camera shutter AND the screenshot on Pixel.
SOUNDS="camera_click.ogg camera_focus.ogg VideoRecord.ogg VideoStop.ogg camera_shutter.ogg ScreenCapture.ogg Screenshot.ogg audio_end.ogg"

# Real partitions/dirs Pixel keeps UI audio in.
DIRS="/system/media/audio/ui /system/product/media/audio/ui /product/media/audio/ui /system/system_ext/media/audio/ui /system_ext/media/audio/ui /system/vendor/media/audio/ui /vendor/media/audio/ui"

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
    *) continue ;;
  esac
  for s in $SOUNDS; do
    if [ -f "$d/$s" ]; then
      mkdir -p "$MODPATH/$mp"
      cp -f "$SILENT" "$MODPATH/$mp/$s"
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
fi

set_perm_recursive "$MODPATH/system" 0 0 0755 0644
