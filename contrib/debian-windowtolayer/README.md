# Debian/Ubuntu packaging for windowtolayer

Debian packaging for [`windowtolayer`](https://gitlab.freedesktop.org/mstoeckl/windowtolayer)
(GPL-3.0-or-later, Rust). Like the COPR package
([`contrib/rpm/windowtolayer.spec`](../rpm/windowtolayer.spec)), the packaging
lives in this repo — there is no windowtolayer fork — and the build **tracks
the latest upstream stable tag**, resolved at build time. The `.deb`s are
attached to this repo's GitHub Releases next to the swaylock-plugin ones (the
screensaver lockscreen setup needs both).

Unlike `contrib/debian/` (which is the swaylock-plugin `debian/` dir
verbatim), this directory nests the real packaging under `debian/` so the
`fetch-source.sh` helper can live beside it without leaking into the package.

## Building locally

    sudo apt install build-essential debhelper devscripts curl ca-certificates
    contrib/debian-windowtolayer/fetch-source.sh /tmp/wtl
    cd /tmp/wtl/windowtolayer-v*/
    sudo apt build-dep .        # or: mk-build-deps -i -r debian/control
    dpkg-buildpackage -us -uc -b

The `.deb` lands in `/tmp/wtl/`.

## Notes

* Upstream needs **rust >= 1.80** (`Cargo.toml` `rust-version`). Debian 13
  (1.85) and Ubuntu 25.10+ are fine; on Ubuntu 24.04 (default rust 1.75)
  install the archive's versioned toolchain and put it on PATH first, as
  `deb.yml` does:

      sudo apt install cargo-1.84
      export PATH=/usr/lib/rust-1.84/bin:$PATH

* The build runs `cargo build --release --locked`: the committed
  `Cargo.lock` pins the whole dependency tree (the RPM's `%cargo_*` macros
  do not vendor either); crates are fetched from crates.io at build time.
