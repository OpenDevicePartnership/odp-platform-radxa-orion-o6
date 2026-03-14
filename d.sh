#!/usr/bin/env bash
podman run --rm --interactive --tty --userns=keep-id --workdir /workspace --volume "$PWD:/workspace" odp-orion-o6 make
