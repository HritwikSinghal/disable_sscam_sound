# Project: disable_sscam_sound
> Last updated: 2026-06-20 | Session: 1

## Overview
disable_sscam_sound is a flashable Magisk/KernelSU/APatch module that silences the camera shutter and screenshot sound on modern Android (especially Pixel) by overlaying a short silent Ogg clip over the system UI sound files. The original 2019 module no longer works on current Pixel devices, so it was rewritten as v2. The module source, build/validate scripts, CI workflows, README, and LICENSE are all written; what remains is verification on a real device and publishing the first release. The agent does not build, flash, or test on hardware -- the user deploys.

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

### Phase 4: Device verification and release -- PENDING
- [ ] Flash the built module on the target Pixel and reboot
- [ ] Confirm the screenshot sound is silenced
- [ ] Confirm the camera shutter sound is silenced
- [ ] If anything still plays, run the find diagnostic and extend the sound-file/partition lists in customize.sh
- [ ] Tag v2.0 and push to trigger the release workflow, verify the GitHub Release artifact

## Status Summary
| Phase | Status | Progress |
|-------|--------|----------|
| Phase 1: Module rewrite (v2) | Done | 5/5 |
| Phase 2: Tooling and CI | Done | 4/4 |
| Phase 3: Docs and repo hygiene | Done | 4/4 |
| Phase 4: Device verification and release | Pending | 0/5 |

## Decisions & Notes
<!-- Append entries as: YYYY-MM-DD: [decision or important note] -->
- 2026-06-20: Rewrote the broken 2019 module as v2. Root causes of the failure on modern Pixel were: (1) a 0-byte ogg file, which crashes SystemUI on Android 13+ rather than silencing the sound; (2) a single hardcoded overlay path that no longer matches where the sound files live; and (3) the dead /dev/magisk_img legacy update-binary, which modern Magisk/KernelSU/APatch no longer support. Chose an adaptive installer (customize.sh) that scans all partitions and overlays only the sound files that actually exist on the device. Added GitHub Actions for build (validate + build + upload artifact on push/PR) and release (publish the zip to a GitHub Release on a v* tag).

## Blockers
<!-- List any active blockers. Remove the line when resolved. -->
- Phase 4 requires a physical Pixel device. The user deploys/flashes and verifies on hardware -- the agent does not build, test, or flash here.
