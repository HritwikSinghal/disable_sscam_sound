# sound_paths.sh - shared lists, sourced by customize.sh (install time) and
# post-fs-data.sh (every boot). Keep these two lists the single source of truth
# so the install-time preview and the boot-time bind never drift apart.

# UI sound filenames to silence.
# camera_click.ogg is the framework shutter sound, played by
# android.media.MediaActionSound (SHUTTER_CLICK). On Pixel the screenshot uses
# the SAME MediaActionSound path, so silencing camera_click.ogg silences both
# the shutter and the screenshot. The rest are camera/video and OEM variants;
# every entry is guarded by [ -f ] so missing ones are safe no-ops.
SSCAM_SOUNDS="camera_click.ogg camera_focus.ogg VideoRecord.ogg VideoStop.ogg \
camera_click_short.ogg Shutter.ogg Shutter01.ogg camera_shutter.ogg \
ScreenCapture.ogg Screenshot.ogg"

# Real partitions/dirs modern Android keeps UI audio in. MediaActionSound reads
# /product/media/audio/ui first, then /system/product/..., then /system/...,
# so /product must be covered. Both the canonical .../media/audio/ui dir and
# the flatter .../media/audio dir are scanned, plus /odm. All guarded by [ -d ].
SSCAM_DIRS="\
/system/media/audio/ui /system/media/audio \
/system/product/media/audio/ui /system/product/media/audio \
/product/media/audio/ui /product/media/audio \
/system/system_ext/media/audio/ui /system/system_ext/media/audio \
/system_ext/media/audio/ui /system_ext/media/audio \
/system/vendor/media/audio/ui /system/vendor/media/audio \
/vendor/media/audio/ui /vendor/media/audio \
/odm/media/audio/ui /odm/media/audio \
/system/odm/media/audio/ui /system/odm/media/audio"
