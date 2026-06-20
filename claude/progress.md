# Project: disable_sscam_sound
> Last updated: 2026-06-20 | Session: 3

## Overview
disable_sscam_sound is a flashable Magisk/KernelSU/APatch module that silences the camera shutter and screenshot sound on modern Android (especially Pixel) by overlaying a short silent Ogg clip over the system UI sound files. The original 2019 module was rewritten as v2 and is now SHIPPED as v2.2 (published GitHub Release, marked Latest). It is VERIFIED working on a Pixel 10a (Android 17, KernelSU-Next + susfs). Mechanism: post-fs-data.sh does `mount --bind` of silent.ogg over each found UI sound file every boot (plus a best-effort, here-ineffective susfs open_redirect). Core caveat: on KernelSU setups that HIDE modules from apps (Umount modules / susfs auto_try_umount), the overlay is unmounted from System UI and the sound keeps playing until the user disables "Umount modules" for System UI (one-time, persistent); customize.sh prints this at install. The agent CAN drive the device over adb this session (KernelSU root; USB is flaky -- reconnect with `adb wait-for-device`). Phases 1-4 are DONE; only optional enhancements (Phase 5) remain.

## Plan

### Phase 1: Module rewrite (v2) -- DONE
- [x] Diagnose why the original 2019 module fails on modern Pixel (0-byte ogg, single overlay path, legacy update-binary)
- [x] Generate a real ~0.25s silent Ogg/Vorbis clip (silent.ogg)
- [x] Write adaptive customize.sh that scans all partitions and overlays only existing sound files
- [x] Replace legacy update-binary with the modern install_module trampoline (Magisk 20.4+, KernelSU/APatch)
- [x] Write module.prop (id=silence-shutter-screenshot, v2.0)

### Phase 2: Tooling and CI -- DONE
- [x] scripts/build.sh -- build dist zip with version from module.prop
- [x] scripts/validate.sh -- sanity-check module source
- [x] .github/workflows/build.yml -- validate + build + upload artifact on push/PR
- [x] .github/workflows/release.yml -- publish zip to GitHub Release on v* tag

### Phase 3: Docs and repo hygiene -- DONE
- [x] README.md (install, how-it-works, diagnostics, legal note)
- [x] LICENSE (MIT)
- [x] CLAUDE.md + claude/ tracking files
- [x] .gitignore (dist/, result, editor noise)

### Phase 4: Device verification and release -- IN PROGRESS
- [x] Flash v2.0 on Pixel 10a (Android 17, KernelSU 3.2.0) and reboot
- [x] Diagnose v2.0/v2.1: magic-mount does not reach /product; bind does, BUT the deeper cause is module-hiding (KernelSU "Umount modules" + susfs auto_try_umount=1 + rezygisk) which unmounts ALL module overlays from non-root apps incl. System UI (proven: bindhosts also invisible to System UI). inotify trace confirmed the screenshot opens+reads /product/media/audio/ui/camera_click.ogg live each capture.
- [x] Ruled out susfs open_redirect: CONFIG flag present but NO-OP on this kernel (proven in isolation)
- [x] Ship v2.2: post-fs-data.sh does mount --bind + best-effort open_redirect; README documents the umount caveat and fixes
- [x] VERIFIED FIX (user ear test + /proc/<systemui>/root check == 3584): disable KernelSU "Umount modules" for com.android.systemui (per-app), reboot -> bind reaches System UI -> screenshot/shutter SILENT, hiding kept for other apps
- [x] Commit + push v2.2 (bind + best-effort open_redirect + install-time hiding warning in customize.sh, verified firing on-device)
- [x] Investigated auto-setting per-app umount: NOT feasible safely -- ksud has no per-app umount CLI (profile = root sepolicy/templates only); only the GLOBAL `ksud feature set kernel_umount 0` exists (weakens hiding for all apps). Per-app lives in /data/adb/ksu/.allowlist (manager GUI only); editing it from a module is unsupported/fragile. Decision: keep systemless + print one-time per-app instructions at install.
- [x] Deleted the prematurely-tagged v2.1 GitHub Release + tag (local+remote); v2.0 left as-is
- [x] Tagged + published v2.2 GitHub Release (release.yml green; disable_sscam_sound-2.2.zip attached, marked Latest)

