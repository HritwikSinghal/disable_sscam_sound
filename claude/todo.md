# Todo -- Pixel Sound Expert

## Notes & Conventions

- Verify on-device by file SIZE, not the mount table: susfs scrubs module
  mounts from `mount`. silent.ogg is 3584 bytes; stock camera_click.ogg on
  Pixel 10a is 6401.
- Verify what an APP sees via `/proc/<app_pid>/root/<path>`, never a root shell
  (root is exempt from KernelSU module umount).
- Device: Pixel 10a, Android 17, KernelSU(-Next) + susfs + Hybrid Mount. USB
  adb is flaky -- reconnect with `adb wait-for-device`.
- Release = bump `version` + `versionCode`, add `## v<version>` to CHANGELOG.md,
  tag `v<version>`. CI refuses a tag that does not match module.prop.

## Open

- [ ] Confirm v2.5 upgrade over v2.4 on device removes `silence-shutter-screenshot` -- release-pipeline, awaiting user install, see workstreams/release-pipeline.md
- [ ] Silence without the per-app "Umount modules" toggle on hiding setups (susfs legit_mounts / add_sus_mount) -- shutter-silencing, research, see workstreams/shutter-silencing.md
- [ ] Retest susfs open_redirect on a kernel that honors CONFIG_KSU_SUSFS_OPEN_REDIRECT -- shutter-silencing, needs another device
- [ ] Test on plain Magisk, non-hiding KernelSU, and APatch (incl. `$KSU` unset on APatch so the hiding warning stays quiet) -- shutter-silencing + headphone-warning, needs devices
- [ ] Add more sound filenames to module/sound_paths.sh if reports find others -- shutter-silencing, waiting on user reports
- [ ] Generate silent.ogg in CI with ffmpeg instead of committing it -- release-pipeline, optional
