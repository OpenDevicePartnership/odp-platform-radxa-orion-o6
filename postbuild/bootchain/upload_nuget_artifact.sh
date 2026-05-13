#!/usr/bin/env bash
#
# upload_nuget_artifact.sh
#
# End-to-end helper that publishes a directory of build outputs to a GitHub Packages NuGet
# feed as a single calver-versioned package. This is the script the bootchain CI workflows
# call after `make all` finishes; it does all three of "compute version", "pack nupkg", and
# "push to feed" so the workflow YAML stays a thin wrapper.
#
# It is also designed to be runnable locally for testing: with a personal access token in
# $GH_TOKEN you can invoke it from your laptop against any package you own.
#
# ---------------------------------------------------------------------------
# How NuGet packaging works at a glance
# ---------------------------------------------------------------------------
#
# A NuGet package (.nupkg) is a ZIP file with:
#   - a manifest (.nuspec) describing id/version/etc.
#   - a payload tree (lib/, content/, tools/, ...).
#
# We use `dotnet pack` (from the .NET SDK in the devcontainer image) to build the .nupkg.
# `dotnet pack` requires *a* project file as its anchor, so this repo ships a tiny shared
# csproj at postbuild/bootchain/bootchain.csproj that contains only the file-layout rules.
# Every per-package property (id, version, description, ...) is supplied at pack time via
# `-p:Key=Value` flags so the same csproj works for both debug and release packages.
#
# Once packed we push to https://nuget.pkg.github.com/<owner>/index.json with the GitHub
# token. `--skip-duplicate` makes re-runs on the same version a no-op rather than a failure.
#
# ---------------------------------------------------------------------------
# Versioning strategy (calver)
# ---------------------------------------------------------------------------
#
# Base version is the current UTC date in Y.M.D form (e.g. 2026.5.12). NuGet rejects
# leading zeros in numeric segments, so we use `%-m`/`%-d` (GNU date) to strip them.
#
# If a package with that base already exists for today, we append `.N` where N is the count
# of existing same-day versions. So:
#   first publish today  -> 2026.5.12
#   second publish today -> 2026.5.12.1
#   third publish today  -> 2026.5.12.2
#
# This keeps versions monotonic across same-day re-cuts without a separate sequence store.
#
# ---------------------------------------------------------------------------
# Required environment
# ---------------------------------------------------------------------------
#
#   GH_TOKEN   GitHub token with `read:packages` (to query versions) and `write:packages`
#              (to push the new .nupkg). Inside Actions, ${{ secrets.GITHUB_TOKEN }} works
#              when the workflow has `permissions: packages: write`.
#
# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
#
#   upload_nuget_artifact.sh \
#     --owner <user-or-org> \
#     --owner-kind <users|orgs> \
#     --package-id <NuGet.Package.Id> \
#     --description "<one-line description>" \
#     --repo-url <https://github.com/owner/repo> \
#     --payload <absolute path to dir of files to ship> \
#     [--csproj <path to shared csproj>] \
#     [--authors <name>] \
#     [--license <SPDX expression>] \
#     [--feed-url <NuGet feed URL>]
#
# Defaults:
#   --csproj    postbuild/bootchain/bootchain.csproj
#   --authors   <owner>
#   --license   MIT
#   --feed-url  https://nuget.pkg.github.com/<owner>/index.json
#
# Output: prints the published version to stdout on success. The workflow can capture this
# with `version=$(upload_nuget_artifact.sh ...)` and forward to $GITHUB_OUTPUT if needed.
#
# Example (CI):
#   upload_nuget_artifact.sh \
#     --owner rogurr --owner-kind users \
#     --package-id Rogurr.OrionO6.SpiNorDebug \
#     --description "Radxa Orion O6 debug bootchain SPI-NOR binaries." \
#     --repo-url https://github.com/rogurr/rg_orion-o6 \
#     --payload "$GITHUB_WORKSPACE/build/postbuild/bootchain"
#
# SPDX-License-Identifier: MIT

set -euo pipefail

# ----- Argument parsing ----------------------------------------------------

owner=""
owner_kind=""
package_id=""
description=""
repo_url=""
payload=""
csproj="postbuild/bootchain/bootchain.csproj"
authors=""
license="MIT"
feed_url=""

