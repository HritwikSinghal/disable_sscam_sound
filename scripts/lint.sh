#!/usr/bin/env bash
# Shellcheck every script in the repo. Run locally and in CI.
# update-binary is the verbatim upstream Magisk trampoline, so it is not linted.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# module/ scripts run under Android's /system/bin/sh (mksh), so check as POSIX sh.
shellcheck -S warning -x -P module -s sh module/*.sh
shellcheck -S warning -x scripts/*.sh

echo "lint: OK"
