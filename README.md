# ODP Platform — Radxa Orion O6

This repository is designed to be a demonstration of the Open Device Partnership firmware and software solutions.  It is based on a modified community version of the [CIX P1 BIOS](https://github.com/cixtech/bios) that boots the Radxa Orion O6 hardware and includes features and optimizations from the ODP organization.

## Folder Structure and Content

The repository contains all resources necessary to produce a firmware binary image and an OS image that can be used to boot the platform.  The top-level directories are as follows:

- Dot-prefixed (`.devcontainer/`, `.github/`, etc.) - Infrastructure and tooling for the development environment, CI/CD pipelines, etc.  No code that is part of the final images will reside in these folders.

- `common/` - Tools, documentation, and code files shared by one or more of the folders that produce artifacts.

- `docs` - Detailed documentation specific to this repository intended to supplement any common documentation.

- `bin-???` - Directories prefixed with `bin-` produce a single binary artifact that will be used when creating the final firmware binary image.  None will link code from another bin directory, but may link code in a common directory or require an artifact from a bin directory.

- `image-???` - Directories prefixed with `image-` contain scripts and resources to stitch artifacts into final images that can be used to boot the system.

## Quick Start - Building

This is a demonstration repository that has a single configuration, but does support DEBUG and RELEASE targets.  The simplest way to pull the code and compile is to follow the flow used by the CI/CD GitHub action in a Linux container.  For other options, please refer to the [Build Details](https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6/blob/main/docs/build_details.md) document.

1) If building in Windows, install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) and open a command window to provide a Linux environment.  If building in Linux, skip to step 2.

   Note:  The WSL file system can be accessed from Windows by using the path `\\wsl.localhost\...` and the Windows drives can be accessed from WSL by using the path `/mnt/<drive letter>/...`.  But every access across that boundary has delays that can add significant time to the build.  It is highly recommended to clone and build within WSL then use those paths when copying build remnants.

2) Clone this repository making sure to pull all submodule code and switch to the root of the directory.

   ``` bash
   git clone --recurse-submodules https://github.com/OpenDevicePartnership/odp-platform-radxa-orion-o6.git
   cd odp-platform-radxa-orion-o6
   ```

3) Install a container manager to build and run the development container.  [Docker](https://www.docker.com/get-started/) is typically used in corporate environments, but [Podman](https://podman.io/) is an open source manager that is a little simpler to get started with and what this demonstration is using.

4) Build the container using the data in the .devcontainer directory.  Note the use of the `.` at the end of the command.

   ``` bash
   podman build \
      --tag odp-orion-o6 \
      --file .devcontainer/Dockerfile \
      --build-arg USERNAME=$(whoami) \
      .
   ```

5) Start the container in detached mode so that it is waiting for an execute command and its workspace is mapped to the current directory.  Note that the Dockerfile configured the container to sleep infinitely waiting for an exec command by default.

   ``` bash
   podman run \
      --detach \
      --name odp-build \
      --userns=keep-id \
      --workdir /workspace \
      --volume "$PWD:/workspace" \
      odp-orion-o6
   ```

   The above command assigns the name `odp-build` so that the next time you want to start the container (for instance after a reboot), you only need to execute the following without having to build it again:

   ``` bash
   podman start odp-build 
   ```

6) Use the container exec command to execute `make` within the container. The first compilation may take a while to download and build all tools, but the container volume is kept by Podman so the next build will be significantly faster.

   ``` bash
   podman exec -it odp-build make
   ```

   The directory `Build/` will be created with all of the build remnants.  And the command line text `make` can be replaced with any command that is needed to be executed within the container.  For example, `make TARGET=RELEASE` will compile in release mode.

7) A reboot will automatically shutdown the container, but to force it down, `podman stop odp-build` can be executed to release resources.  Or to remove it entirely from Podman's cache, `podman rm odp-build` can be executed.

## Quick Start - Booting

**TBD**:  Need to document the final outputs from the build process and how to get them onto the platform
