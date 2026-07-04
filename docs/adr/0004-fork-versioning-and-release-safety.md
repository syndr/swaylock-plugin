# 4. Version the fork distinctly and keep non-release builds from shipping

Status: Accepted — 2026-07-04

## Context

`meson.build`'s `project(version:)` is the natural source of truth for the RPM
`Version`, but two problems complicate turning it into safe releases:

- **The upstream tag is in the way.** `v1.8.6` already exists on `origin`,
  pointing at an upstream commit; this fork adds commits on top *without*
  bumping the version. Releasing "1.8.6" would collide with that tag.
- **RPM `Version` cannot contain `-`.** A semver-style `1.8.6-syndr` trailer is
  invalid, so fork provenance has to live in `Release`, not `Version`.
- **Non-release builds can clobber a release.** The webhook fires on any
  tag/branch creation, and COPR's "Rebuild" button builds the default branch.
  Any such build would otherwise produce the *same* NVR as a published release,
  and because COPR serves the latest build for a given NVR, it would silently
  replace the real package.

## Decision

- **Version** = `meson.build`'s `project(version:)`. The fork advances on a
  **four-part line (`1.8.6.N`)** so it never collides with upstream's three-part
  `vX.Y.Z` tags. First fork release: **`1.8.6.1`**.
- **Provenance** = a **`.syndr` marker in `Release`** (`swaylock-plugin` only;
  `windowtolayer` stays clean upstream). Release NVR:
  `swaylock-plugin-1.8.6.1-1.syndr.fc44`.
- **Release vs snapshot**, decided in `make-srpm.sh`:
  - HEAD is an exact `vX.Y.Z` tag matching `meson.build` → `Release: 1` — the
    release.
  - A tag is present but does **not** match `meson.build` → **hard fail**.
  - Any **non-tag** build → `Release: 0.<utc>.g<sha>`, which sorts **below**
    `-1`.
- `release.yml` pushes a tag **only** when `meson.build`'s version is new and
  strictly greater than the highest existing tag.

## Consequences

- A non-release build (branch creation, manual "Rebuild", PR CI) can never
  overwrite or upgrade a published NVR — it sorts below the release and `dnf`
  never offers it as an update.
- To cut a release you **must** bump `meson.build` to an untagged, higher
  version; a merge that does not bump produces no tag and no publish.
- The fork's version line is unambiguous against upstream, and the `.syndr`
  marker signals a downstream build.
- Verified in a `fedora-toolbox:44` distrobox (release → `…-1.syndr`, snapshot →
  `…-0.<snap>.syndr`, ordering confirmed) and in a live COPR smoke-test: a
  throwaway non-version tag failed `swaylock-plugin` exactly on the version
  guard while `windowtolayer` built and published.
