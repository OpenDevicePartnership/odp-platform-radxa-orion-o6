#!/bin/bash
set -e

# Apply ACPICA patch if workspace is mounted (skip if already done)
if [ -d "/workspace/uefi/tools/acpica" ] && [ ! -f /tmp/.entrypoint-init-done ]; then
    cd /workspace
    git submodule update --init --recursive 2>/dev/null \
        || echo "Warning: git submodule update --init --recursive failed; please run it manually to investigate."
    cd /workspace
    touch /tmp/.entrypoint-init-done
fi

# If a command is given, run it; otherwise start bash
if [ $# -gt 0 ]; then
    exec "$@"
else
    exec /bin/bash
fi
