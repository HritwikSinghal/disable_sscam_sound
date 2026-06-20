# Project Instructions & Learnings

Durable, project-specific instructions and learnings. Appended to over time (e.g. via /mem-add).

## Learnings

- A 0-byte silent.ogg crashes SystemUI and breaks screenshots on Android 13+; the clip must be a real short (~0.25s) Ogg/Vorbis file.
- On Pixel the camera shutter and the screenshot share the SAME sound file (camera_click.ogg), so silencing one silences both.
- Sound files live across multiple partitions (/system, /system/product, /product, /system_ext, /system/system_ext, /vendor), so the installer must scan all of them and overlay only what exists.
- The legacy /dev/magisk_img update-binary is dead since Magisk 19; use the modern install_module trampoline (Magisk 20.4+, KernelSU/APatch compatible).
- Some regional firmware bakes the shutter sound into an APK rather than a standalone Ogg, so plain file overlays cannot silence it on those builds.
