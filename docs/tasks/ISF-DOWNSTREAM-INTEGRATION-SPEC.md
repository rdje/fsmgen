# ISF-DOWNSTREAM-INTEGRATION-SPEC: Self-Contained ISF Integration Contract

## Metadata

- Tree ID: `ISF-DOWNSTREAM-INTEGRATION-SPEC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Publish one self-contained downstream integration specification for `.isf` so
SPECFORGE or another consumer can integrate against the current bounded public
surface without reconstructing behavior from the mdBook, implementation files,
public contract metadata, fixtures, and tests.

## Non-Goals

- Do not freeze the full future `.isf` language as an external standard.
- Do not change parser, scheduler, report, or HDL behavior in this tree.
- Do not replace the machine-readable `embedding.isf_public_interface`
  contract; the integration spec explains and packages that surface for human
  downstream implementers.
- Do not claim deferred constructs are shipped just because their syntax is
  brainstormed or parser-carried.

## Acceptance Criteria

- A single canonical document,
  [docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](../ISF_DOWNSTREAM_INTEGRATION_SPEC.md),
  describes current ISF readiness, source syntax, semantics, CLI/API entry
  points, lower-result and schedule-report surfaces, diagnostics, conformance
  fixtures, and deferred boundaries.
- The mdBook exposes that same canonical content without duplicating a second
  divergent copy.
- The downstream integration spec is registered in the public synchronization
  workflow and the machine-readable ISF public contract live-doc path list, so
  future downstream-visible ISF changes keep it synchronized with the live
  docs, book, tests, manifest metadata, and code.
- README, task-tree, roadmap, live recovery docs, changes, and engineering
  notes identify the downstream integration spec as the answer to the
  SPECFORGE integration gap.
- Focused documentation and public-contract checks pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DOWNSTREAM-INTEGRATION-SPEC`
  Status: `done`
  Goal: `Track the self-contained downstream ISF integration document.`
  Children: `ISF-DOWNSTREAM-INTEGRATION-SPEC.1`

- ID: `ISF-DOWNSTREAM-INTEGRATION-SPEC.1`
  Status: `done`
  Goal: `Publish the self-contained downstream integration spec.`
  Acceptance: `The canonical integration document is complete enough for a downstream consumer to understand the current bounded ISF surface, and the book/index/live docs point to it.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1120-isf-public-live-document-path-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DOWNSTREAM-INTEGRATION-SPEC.1: publish integration spec`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The requested downstream integration spec is published. |

## Decisions

- `2026-05-16`: A downstream consumer needs one canonical integration
  document. The existing `.isf` definition, implementation, public contract,
  tests, and book are real, but expecting SPECFORGE to reconstruct the surface
  from multiple artifacts is an integration blocker.
- `2026-05-16`: The canonical downstream document is
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`. The mdBook includes that file
  rather than maintaining a divergent copy.
- `2026-05-16`: The integration spec is authoritative for human downstream
  implementation guidance, while `embedding.isf_public_interface` remains the
  machine-readable discovery/check surface for key lists, return shapes, and
  tested provenance.
- `2026-05-16`: This slice is documentation packaging only. Behavior, accepted
  syntax, schedule-report shape, manifest metadata, and HDL output are
  unchanged.
- `2026-05-16`: The integration handoff is a mandatory sync target. Future
  downstream-visible ISF changes must keep it truthful with respect to the
  codebase, live spec, mdBook, public contract, manifest metadata, tests, and
  explicit deferrals.

## Open Questions

- None for this tree. Future grammar/schema generation should use a fresh
  task-tree owner if SPECFORGE needs machine-consumable EBNF or JSON Schema
  artifacts beyond the current integration document and manifest metadata.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DOWNSTREAM-INTEGRATION-SPEC.1` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1120-isf-public-live-document-path-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DOWNSTREAM-INTEGRATION-SPEC.1` | `ISF-DOWNSTREAM-INTEGRATION-SPEC.1: publish integration spec` | Published the single downstream integration contract and linked it into the book/live docs. |

## Changelog

- `2026-05-16`: Created and completed the tree with
  `ISF-DOWNSTREAM-INTEGRATION-SPEC.1`.
