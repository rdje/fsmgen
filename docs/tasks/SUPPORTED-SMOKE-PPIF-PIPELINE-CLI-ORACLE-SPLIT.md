# SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT: Separate PPIF Entry And Aggregate HDL Oracles

## Metadata

- Tree ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT`
- Status: `proposed`
- Roadmap lane: `test integrity / IAL2 PPIF support accounting`
- Created: `2026-07-31`
- Last updated: `2026-07-31`
- Owner: repo-local workflow

## Goal

Make the supported-smoke runtime audit assert the correct generated entry
module for the in-memory PPIF pipeline result and the correct aggregate top for
the public CLI output, instead of applying one incompatible module oracle to
both surfaces.

## Non-Goals

- Do not change PPIF lowering, artifact selection, CLI aggregation, or HDL.
- Do not weaken the public aggregate-top assertion.
- Do not change VIAL or its semantic-only support classification.
- Do not activate this tree while another task tree owns a dirty worktree.

## Acceptance Criteria

- The PPIF support schema distinguishes an in-memory generated entry artifact
  oracle from a CLI aggregate-top oracle wherever they differ.
- `t/296-regression-corpus-supported-behavior.t` asserts each surface against
  its own declared contract and passes its full default/strict matrix.
- Focused PPIF pipeline, CLI, support-accounting, and defensive-copy gates pass
  without generated HDL changes.
- Project-local temporary output is used and removed exactly.
- Task index, continuity records, and changelog are synchronized and the slice
  commits through `COMMIT.md`.

## Task Tree

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT`
  Status: `proposed`
  Goal: `Separate PPIF in-memory entry-module and CLI aggregate-top support oracles.`
  Children: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1`

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1`
  Status: `pending`
  Goal: `Repair the supported-smoke PPIF runtime audit without changing product output.`
  Acceptance: `Each PPIF entry declares and proves the in-memory generated entry module plus public CLI aggregate top as applicable; t296 and focused PPIF/support gates pass with unchanged HDL bytes and semantic reports.`
  Verification: `Discovery during HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3: after semantic-only VIAL is correctly excluded from HDL generation, t296 repeatedly expects module ahb_tb in an in-memory pipeline result whose source_info.generated_hdl_entry_artifact is ahb_interconnect.fsm and whose hdl_code contains module ahb_interconnect. The public CLI output for the same ppif/ahb_interconnect.ppif source contains amba_requester, ahb_interconnect, ahb_lite_subordinate, and aggregate module ahb_tb. t296 _assert_entry_hdl_shape currently applies expected_module_name=ahb_tb to both surfaces. The failing run was stopped after deterministic repeated PPIF mismatches to avoid generating further redundant output.`
  Commit: `pending activation after the current dirty VIAL slice is committed cleanly`

## Decisions

- `2026-07-31`: Treat the mismatch as an oracle-surface conflation, not a VIAL
  regression and not evidence that the pipeline or CLI should change output.
- `2026-07-31`: Preserve both assertions with separate identities; skipping
  PPIF from the runtime audit is not an acceptable repair.

## Open Questions

- Should the in-memory oracle be declared as an exact module name or derived
  from `source_info.generated_hdl_entry_artifact` and cross-checked against a
  catalog field? Leaf `.1` must select one explicit contract.

## Blockers

- Activation waits for the current dirty VIAL task-tree leaf to commit cleanly.

## Acceptance Checklist (enforced for implementation changes)

- [ ] **ROOT CAUSE (WHY + WHERE)** — `pending fresh staged evidence`
- [ ] **ADDRESSED (verified)** — `pending fresh staged evidence`
- [ ] **NO REGRESSION** — `pending fresh staged evidence`
