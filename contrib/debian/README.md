# Debian/Ubuntu packaging

Debian packaging for `swaylock-plugin`, mirroring the file set installed by
[`contrib/rpm/swaylock-plugin.spec`](../rpm/swaylock-plugin.spec): the two
binaries, `/etc/pam.d/swaylock-plugin` (a conffile), the man page, shell
completions, and `/usr/libexec/swaylock-plugin/example_xwayland_wrapper.py`.

There is no PPA or external build service. GitHub is the distribution
endpoint: `.github/workflows/deb.yml` builds the package inside Debian and
Ubuntu containers and, on release (called from `release.yml` right after the
version tag is pushed), attaches the `.deb` files to the GitHub Release with
a distro suffix in the file name, e.g.
`swaylock-plugin_1.8.6.1-1_amd64.ubuntu24.04.deb`. On pull requests the same
workflow uploads the `.deb`s as CI artifacts and gates on `lintian
--fail-on error`.

## Building locally

This directory is kept out of the source root (like `contrib/rpm`) so the
repo stays packaging-neutral; copy it into place first:

    cp -a contrib/debian debian
    sudo apt build-dep .        # or: mk-build-deps -i -r debian/control
    dpkg-buildpackage -us -uc -b

The `.deb` lands in the parent directory.

## Notes

* `meson.build` requires `wayland-protocols >= 1.47`; Debian 13 and
  Ubuntu 24.04 ship older versions, so `debian/rules` configures meson with
  `--wrap-mode=default` and `subprojects/wayland-protocols.wrap` provides a
  pinned fallback (downloaded at configure time, hash-verified). A
  new-enough system copy always wins over the wrap.
* The version comes from `debian/changelog`. `deb.yml` prepends a changelog
  entry automatically (via `dch`) whenever `meson.build`'s version is newer,
  so a version bump in `meson.build` is enough for a release — same
  single-source-of-truth rule as the RPM flow.
* `windowtolayer` (needed for X11 wallpaper programs) is packaged separately
  from [`contrib/debian-windowtolayer/`](../debian-windowtolayer/) and
  attached to the same GitHub Releases.
