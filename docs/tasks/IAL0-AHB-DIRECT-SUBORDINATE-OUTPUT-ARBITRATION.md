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
  Status: `active`
  Goal: `Make direct AHB subordinate output modes exclusive and assertion-clean.`
  Children: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1, IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.2`

- ID: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1`
  Status: `done`
  Goal: `Select the exact exclusive direct-seed output-mode contract and implementation boundary.`
  Acceptance: `Activate only through a later clean-boundary roadmap selector after the generated endpoint priority completes or explicitly defers. Reconcile the audit, fsm/ahb_lite_subordinate.fsm, t1520, output selector metadata, access/wait/read/write/ERROR/completion-edge modes, generic assertion invariants, public preservation, same-volume cleanup, the authorized macOS host-max 100 / descendant 4096-MiB profile with exact capacity and separate kernel-pressure reporting, and rollback. Freeze a separate implementation leaf before changing the seed.`
  Verification: `Selected removal of exactly four redundant zero writes: access HREADYOUT/HRESP/HRDATA and unsupported HRESP. The current emitter's implicit zero mux baseline preserves values where conditional nonzero access/ERROR owners remain, while already-exclusive unsupported HREADYOUT/HRDATA zero drives stay explicit. A repository-local exact-four candidate lowered through public bin/fsmgen, compiled without --no-assert, retained all selector assertions, and passed the complete t1520 harness with unchanged exact success, active-ERROR, SEQ-to-ERROR, ERROR-to-IDLE, ready-low, error-cycle, capture/completion, and storage results. An earlier safe six-write candidate was rejected as broader because it also removed exclusive unsupported HREADYOUT/HRDATA ownership. The 28-file/1,116,367-byte six-write workspace and 27-file/1,102,673-byte selected workspace were removed with no residue. Knowledge Map regeneration produced 1019 facts/5185 question keys, mdBook built successfully, all doctrine checks passed, and its exact 72-file/16,098,053-byte build output was removed with no residue. Post-gate Stats-compatible host capacity was 52.6% (12.61/24.00 GiB) with kernel pressure 1 (normal); ram-guard occupancy was not used as capacity truth. Proposed .2 owns the exact source/test/docs implementation after this contract commits cleanly. No shipped behavior changed.`
  Commit: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1: select implicit-zero output contract`

- ID: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.2`
  Status: `proposed`
  Goal: `Implement the selected four-write direct-seed arbitration repair and retire t1520 assertion suppression.`
  Acceptance: `Activate only from the clean .1 contract commit. Remove exactly HREADYOUT/HRESP/HRDATA zero writes from access and the HRESP zero write from unsupported in fsm/ahb_lite_subordinate.fsm; retain unsupported HREADYOUT/HRDATA zero drives, all idle/error_complete drives, conditional access success/read/error and unsupported ERROR drives, storage, Q-named capture, transitions, names, widths, and generic same-value/multi-value assertions. Update t1520 structural checks for the exact removals, retained explicit owners, and emitted implicit zero baselines; remove only Verilator --no-assert and prove unchanged exact success/active-ERROR/SEQ-to-ERROR/ERROR-to-IDLE results. Preserve strict/check JSON, module/source/support/artifact identities, t1211/t1219, generated endpoint t1519, t248/t297 accounting, all public/report/semantic-MCP surfaces, protocols/backends/VHDL, HIAL/VIAL, and decision 0020. Synchronize behavior docs/README/roadmap/mdBook/task/index/Memory/Knowledge Map; use repository-derived same-volume storage, authorized host100/process4096, exact Stats-compatible capacity plus separate kernel pressure, exact cleanup census, and rollback.`
  Verification: `pending`
  Commit: `pending`

## Activation Gate

Satisfied. Parent selector `.815` committed cleanly at `8cae38a73` after the
generated endpoint tree completed at `1eec6253d`. Leaf `.1` activates from
that clean boundary as a documentation-only slice. No source, test, generated
artifact, selector, HDL, or runtime behavior changes in activation.

Contract `.1` selects proposed implementation `.2`: remove exactly four
conflicting zero writes and retire only t1520's `--no-assert` after a clean
contract commit. See
`docs/IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md`.

## Blockers

- None. Contract selector `.1` is complete; implementation `.2` awaits
  activation from its clean commit boundary.

## Rollback

Rollback of `.1` removes its contract/fact and proposed `.2`. After
implementation activates, restore the four zero writes, t1520 `--no-assert`,
assertion expectations, docs, and tests together.
