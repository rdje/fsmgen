# CI-SHARED-DP-SURFACE-REPAIR: Repair Shared-Datapath Surface CI Failures

## Metadata

- Tree ID: `CI-SHARED-DP-SURFACE-REPAIR`
- Status: `done`
- Roadmap lane: `CI/composition contract integrity`
- Created: `2026-06-10`
- Last updated: `2026-06-10`
- Owner: repo-local workflow

## Goal

Restore the failing GitHub `Perl FSM Regression` surface after the
`ARCHITECTURE-DEBT-FRONTIER.3` push by repairing the reproduced composition
net/report/IR expectations and the stale public contract fixtures without
changing the intended composition semantics.

## Non-Goals

- Do not change generated-child shared-datapath behavior unless investigation
  proves the runtime behavior is wrong.
- Do not broaden VHDL composition support; only keep the documented fail-closed
  boundary and diagnostic classification in sync with the shipped wording.
- Do not alter frozen legacy prose blobs.
- Do not push to GitHub; pushing remains explicitly user-gated.

## Acceptance Criteria

- The reproduced CI failure cluster passes locally:
  `t/21`, `t/22`, `t/84`-`t/87`, `t/93`, `t/94`, `t/99`-`t/101`,
  `t/158`, `t/160`, `t/162`, `t/193`, `t/249`, `t/300`, `t/304`,
  `t/383`, `t/582`, and `t/624`.
- Shared-datapath unused export sink nets remain documented and either stay out
  of public internal-carrier summaries or are tested explicitly as sink support,
  not conflated with user-authored composition carrier nets.
- The VHDL composition expected-failure corpus entry still classifies as
  `FSMGEN_COMPOSITION_TARGET_SUPPORT`.
- Contract family maps keep the array-valued shape required by the integrity
  audit.
- The mdBook is updated only if user-facing behavior or public support wording
  changes.
- Required memory architecture and path gates pass before commit.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `CI-SHARED-DP-SURFACE-REPAIR`
  Status: `done`
  Goal: `Repair the latest GitHub CI regression cluster.`
  Children: `CI-SHARED-DP-SURFACE-REPAIR.1`

- ID: `CI-SHARED-DP-SURFACE-REPAIR.1`
  Status: `done`
  Goal: `Fix the reproduced shared-datapath surface and stale contract fixture
  failures from GitHub run 27086344097.`
  Acceptance: Focused failing tests pass; public diagnostic classification is
  restored; memory/task-tree gates pass.
  Verification: `PASS`; focused GitHub failure cluster, contract metadata
  tests, quick regression, mdBook, Knowledge Map, memory, path, and diff gates
  pass.
  Commit: `CI-SHARED-DP-SURFACE-REPAIR.1: repair CI surface contracts`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `CI-SHARED-DP-SURFACE-REPAIR.1` | `done` | Repaired the reproduced GitHub `Perl FSM Regression` composition/contract cluster and restored focused gates. |

## Decisions

- `2026-06-10`: Treat the current repair as one CI slice because the focused
  failures share two concrete roots: shared-datapath sink nets leaking into
  composition public net surfaces, and stale contract expectations after
  bounded VHDL composition wording expanded.
- `2026-06-10`: The runtime behavior is not changed: generated-child
  `shared_dp_unused_*` sink nets remain intentional physical HDL wiring.
  Tests now distinguish authored carrier nets from shared-datapath sink wiring
  instead of counting all plan nets as authored carriers.
- `2026-06-10`: The public contract convention is clarified: top-level
  `*_package_import_entry_value_meaning` fields remain scalar strings, while
  grouped `presence_key_family_map` discovery entries carry the same value as a
  single-element array to preserve the array-valued grouped-map invariant.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-10` | `CI-SHARED-DP-SURFACE-REPAIR.1` | `prove -I perl` over the GitHub failed-test cluster | `FAIL` before repair; reproduces run `27086344097` plus current-head residual failures. |
| `2026-06-10` | `CI-SHARED-DP-SURFACE-REPAIR.1` | `prove -I perl t/21-composition-two-fsm-linking.t t/22-composition-fsm-plus-rtl.t t/84-composition-external-fsm-child-sources.t t/85-composition-standalone-dt-children.t t/86-composition-single-child-connect-by-name.t t/87-composition-mixed-connect-by-name.t t/93-composition-multi-generated-plus-rtl-children.t t/94-composition-multi-generated-plus-rtl-connect-by-name.t t/99-composition-implicit-internal-carriers.t t/100-composition-internal-carrier-top-reexport.t t/101-composition-explicit-link-implicit-ports.t t/158-composition-generated-child-forward-ir-exports.t t/160-composition-top-forward-ir-surface.t t/162-composition-top-structural-rtl-ir-surface.t t/193-forward-structural-rtl-ir-builder-direct-root.t t/249-regression-corpus-classified-behavior.t t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t t/383-contract-family-map-integrity-audit.t t/582-composition-generation-module-info-lowered-ir-alias-boundary-audit.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t` | `PASS`; 21 files / 124 tests. |
| `2026-06-10` | `CI-SHARED-DP-SURFACE-REPAIR.1` | `prove -I perl t/297-capability-manifest.t t/311-normalized-semantic-report-contract.t t/330-normalized-semantic-payload-contract.t t/334-normalized-semantic-forward-ir-contract.t t/335-normalized-semantic-symbol-contract.t t/339-normalized-semantic-intent-hir-contract.t t/383-contract-family-map-integrity-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t` | `PASS`; 9 files / 25 tests. |
| `2026-06-10` | `CI-SHARED-DP-SURFACE-REPAIR.1` | `./bin/ci-regression quick --no-book` | `PASS`; 8 files / 145 tests. |
| `2026-06-10` | `CI-SHARED-DP-SURFACE-REPAIR.1` | `mdbook build docs/book`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -I perl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS`. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `CI-SHARED-DP-SURFACE-REPAIR.1` | `CI-SHARED-DP-SURFACE-REPAIR.1: repair CI surface contracts` | Restores the reproduced GitHub CI failure cluster locally; push remains user-gated. |

## Changelog

- `2026-06-10`: Created exact owner for repairing the latest GitHub CI
  regression cluster before any source/test/doc edits.
- `2026-06-10`: Repaired the focused CI cluster, synced mdBook/fact-card
  contract wording, regenerated Knowledge Map, and completed verification.
