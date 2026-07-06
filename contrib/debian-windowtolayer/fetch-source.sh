#!/usr/bin/env bash
# =============================================================================
# contrib/debian-windowtolayer/fetch-source.sh
#
# Deb-side mirror of contrib/rpm/make-srpm.sh's windowtolayer branch:
# track-latest — resolve the newest stable vX.Y.Z tag from the upstream
# GitLab repo at build time, download that tarball, unpack it into <workdir>,
# stage the debian/ dir next to this script into it, and align
# debian/changelog with the resolved version (the committed entry is only a
# fallback). Prints the prepared source directory on stdout.
#
#   Usage: fetch-source.sh <workdir>
#
# Needs: curl, tar, dpkg-dev (dpkg-parsechangelog), devscripts (dch).
# Used by .github/workflows/deb.yml and runnable locally.
# =============================================================================
set -euo pipefail

workdir="${1:?usage: fetch-source.sh <workdir>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

api="https://gitlab.freedesktop.org/api/v4/projects/mstoeckl%2Fwindowtolayer/repository/tags"
version="$(curl -sfL "${api}" \
    | grep -oE '"name":"v[0-9]+\.[0-9]+\.[0-9]+"' \
    | sed -E 's/.*"v([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' \
    | sort -V | tail -n1)"
[ -n "${version}" ] || { echo "could not resolve latest windowtolayer tag from ${api}" >&2; exit 1; }
echo "fetch-source.sh: windowtolayer track-latest -> v${version}" >&2

mkdir -p "${workdir}"
curl -sfL "https://gitlab.freedesktop.org/mstoeckl/windowtolayer/-/archive/v${version}/windowtolayer-v${version}.tar.gz" \
    | tar -xz -C "${workdir}"
src="${workdir}/windowtolayer-v${version}"
[ -d "${src}" ] || { echo "expected ${src} in upstream tarball" >&2; exit 1; }

cp -a "${here}/debian" "${src}/debian"

current="$(dpkg-parsechangelog -l "${src}/debian/changelog" -S Version | sed -E 's/-[0-9]+$//')"
if [ "${version}" != "${current}" ]; then
    DEBEMAIL='syndr@ultroncore.net' DEBFULLNAME='syndr' \
        dch -c "${src}/debian/changelog" --newversion "${version}-1" --distribution unstable \
            "Track-latest build for upstream v${version} (entry generated at build time)."
fi

echo "${src}"
