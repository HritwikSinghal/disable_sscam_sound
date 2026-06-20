#!/usr/bin/env bash
# Sanity checks on the module source before packaging.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
M="$ROOT/module"
fail=0
err() { echo "FAIL: $*" >&2; fail=1; }

# Required files for a flashable module.
for f in module.prop META-INF/com/google/android/update-binary META-INF/com/google/android/updater-script customize.sh post-fs-data.sh sound_paths.sh silent.ogg; do
  [ -f "$M/$f" ] || err "missing $f"
done

# module.prop must have the required keys.
for k in id name version versionCode author description updateJson; do
  grep -qE "^$k=" "$M/module.prop" || err "module.prop missing key: $k"
done

# updateJson must be an https URL (the manager fetches it for in-app updates).
grep -qE '^updateJson=https://' "$M/module.prop" || err "updateJson must be an https:// URL"

# updater-script must be exactly the Magisk marker.
[ "$(tr -d '[:space:]' < "$M/META-INF/com/google/android/updater-script")" = "#MAGISK" ] \
  || err "updater-script must contain only '#MAGISK'"

# silent.ogg must be a real Ogg/Vorbis file, not a 0-byte placeholder
# (the 0-byte approach is exactly what broke the original module).
[ -s "$M/silent.ogg" ] || err "silent.ogg is empty (0-byte files crash SystemUI on modern Android)"
if command -v file >/dev/null; then
  file "$M/silent.ogg" | grep -qi 'ogg' || err "silent.ogg is not an Ogg file"
fi

# No CRLF line endings in shell/prop files (breaks the installer).
for f in module.prop customize.sh post-fs-data.sh sound_paths.sh META-INF/com/google/android/update-binary; do
  if grep -lq $'\r' "$M/$f" 2>/dev/null; then err "$f has CRLF line endings (must be LF)"; fi
done

# post-fs-data.sh must keep silent.ogg around to bind at boot -- a customize.sh
# that deletes the clip would leave the boot script with nothing to mount.
if grep -Eq '(^|[[:space:]])rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*"?\$?\{?MODPATH\}?/silent\.ogg' "$M/customize.sh" 2>/dev/null; then
  err "customize.sh deletes silent.ogg, but post-fs-data.sh needs it as the bind source"
fi

# The update.json generator must produce valid JSON (it feeds the in-app updater).
if [ -f "$ROOT/scripts/gen-update-json.sh" ]; then
  tmp="$(mktemp)"
  if bash "$ROOT/scripts/gen-update-json.sh" >/dev/null 2>&1 "" "$tmp"; then
    if command -v python3 >/dev/null; then
      python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$tmp" 2>/dev/null \
        || err "gen-update-json.sh produced invalid JSON"
    fi
  else
    err "gen-update-json.sh failed to run"
  fi
  rm -f "$tmp"
fi

if [ "$fail" -eq 0 ]; then echo "validate: OK"; else exit 1; fi
