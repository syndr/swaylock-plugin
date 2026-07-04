# 3. Build and release without a COPR API token

Status: Accepted — 2026-07-04

## Context

The first design had GitHub Actions build the SRPMs and submit them with
`copr-cli`. That requires a `COPR_API_TOKEN` secret, which:

- **expires every 180 days**, so releases silently break until it is rotated; and
- **authenticates as the whole Fedora account**, not scoped to one project.

We want per-tag releases, a pull-request build gate, and the fewest possible
long-lived secrets.

## Decision

Two layers, with **no COPR credential anywhere**:

**1. COPR builds the SRPM itself (SCM "make srpm").** Each package is configured
as source type *SCM*, method *`make srpm`*, clone url of this repo, plus a *Spec
File* field. COPR runs `make -f .copr/Makefile srpm outdir=<dir> spec=<path>`;
`.copr/Makefile` delegates to `contrib/rpm/make-srpm.sh`, which branches on the
spec basename (`git archive` for `swaylock-plugin`; latest-tag resolution for
`windowtolayer`). Builds are triggered by a **GitHub webhook on "Branch or tag
creation"** to the project's COPR integration URL.

**2. GitHub Actions handles CI and tagging with only the ephemeral
`GITHUB_TOKEN`.**

- `ci.yml` on `pull_request`: in a `fedora:44` container, build both SRPMs
  through the real `make -f .copr/Makefile srpm` entry point and full-build the
  `swaylock-plugin` RPM. No publish, no secret.
- `release.yml` on `push: main`: if `meson.build`'s version is new and higher,
  push the `vX.Y.Z` tag (see
  [ADR-0004](0004-fork-versioning-and-release-safety.md)). A tag pushed by
  `GITHUB_TOKEN` does not re-trigger Actions but **does** reach the COPR webhook.

## Consequences

- No expiring or account-wide secret; triggering and provenance come from git.
- The `make srpm` step runs in COPR's SRPM phase, which has network — that is
  where `make-srpm.sh` fetches windowtolayer's tarball. The separate "internet
  during builds" chroot toggle stays **off**; RPM builds resolve dependencies
  from the Fedora repos.
- COPR builds the **pushed tag ref** (confirmed by a live smoke-test), so the
  version guard in ADR-0004 sees the tag.
- The webhook also fires on **branch** creation — GitHub cannot narrow the event
  to tags only — but ADR-0004's snapshot rule makes such a build harmless.
- The same script runs in COPR's mock and locally
  (`make -f .copr/Makefile srpm outdir=/tmp spec=…`), so packaging is testable
  without COPR.

## Rejected alternatives

- **`copr-cli` from Actions** with a `COPR_API_TOKEN` — the 180-day expiry and
  account-wide scope this ADR exists to avoid.
- **Pinning the built ref with COPR's `committish`** — COPR's precedence of
  `committish` versus the webhook payload ref is undocumented, so it is not a
  dependable safety lever. Setting it to `main` is fine as a default for the
  manual "Rebuild" button, but the real guarantee is ADR-0004's snapshot rule.
