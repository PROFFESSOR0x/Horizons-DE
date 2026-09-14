# Install scripts for Ubuntu

This native Ubuntu path keeps Horizons off the experimental Nix fallback.

It enables the `universe` component, installs distro packages where Ubuntu
provides them, and adds the official Quickshell PPA used by upstream Quickshell
when the package is not already available from enabled apt sources.
