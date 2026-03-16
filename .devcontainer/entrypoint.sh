#!/bin/bash
set -e

# If a command is given, run it; otherwise start bash
if [ $# -gt 0 ]; then
    exec "$@"
else
    exec /bin/bash
fi
