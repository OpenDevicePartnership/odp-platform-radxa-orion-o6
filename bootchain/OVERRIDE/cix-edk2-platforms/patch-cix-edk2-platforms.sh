#!/usr/bin/env bash
#
# Verify the cix-edk2-platforms submodule revision and apply its bootchain fixups.
#
# SPDX-License-Identifier: MIT
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PATCH_FILE="$SCRIPT_DIR/cix-edk2-platforms.patch"

submodule_path=common/cix-edk2-platforms
expected_commit=1a48c6523a3225f3ef01b1c91eb3e3dc0dd1857f
submodule_dir="$REPO_ROOT/$submodule_path"

actual_commit="$(git -C "$submodule_dir" rev-parse HEAD)"
if [[ "$actual_commit" != "$expected_commit" ]]; then
	echo "error: $submodule_path is at commit $actual_commit, expected commit $expected_commit." >&2
	exit 1
fi

if git -C "$REPO_ROOT" apply --check "$PATCH_FILE" 2>/dev/null; then
	echo "Applying $PATCH_FILE ..."
	git -C "$REPO_ROOT" apply "$PATCH_FILE"
elif git -C "$REPO_ROOT" apply --reverse --check "$PATCH_FILE" 2>/dev/null; then
	echo "$PATCH_FILE already applied."
else
	echo "error: $PATCH_FILE does not apply cleanly, check for conflicts." >&2
	exit 1
fi
