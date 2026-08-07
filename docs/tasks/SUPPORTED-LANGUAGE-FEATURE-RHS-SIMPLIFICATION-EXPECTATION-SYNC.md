# SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC: Align HDL Shape Oracles With Shipped RHS Simplification

## Metadata

- Tree ID: `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC`
- Status: `done`
- Roadmap lane: `test integrity / generated HDL expression simplification`
- Created: `2026-07-31`
- Last updated: `2026-08-07`
- Owner: repo-local workflow

## Goal

Restore the full supported-language-feature corpus gate by reconciling twelve
stale HDL text patterns with the already-shipped width-safe RHS simplifier,
while proving the accepted output remains semantically correct.

## Non-Goals

- Do not weaken or remove semantic HDL-shape coverage.
- Do not change VIAL, its support entry, or its semantic-only integration.
- Do not widen the RHS simplifier beyond its existing proven contract.
- Do not activate this tree while another task tree owns a dirty worktree.

## Acceptance Criteria

- Root-cause whether each mismatch is an intended simplification or a generator
  regression before changing an oracle.
- Update only expectations proved stale; repair the generator instead if any
  output violates the selected simplification/semantic contract.
- `t/261-regression-corpus-supported-language-features.t` passes in default and
  strict pipeline/CLI modes with its full assertion count recorded.
- Focused RHS simplification tests and a broader regression pass without
  unrelated failures.
- Task index, continuity records, and changelog are synchronized and the slice
  commits through `COMMIT.md`.

## Task Tree

- ID: `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC`
  Status: `done`
  Goal: `Reconcile stale supported-language-feature HDL shape expectations with shipped RHS simplification.`
  Children: `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC.1`

- ID: `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC.1`
  Status: `done`
  Goal: `Classify and repair the twelve stale expression-simplification HDL shape oracles.`
  Acceptance: `The six affected corpus entries retain meaningful semantic assertions for simplified unary and Boolean-identity expressions; t261 passes in all four default/strict pipeline/CLI paths; focused RHS simplifier and broader gates pass without changing VIAL or unsupported behavior.`
  Verification: `Fresh clean-tree reproduction on 2026-08-07 confirmed t261 failed 24 of 613 default assertions and 24 of 614 strict assertions. A filtered exact-regex census proved twelve stale patterns, each repeated through pipeline/CLI and default/strict paths: three parenthesized unary-identifier expectations in feature.rhs_expression_supported_variants; four redundant & 1'b1 enables in feature.compound_update_variants; one redundant & 1'b1 enable in feature.state_dte_guards; two redundant & 1'b1 enables in feature.standalone_dt_guards; one parenthesized unary-identifier expectation in feature.relational_operator_chains; and one double-negation expectation in feature.test_selector_symbolic_default. git history dates the expectations to their May corpus-widening commits; RHS-LOGIC-SIMPLIFICATION-FRONTIER shipped explicit width-safe double-negation and Boolean identity/expression minimization at 425f03d1b on 2026-06-18. After the twelve expectation repairs: RegressionCorpus.pm compiles; t206/t207/t208 pass (Files=3, Tests=4); t261 passes (Files=1, Tests=2) while internally checking all 613 default and 614 strict pipeline/CLI assertions; and the t248/t249/t491/t1333/t163/t624 broader regression passes (Files=6, Tests=7104). Every prove run reports All tests successful. No generator or user-facing behavior changed, so the already-accurate mdBook required no edit.`
  Commit: `this commit (SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC.1: align simplification oracles)`

## Decisions

- `2026-07-31`: Track the failure separately from VIAL because the VIAL corpus
  entry is excluded by t261's `language_feature_fixture` filter and the current
  slice changes no HDL generator.
- `2026-07-31`: Do not update text patterns until focused semantic evidence
  confirms the emitted simplified forms are the intended contract.
- `2026-08-07`: The unfiltered reproduction confirms the historical failure
  totals but disproves the original six-pattern/three-entry classification.
  Filtering every failed regex proves twelve stale patterns across six entries;
  all are already-shipped single-bit Boolean identities, double-negation, or
  renderer-normalized unary forms and remain one expectation-only leaf.

## Open Questions

- None. Source declarations confirm all affected enables/identifiers are
  single-bit, while `t/208-rhs-logic-simplification-width-safety.t` proves the
  simplifier preserves wider expressions instead of applying scalar identities.

## Blockers

- None.

## Acceptance Checklist (enforced for implementation changes)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` over each stale regex traces
  the six corpus entries to their May widening commits, while commit
  `425f03d1b` subsequently shipped the intentional scalar Boolean-identity,
  double-negation, and unary-rendering simplifications. The exact t261
  failed-regex census located twelve stale patterns in
  `perl/FSM/Support/RegressionCorpus.pm`; no generator regression was present.
- [x] **ADDRESSED (verified)** — the twelve expectations now match the proved
  simplified HDL forms. `env TMPDIR=.artifacts/tmp prove -Iperl
  t/261-regression-corpus-supported-language-features.t` changed from 24/613
  default and 24/614 strict failures to `All tests successful` (Files=1,
  Tests=2), covering all four default/strict pipeline/CLI paths.
- [x] **NO REGRESSION** — `env TMPDIR=.artifacts/tmp prove -Iperl
  t/206-rhs-logic-simplification.t t/207-rhs-logic-simplification-proof.t
  t/208-rhs-logic-simplification-width-safety.t` reports `All tests successful`
  (Files=3, Tests=4), and the independent t248/t249/t491/t1333/t163/t624
  broader run reports `All tests successful` (Files=6, Tests=7104).
