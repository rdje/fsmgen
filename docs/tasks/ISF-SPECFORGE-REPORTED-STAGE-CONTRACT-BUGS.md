# ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS: SPECFORGE Stage And Contract Bug Reports

## Metadata

- Tree ID: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS`
- Status: `active`
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
  Status: `active`
  Goal: `Fix or explicitly reconcile SPECFORGE's two minimized ISF stage/contract reports.`
  Children: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1`, `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2`, `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3`

- ID: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1`
  Status: `done`
  Goal: `Resolve sf-isf-contract-eventually-flat.`
  Acceptance: `The minimized flat bounded-eventually bundle is reproduced locally, FSMGen behavior is aligned with the documented source contract, focused regression coverage locks the accepted or corrected surface, and ISF spec/downstream handoff/mdBook/public contract text stays truthful.`
  Verification: `reproduced first: ./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-contract-eventually-flat/sources/fsmgen-input/f1-contract-eventually-flat.isf exited 255, wrote 0 bytes stdout, and reported Transaction 'txn_demo': contract 'c_demo' supports only '(eventually signal (within cycles))' on stderr; after the fix the same command passes with success:true JSON; focused contract/boundary tests, mdBook build, doc audits, and the broad ISF gate pass`
  Commit: `pending commit for .1 implementation slice`

- ID: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2`
  Status: `active`
  Goal: `Resolve sf-isf-stage-ready-valid.`
  Acceptance: `The minimized ready/valid stage bundle is reproduced locally, FSMGen behavior is aligned with the documented source contract, focused regression coverage locks the accepted or corrected surface, and ISF spec/downstream handoff/mdBook/public contract text stays truthful.`
  Verification: `reproduced before implementation: ./bin/fsmgen --strict --check --json $SPECFORGE_ROOT/docs/fsmgen-issues/sf-isf-stage-ready-valid/sources/fsmgen-input/f2-stage-ready-valid.isf exits 255, writes 0 bytes stdout, and reports Transaction 'txn_demo': stage 's_demo' has unsupported subclause 'ready' on stderr; baseline-good.isf passes strict JSON check`
  Commit: `pending`

- ID: `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3`
  Status: `pending`
  Goal: `Triage the shared strict-check JSON failure surface.`
  Acceptance: `For parser/strict-check failures reached through --strict --check --json, FSMGen either emits a documented JSON failure payload with regression coverage or the live docs explicitly mark the current empty-stdout behavior as unsupported with rationale.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1` | `done` | The flat bounded-eventually report now passes strict JSON check with the documented flat `within` spelling while preserving the nested alias. |
| 2 | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2` | `active` | The ready/valid stage report is the second independent documented-form mismatch. |
| 3 | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3` | `pending` | Both reports expose the same downstream JSON failure-surface concern after the source-form mismatches are understood. |

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

## Open Questions

- None blocking the active `.2` leaf. The ready/valid stage implementation
  must preserve the existing accepted stage surface and stay aligned with the
  downstream handoff and mdBook.

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS` | `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS: track reproduced reports` | `created tracking tree and reproduced both reported failures before implementation` |
| `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1` | `pending commit: ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1: accept flat eventual contracts` | `accepts the documented flat bounded-eventually source form and preserves the nested alias` |
| `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2` | `pending` | `pending` |
| `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3` | `pending` | `pending` |

## Changelog

- `2026-05-18`: Created the tracking tree before implementation and
  reproduced both SPECFORGE reports locally.
- `2026-05-18`: Completed `.1` by accepting the documented flat
  bounded-eventually contract syntax, preserving the older nested alias, and
  verifying the minimized downstream issue bundle now passes.
