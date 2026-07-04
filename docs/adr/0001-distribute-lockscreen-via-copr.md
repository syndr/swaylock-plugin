# 1. Distribute the lockscreen packages via COPR

Status: Accepted — 2026-07-04

## Context

The [`phalanx`][phalanx] hyprland image needs `swaylock-plugin` (this fork) and
[`windowtolayer`][wtl] to provide an xscreensaver-style lockscreen. Two facts
shape how we deliver them:

- **Neither is in Fedora's official repositories**, so there is nothing to
  `dnf install` today.
- The consuming host/image is an **immutable, `rpm-ostree`-based Fedora 44**
  (x86_64). The clean way to add software there is to layer prebuilt, signed
  RPMs from a repository — not to build on the host.

It must be built from **this fork's `main`**, which carries fixes the lockscreen
depends on and that are not upstream:

- `SIGCHLD` reset in spawned plugins — without it, Xwayland's `waitpid()` for
  `xkbcomp` returns `ECHILD` and the hack background never starts.
- multi-output use-after-free crash fix (`--command-each` on N monitors).
- `__DATE__` version-string fix.

## Decision

Publish Fedora RPMs to a **COPR project `syndr/swaylock-plugin`** holding **two
packages** (`swaylock-plugin` and `windowtolayer`). Target chroot
**`fedora-44-x86_64`**; `fedora-44-aarch64` is enabled opportunistically (it
builds cleanly) but no consumer requires it yet. Consumers enable the repo
anonymously with `dnf copr enable syndr/swaylock-plugin`; only the project owner
needs a (free) Fedora account.

## Consequences

- COPR builds in clean chroots, signs packages, and serves repodata — no
  self-hosted build or repo infrastructure.
- Builds come from the fork's `main`, so the required fixes are always present.
  How the fork's version is distinguished from upstream is [ADR-0004](0004-fork-versioning-and-release-safety.md).
- Delivery is tied to Fedora 44; supporting another release means adding chroots.
- If the fixes are ever upstreamed, revisit whether to keep packaging from the
  fork or from a tagged upstream release.

[phalanx]: https://github.com/syndr/phalanx
[wtl]: https://gitlab.freedesktop.org/mstoeckl/windowtolayer
