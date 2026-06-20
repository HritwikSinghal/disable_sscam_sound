#!/usr/bin/env bash
# Build the flashable Magisk/KernelSU/APatch module zip from module/.
# Usage: scripts/build.sh [output-dir]
# Output: <output-dir>/disable_sscam_sound-<version>.zip  (default output-dir: dist/)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_DIR="$ROOT/module"
OUT_DIR="${1:-$ROOT/dist}"

# Canonicalize OUT_DIR to an absolute path: the zip step cd's into module/ and a
# relative OUT_DIR (e.g. "dist", as CI passes) would then resolve under module/.
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

# Pull version from module.prop so the artifact name always matches metadata.
VERSION="$(grep -E '^version=' "$MODULE_DIR/module.prop" | cut -d= -f2)"
[ -n "$VERSION" ] || { echo "ERROR: no version= in module.prop" >&2; exit 1; }

ZIP="$OUT_DIR/disable_sscam_sound-${VERSION}.zip"
rm -f "$ZIP"

# zip from inside module/ so paths are at the archive root (required by installers).
( cd "$MODULE_DIR" && zip -r9 "$ZIP" . -x '.git*' >/dev/null )

echo "Built: $ZIP"
unzip -l "$ZIP"
