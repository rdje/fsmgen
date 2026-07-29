# IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION: Direct Seed Output Arbitration

## Metadata

- Tree ID: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION`
- Status: `active`
- Roadmap lane: `IAL0 / AHB direct-seed correctness`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Make the hand-authored `fsm/ahb_lite_subordinate.fsm` output modes
assertion-clean without changing its bounded AHB-Lite behavior.

## Origin And Evidence

Audit `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1` compiled the
direct seed with the existing t1520 harness and all selector assertions
enabled. Runtime stopped first on `selector multi-value conflict: HREADYOUT`.

Diagnostic-only disposable HDL kept every internal assertion enabled and
logged three actual bus-output overlaps while the complete functional harness
passed:

- access default `HREADYOUT=0` plus successful completion `HREADYOUT=1`;
- access default `HRDATA=0` plus read `HRDATA=reg_data_q`;
- access/unsupported default `HRESP=0` plus ERROR `HRESP=1`.

These conditional overrides are authored directly in the IAL0 seed. They are
independent of the generated `AhbSubordinate.pm` phase-rule defect.

## Non-Goals

- Do not weaken generic same-value or multi-value assertions.
- Do not fold this direct-seed repair into the active generated endpoint task.
- Do not change public AHB syntax, reports, support, protocols, backends,
  VHDL, or decision 0020.
- Do not change the bounded word-only/two-cycle-ERROR behavior without a
  separately selected contract.

## Task Tree

- ID: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION`
  Status: `done`
  Goal: `Make direct AHB subordinate output modes exclusive and assertion-clean.`
  Children: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1, IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.2`

- ID: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1`
  Status: `done`
  Goal: `Select the exact exclusive direct-seed output-mode contract and implementation boundary.`
  Acceptance: `Activate only through a later clean-boundary roadmap selector after the generated endpoint priority completes or explicitly defers. Reconcile the audit, fsm/ahb_lite_subordinate.fsm, t1520, output selector metadata, access/wait/read/write/ERROR/completion-edge modes, generic assertion invariants, public preservation, same-volume cleanup, the authorized macOS host-max 100 / descendant 4096-MiB profile with exact capacity and separate kernel-pressure reporting, and rollback. Freeze a separate implementation leaf before changing the seed.`
  Verification: `Selected removal of exactly four redundant zero writes: access HREADYOUT/HRESP/HRDATA and unsupported HRESP. The current emitter's implicit zero mux baseline preserves values where conditional nonzero access/ERROR owners remain, while already-exclusive unsupported HREADYOUT/HRDATA zero drives stay explicit. A repository-local exact-four candidate lowered through public bin/fsmgen, compiled without --no-assert, retained all selector assertions, and passed the complete t1520 harness with unchanged exact success, active-ERROR, SEQ-to-ERROR, ERROR-to-IDLE, ready-low, error-cycle, capture/completion, and storage results. An earlier safe six-write candidate was rejected as broader because it also removed exclusive unsupported HREADYOUT/HRDATA ownership. The 28-file/1,116,367-byte six-write workspace and 27-file/1,102,673-byte selected workspace were removed with no residue. Knowledge Map regeneration produced 1019 facts/5185 question keys, mdBook built successfully, all doctrine checks passed, and its exact 72-file/16,098,053-byte build output was removed with no residue. Post-gate Stats-compatible host capacity was 52.6% (12.61/24.00 GiB) with kernel pressure 1 (normal); ram-guard occupancy was not used as capacity truth. Contract selection changed no shipped behavior; completed .2 now owns and ships its exact source/test/docs implementation.`
  Commit: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1: select implicit-zero output contract`

- ID: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.2`
  Status: `done`
  Goal: `Implement the selected four-write direct-seed arbitration repair and retire t1520 assertion suppression.`
  Acceptance: `Activate only from the clean .1 contract commit. Remove exactly HREADYOUT/HRESP/HRDATA zero writes from access and the HRESP zero write from unsupported in fsm/ahb_lite_subordinate.fsm; retain unsupported HREADYOUT/HRDATA zero drives, all idle/error_complete drives, conditional access success/read/error and unsupported ERROR drives, storage, Q-named capture, transitions, names, widths, and generic same-value/multi-value assertions. Update t1520 structural checks for the exact removals, retained explicit owners, and emitted implicit zero baselines; remove only Verilator --no-assert and prove unchanged exact success/active-ERROR/SEQ-to-ERROR/ERROR-to-IDLE results. Preserve strict/check JSON, module/source/support/artifact identities, t1211/t1219, generated endpoint t1519, t248/t297 accounting, all public/report/semantic-MCP surfaces, protocols/backends/VHDL, HIAL/VIAL, and decision 0020. Synchronize behavior docs/README/roadmap/mdBook/task/index/Memory/Knowledge Map; use repository-derived same-volume storage, authorized host100/process4096, exact Stats-compatible capacity plus separate kernel pressure, exact cleanup census, and rollback.`
  Verification: `Activated from clean contract commit 454767c15 at 37d7b9b04, then removed exactly access HREADYOUT/HRESP/HRDATA zero writes and unsupported HRESP zero. Retained unsupported HREADYOUT/HRDATA zero, all idle/error_complete drives, conditional access success/read/error plus unsupported ERROR, storage, Q-named capture, transitions, names, widths, and generic assertions. t1520 now checks exact source removals/retained owners, emitted zero baselines/selector identities, and compiles without --no-assert; 2 top-level subtests and all four exact success/active-ERROR/SEQ-to-ERROR/ERROR-to-IDLE scenarios pass unchanged with selector assertions enabled. Strict/check JSON passes with zero diagnostics, module ahb_lite_subordinate, 4 states, 11 signals, and matched protocol.ahb_lite_subordinate identity. Generic selector/priority t1211/t1219 pass 2 files/7 tests; generated endpoint t1519 passes 1 file/3 tests; accounting/capability t248/t297 pass 2 files/6911 tests. Public/report/semantic-MCP, generated IAL2, protocol/backend/VHDL, HIAL/VIAL, and decision-0020 boundaries are unchanged. Knowledge Map is synchronized at 1020 facts/5190 question keys; mdBook and every doctrine check pass. The exact 72-file/16,111,896-byte book output was removed with no residue, and repo-local test temporaries returned to the observed six-entry pre-existing baseline without touching those entries. Post-gate Stats-compatible capacity was 48.8% (11.72/24.00 GiB), kernel pressure was 1 (normal), and ram-guard occupancy was excluded as capacity truth.`
  Commit: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.2: ship assertion-clean direct seed arbitration`

## Activation Gate

Satisfied. Parent selector `.815` committed cleanly at `8cae38a73` after the
generated endpoint tree completed at `1eec6253d`. Leaf `.1` activates from
that clean boundary as a documentation-only slice. No source, test, generated
artifact, selector, HDL, or runtime behavior changes in activation.

Contract `.1` committed cleanly at `454767c15`. Implementation `.2` activates
from that handoff-ready boundary as a documentation-only slice. It will remove
exactly four conflicting zero writes and retire only t1520's `--no-assert`.
No source, test, generated artifact, HDL, or runtime behavior changes in
activation. See
`docs/IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md`.

## Blockers

- None. Implementation `.2` and this task tree are complete; the parent IAL2
  frontier may select its next owner only after the behavior commit is clean.

## Rollback

Rollback of `.1` removes its contract/fact and proposed `.2`. After
implementation activates, restore the four zero writes, t1520 `--no-assert`,
assertion expectations, docs, and tests together.
