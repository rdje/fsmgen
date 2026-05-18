# ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS: SPECFORGE Stage And Contract Bug Reports

## Metadata

- Tree ID: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-18`
- Last updated: `2026-05-18`
- Owner: repo-local workflow

## Goal

Track and fix the two minimized SPECFORGE downstream issue bundles reported
against FSMGen's shipped `.isf` stage/contract surface:

- `sf-isf-contract-eventually-flat`
- `sf-isf-stage-ready-valid`

The fixes must keep the codebase, ISF spec, downstream integration handoff,
public contract, mdBook, task tree, and regression tests synchronized.

## Non-Goals

- Broadening temporal contracts beyond the shipped bounded-eventually subset.
- Broadening transaction stages beyond the shipped ready/valid barrier subset.
- Changing generated HDL semantics for already accepted nested bounded
  eventual contracts or `(input ...)/(output ...)` ready/valid stages unless
  a focused reproducer proves that existing behavior is wrong.
- Editing the SPECFORGE issue bundles in place.

## Acceptance Criteria

- Each SPECFORGE issue bundle is reproduced locally before the corresponding
  fix is implemented.
- The documented flat bounded-eventually form
  `(contract NAME (eventually SIGNAL within N))` is either accepted as a
  shipped alias with tests/docs, or the source-of-truth docs are corrected
  with explicit rationale if implementation proves that the documented form
  was never intended to be shipped.
- The documented ready/valid stage form
  `(stage NAME (ready READY_SIGNAL) (valid VALID_SIGNAL))` is either accepted
  as a shipped alias with tests/docs, or the source-of-truth docs are
  corrected with explicit rationale if implementation proves that the
  documented form was never intended to be shipped.
- If an originally reported bundle reveals a second independent semantic
  failure after the documented source spelling is accepted, that residual
  diagnostic is recorded explicitly and remains task-tree tracked instead of
  being hidden by the syntax fix.
- `--strict --check --json` behavior for these downstream-facing failures is
  triaged and either fixed to emit JSON or documented as a separate explicit
  non-claim with regression coverage.
- Focused tests cover the minimized issue shapes and preserve existing accepted
  syntax.
- Broader ISF validation runs when the parser/lowering/CLI blast radius
  warrants it.
- Each completed leaf is committed through `COMMIT.md` before the next leaf
  starts.

## Task Tree

- ID: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS`
  Status: `done`
  Goal: `Fix or explicitly reconcile SPECFORGE's two minimized ISF stage/contract reports.`
  Children: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1`, `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2`, `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3`

- ID: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1`
  Status: `done`
  Goal: `Resolve sf-isf-contract-eventually-flat.`
  Acceptance: `The minimized flat bounded-eventually bundle is reproduced locally, FSMGen behavior is aligned with the documented source contract, focused regression coverage locks the accepted or corrected surface, and ISF spec/downstream handoff/mdBook/public contract text stays truthful.`
  Verification: `reproduced first: ./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-contract-eventually-flat/sources/fsmgen-input/f1-contract-eventually-flat.isf exited 255, wrote 0 bytes stdout, and reported Transaction 'txn_demo': contract 'c_demo' supports only '(eventually signal (within cycles))' on stderr; after the fix the same command passes with success:true JSON; focused contract/boundary tests, mdBook build, doc audits, and the broad ISF gate pass`
  Commit: `610cb26e ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1: accept flat eventual contracts`

