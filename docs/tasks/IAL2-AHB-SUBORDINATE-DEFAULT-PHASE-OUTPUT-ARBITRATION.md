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
  Children: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1, IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.2`

- ID: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1`
  Status: `done`
  Goal: `Audit the complete subordinate output-overlap set and select the smallest repair owner.`
  Acceptance: `Activate only from a clean tree after the current interconnect work reaches a handoff-ready boundary. Reproduce the exact idle plus ahb_phase_capture HRDATA_REGS zero overlap independently; map all generated subordinate same-value/multi-value output selectors and phase/completion conditions across current variants; distinguish AHB-generator authoring from generic rule/transaction priority behavior; freeze a separate no-behavior contract or prerequisite with assertion-enabled runtime gates, preservation, same-volume disposal, the director-authorized macOS host-max 100 / descendant 4096-MiB profile, exact Stats-compatible capacity reporting, separate kernel-pressure reporting, and rollback. Do not change shipped behavior in the audit.`
  Verification: `Independently reproduced the richest generated direct endpoint at time 40 on selector same-value conflict: HRDATA 0 and the repaired-fabric paired endpoint at time 345 on HRDATA_REGS 0. Inventoried all shipped generated variants: base has 8 selector targets, byte-lane 10, and SEQ/HBURST/BUSY-park 20; every variant has exactly HRDATA/HREADYOUT/HRESP bus targets, with base 2/2/3 and narrow 8/2/3 RHS families. Diagnostic-only HDL kept internal assertions active and proved generated vectors 01100000 idle+capture, 01010000 idle+hold, 10100000 retire+capture, plus explicit-OKAY HRESP retire+capture. Rich active success/SEQ, ERROR continuation/cancel, and paired four-write/one-BUSY behavior passed. Generic ISF correctly suppresses different-value priority losers but deliberately leaves same-value multiple ownership visible; selected AhbSubordinate.pm-local contract leaf .2. Separately proved the hand-authored IAL0 seed has HREADYOUT/HRDATA/HRESP conditional-override conflicts and routed it to proposed IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION without pivoting. Focused preservation passed 34 tests across ten files in 611 seconds, covering generic selector/priority, every generated variant, paired BUSY, rich generated runtime, and the direct seed. All heavy runs used authorized host100/process4096 with no descendant trip; exact post-audit capacity was 49.5% (11.87/24.00 GiB), kernel pressure 1 normal. The exact same-volume workspace contained 233 files/210,967,439 bytes, was removed, and residue is none. Knowledge Map passes at 1,014 facts/5,155 keys; mdBook builds; all doctrines pass. Generated book output contained 72 files/16,031,568 bytes, was removed, and residue is none. Canonical audit/facts/task/index/roadmap/mdBook/Memory/Knowledge Map are synchronized. No shipped behavior changed.`
  Commit: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1: audit endpoint selector ownership`

- ID: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.2`
  Status: `proposed`
  Goal: `Select the exact generated subordinate output-ownership contract and implementation boundary.`
  Acceptance: `Activate only after .1 commits cleanly. Read .1, docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_AUDIT.md, AhbSubordinate.pm, all generated base/byte-lane/SEQ/HBURST/BUSY-park IAL1/IAL0/HDL selector families, generic priority/selector owners and tests, direct and aggregate runtime evidence, t1475/t1482/t1486/t1490/t1494/t1513-t1516/t1519/t1523/t1525, public reports/support/artifacts/semantic-MCP surfaces, roadmap, mdBook, Memory, and Knowledge Map. Select exact mutually exclusive transaction-idle/capture/hold/retire/enter/read/write/success/ERROR output modes or only provably redundant assignment removal in AhbSubordinate.pm; preserve initial capture, one-bank backpressure, wait, same-edge completion plus next capture, data, writes, success, two-cycle ERROR, SEQ, BUSY, IDLE, public syntax/ports/names/reports/support/artifacts/semantic-MCP surfaces, generic assertions, direct IAL0 seed ownership, protocols/backends/VHDL, and decision 0020. Freeze a separate implementation leaf with assertion-enabled base/rich direct plus one-/two-window paired gates, removal of --no-assert only where the generated endpoint is the final blocker, preservation, same-volume cleanup, authorized macOS host-max 100 / descendant 4096-MiB profile, exact Stats-compatible capacity plus separate kernel-pressure reporting, and rollback. Do not change shipped behavior in contract selection.`
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

- None. Audit `.1` selects proposed contract leaf `.2`; activation awaits the
  clean audit commit.

## Rollback

Rollback of `.1` removes its audit/fact/index/direct-seed routing and restores
the pre-audit frontier. After `.2` activates, rollback must follow its selected
contract and restore generator plus assertion expectations together.
