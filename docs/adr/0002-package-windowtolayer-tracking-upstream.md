# 2. Package windowtolayer in-repo, tracking the latest upstream release

Status: Accepted — 2026-07-04

## Context

[`windowtolayer`][wtl] is a **separate upstream project** (not a fork of ours)
that the lockscreen uses to run windowed programs — including X11 hacks via
Xwayland — as wallpaper surfaces. It is:

- **not in Fedora**, so it needs packaging;
- available in a third-party COPR (`sed4906/candela`), but [`phalanx`][phalanx]
  should depend on **only** `syndr/swaylock-plugin`, not a chain of COPRs;
- **pure Rust** (`arrayvec`, `lexopt`, `log`, `rustix`) whose crates all ship in
  the Fedora 44 repos as `rust-*-devel` packages;
- **unmodified by us** — we repackage upstream releases, we do not patch it.

## Decision

Keep `contrib/rpm/windowtolayer.spec` in this repository and publish it to the
**same COPR project**. **Track the newest stable upstream `vX.Y.Z` tag at build
time** — `contrib/rpm/make-srpm.sh` resolves it from the GitLab tags API and
injects it as the RPM `Version` — rather than pinning a version in the spec. Do
**not** fork windowtolayer's source unless we later need local patches.

## Consequences

- **Zero manual maintenance for upstream bumps:** every `swaylock-plugin`
  release rebuilds windowtolayer at whatever is newest upstream.
- **Reproducibility tradeoff:** an upstream change ships without an explicit
  per-release decision. Accepted — the package is small and shares an author
  with upstream swaylock.
- COPR cannot notice a new upstream release on its own: we cannot install a
  webhook on mstoeckl's GitLab, so windowtolayer refreshes when the next
  `swaylock-plugin` tag fires the webhook (see
  [ADR-0003](0003-tokenless-build-and-release-pipeline.md)). To pick up an
  upstream release sooner, trigger a manual COPR rebuild of the package.
- The dynamic crate `BuildRequires` resolve from the Fedora repos, so there is
  **no vendoring and no networked RPM build**.
- windowtolayer ships as **clean upstream** (no fork marker), unlike
  `swaylock-plugin` ([ADR-0004](0004-fork-versioning-and-release-safety.md)).

[phalanx]: https://github.com/syndr/phalanx
[wtl]: https://gitlab.freedesktop.org/mstoeckl/windowtolayer