### Phase 5: Optional enhancements -- BACKLOG (none required; project goal met)
- [ ] Research silencing WITHOUT the per-app toggle on hiding setups: susfs legit_mounts.txt / `ksu_susfs add_sus_mount` to keep our bind from being umounted, or another mechanism that survives umount. Uncertain; susfs-specific. (See "Why the sound may still play" in README.)
- [ ] Revisit susfs open_redirect on kernels that actually honor CONFIG_KSU_SUSFS_OPEN_REDIRECT (no-op on this Pixel 10a kernel; the module already applies it best-effort with uid schemes 2/0/4).
- [ ] Test on plain Magisk and on non-hiding KernelSU to confirm the bind silences with zero manual steps there.
- [x] Add updateJson URL to module.prop for in-app updates (v2.3): updateJson -> releases/latest/download/update.json; release.yml generates+uploads update.json (scripts/gen-update-json.sh) per tag; CHANGELOG.md added; validate.sh requires updateJson + JSON-checks the generator. RELEASED v2.3 (tag pushed, workflow green): release has both the zip and update.json; the latest/download/update.json URL resolves and its zipUrl returns HTTP 200. Auto-update works from v2.3 onward (v2.3 installed manually once, then future releases update in-app).
- [ ] Consider generating silent.ogg in CI (see tasks.md).

## Status Summary
| Phase | Status | Progress |
|-------|--------|----------|
| Phase 1: Module rewrite (v2) | Done | 5/5 |
| Phase 2: Tooling and CI | Done | 4/4 |
| Phase 3: Docs and repo hygiene | Done | 4/4 |
| Phase 4: Device verification and release | Done | 9/9 |
| Phase 5: Optional enhancements | Backlog | 0/4 |

## Decisions & Notes
<!-- Append entries as: YYYY-MM-DD: [decision or important note] -->
- 2026-06-20: Rewrote the broken 2019 module as v2. Root causes of the failure on modern Pixel were: (1) a 0-byte ogg file, which crashes SystemUI on Android 13+ rather than silencing the sound; (2) a single hardcoded overlay path that no longer matches where the sound files live; and (3) the dead /dev/magisk_img legacy update-binary, which modern Magisk/KernelSU/APatch no longer support. Chose an adaptive installer (customize.sh) that scans all partitions and overlays only the sound files that actually exist on the device. Added GitHub Actions for build (validate + build + upload artifact on push/PR) and release (publish the zip to a GitHub Release on a v* tag).
- 2026-06-20 (session 2): v2.0 installed on Pixel 10a but silenced nothing. Diagnosed via adb: KernelSU 3.2.0 magic-mount applies /system overlays (bindhosts works) but does NOT overlay the separate /product partition, so the camera_click.ogg overlay never took (live file stayed the original 6401 bytes; susfs also hides module mounts from `mount`, so verify by file size not mount list). Also confirmed the screenshot sound is camera_click.ogg via MediaActionSound (read from /product/media/audio/ui/ first), NOT baked into an APK as the old comments claimed. Fix = v2.1: dropped magic-mount; post-fs-data.sh now `mount --bind`s silent.ogg over each existing sound file every boot (after chcon to system_file), with SSCAM_SOUNDS/SSCAM_DIRS shared via sound_paths.sh. Verified the bind silences the screenshot live on-device before packaging. mount --bind is portable across Magisk/KernelSU/APatch.
- 2026-06-20 (session 3): v2.1 was released prematurely on a FALSE "verified" claim -- the bind reached root shells but NOT System UI. Real root cause: the module-hiding stack (KernelSU "Umount modules" + susfs auto_try_umount=1 + rezygisk) unmounts ALL module overlays from non-root apps incl. System UI; proven device-wide (bindhosts /system/etc/hosts also invisible to System UI). inotify trace confirmed the screenshot opens+reads camera_click.ogg live each capture. susfs open_redirect is a NO-OP on this kernel (proven in isolation: redirected a plain file, non-su read still original). VERIFY APP VISIBILITY via /proc/<app_pid>/root/<path>, NOT a root shell (root is exempt from umount). Verified fix: disable "Umount modules" for com.android.systemui (KernelSU-Next GUI), reboot -> System UI sees the 3584 clip -> silent (user ear test + /proc check). Per-app umount is NOT settable from a module (no ksud CLI; only global kernel_umount; .allowlist is GUI/kernel only). Shipped v2.2 (bind + best-effort open_redirect + install-time hiding warning). Deleted the broken v2.1 release+tag; published v2.2.

## Blockers
<!-- List any active blockers. Remove the line when resolved. -->
- None. Device (Pixel 10a) is reachable over adb with root this session.
