# Changelog

This file is the changelog shown by the root manager's in-app updater (the
`changelog` URL in update.json points here). Newest first.

## v2.4

- Disable the headphone "high volume" warning and its automatic volume
  lowering. A new RRO overlay (system/product/overlay/NoSafeMediaVolume/) sets
  `config_safe_media_volume_enabled` and `config_safe_sound_dosage_enabled` to
  false, which turns off both sound dose (CSD) and the legacy safe-volume
  warning. Takes effect after a reboot.
- KernelSU: the overlay is mounted only through a metamodule (e.g. Hybrid
  Mount); the installer warns when none is present.
- No change to the shutter/screenshot silencing.

## v2.3

- Add in-app auto-update: module.prop now carries `updateJson`, and CI publishes
  an `update.json` release asset so KernelSU(-Next) / Magisk / APatch can update
  the module from within the manager once a newer release is published.
- No behavior change to the silencing itself vs v2.2.

## v2.2

- Add a best-effort susfs `add_open_redirect` layer alongside the bind mount.
- Installer now detects KernelSU module-hiding (Umount modules / susfs
  auto_try_umount) and prints the one-time per-app step (disable "Umount
  modules" for System UI), without which the overlay cannot reach System UI.
- Documented the full module-hiding root cause and fixes in the README.

## v2.1

- Replaced the magic-mount overlay with an explicit `mount --bind` in
  post-fs-data.sh (magic-mount did not reach the separate /product partition on
  KernelSU). Note: the v2.1 GitHub release was later removed as premature.

## v2.0

- Full rewrite of the broken 2019 module: real (non-empty) silent Ogg clip,
  adaptive multi-partition scan, and the modern install_module trampoline.
