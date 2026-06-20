#!/usr/bin/env bash
# Generate update.json for KernelSU(-Next) / Magisk / APatch in-app auto-update.
#
# The manager fetches the URL in module.prop's `updateJson` field, compares the
# `versionCode` to the installed one, and offers to download+flash `zipUrl` when
# it is higher. We publish this file as a release asset, and module.prop points
# updateJson at .../releases/latest/download/update.json -- so the manager always
# reads the newest release's metadata with no commit-back to the repo.
#
# Usage: scripts/gen-update-json.sh [tag] [out-file]
#   tag:      release tag, e.g. v2.3 (default: v<version-from-module.prop>)
#   out-file: output path (default: dist/update.json)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROP="$ROOT/module/module.prop"
REPO="HritwikSinghal/disable_sscam_sound"
BRANCH="master"

VERSION="$(grep -E '^version=' "$PROP" | cut -d= -f2)"
VERSIONCODE="$(grep -E '^versionCode=' "$PROP" | cut -d= -f2)"
[ -n "$VERSION" ] && [ -n "$VERSIONCODE" ] || { echo "ERROR: version/versionCode missing in module.prop" >&2; exit 1; }

TAG="${1:-v$VERSION}"
OUT="${2:-$ROOT/dist/update.json}"

# The zip asset lives under the release tag and is named by version (build.sh).
# Warn (do not fail) if the tag does not match the module version, since the zip
# URL embeds both and they must line up for the download to resolve.
if [ "$TAG" != "v$VERSION" ]; then
  echo "WARNING: tag '$TAG' != 'v$VERSION' (module.prop version); zipUrl may 404" >&2
fi

ZIP_URL="https://github.com/$REPO/releases/download/$TAG/disable_sscam_sound-${VERSION}.zip"
CHANGELOG_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/CHANGELOG.md"

mkdir -p "$(dirname "$OUT")"
cat > "$OUT" <<EOF
{
  "version": "v$VERSION",
  "versionCode": $VERSIONCODE,
  "zipUrl": "$ZIP_URL",
  "changelog": "$CHANGELOG_URL"
}
EOF

echo "Wrote $OUT:"
cat "$OUT"
