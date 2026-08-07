# SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC: Align HDL Shape Oracles With Shipped RHS Simplification

## Metadata

- Tree ID: `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC`
- Status: `active`
- Roadmap lane: `test integrity / generated HDL expression simplification`
- Created: `2026-07-31`
- Last updated: `2026-07-31`
- Owner: repo-local workflow

## Goal

Restore the full supported-language-feature corpus gate by reconciling six
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
  Status: `active`
  Goal: `Reconcile stale supported-language-feature HDL shape expectations with shipped RHS simplification.`
  Children: `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC.1`

- ID: `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC.1`
  Status: `active`
  Goal: `Classify and repair the six stale expression-simplification HDL shape oracles.`
  Acceptance: `The four affected corpus entries retain meaningful semantic assertions for simplified unary and Boolean-identity expressions; t261 passes in all four default/strict pipeline/CLI paths; focused RHS simplifier and broader gates pass without changing VIAL or unsupported behavior.`
  Verification: `Fresh clean-tree reproduction on 2026-08-07 confirms t261 fails 24 of 613 default assertions and 24 of 614 strict assertions. Six stale patterns repeat through pipeline/CLI and default/strict paths: three parenthesized unary-identifier expectations in feature.rhs_expression_supported_variants, one redundant & 1'b1 output-enable expectation in feature.standalone_dt_guards, one parenthesized unary-identifier expectation in feature.relational_operator_chains, and one double-negation expectation in feature.test_selector_symbolic_default. git blame dates the expectations to 2026-05-20/21; RHS-LOGIC-SIMPLIFICATION-FRONTIER shipped explicit width-safe double-negation and Boolean identity/expression minimization on 2026-06-18. No generator change is in scope.`
  Commit: `pending`

## Decisions

- `2026-07-31`: Track the failure separately from VIAL because the VIAL corpus
  entry is excluded by t261's `language_feature_fixture` filter and the current
  slice changes no HDL generator.
- `2026-07-31`: Do not update text patterns until focused semantic evidence
  confirms the emitted simplified forms are the intended contract.
- `2026-08-07`: Fresh reproduction corrects the discovery record from three to
  four affected entries. The sixth mismatch is the standalone-DT output-enable
  identity `expr_guard_en & 1'b1` simplifying to `expr_guard_en`; it belongs to
  the same already-shipped simplification boundary and remains in this leaf.

## Open Questions

- Do any four-state or width contexts make one of the apparent unary
  simplifications unsafe? This must be answered by `.1` evidence.

## Blockers

- None.

## Acceptance Checklist (enforced for implementation changes)

- [ ] **ROOT CAUSE (WHY + WHERE)** — `pending fresh staged evidence`
- [ ] **ADDRESSED (verified)** — `pending fresh staged evidence`
- [ ] **NO REGRESSION** — `pending fresh staged evidence`
