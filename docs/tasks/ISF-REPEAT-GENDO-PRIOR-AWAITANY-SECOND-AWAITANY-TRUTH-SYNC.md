# ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC: Align Book And Audit Test With Shipped Prior-Observation Second AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Align the mdBook (chapters `13h-lowering-reference.md`, `13b-transactions.md`, and
`13k-isf-feature-support-matrix.md`) with the already-shipped validator behavior
at `perl/FSM/Scheduler/ISF/LoweringIR.pm:6470` that accepts a second post-spawn
multi-pending `(await_any done)` in the prior-multi-pending-observation form
for the top-level when-body and switch-branch nested-repeat generated-child,
static-parameter, bound, and same-domain do-then-spawn subsets before the
mandatory same-body `(await_all done)` drain. Concurrently fix the
`documents_stale_domain_prior_await_any_second_post_spawn_deferral` helper bug
in `t/1307-isf-loop-body-doc-truth-audit.t` and add
`docs/book/src/13h-lowering-reference.md` to the audit file list so that the
loop-body doc-truth audit reliably catches stale fail-closed wording for this
shape across all four generated-do families in the future.

## Non-Goals

- Do not change validator, lowering, schedule reports, generated HDL, manifests,
  public API, or any user-visible runtime behavior.
- Do not touch the held `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE`
  slice; it remains separately tracked.
- Do not update `ISF_SPEC.md`, `ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  `ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, `13d-control-flow.md`, or
  `14-feature-backlog.md`; those were correctly synced by the predecessor
  feature commits (`d9432d91`, `d23c6d74`, `ae6c7d64`, `edcd447c`).

## Acceptance Criteria

- `docs/book/src/13h-lowering-reference.md` no longer claims that the
  prior-observation second post-spawn `(await_any done)` "remains fail-closed"
  for the four generated-do families; positive wording instead documents the
  shipped accept-with-mandatory-drain contract.
- `docs/book/src/13b-transactions.md` no longer claims the same shape "remains
  fail-closed" for the four families; positive wording mirrors `13h` and
  `ISF_SPEC.md`.
- `docs/book/src/13k-isf-feature-support-matrix.md` no longer contains the
  three stale sentences contradicting the same row's long shipped-list and
  post-row summary: row 61 inline narrative, lines ~95-96, and lines ~269-272.
- `t/1307-isf-loop-body-doc-truth-audit.t`'s
  `documents_stale_domain_prior_await_any_second_post_spawn_deferral` helper
  uses an exclusion pattern symmetric with the predecessor helpers for
  plain/static-parameter/bound (i.e., excludes narrower-family wording rather
  than excluding the orthogonal cross-domain/missing/deeper/cdc lexicon).
- `t/1307` audit file list includes `docs/book/src/13h-lowering-reference.md`.
- `prove -Iperl t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t t/1215-isf-spawn-parameter-binding.t`
  succeeds.
- `mdbook build docs/book` succeeds.
- `./bin/ci-regression isf --no-book` succeeds.
- `git diff --check` is clean.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC`
  Status: `done`
  Goal: `Align book and t/1307 audit with shipped prior-observation second await_any behavior.`
  Children: `ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.1`

- ID: `ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Fix t/1307 same-domain stale-helper exclusion, add 13h to audit list, and update 13h/13b/13k positive wording.`
  Acceptance: `Helper exclusion pattern symmetric with siblings; 13h in audit list; 13h/13b/13k no longer assert prior-observation second await_any fail-closed; full validation passes.`
  Verification: `prove -Iperl t/1305 t/1307 t/1215; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.1` | `done` | Closed the picky-audit-identified gap between shipped behavior and book/test truth. |

## Decisions

- `2026-05-26`: Bundle helper fix and book sync into one commit so the test
  never lands in a broken state. The validation log records the intermediate
  proof: after only the helper fix, t/1307 fails on the stale 13b/13h wording
  (proving the bug existed); after the book update, t/1307 passes again.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.1` | `prove -Iperl t/1215-isf-spawn-parameter-binding.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; focused `Files=3, Tests=803`; mdBook built clean; ISF CI `Files=275, Tests=2022`; whitespace clean. Helper bug proof: with only the t/1307 helper fix applied (before book updates), the test failed on the live `13b-transactions.md` same-domain stale wording at line 798, confirming the original exclusion list swallowed legitimate stale detection. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.1` | `ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.1: sync prior-observation second post-spawn await_any book and audit truth` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created R14 task tree to align mdBook and t/1307 audit with
  shipped prior-observation second post-spawn `await_any` behavior for the
  top-level when-body and switch-branch nested-repeat generated-child,
  static-parameter, bound, and same-domain generated-do families.
- `2026-05-26`: Completed the selected leaf. Tightened the
  `documents_stale_domain_prior_await_any_second_post_spawn_deferral` helper
  in `t/1307-isf-loop-body-doc-truth-audit.t` to phrase-level anchors and a
  700-character window without orthogonal exclusions, added
  `docs/book/src/13h-lowering-reference.md` to a focused
  `@prior_observation_second_await_any_truth_docs` list with sixteen
  positive-wording and stale-wording assertions across the five generated-do
  families in both branch-contained contexts, and rewrote the stale
  paragraphs in `docs/book/src/13b-transactions.md`,
  `docs/book/src/13h-lowering-reference.md`, and
  `docs/book/src/13k-isf-feature-support-matrix.md` to the positive
  shipped-with-mandatory-drain wording.