- ID: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2`
  Status: `done`
  Goal: `Resolve sf-isf-stage-ready-valid.`
  Acceptance: `The minimized ready/valid stage bundle is reproduced locally, FSMGen behavior is aligned with the documented source contract, focused regression coverage locks the accepted or corrected surface, and ISF spec/downstream handoff/mdBook/public contract text stays truthful.`
  Verification: `reproduced before implementation: ./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-stage-ready-valid/sources/fsmgen-input/f2-stage-ready-valid.isf exited 255, wrote 0 bytes stdout, and reported Transaction 'txn_demo': stage 's_demo' has unsupported subclause 'ready' on stderr; after the syntax fix the documented ready/valid form is accepted by focused strict JSON tests, and the exact bundle advances to the existing isf_priority_mixed_timing_conflict on ADDRESS because rule_7 and the stage valid endpoint both write ADDRESS`
  Commit: `d4d6dfab ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2: accept ready-valid stages`

- ID: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3`
  Status: `done`
  Goal: `Triage the shared strict-check JSON failure surface.`
  Acceptance: `For parser/strict-check failures reached through --strict --check --json, FSMGen either emits a documented JSON failure payload with regression coverage or the live docs explicitly mark the current empty-stdout behavior as unsupported with rationale.`
  Verification: `fixed: ISF parser/lowering/report/semantic check failures under --check --json emit success:false JSON on stdout, keep stderr clean, and preserve diagnostic text; exact sf-isf-stage-ready-valid now emits JSON failure for the mixed-timing conflict`
  Commit: `this commit: ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3: emit ISF check JSON failures`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1` | `done` | The flat bounded-eventually report now passes strict JSON check with the documented flat `within` spelling while preserving the nested alias. |
| 2 | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2` | `done` | The ready/valid stage report now accepts the documented `ready`/`valid` spelling while preserving the older `input`/`output` alias. |
| 3 | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3` | `done` | Strict check JSON now emits `success:false` failure payloads for ISF lowering/report/semantic failures instead of empty stdout. |

Current frontier: `closed`.

## Decisions

- `2026-05-18`: Created a fresh active R14 task tree for the SPECFORGE issue
  bundles instead of reopening completed stage/contract trees. These reports
  are downstream conformance findings against the current integration handoff,
  so they need their own reproduction evidence and commit-scoped fixes.
- `2026-05-18`: Tracked the shared `--strict --check --json` empty-stdout
  observation as a separate leaf because it affects downstream diagnostics
  regardless of whether each source-form mismatch is fixed in parser/lowering
  or reconciled as a documentation error.
- `2026-05-18`: Reproduced both SPECFORGE issue bundles locally before any
  implementation changes. `sf-isf-contract-eventually-flat` exits `255` with
  zero stdout bytes and the reported bounded-eventually diagnostic on stderr.
  `sf-isf-stage-ready-valid` exits `255` with zero stdout bytes and the
  reported unsupported `ready` subclause diagnostic on stderr. Both
  `expected/baseline-good.isf` counterparts pass
  `./bin/fsmgen --strict --check --json` with `success: true`.
- `2026-05-18`: Resolved the flat bounded-eventually report by accepting the
  documented `(eventually signal within cycles)` spelling as the preferred
  source form and retaining `(eventually signal (within cycles))` as a
  compatibility alias. Both spellings lower to the same bounded monitor
  semantics.
- `2026-05-18`: Resolved the ready/valid source-form mismatch by accepting
  `(ready ready_signal)` and `(valid valid_signal)` as the preferred
  transaction-stage spelling while keeping `(input ready_signal)` and
  `(output valid_signal)` as aliases. The exact SPECFORGE stage bundle now
  reaches the existing mixed-timing conflict checker because its `valid`
  endpoint and `rule_7` both write `ADDRESS`; that residual failure belongs
  to the shared strict JSON/failure-surface leaf, not the syntax leaf.
- `2026-05-18`: Resolved the shared strict-check JSON failure surface for the
  ISF path. `.isf` parser, lowering, schedule-report, and downstream semantic
  check failures now emit bounded `success:false` check JSON to stdout in
  `--check --json` / `--check-json` mode and keep stderr clean.

## Open Questions

- None. This task tree is closed.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-18` | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS` | `task-tree creation only` | `tracking owner created before code changes` |
| `2026-05-18` | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1` | `./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-contract-eventually-flat/sources/fsmgen-input/f1-contract-eventually-flat.isf`; `./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-contract-eventually-flat/expected/baseline-good.isf` | `reproduced: failing source exits 255 with 0 stdout bytes and the reported contract diagnostic; baseline passes with success:true JSON` |
| `2026-05-18` | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2` | `./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-stage-ready-valid/sources/fsmgen-input/f2-stage-ready-valid.isf`; `./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-stage-ready-valid/expected/baseline-good.isf` | `reproduced: failing source exits 255 with 0 stdout bytes and the reported stage diagnostic; baseline passes with success:true JSON` |
| `2026-05-18` | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1175-isf-contract-fail-closed.t t/1180-isf-unsupported-transaction-clause-boundary.t t/1224-isf-contract-lowering.t`; `./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-contract-eventually-flat/sources/fsmgen-input/f1-contract-eventually-flat.isf`; `./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-contract-eventually-flat/expected/baseline-good.isf` | `fixed: syntax check passes; focused contract/boundary tests pass; minimized flat source and baseline both pass strict JSON check with success:true` |
| `2026-05-18` | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1` | `mdbook build docs/book`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `./bin/ci-regression isf --no-book`; `git diff --check` | `passed: book builds, focused doc audits pass, broad ISF gate passes with Files=228, Tests=1341, and diff whitespace check passes` |
| `2026-05-18` | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1179-isf-phase-stage-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t t/1223-isf-stage-lowering.t t/1225-isf-stage-contract-schedule-report.t`; `./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-stage-ready-valid/sources/fsmgen-input/f2-stage-ready-valid.isf`; `./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-stage-ready-valid/expected/baseline-good.isf` | `fixed source-form mismatch: focused ready/valid strict JSON and report tests pass; baseline passes; exact bundle no longer reports unsupported ready and now reaches isf_priority_mixed_timing_conflict on ADDRESS, preserving existing conflict safety` |
| `2026-05-18` | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2` | `mdbook build docs/book`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `./bin/ci-regression isf --no-book`; `git diff --check` | `passed: book builds, focused doc audits pass, broad ISF gate passes with Files=228, Tests=1342, and diff whitespace check passes` |
| `2026-05-18` | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3` | `perl -c bin/fsmgen`; `prove -Iperl t/1323-isf-check-json-failure-surface.t t/1223-isf-stage-lowering.t t/1224-isf-contract-lowering.t`; exact `sf-isf-contract-eventually-flat` source and baseline strict JSON checks; exact `sf-isf-stage-ready-valid` source and baseline strict JSON checks; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `./bin/ci-regression isf --no-book`; `git diff --check` | `passed after adding the new focused test to the ISF spec index: focused tests pass; flat-contract source and baselines pass; exact stage bundle exits nonzero with success:false JSON on stdout, one diagnostic, and the mixed-timing message; broad ISF gate passes with Files=229, Tests=1344` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS` | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS: track reproduced reports` | `created tracking tree and reproduced both reported failures before implementation` |
| `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1` | `610cb26e ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1: accept flat eventual contracts` | `accepts the documented flat bounded-eventually source form and preserves the nested alias` |
| `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2` | `d4d6dfab ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2: accept ready-valid stages` | `accepts the documented ready/valid stage source form, preserves the older input/output alias, and records the exact bundle's residual mixed-timing conflict` |
| `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3` | `this commit: ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3: emit ISF check JSON failures` | `emits structured check JSON for ISF lowering/report/semantic failures` |

## Changelog

- `2026-05-18`: Created the tracking tree before implementation and
  reproduced both SPECFORGE reports locally.
- `2026-05-18`: Completed `.1` by accepting the documented flat
  bounded-eventually contract syntax, preserving the older nested alias, and
  verifying the minimized downstream issue bundle now passes.
- `2026-05-18`: Completed `.2` by accepting the documented ready/valid stage
  syntax, preserving the older input/output alias, and recording that the
  exact reported artifact now reaches the existing mixed-timing conflict
  checker instead of failing on the `ready` subclause.
- `2026-05-18`: Completed `.3` by emitting structured check JSON for ISF
  lowering/report/semantic failures and closing the SPECFORGE stage/contract
  report tree.
