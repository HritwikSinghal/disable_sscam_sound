# Project Instructions & Learnings

Durable, project-specific instructions and learnings. Appended to over time (e.g. via /mem-add).

## Learnings

- A 0-byte silent.ogg crashes SystemUI and breaks screenshots on Android 13+; the clip must be a real short (~0.25s) Ogg/Vorbis file.
- On Pixel the camera shutter and the screenshot share the SAME sound file (camera_click.ogg), so silencing one silences both.
- Sound files live across multiple partitions (/system, /system/product, /product, /system_ext, /system/system_ext, /vendor), so the installer must scan all of them and overlay only what exists.
- The legacy /dev/magisk_img update-binary is dead since Magisk 19; use the modern install_module trampoline (Magisk 20.4+, KernelSU/APatch compatible).
- Some regional firmware bakes the shutter sound into an APK rather than a standalone Ogg, so plain file overlays cannot silence it on those builds.
- KernelSU 3.2.0 magic-mount does NOT overlay the separate /product partition (verified on Pixel 10a, Android 17): /system overlays apply (e.g. bindhosts works), /product ones silently do not. v2.0 therefore installed cleanly but silenced nothing. Fix (v2.1): post-fs-data.sh does an explicit `mount --bind` of silent.ogg over each sound file every boot -- portable across Magisk/KernelSU/APatch.
- susfs scrubs module mounts from the `mount` table, so do NOT trust the mount list to tell whether an overlay applied -- check the live file's content/size instead (silent.ogg is 3584 bytes vs the original camera_click.ogg 6401 bytes on Pixel 10a).
- The screenshot sound on Pixel 10a / Android 17 is camera_click.ogg via MediaActionSound (SHUTTER_CLICK), read from /product/media/audio/ui/ first -- NOT baked into SystemUI.apk. The old "baked into APK on 13+" comment was wrong and has been corrected.
- Bind the clip after `chcon u:object_r:system_file:s0` so SystemUI can read it; without it the bound file keeps its /data/adb module context and may be denied.
