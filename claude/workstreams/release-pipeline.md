---
name: release-pipeline
description: CI and releases -- GitHub Actions ci.yml / release.yml, shellcheck lint, update.json in-app auto-update (updateJson), version bump, rename to Pixel Sound Expert / module id migration
status: active
---

# CI, releases and auto-update

- ci.yml: lint (scripts/lint.sh shellcheck + actionlint), validate, build,
  upload artifact. release.yml calls ci.yml, then checks tag == v<version>,
  builds, generates update.json, publishes with the CHANGELOG section as notes.
- Auto-update (v2.3+): module.prop `updateJson` ->
  releases/latest/download/update.json, uploaded per release. Verified on v2.3
  and v2.4.

## v2.5 rename (2026-10-23)

- Module id `silence-shutter-screenshot` -> `pixel-sound-expert`, name
  "Pixel Sound Expert", repo renamed to HritwikSinghal/pixel-sound-expert,
  license MIT -> GPL-3.0, README rewritten (detail moved to docs/architecture.md).
- customize.sh touches /data/adb/modules/silence-shutter-screenshot/remove so an
  update from v2.4 does not leave both modules installed.
- v2.4 installs auto-update through GitHub's redirect from the old repo URL.
- Open: user to install v2.5 over v2.4 and confirm the old module is removed.
