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
  Children: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1`

- ID: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1`
  Status: `active`
  Goal: `Select the exact exclusive direct-seed output-mode contract and implementation boundary.`
  Acceptance: `Activate only through a later clean-boundary roadmap selector after the generated endpoint priority completes or explicitly defers. Reconcile the audit, fsm/ahb_lite_subordinate.fsm, t1520, output selector metadata, access/wait/read/write/ERROR/completion-edge modes, generic assertion invariants, public preservation, same-volume cleanup, the authorized macOS host-max 100 / descendant 4096-MiB profile with exact capacity and separate kernel-pressure reporting, and rollback. Freeze a separate implementation leaf before changing the seed.`
  Verification: `Activated from clean selector commit 8cae38a73 after .815 selected this direct-seed correctness owner from the completed assertion-clean generated endpoint boundary. Activation changes task/index/Memory/roadmap/mdBook/fact continuity only; no seed, test, generated artifact, selector, HDL, or runtime behavior changed.`
  Commit: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1: activate direct seed arbitration contract`

## Activation Gate

Satisfied. Parent selector `.815` committed cleanly at `8cae38a73` after the
generated endpoint tree completed at `1eec6253d`. Leaf `.1` activates from
that clean boundary as a documentation-only slice. No source, test, generated
artifact, selector, HDL, or runtime behavior changes in activation.

## Blockers

- None. Contract selector `.1` is the active frontier.

## Rollback

Before activation, rollback removes this proposed task/fact/index entry only.
After activation, follow the selected contract and restore the direct seed,
assertion expectations, docs, and tests together.
