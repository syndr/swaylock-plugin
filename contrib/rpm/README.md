# RPM packaging (COPR)

This directory packages **`swaylock-plugin`** (this fork) and
**`windowtolayer`** as Fedora 44 RPMs, published to the COPR project
**[`syndr/swaylock-plugin`][copr]**. This is the *how-to*; the *why* is in the
[Architecture Decision Records](../../docs/adr/).

```
contrib/rpm/
  swaylock-plugin.spec   # this fork; Version from meson.build, .syndr Release marker
  windowtolayer.spec     # upstream, track-latest (see below)
  make-srpm.sh           # SRPM generator; branches per spec
../../.copr/Makefile     # COPR "make srpm" entry point -> make-srpm.sh
../../.github/workflows/  # ci.yml (PR build gate), release.yml (auto-tag on bump)
```

## Install (consumers)

```sh
sudo dnf copr enable syndr/swaylock-plugin
sudo dnf install swaylock-plugin windowtolayer
```

`swaylock-plugin` ships PAM (`/etc/pam.d/swaylock-plugin`), both binaries, the
man page, shell completions, and the Xwayland wrapper at
`/usr/libexec/swaylock-plugin/example_xwayland_wrapper.py`. For the xscreensaver
lockscreen a consuming image must **also** install `xorg-x11-server-Xwayland`
and `xkbcomp`, and ensure `/var/lib/xkb` exists with mode `1777`.

## How releases work

`meson.build`'s `project(version:)` is the single source of truth, and the fork
releases on a four-part line (`1.8.6.N`) to stay clear of upstream's `vX.Y.Z`
tags (see [ADR-0004](../../docs/adr/0004-fork-versioning-and-release-safety.md)).

To cut a release:

1. Bump `project(version:)` in `meson.build` (e.g. `1.8.6.1` → `1.8.6.2`) in a PR.
2. Merge to `main`. `release.yml` sees the new, higher version and pushes tag
   `vX.Y.Z`.
3. The tag push fires the COPR webhook, which builds and publishes
   `swaylock-plugin-X.Y.Z-1.syndr` and refreshes `windowtolayer` to the newest
   upstream tag.

A merge that does **not** bump the version produces no tag and no release.
`windowtolayer` has no version of its own to bump here — it tracks upstream (see
[ADR-0002](../../docs/adr/0002-package-windowtolayer-tracking-upstream.md)); to
pick up an upstream release between `swaylock-plugin` releases, trigger a manual
COPR rebuild of the `windowtolayer` package.

## COPR project setup (one-time, owner)

1. Create project **`syndr/swaylock-plugin`**, chroot **`fedora-44-x86_64`**
   (add `fedora-44-aarch64` only if a consumer needs it).
2. Add **two packages**, both source type **SCM**, method **`make srpm`**,
   Auto-rebuild **on** — identical except the Spec File:

   | Field | `swaylock-plugin` | `windowtolayer` |
   |---|---|---|
   | Clone url | `https://github.com/syndr/swaylock-plugin` | *(same)* |
   | Committish / Subdirectory | *(blank)* | *(blank)* |
   | Build method | `make srpm` | `make srpm` |
   | Spec File | `contrib/rpm/swaylock-plugin.spec` | `contrib/rpm/windowtolayer.spec` |

3. **Leave "Enable internet access during builds" off** — dependencies resolve
   from Fedora repos; only the SRPM phase needs network, which it always has.
4. Project **Settings → Integrations**: copy the GitHub webhook URL.
5. On GitHub (repo **Settings → Webhooks → Add webhook**): payload URL from
   step 4, content type `application/json`, **"Let me select individual events"
   → Branch or tag creation** (untick Pushes). No secret token is used.

## Local testing

Both packages build through the exact COPR entry point, so you can validate a
change without COPR — ideally in a `fedora-toolbox:44` distrobox (see
[`contrib/build-env.sh`](../build-env.sh) for the toolchain):

```sh
make -f .copr/Makefile srpm outdir=/tmp/srpms spec=contrib/rpm/swaylock-plugin.spec
make -f .copr/Makefile srpm outdir=/tmp/srpms spec=contrib/rpm/windowtolayer.spec
rpmbuild --rebuild /tmp/srpms/swaylock-plugin-*.src.rpm
```

Off a tag, `swaylock-plugin` gets a snapshot `Release` (`0.<utc>.g<sha>`); on an
exact `vX.Y.Z` tag matching `meson.build` it gets `Release: 1`.

## Consumers

- Image: [`syndr/phalanx`][phalanx] — `dnf copr enable` + install into the
  hyprland image.
- Config: [`syndr/hyprland-wm-config`][cfg] — lock wiring; references the wrapper
  at `/usr/libexec/swaylock-plugin/example_xwayland_wrapper.py`.

[copr]: https://copr.fedorainfracloud.org/coprs/syndr/swaylock-plugin/
[phalanx]: https://github.com/syndr/phalanx
[cfg]: https://github.com/syndr/hyprland-wm-config
