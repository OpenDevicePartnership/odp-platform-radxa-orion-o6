#!/bin/bash
# The following script builds an ODP development container image, starts it running, and enters it at an interactive
# bash prompt with the project root mapped to /workspace.  The container is configured to run with the user as host
# user, so file permissions, tools, and scripts should behave as expected to compile this repository's code.  It will
# also detect existing images and rebuild if outdated, so it is safe to run repeatedly.
#
# SPDX-License-Identifier: MIT
#

set -euo pipefail

# Configuration settings
IMAGE_NAME="odp-orion-o6"
CONTAINER_NAME="odp-orion-o6-build"
WORKSPACE_DIR="/workspace"
CONTAINER_TOOL_NAME="podman"
IMAGE_VERSION_LABEL="odp.image-version"

# Resolve the project root (two levels up from this script).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCKERFILE_PATH="${PROJECT_ROOT}/.devcontainer/Dockerfile"

# Detect if the image exists
image_exists() {
    "${CONTAINER_TOOL_NAME}" image exists "${IMAGE_NAME}" 2>/dev/null
}

# Detect if the container exists
container_exists() {
    "${CONTAINER_TOOL_NAME}" container exists "${CONTAINER_NAME}" 2>/dev/null
}

# Detect if the container is running
container_is_running() {
    [[ "$("${CONTAINER_TOOL_NAME}" inspect --format '{{.State.Status}}' "${CONTAINER_NAME}" 2>/dev/null)" == "running" ]]
}

# The expected version is declared in the Dockerfile using 'ARG ODP_IMAGE_VERSION='
expected_version() {
    sed -n 's/^ARG ODP_IMAGE_VERSION=\(.*\)$/\1/p' "${DOCKERFILE_PATH}" | head -n1
}

# The version baked into the existing local image's 'odp.image-version' label at the time it was built. Prints an
# empty string if the image does not exist.
image_version() {
    "${CONTAINER_TOOL_NAME}" inspect --format "{{ index .Config.Labels \"${IMAGE_VERSION_LABEL}\" }}" "${IMAGE_NAME}" 2>/dev/null || true
}

# Step 1: Verify a version was found in the Dockerfile
if [[ -z "$(expected_version)" ]]; then
    echo "Error: could not find 'ARG ODP_IMAGE_VERSION=' in ${DOCKERFILE_PATH}." >&2
    exit 1
fi

# Step 2: Remove the existing image if it's out of date. '--force' also removes any container still using it, so an
# outdated container never lingers alongside a fresh image.
if image_exists && [[ "$(image_version)" != "$(expected_version)" ]]; then
    echo "Removing outdated container image '${IMAGE_NAME}' (version $(image_version)) ..."
    "${CONTAINER_TOOL_NAME}" rmi --force "${IMAGE_NAME}"
fi

# Step 3: Build the image if it's missing
if ! image_exists; then
    echo "Building container image '${IMAGE_NAME}' (version $(expected_version)) ..."
    "${CONTAINER_TOOL_NAME}" build \
        --tag "${IMAGE_NAME}" \
        --file "${DOCKERFILE_PATH}" \
        --build-arg USERNAME="$(whoami)" \
        "${PROJECT_ROOT}"
fi

# Step 4: Create the container if it does not exist
if ! container_exists; then
    echo "Creating container '${CONTAINER_NAME}' ..."
    "${CONTAINER_TOOL_NAME}" run \
        --detach \
        --name "${CONTAINER_NAME}" \
        --userns=keep-id \
        --network=host \
        --workdir "${WORKSPACE_DIR}" \
        --volume "${PROJECT_ROOT}:${WORKSPACE_DIR}" \
        "${IMAGE_NAME}"
fi

# Step 5: Run the container - start it if stopped, then enter it at an interactive prompt
if ! container_is_running; then
    echo "Starting existing container '${CONTAINER_NAME}' ..."
    "${CONTAINER_TOOL_NAME}" start "${CONTAINER_NAME}"
fi
echo "Entering container '${CONTAINER_NAME}' ..."
exec "${CONTAINER_TOOL_NAME}" exec -it --workdir "${WORKSPACE_DIR}" "${CONTAINER_NAME}" /bin/bash
