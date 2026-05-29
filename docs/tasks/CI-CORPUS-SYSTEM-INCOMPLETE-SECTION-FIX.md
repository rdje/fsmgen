# CI-CORPUS-SYSTEM-INCOMPLETE-SECTION-FIX: Fix Stale Corpus Fixture

## Metadata

- Tree ID: `CI-CORPUS-SYSTEM-INCOMPLETE-SECTION-FIX`
- Status: `pending`
- Roadmap lane: `CI maintenance`

## Goal

GitHub CI `Perl FSM Regression` workflow has been failing on
`t/249-regression-corpus-classified-behavior.t`,
`t/300-check-json-regression-corpus.t`, and a semantic-JSON
regression for the corpus entry
`contract.system_incomplete_section`.

The entry's fixture `t/corpus/system_incomplete_section.fsm`
currently contains `(+system (clock clk))` — a clock-only system
section. The corpus expects this to be REJECTED with diagnostic
`FSMGEN_LANGUAGE_INCOMPLETE_SYSTEM_SECTION` and the boundary
text `Incomplete '+system' section`.

But commit `0cf60ad3 NO-RESET-SCHEDULED-FSM-HDL.1: support
clock-only HDL` deliberately allowed clock-only `+system`
contracts as a shipped feature. The validator in
`perl/FSM/Adapter/FSMGenFull/Parser.pm` now checks only
`unless $parsed{clock}` rather than `unless $parsed{clock} &&
$parsed{reset}`. The fixture is therefore accepted, and the
corpus's expectation is stale.

Fix: update the fixture to a genuinely incomplete `+system`
shape — `(+system (sreset rst_n))` (reset but no clock) — which
still triggers the `Incomplete '+system' section. The active
contract currently expects exactly one '(clock name)' entry`
diagnostic.

## Non-Goals

- Do not roll back the clock-only support; that was a shipped
  feature.
- Do not change `RegressionCorpus.pm` or `DiagnosticCodes.pm` —
  the diagnostic code and pattern are still valid.

## Acceptance Criteria

- `t/corpus/system_incomplete_section.fsm` updated to a
  no-clock shape that still triggers the diagnostic.
- `prove -Iperl t/249-regression-corpus-classified-behavior.t
  t/300-check-json-regression-corpus.t` passes.
- GitHub CI `Perl FSM Regression` passes after push.
- mdBook clean; git diff --check clean.
- The slice is committed through `COMMIT.md`.

## Commit Log

| Leaf | Subject |
| --- | --- |
| `.1` | `CI-CORPUS-SYSTEM-INCOMPLETE-SECTION-FIX.1: select fixture fix` |
| `.2` | `CI-CORPUS-SYSTEM-INCOMPLETE-SECTION-FIX.2: ship fixture fix` |
