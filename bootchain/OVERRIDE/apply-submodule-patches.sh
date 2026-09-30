#!/usr/bin/env bash
#
# Applies bootchain-only fixups on top of the upstream submodule commits.
#
# bootchain-submodule.patch carries fixes (e.g. GCC 15.2.rel1 warning/error
# fixes) that used to live in private forks of the Trusted_Execution_Environment
# and cix-edk2-platforms submodules. The submodules now point at the upstream
# repositories, so this script verifies each submodule is still checked out at
# the exact commit the patch was generated against, then applies the patch to
# the working tree if it hasn't been applied yet.
#
# SPDX-License-Identifier: MIT
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
PATCH_FILE="$SCRIPT_DIR/bootchain-submodule.patch"

# Submodule path (relative to REPO_ROOT) -> commit the patch was generated against.
declare -A SUBMODULE_BASE_COMMITS=(
	[bootchain/modules/tee/op-tee-cix-odp]=cc66640f3815da4defc50f72b66ae3bac97cd48a
	[common/cix-edk2-platforms]=1a48c6523a3225f3ef01b1c91eb3e3dc0dd1857f
)

if [[ ! -f "$PATCH_FILE" ]]; then
	echo "error: patch file not found: $PATCH_FILE" >&2
	exit 1
fi

for submodule_path in "${!SUBMODULE_BASE_COMMITS[@]}"; do
	expected_commit="${SUBMODULE_BASE_COMMITS[$submodule_path]}"
	submodule_dir="$REPO_ROOT/$submodule_path"

	if [[ ! -d "$submodule_dir" ]] || ! git -C "$submodule_dir" rev-parse --git-dir >/dev/null 2>&1; then
		echo "error: submodule not initialized: $submodule_path" >&2
		echo "       run 'git submodule update --init -- $submodule_path' first" >&2
		exit 1
	fi

	actual_commit="$(git -C "$submodule_dir" rev-parse HEAD)"
	if [[ "$actual_commit" != "$expected_commit" ]]; then
		echo "error: $submodule_path is at commit $actual_commit," >&2
		echo "       but $PATCH_FILE was generated against $expected_commit." >&2
		echo "       Refusing to apply a bootchain-only patch to an unexpected tree." >&2
		exit 1
	fi
done

# Determine whether the patch still needs to be applied. A combined patch
# spanning multiple submodules is applied from the superproject root, since
# 'git apply' only needs matching file paths, not a single git repository.
if git -C "$REPO_ROOT" apply --check "$PATCH_FILE" 2>/dev/null; then
	echo "Applying $PATCH_FILE ..."
	git -C "$REPO_ROOT" apply "$PATCH_FILE"
	echo "Patch applied."
elif git -C "$REPO_ROOT" apply --reverse --check "$PATCH_FILE" 2>/dev/null; then
	echo "Patch already applied, nothing to do."
else
	echo "error: $PATCH_FILE does not apply cleanly to the current submodule trees." >&2
	echo "       The submodules may have local modifications that conflict with it." >&2
	exit 1
fi
