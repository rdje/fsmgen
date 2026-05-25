# ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC: Output Bundle Meaning Truth Sync

## Metadata

- Tree ID: `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Clarify the public `output_bundle` wording after explicit member lists shipped:
unmembered bundles still describe the historical bound-rule driven output/LHS
intent, while explicit `(members ...)` lists are intentionally limited to
declared actor output ports.

## Non-Goals

- Do not change parser, lowerer, emitter, HDL, CLI, or report behavior.
- Do not widen explicit `output_bundle` members beyond declared actor outputs.
- Do not add output-target users, transaction users, named-drive users, route
  mux/storage, non-output members, or new resource arbiters.

## Acceptance Criteria

- ISF spec, public contract prose, downstream integration spec, mdBook, and
  live docs consistently describe the distinction between implicit
  output/LHS-target bundle intent and explicit declared-output members.
- The resource catalog remains behaviorally unchanged.
- Focused public-doc audits, mdBook build, and `git diff --check` pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC`
  Status: `done`
  Goal: `Sync output_bundle public wording after member-list shipment`
  Children: `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.1`

- ID: `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Clarify output_bundle implicit versus explicit member semantics`
  Acceptance: `Public docs distinguish unmembered output/LHS-target bundle
  intent from explicit declared-output members, and no behavior-bearing code
  changes are made`
  Verification: `focused public-doc audits, mdBook build, git diff check`
  Commit: `fe177b50 ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.1: sync output bundle wording`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `The documentation truth-sync slice is ready for commit.` |

## Decisions

- `2026-05-23`: Keep `FSM::Support::ISFResourceCatalog` unchanged because its
  `output_bundle` meaning still matches the shipped unmembered behavior:
  priority grants gate whole bound rule DTs, whose assignments may include
  actor outputs or other LHS targets.
- `2026-05-23`: Clarify that explicit `(members output...)` is narrower than
  the historical implicit bundle surface. It is a declared-output validation
  and reporting surface, not a new routing or storage-ownership surface.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.1` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t` | `passed: Files=6, Tests=347` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.1` | `mdbook build docs/book` | `passed` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.1` | `rg -n "group of actor outputs with rule users|named bundle of actor outputs for rule users|ownership of a group of actor outputs for rule users|currently represents the named bundle through" docs/...` | `passed: no stale wording` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.1` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.1` | `fe177b50 ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.1: sync output bundle wording` | `documentation truth-sync slice` |

## Changelog

- `2026-05-23`: Created and completed the documentation truth-sync task tree.
