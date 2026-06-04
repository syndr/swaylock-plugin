#!/usr/bin/env bash
# =============================================================================
# contrib/build-env.sh
#
# Create a Fedora distrobox containing the toolchain needed to build
# swaylock-plugin. Intended for immutable / rpm-ostree hosts (Fedora Silverblue,
# Kinoite, Bazzite, ...) where layering build dependencies onto the base image
# is undesirable.
#
# This only provisions the *build environment*. Building and installing is done
# with the normal Meson workflow afterwards -- see the README "Installation"
# section. swaylock-plugin must be RUN on the host (PAM authenticates against
# your real login), so it is built against host-compatible libraries by matching
# the container's Fedora release to the host where possible.
#
# Idempotent: re-running reuses an existing container and just (re)installs deps.
#
# Environment overrides:
#   CONTAINER   distrobox name           (default: swaylock-build)
#   IMAGE       base image               (default: fedora-toolbox:<host ver, else 44>)
# =============================================================================
set -euo pipefail

CONTAINER="${CONTAINER:-swaylock-build}"

# Match the container's Fedora release to the host's when we can read it, so the
# resulting binary links against compatible libraries when run on the host.
host_ver=""
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    host_ver="$(. /etc/os-release 2>/dev/null && echo "${VERSION_ID:-}")"
fi
IMAGE="${IMAGE:-registry.fedoraproject.org/fedora-toolbox:${host_ver:-44}}"

if ! command -v distrobox >/dev/null 2>&1; then
    echo "error: distrobox is required (https://distrobox.it)" >&2
    exit 1
fi

echo "==> Creating build container '${CONTAINER}' from ${IMAGE}"
if ! distrobox list | awk '{print $3}' | grep -qx "${CONTAINER}"; then
    distrobox create --name "${CONTAINER}" --image "${IMAGE}" --yes
else
    echo "    container '${CONTAINER}' already exists -- reusing"
fi

echo "==> Installing swaylock-plugin build dependencies"
distrobox enter "${CONTAINER}" -- sudo dnf install -y \
    meson ninja-build gcc pkgconf-pkg-config \
    wayland-devel wayland-protocols-devel libxkbcommon-devel \
    cairo-devel gdk-pixbuf2-devel pam-devel systemd-devel \
    scdoc git

cat <<EOF

==> Build environment ready in distrobox '${CONTAINER}'.

Build and install (run from the repository root). On an immutable host, install
to a writable prefix such as ~/.local and place the PAM file separately:

    distrobox enter ${CONTAINER} -- meson setup build --prefix="\$HOME/.local"
    distrobox enter ${CONTAINER} -- ninja -C build
    distrobox enter ${CONTAINER} -- ninja -C build install
    sudo install -Dm644 pam/swaylock-plugin /etc/pam.d/swaylock-plugin

See the README "Installation" section for the full notes (sysconfdir, PAM, and
the /var/lib/xkb requirement for Xwayland-based plugins).
EOF