usage() {
  cat >&2 <<'EOF'
usage: upload_nuget_artifact.sh \
         --owner <user-or-org> \
         --owner-kind <users|orgs> \
         --package-id <NuGet.Package.Id> \
         --description "<one-line description>" \
         --repo-url <https://github.com/owner/repo> \
         --payload <absolute path to dir of files to ship> \
         [--csproj <path>] [--authors <name>] [--license <spdx>] [--feed-url <url>]

Requires GH_TOKEN in the environment. See the file header for full documentation.
EOF
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --owner)        owner="$2";        shift 2;;
    --owner-kind)   owner_kind="$2";   shift 2;;
    --package-id)   package_id="$2";   shift 2;;
    --description)  description="$2";  shift 2;;
    --repo-url)     repo_url="$2";     shift 2;;
    --payload)      payload="$2";      shift 2;;
    --csproj)       csproj="$2";       shift 2;;
    --authors)      authors="$2";      shift 2;;
    --license)      license="$2";      shift 2;;
    --feed-url)     feed_url="$2";     shift 2;;
    -h|--help)      usage;;
    *)              echo "unknown argument: $1" >&2; usage;;
  esac
done

for var in owner owner_kind package_id description repo_url payload; do
  if [ -z "${!var}" ]; then
    echo "missing required --${var//_/-}" >&2
    usage
  fi
done

case "$owner_kind" in
  users|orgs) ;;
  *) echo "--owner-kind must be 'users' or 'orgs', got '$owner_kind'" >&2; exit 2;;
esac

if [ -z "${GH_TOKEN:-}" ]; then
  echo "GH_TOKEN environment variable is required" >&2
  exit 2
fi

if [ ! -f "$csproj" ]; then
  echo "csproj not found: $csproj" >&2
  exit 2
fi

if [ ! -d "$payload" ]; then
  echo "payload directory not found: $payload" >&2
  exit 2
fi

[ -n "$authors"  ] || authors="$owner"
[ -n "$feed_url" ] || feed_url="https://nuget.pkg.github.com/${owner}/index.json"

# ----- Step 1: compute next calver version ---------------------------------
#
# Date in NuGet-friendly form (no leading zeros on month or day).
base="$(date -u +%Y.%-m.%-d)"

# Query existing versions. A 404 (first-ever publish) is normal, so we discard stderr and
# `|| true` to keep `set -e` happy. Output is a newline-separated list of version strings.
existing=$(gh api -H "Accept: application/vnd.github+json" \
             "/${owner_kind}/${owner}/packages/nuget/${package_id}/versions" \
             --jq '.[].name' 2>/dev/null || true)

# Count versions already published with today's base. -E enables extended regex; the regex
# matches `base` exactly OR `base.<digits>`. `|| true` swallows grep's exit-1 on zero matches.
count=$(printf '%s\n' "$existing" | grep -cE "^${base}(\.[0-9]+)?$" || true)

if [ "$count" -eq 0 ]; then
  version="${base}"
else
  version="${base}.${count}"
fi

echo "Computed NuGet version: ${version}" >&2

# ----- Step 2: pack the .nupkg ---------------------------------------------
#
# `dotnet pack` evaluates the shared csproj using the per-package metadata we pass via
# `-p:` (MSBuild property) flags. The csproj's <None Include="$(PayloadPath)/**/*"> rule
# pulls every file in the payload directory into the package's content/ folder.
#
# Output goes to ./nupkg-out which is created by `dotnet pack` if missing.
out_dir="nupkg-out"
mkdir -p "$out_dir"

dotnet pack "$csproj" \
  -p:PackageId="${package_id}" \
  -p:Version="${version}" \
  -p:Authors="${authors}" \
  -p:Description="${description}" \
  -p:RepositoryUrl="${repo_url}" \
  -p:PackageLicenseExpression="${license}" \
  -p:PayloadPath="${payload}" \
  -o "${out_dir}" >&2

# ----- Step 3: push to the GitHub Packages NuGet feed ----------------------
#
# `--skip-duplicate` turns "already exists" into a soft success so re-running the workflow
# on an unchanged commit doesn't fail.
dotnet nuget push "${out_dir}/*.nupkg" \
  --source "${feed_url}" \
  --api-key "${GH_TOKEN}" \
  --skip-duplicate >&2

# Final stdout: the version string, so callers can capture it.
echo "${version}"
