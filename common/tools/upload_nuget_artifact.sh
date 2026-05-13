#!/usr/bin/env bash
#
# Helper to publish build outputs to a GitHub Packages NuGet feed. 
#
# SPDX-License-Identifier: MIT
#
# The packages will use a version based on the date in Y.M.D form (e.g. 2026.5.12) without leading zeros due to NuGet
# restrictions. If a package with a version already exists, `.(n)` is appended where (n) is the count of existing
# same-day versions.
#
#   first published today  -> 2026.5.12
#   second published today -> 2026.5.12.1
#   third published today  -> 2026.5.12.2
#
# Usage:
#   upload_nuget_artifact.sh \
#     --package-id <NuGet.Package.Id> \
#     --description "<one-line description>" \
#     --input_dir "<absolute path to directory of files to package>" \
#     --output_dir "<absolute path to directory where .nupkg will be written>"
#

set -euo pipefail

# ----- Argument parsing ----------------------------------------------------------------------------------------------

package_id=""
description=""
input_dir=""
output_dir=""

usage() {
  cat >&2 <<'EOF'
usage: upload_nuget_artifact.sh \
         --package-id <NuGet.Package.Id> \
         --description "<one-line description>" \
         --input_dir "<absolute path to directory of files to package>" \
         --output_dir "<absolute path to directory where .nupkg will be written>"

Requires GH_TOKEN in the environment. See the file header for full documentation.
EOF
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --package-id)   package_id="$2";   shift 2;;
    --description)  description="$2";  shift 2;;
    --input_dir)    input_dir="$2";    shift 2;;
    --output_dir)   output_dir="$2";   shift 2;;
    -h|--help)      usage;;
    *)              echo "unknown argument: $1" >&2; usage;;
  esac
done

for var in package_id description input_dir output_dir; do
  if [ -z "${!var}" ]; then
    echo "missing required --${var//_/-}" >&2
    usage
  fi
done

if [ -z "${GH_TOKEN:-}" ]; then
  echo "GH_TOKEN environment variable is required" >&2
  exit 2
fi

if [ ! -d "$input_dir" ]; then
  echo "input directory not found: $input_dir" >&2
  exit 2
fi

# ----- Version string ------------------------------------------------------------------------------------------------

# Date in NuGet-friendly form (no leading zeros on month or day).
base="$(date -u +%Y.%-m.%-d)"

# Get number of existing versions
# TODO: rogurr namespace. Revert to opendevicepartnership before merging to upstream.
existing=$(gh api -H "Accept: application/vnd.github+json" \
             "/users/rogurr/packages/nuget/${package_id}/versions" \
             --jq '.[].name' 2>/dev/null || true)
count=$(printf '%s\n' "$existing" | grep -cE "^${base}(\.[0-9]+)?$" || true)

# Append count suffix if a version with today's date already exists.
if [ "$count" -eq 0 ]; then
  version="${base}"
else
  version="${base}.${count}"
fi

# ----- Create package ------------------------------------------------------------------------------------------------

mkdir -p "$output_dir"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dotnet pack "${script_dir}/nuget_release_project.csproj" \
  -p:PackageId="${package_id}" \
  -p:Version="${version}" \
  -p:Description="${description}" \
  -p:PayloadPath="${input_dir}" \
  -o "${output_dir}" >&2

# ----- Push package to NuGet feed ------------------------------------------------------------------------------------

# TODO: rogurr namespace. Revert source to opendevicepartnership before merging to upstream.
dotnet nuget push "${output_dir}/${package_id}.${version}.nupkg" \
  --source "https://nuget.pkg.github.com/rogurr/index.json" \
  --api-key "${GH_TOKEN}" \
  --skip-duplicate >&2

# ----- Output Status -------------------------------------------------------------------------------------------------

cat >&2 <<EOF
Nuget package published successfully:
  Package ID:  ${package_id}
  Version:     ${version}
  Description: ${description}
  Input Dir:   ${input_dir}
  Output Dir:  ${output_dir}
EOF
