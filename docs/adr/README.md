# Architecture Decision Records

This directory records the significant decisions behind how this fork is
packaged and released as Fedora RPMs on COPR. The format is the
[Michael Nygard template][nygard] (Title · Status · Context · Decision ·
Consequences), one decision per record.

ADRs are **immutable**: to change a decision, add a new ADR that supersedes the
old one rather than rewriting history. The prose here explains *why*; for the
*how* (COPR setup, cutting a release, local testing) see
[`contrib/rpm/README.md`](../../contrib/rpm/README.md).

| ADR | Decision |
|-----|----------|
| [0001](0001-distribute-lockscreen-via-copr.md) | Distribute the lockscreen packages via COPR |
| [0002](0002-package-windowtolayer-tracking-upstream.md) | Package windowtolayer in-repo, tracking the latest upstream release |
| [0003](0003-tokenless-build-and-release-pipeline.md) | Build and release without a COPR API token |
| [0004](0004-fork-versioning-and-release-safety.md) | Version the fork distinctly and keep non-release builds from shipping |

[nygard]: https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
