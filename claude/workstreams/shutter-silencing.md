---
name: shutter-silencing
description: Camera shutter / screenshot sound silencing -- camera_click.ogg bind mount, post-fs-data.sh, KernelSU module hiding (Umount modules, susfs auto_try_umount, open_redirect), sound_paths.sh filenames
status: done (research backlog open)
---

# Shutter and screenshot silencing

Shipped and verified on Pixel 10a (Android 17). Mechanism and history:
docs/architecture.md ("Shutter and screenshot sound", "Module hiding").

## Verified facts

- Screenshot + shutter both play /product/media/audio/ui/camera_click.ogg via
  MediaActionSound; inotify trace showed it opened live per capture.
- v2.0 magic-mount missed /product on KernelSU 3.2.0; v2.1+ uses mount --bind.
- v2.1 was released on a false "verified" claim (checked from a root shell);
  System UI was still served the original because module hiding unmounts it.
  The v2.1 release + tag were deleted.
- Fix verified by ear + /proc/<systemui>/root size == 3584: turn off "Umount
  modules" for com.android.systemui only.
- susfs open_redirect: CONFIG flag present but no-op on the 10a kernel (tested
  on a plain file in isolation). Applied best-effort anyway (uid schemes 2/0/4).
- Per-app umount is not settable from a module: ksud has only the global
  `ksud feature set kernel_umount 0`; per-app state is /data/adb/ksu/.allowlist,
  written only by the manager.

## Open research

- Keep the bind from being umounted without the per-app toggle: susfs
  `legit_mounts.txt` / `ksu_susfs add_sus_mount`. Uncertain, susfs-specific.
- open_redirect on a kernel that honors it.
