# GitHub Support

This directory contains all files used by GitHub to manage and automate this repository.  Nothing here is part of a build artifact; everything supports repository operation, automation, or contributor experience.  See the individual .yml file headers for specific targeted information.

| Directory | Description |
| --- | --- |
| `<root>` | Repository-wide GitHub configuration files. |
| `workflows/` | GitHub Actions workflow definitions. |

## Workflows

The workflow files are grouped by purpose by using filenames that follow a `<group>_<target>.yml` convention:

| Group | Purpose |
| --- | --- |
| `build_*` | Compile the specific `<target>` and upload the result as a build artifact.  Triggered automatically on pull requests for CI validation and reusable by the publish workflows. |
| `publish_*` | Manually triggered release workflows that invoke the appropriate `build_*` workflows, then publish the resulting artifacts.  Gated by the `release` GitHub Environment and must be dispatched from a versioned Git tag of format `vYYYY.MM.DD` which is then used as the version it is published against. |
| `unit_tests_*` | Runs host-side unit tests, triggered automatically on pull requests for CI validation. |
