#!/usr/bin/env bash
#
# Compute the next NuGet calver version for a GitHub Packages NuGet feed.
#
# Strategy:
#   - Base version is the current UTC date in Y.M.D form (no leading zeros; NuGet rejects them).
#   - If no package with that base exists yet, emit base. Otherwise emit base.<count>, where
#     <count> is the number of existing versions matching ^base(\.[0-9]+)?$.
#
# The script prints the computed version to stdout. It does NOT write to $GITHUB_OUTPUT;
# callers are expected to capture stdout and forward as appropriate, keeping this script
# usable outside GitHub Actions.
#
# Required environment:
#   GH_TOKEN - a GitHub token with read access to the target user/org's packages.
#
# Usage:
#   nuget_version.sh <owner> <owner_kind> <package_id>
#
#   owner      e.g. "rogurr" or "OpenDevicePartnership"
#   owner_kind one of "users" | "orgs"
#   package_id e.g. "Rogurr.OrionO6.SpiNorDebug"
#
# Examples:
#   GH_TOKEN=$TOKEN nuget_version.sh rogurr users Rogurr.OrionO6.SpiNorDebug
#
# SPDX-License-Identifier: MIT

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <owner> <owner_kind:users|orgs> <package_id>" >&2
  exit 2
fi

owner="$1"
owner_kind="$2"
package_id="$3"

case "$owner_kind" in
  users|orgs) ;;
  *) echo "owner_kind must be 'users' or 'orgs', got '$owner_kind'" >&2; exit 2;;
esac

base="$(date -u +%Y.%-m.%-d)"

# A 404 (first-ever publish) is a normal case, not an error. Swallow stderr and
# coerce the failure with `|| true` so `set -e` doesn't trip.
existing=$(gh api -H "Accept: application/vnd.github+json" \
             "/${owner_kind}/${owner}/packages/nuget/${package_id}/versions" \
             --jq '.[].name' 2>/dev/null || true)

count=$(printf '%s\n' "$existing" | grep -cE "^${base}(\.[0-9]+)?$" || true)

if [ "$count" -eq 0 ]; then
  version="${base}"
else
  version="${base}.${count}"
fi

echo "$version"
