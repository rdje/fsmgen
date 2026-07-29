# IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION: Audit Subordinate Output Arbitration

## Metadata

- Tree ID: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION`
- Status: `active`
- Roadmap lane: `IAL2 / AHB subordinate correctness`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Audit and repair generated AHB subordinate output-selector overlaps between
transaction-state defaults, phase capture/hold rules, response retirement,
and data-phase drives so endpoint assertions can remain enabled.

## Origin And Evidence

During
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.2`, a same-volume
feasibility run suppressed only the generated interconnect assertion block and
compiled the existing one-window paired harness without `--no-assert`.
Requester and subordinate assertions remained active. The runtime stopped at
cycle 345 in `dut.regs` with:

```text
selector same-value conflict: HRDATA_REGS 0 enables=01100000
```

The ordered vector proves the generated transaction idle state's
`HRDATA_REGS <- 0` and generated `ahb_phase_capture` rule's
`HRDATA_REGS <- 0` are simultaneously enabled on the first selected ready
active phase. `AhbSubordinate.pm` authors both source families. The complete
affected-output set and interaction with same-edge completion capture have not
yet been audited.

## Non-Goals

- Do not weaken or disable generic selector assertions.
- Do not fold this endpoint issue into the interconnect-local repair.
- Do not assume the first `HRDATA_REGS` assertion is the complete conflict set.
- Do not select an AHB generator-local versus generic ISF priority repair
  before source, IAL1, IAL0, HDL, and runtime evidence is complete.
- Do not broaden public AHB syntax, queues, managers, protocols, backends,
  VHDL, or decision 0020.

## Acceptance Criteria

- Reproduce the endpoint failure without relying on the interconnect conflict.
- Decode the complete same-value and multi-value assertion set across base,
  byte-lane, HBURST/SEQ, BUSY-parking, and direct/generated subordinate forms.
- Trace transaction-state defaults, `ahb_phase_capture`, `ahb_phase_hold`,
  `ahb_error_retire`, enter/wait, success/read/write, and two-cycle ERROR
  ownership through IAL1, IAL0, and HDL.
- Prove initial capture, wait, current completion plus next-phase capture,
  read data, write, success, ERROR, SEQ, BUSY, and IDLE boundaries.
- Decide whether the smallest honest repair belongs in `AhbSubordinate.pm`,
  generic rule/transaction priority enforcement, or another exact owner.
- Freeze a separate contract/implementation leaf, preservation, resource cap,
  rollback, docs, and assertion-enabled paired handoff before behavior changes.

## Task Tree

- ID: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION`
  Status: `active`
  Goal: `Make generated AHB subordinate output arbitration assertion-clean without masking ownership conflicts.`
  Children: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1`

- ID: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1`
  Status: `active`
  Goal: `Audit the complete subordinate output-overlap set and select the smallest repair owner.`
  Acceptance: `Activate only from a clean tree after the current interconnect work reaches a handoff-ready boundary. Reproduce the exact idle plus ahb_phase_capture HRDATA_REGS zero overlap independently; map all generated subordinate same-value/multi-value output selectors and phase/completion conditions across current variants; distinguish AHB-generator authoring from generic rule/transaction priority behavior; freeze a separate no-behavior contract or prerequisite with assertion-enabled runtime gates, preservation, same-volume disposal, the director-authorized macOS host-max 100 / descendant 4096-MiB profile, exact Stats-compatible capacity reporting, separate kernel-pressure reporting, and rollback. Do not change shipped behavior in the audit.`
  Verification: `pending`
  Commit: `pending`

## Activation Gate

Satisfied. Parent selector `.814` committed cleanly at `ece98c002` after the
interconnect tree completed at `6eeac974c`; the separately parked scalability
requirement then committed without a priority pivot at clean boundary
`54964456f`. Leaf `.1` activates from that boundary as a documentation-only
slice. No source, generator, test, artifact, HDL, or runtime behavior changes
in activation.

## Blockers

- None. Audit `.1` is the active frontier.

## Rollback

Before activation, rollback removes this proposed task/fact/index entry only.
After activation, rollback must follow the selected child contract and restore
generator plus assertion expectations together.
