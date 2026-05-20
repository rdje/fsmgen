# R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT: Preferred Partial-LHS Dual-Output Coverage

## Metadata

- Tree ID: `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT`
- Status: `done`
- Roadmap lane: `R8`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Close a concrete R8 language-contract gap by proving the forward
dual-output assignment spelling `<=-` has the same partial-LHS lowering
contract already guarded for the legacy `<=+` compatibility alias, then
record the remaining delayed-pulse/vector widening decision explicitly.

## Non-Goals

- Do not change the public assignment operator semantics unless a focused
  regression proves current behavior is wrong.
- Do not remove or deprecate legacy `<=+`; it remains documented
  compatibility residue.
- Do not widen delayed-pulse `<N` or vector-pulse semantics in the same slice
  as the preferred `<=-` coverage.
- Do not touch ISF/ATL scheduling behavior in this tree.

## Acceptance Criteria

- The active R8 lane has task-tree ownership before any code or test changes.
- Current partial-LHS coverage is audited and the next implementation leaf is
  selected.
- Preferred `<=-` partial-LHS behavior is covered through focused tests and
  corpus/accounting checks.
- The book and live docs explain the supported preferred/legacy split
  accurately.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT`
  Status: `done`
  Goal: `Lock preferred <=- partial-LHS dual-output behavior and record the
  remaining pulse/vector decision.`
  Children: `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.1`,
  `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.2`,
  `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.3`

- ID: `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.1`
  Status: `done`
  Goal: `Audit the current partial-LHS contract gap and select the next leaf.`
  Acceptance: `The task tree identifies that current focused/corpus coverage
  proves partial-LHS dual-output lowering for legacy '<=+' but does not
  directly prove the preferred '<=-' spelling, and '.2' is selected as the
  bounded implementation leaf.`
  Verification: `static roadmap/test/book coverage audit`; `git diff --check`; `mdbook build docs/book`
  Commit: `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.1: select preferred partial-LHS coverage`

- ID: `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.2`
  Status: `done`
  Goal: `Add preferred '<=-' partial-LHS dual-output coverage.`
  Acceptance: `Focused language-contract tests and maintained regression
  corpus coverage prove partial indexed/sliced '<=-' writes assemble full-width
  D-input expressions, keep full-width '*_r' auxiliary outputs, and keep the
  existing '<=+' compatibility coverage intact.`
  Verification: `perl -Iperl -c t/258-partial-lhs-assignment-lowering.t`;
  `perl -Iperl -c t/259-partial-dual-output-lhs-lowering.t`;
  `perl -Iperl -c t/260-partial-target-width-inference.t`;
  `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`;
  `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`;
  `prove -Iperl t/258-partial-lhs-assignment-lowering.t
  t/259-partial-dual-output-lhs-lowering.t
  t/260-partial-target-width-inference.t`;
  `prove -Iperl t/248-regression-corpus-accounting.t
  t/261-regression-corpus-supported-language-features.t`;
  `git diff --check`; `mdbook build docs/book`
  Commit: `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.2: cover preferred partial-LHS writes`

- ID: `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.3`
  Status: `done`
  Goal: `Record the delayed-pulse/vector widening decision after '.2'.`
  Acceptance: `The remaining R8 question about widening partial-LHS semantics
  into delayed-pulse/vector edge cases is either split into a new task tree
  with concrete acceptance criteria or explicitly deferred with rationale.`
  Verification: `delayed-pulse partial-LHS probe`; `static parser/backend
  boundary audit`; `git diff --check`; `mdbook build docs/book`
  Commit: `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.3: split pulse boundary`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.1` | `done` | Selected the concrete coverage gap before implementation. |
| 2 | `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.2` | `done` | Preferred `<=-` is now directly proven while existing legacy `<=+` coverage remains intact. |
| 3 | `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.3` | `done` | Split delayed-pulse partial-LHS rejection into `R8-PARTIAL-LHS-PULSE-BOUNDARY`; vector-pulse semantics are deferred. |

## Decisions

- `2026-05-20`: Selected this R8 tree after the architecture backlog reached
  exhaustion and `R8. Language-contract hardening` remained in progress.
- `2026-05-20`: Completed `.1` by auditing the partial-LHS contract surface:
  current docs recommend `<=-` as the preferred dual-output D-input spelling,
  current focused/corpus coverage proves legacy `<=+` partial-LHS lowering,
  and the next bounded implementation leaf is to add direct preferred `<=-`
  coverage without removing the legacy alias.
- `2026-05-20`: Validation for `.1` passed with static coverage searches,
  `git diff --check`, and `mdbook build docs/book`.
- `2026-05-20`: Completed `.2` by adding preferred `<=-` partial-LHS
  coverage to focused lowering tests, dual-output width tests, inferred-width
  tests, maintained regression corpus fixtures, and book/corpus documentation.
  Legacy `<=+` compatibility coverage remains present.
- `2026-05-20`: Completed `.3` by splitting indexed/sliced delayed-pulse LHS
  rejection into `R8-PARTIAL-LHS-PULSE-BOUNDARY.1`. The project should reject
  that unsupported shape deliberately instead of widening `<N>` pulse
  semantics now. Vector-pulse semantics are deferred until a real source
  construct exists.

## Open Questions

- None for this closed tree. Delayed-pulse partial-LHS rejection is tracked by
  `R8-PARTIAL-LHS-PULSE-BOUNDARY`; vector-pulse semantics are deferred until a
  real source construct exists.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.1` | `rg -n '<=-|partial.*<=-|delayed pulse|delayed-pulse|<1 \\\\(' t perl docs/book/src/02-language-basics.md docs/book/src/03-decision-trees-and-fsms.md docs/book/src/10-errors-strict-mode-and-troubleshooting.md docs/USER_GUIDE.md`; `rg -n 'partial|slice|index|lhs|delayed|pulse|operator_symbol|<=-' perl/FSM`; `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.2` | `perl -Iperl -c t/258-partial-lhs-assignment-lowering.t`; `perl -Iperl -c t/259-partial-dual-output-lhs-lowering.t`; `perl -Iperl -c t/260-partial-target-width-inference.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `prove -Iperl t/258-partial-lhs-assignment-lowering.t t/259-partial-dual-output-lhs-lowering.t t/260-partial-target-width-inference.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.3` | `delayed-pulse partial-LHS probe`; `rg -n 'pulse.*slice|slice.*pulse|indexed.*pulse|partial.*pulse|<N|delayed-pulse|delayed pulse' perl t docs/book/src docs/REGRESSION_CORPUS.md ROADMAP_STATUS.md docs/tasks/R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.md`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.1` | `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.1: select preferred partial-LHS coverage` | Selects preferred `<=-` partial-LHS coverage as the next R8 implementation leaf. |
| `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.2` | `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.2: cover preferred partial-LHS writes` | Adds focused/corpus/book coverage for preferred `<=-` partial-LHS behavior while preserving `<=+` alias coverage. |
| `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.3` | `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.3: split pulse boundary` | Splits delayed-pulse partial-LHS rejection into the new `R8-PARTIAL-LHS-PULSE-BOUNDARY` tree and closes this tree. |

## Changelog

- `2026-05-20`: Created and activated the R8 task tree, completed `.1`, and
  selected `.2` for preferred `<=-` partial-LHS dual-output coverage.
- `2026-05-20`: Completed `.2` implementation; `.3` now owns the remaining
  delayed-pulse/vector widening decision.
- `2026-05-20`: Completed `.3`, created the follow-up pulse-boundary tree, and
  closed this tree.
