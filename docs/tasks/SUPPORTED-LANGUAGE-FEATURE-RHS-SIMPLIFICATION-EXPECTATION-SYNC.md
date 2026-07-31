# SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC: Align HDL Shape Oracles With Shipped RHS Simplification

## Metadata

- Tree ID: `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC`
- Status: `proposed`
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
  Status: `proposed`
  Goal: `Reconcile stale supported-language-feature HDL shape expectations with shipped RHS simplification.`
  Children: `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC.1`

- ID: `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC.1`
  Status: `pending`
  Goal: `Classify and repair the six stale unary-expression HDL shape oracles.`
  Acceptance: `The three affected corpus entries retain meaningful semantic assertions for simplified unary expressions; t261 passes in all four default/strict pipeline/CLI paths; focused RHS simplifier and broader gates pass without changing VIAL or unsupported behavior.`
  Verification: `Discovery during HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3: t261 fails 24 of 613 default assertions and 24 of 614 strict assertions. The mismatches are three parenthesized unary-identifier expectations for feature.rhs_expression_supported_variants, one for feature.relational_operator_chains, and one double-negation expectation for feature.test_selector_symbolic_default, repeated through pipeline/CLI and default/strict paths. git blame dates the expectations to 2026-05-20/21; RHS-LOGIC-SIMPLIFICATION-FRONTIER shipped explicit width-safe double-negation and expression minimization on 2026-06-18. No HDL generator file differs in the discovering VIAL slice.`
  Commit: `pending activation after the current dirty VIAL slice is committed cleanly`

## Decisions

- `2026-07-31`: Track the failure separately from VIAL because the VIAL corpus
  entry is excluded by t261's `language_feature_fixture` filter and the current
  slice changes no HDL generator.
- `2026-07-31`: Do not update text patterns until focused semantic evidence
  confirms the emitted simplified forms are the intended contract.

## Open Questions

- Do any four-state or width contexts make one of the apparent unary
  simplifications unsafe? This must be answered by `.1` evidence.

## Blockers

- Activation waits for the current dirty VIAL task-tree leaf to commit cleanly.

## Acceptance Checklist (enforced for implementation changes)

- [ ] **ROOT CAUSE (WHY + WHERE)** — `pending fresh staged evidence`
- [ ] **ADDRESSED (verified)** — `pending fresh staged evidence`
- [ ] **NO REGRESSION** — `pending fresh staged evidence`
