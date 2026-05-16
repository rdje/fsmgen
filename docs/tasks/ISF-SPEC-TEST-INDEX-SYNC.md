# ISF-SPEC-TEST-INDEX-SYNC: ISF Spec Focused-Test Index Sync

## Metadata

- Tree ID: `ISF-SPEC-TEST-INDEX-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Keep the focused ISF test index in `docs/ISF_SPEC.md` synchronized with the
repo's `t/*-isf-*.t` regression files.

## Non-Goals

- Do not change parser, scheduler, report, generated `.fsm`, or HDL behavior.
- Do not reorganize the broader regression suite.
- Do not expand or freeze the whole schedule-report schema.

## Acceptance Criteria

- `docs/ISF_SPEC.md` lists every current `t/*-isf-*.t` regression.
- A focused audit prevents future ISF tests from being added without updating
  the spec's focused-test index.
- Focused validation passes.
- Live docs and roadmap/task-tree status are updated.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SPEC-TEST-INDEX-SYNC`
  Status: `done`
  Goal: `Synchronize and audit the ISF spec focused-test index`
  Children: `ISF-SPEC-TEST-INDEX-SYNC.1`

- ID: `ISF-SPEC-TEST-INDEX-SYNC.1`
  Status: `done`
  Goal: `List missing ISF tests in the spec and add a drift audit`
  Acceptance: `Spec index includes all current ISF tests and the new audit fails if the index drifts`
  Verification: `prove -Iperl t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t t/1248-isf-rule-trigger-parameter-binding.t t/1249-isf-activation-parameter-constants.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SPEC-TEST-INDEX-SYNC.1: audit spec test index`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `_None_` | `_None_` | Tree closed |

## Decisions

- `2026-05-16`: Add a regression audit rather than a one-off prose edit,
  because the ISF spec is a live downstream reference and its focused-test
  index must not drift as new `t/*-isf-*.t` files are added.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-SPEC-TEST-INDEX-SYNC.1` | `prove -Iperl t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t t/1248-isf-rule-trigger-parameter-binding.t t/1249-isf-activation-parameter-constants.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SPEC-TEST-INDEX-SYNC.1` | `ISF-SPEC-TEST-INDEX-SYNC.1: audit spec test index` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree for ISF spec focused-test index sync.
- `2026-05-16`: Closed tree after listing missing focused ISF tests and
  adding a drift audit.
