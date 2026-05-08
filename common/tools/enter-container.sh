#!/bin/bash
# The following script builds an ODP development container image, starts it running, and enters it at an interactive
# bash prompt with the project root mapped to /workspace.  The container is configured to run with the user as host
# user, so file permissions, tools, and scripts should behave as expected to compile this repository's code.  It will
# also detect existing images and containers, so it is safe to run repeatedly.
#
# SPDX-License-Identifier: MIT
#

set -euo pipefail

# Configuration settings
IMAGE_NAME="odp-orion-o6"
CONTAINER_NAME="odp-orion-o6-build"
WORKSPACE_DIR="/workspace"
CONTAINER_TOOL_NAME="podman"

# Resolve the project root (two levels up from this script).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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

# Build the image if it does not exist
if ! image_exists; then
    echo "Building container image '${IMAGE_NAME}' ..."
    "${CONTAINER_TOOL_NAME}" build \
        --tag "${IMAGE_NAME}" \
        --file "${PROJECT_ROOT}/.devcontainer/Dockerfile" \
        --build-arg USERNAME="$(whoami)" \
        "${PROJECT_ROOT}"
fi

# If the container does not exist, create and run it
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

# If the container exists but is not running, start it
elif ! container_is_running; then
    echo "Starting existing container '${CONTAINER_NAME}' ..."
    "${CONTAINER_TOOL_NAME}" start "${CONTAINER_NAME}"
fi

# Enter the container at an interactive prompt
echo "Entering container '${CONTAINER_NAME}' ..."
exec "${CONTAINER_TOOL_NAME}" exec -it --workdir "${WORKSPACE_DIR}" "${CONTAINER_NAME}" /bin/bash
