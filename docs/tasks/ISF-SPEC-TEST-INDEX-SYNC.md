# ISF-SPEC-TEST-INDEX-SYNC: ISF Spec Focused-Test Index Sync

## Metadata

- Tree ID: `ISF-SPEC-TEST-INDEX-SYNC`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-08-25`
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
  Status: `active`
  Goal: `Synchronize and audit the ISF spec focused-test index`
  Children: `ISF-SPEC-TEST-INDEX-SYNC.1, ISF-SPEC-TEST-INDEX-SYNC.2, ISF-SPEC-TEST-INDEX-SYNC.3`

- ID: `ISF-SPEC-TEST-INDEX-SYNC.1`
  Status: `done`
  Goal: `List missing ISF tests in the spec and add a drift audit`
  Acceptance: `Spec index includes all current ISF tests and the new audit fails if the index drifts`
  Verification: `prove -Iperl t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t t/1248-isf-rule-trigger-parameter-binding.t t/1249-isf-activation-parameter-constants.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SPEC-TEST-INDEX-SYNC.1: audit spec test index`

- ID: `ISF-SPEC-TEST-INDEX-SYNC.2`
  Status: `done`
  Goal: `Repair focused-test index drift after ATL doc-status audit coverage`
  Acceptance: `Spec index includes t/1332-isf-atl-doc-status-audit.t and the focused audit passes`
  Verification: `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-SPEC-TEST-INDEX-SYNC.2: sync ATL doc-status audit index`

- ID: `ISF-SPEC-TEST-INDEX-SYNC.3`
  Status: `active`
  Goal: `Repair focused-test index drift after published timing-claim coverage`
  Acceptance: `Record the exact introducing change; add only t/1639-isf-published-timing-claims.t at the lexicographically correct authoritative mdBook source location; prove the index has no missing or extra paths; retain the audit unchanged; pass focused, book, doctrine, and complete guarded-CI gates before the pending 200-commit push.`
  Verification: `Pre-fix guarded ./bin/ci-regression reaches one t/1250 mismatch: listed index 332 has no element where expected index 332 is t/1639-isf-published-timing-claims.t; the independently executed t/1639 passes. Git identifies 8b2a6697905bf6f6b66dad0306b4e4c9576af470 as adding t/1639 without changing the authoritative focused-test source. The same guarded run later reaches t/296 strict-CLI execution and exits 137 only when host occupied memory reaches the authorized 88% cutoff; the active FSMGEN child remains far below its separate 4,096-MiB descendant ceiling. Exact repository-local interrupted-run residue is removed after proving the process tree and open-file set empty. Post-fix ordered and independent set oracles both prove 333 listed/expected with zero missing/extra; focused reference tests, all mdBook chapters, maintained-reference authority, containment, and zero-ceiling-increase gates pass. Complete guarded CI remains pending after the repair commit.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SPEC-TEST-INDEX-SYNC.3` | `active` | Focused repair is green; commit it, then rerun complete guarded CI before closing and pushing. |

## Decisions

- `2026-05-16`: Add a regression audit rather than a one-off prose edit,
  because the ISF spec is a live downstream reference and its focused-test
  index must not drift as new `t/*-isf-*.t` files are added.
- `2026-08-25`: Reopen the exact synchronization tree rather than weaken t/1250 or absorb its failure into HIAL/VIAL runtime measurement. Commit `8b2a66979` added one matching ISF test without the authoritative mdBook source link; `.3` owns only that drift and the complete-gate retry.

## Open Questions

- None.

## Blockers

- None. The first complete guarded-CI attempt was resource-safe and correctly terminated on host-wide occupied memory at the authorized cutoff. Retry is required after `.3` is implemented and committed; no cutoff widening or interference with the unrelated host workload is authorized.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-SPEC-TEST-INDEX-SYNC.1` | `prove -Iperl t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t t/1248-isf-rule-trigger-parameter-binding.t t/1249-isf-activation-parameter-constants.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-05-21` | `ISF-SPEC-TEST-INDEX-SYNC.2` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-08-25` | `ISF-SPEC-TEST-INDEX-SYNC.3` activation | Knowledge Map query; exact t/1250 source/spec comparison; `git show 8b2a66979`; guarded full CI; PID/resource/residue census; `git status --short` | `active`; root cause is one omitted authoritative source link. The broad run independently passes t/1639, reaches final strict-CLI corpus work, then the host guard terminates the tree at 88.1% occupied memory. Descendant ceiling does not trip; exact 4-file/1.8-MiB repository-local residue is removed and both temp roots are absent. |
| `2026-08-25` | `ISF-SPEC-TEST-INDEX-SYNC.3` focused repair | `git log -S'published_wait_16'`; ordered t/1250 plus independent set comparison; t/1120/t/1250/t/1303/t/1414/t/1639; ISF partition, mdBook test/build, render census/cleanup, maintained-reference, containment, ceiling, diff, and doctrine gates | `pass`; one link restores 333/333 with zero missing/extra, focused regression reports `All tests successful`, `Files=5, Tests=37`, all 56 book chapters pass, the exact 91-file render is removed, and +1 line/+85 bytes has fresh authority with zero ceiling increase. Complete guarded CI remains pending. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SPEC-TEST-INDEX-SYNC.1` | `ISF-SPEC-TEST-INDEX-SYNC.1: audit spec test index` | `committed` |
| `ISF-SPEC-TEST-INDEX-SYNC.2` | `ISF-SPEC-TEST-INDEX-SYNC.2: sync ATL doc-status audit index` | `committed` |
| `ISF-SPEC-TEST-INDEX-SYNC.3` | `e9e4c63c3` activation; repair commit pending | `focused green; complete CI pending` |

## Acceptance Checklist — `.3` (enforced before completion)

- [x] **ROOT CAUSE (WHY + WHERE)** — Pre-fix t/1250 emits the exact Perl diagnostic `at t/1250-isf-spec-focused-test-index-audit.t line 32`: listed index 332 is absent where expected index 332 is t/1639. `git log -S'published_wait_16'` identifies introducing commit `8b2a66979`, which adds t/1639 but not the authoritative link.
- [x] **ADDRESSED (verified)** — The one-link repair makes t/1250 pass and an independent unordered census reports `listed=333 expected=333 missing=0 extra=0`; the audit itself is unchanged.
- [x] **NO REGRESSION** — The adjacent reference set reports `All tests successful`, `Files=5, Tests=37`; all mdBook chapters test/build, maintained-reference/containment/ceiling gates pass, and the staged doctrine driver is required. Complete guarded CI remains required before tree closure and push.

## Changelog

- `2026-05-16`: Created task tree for ISF spec focused-test index sync.
- `2026-05-16`: Closed tree after listing missing focused ISF tests and
  adding a drift audit.
- `2026-05-21`: Repaired focused-test index drift found by hosted CI after
  `t/1332-isf-atl-doc-status-audit.t` was added.
- `2026-08-25`: Reopened `.3` after the mandatory full-CI gate found the t/1639 authoritative-list omission, then implemented the exact link and fresh maintained-reference authority; retained the audit, ceilings, and normal RAM cutoffs unchanged.
