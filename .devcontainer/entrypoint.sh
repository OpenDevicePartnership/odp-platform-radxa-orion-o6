#!/bin/bash
set -e

# Apply ACPICA patch if workspace is mounted
if [ -d "/workspace/uefi/tools/acpica" ]; then
    cd /workspace
    git submodule update --init --recursive 2>/dev/null \
        || echo "Warning: git submodule update --init --recursive failed; please run it manually to investigate."
    cd /workspace/uefi/tools/acpica
    git apply ../../../acpica.patch 2>/dev/null \
        || echo "Info: acpica.patch could not be applied (it may already be applied or the target files have changed)."
    cd /workspace
fi

# If a command is given, run it; otherwise check for a TTY
if [ $# -gt 0 ]; then
    exec "$@"
elif [ -t 0 ]; then
    # Interactive terminal available (e.g. docker run -it), start bash
    exec /bin/bash
else
    # No TTY (e.g. VS Code dev container), keep container alive
    exec sleep infinity
fi
