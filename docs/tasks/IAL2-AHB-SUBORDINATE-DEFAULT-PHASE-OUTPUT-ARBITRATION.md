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
  Status: `done`
  Goal: `Make generated AHB subordinate output arbitration assertion-clean without masking ownership conflicts.`
  Children: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1, IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.2, IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.3`

- ID: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1`
  Status: `done`
  Goal: `Audit the complete subordinate output-overlap set and select the smallest repair owner.`
  Acceptance: `Activate only from a clean tree after the current interconnect work reaches a handoff-ready boundary. Reproduce the exact idle plus ahb_phase_capture HRDATA_REGS zero overlap independently; map all generated subordinate same-value/multi-value output selectors and phase/completion conditions across current variants; distinguish AHB-generator authoring from generic rule/transaction priority behavior; freeze a separate no-behavior contract or prerequisite with assertion-enabled runtime gates, preservation, same-volume disposal, the director-authorized macOS host-max 100 / descendant 4096-MiB profile, exact Stats-compatible capacity reporting, separate kernel-pressure reporting, and rollback. Do not change shipped behavior in the audit.`
  Verification: `Independently reproduced the richest generated direct endpoint at time 40 on selector same-value conflict: HRDATA 0 and the repaired-fabric paired endpoint at time 345 on HRDATA_REGS 0. Inventoried all shipped generated variants: base has 8 selector targets, byte-lane 10, and SEQ/HBURST/BUSY-park 20; every variant has exactly HRDATA/HREADYOUT/HRESP bus targets, with base 2/2/3 and narrow 8/2/3 RHS families. Diagnostic-only HDL kept internal assertions active and proved generated vectors 01100000 idle+capture, 01010000 idle+hold, 10100000 retire+capture, plus explicit-OKAY HRESP retire+capture. Rich active success/SEQ, ERROR continuation/cancel, and paired four-write/one-BUSY behavior passed. Generic ISF correctly suppresses different-value priority losers but deliberately leaves same-value multiple ownership visible; selected AhbSubordinate.pm-local contract leaf .2. Separately proved the hand-authored IAL0 seed has HREADYOUT/HRDATA/HRESP conditional-override conflicts and routed it to proposed IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION without pivoting. Focused preservation passed 34 tests across ten files in 611 seconds, covering generic selector/priority, every generated variant, paired BUSY, rich generated runtime, and the direct seed. All heavy runs used authorized host100/process4096 with no descendant trip; exact post-audit capacity was 49.5% (11.87/24.00 GiB), kernel pressure 1 normal. The exact same-volume workspace contained 233 files/210,967,439 bytes, was removed, and residue is none. Knowledge Map passes at 1,014 facts/5,155 keys; mdBook builds; all doctrines pass. Generated book output contained 72 files/16,031,568 bytes, was removed, and residue is none. Canonical audit/facts/task/index/roadmap/mdBook/Memory/Knowledge Map are synchronized. No shipped behavior changed.`
  Commit: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1: audit endpoint selector ownership`

- ID: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.2`
  Status: `done`
  Goal: `Select the exact generated subordinate output-ownership contract and implementation boundary.`
  Acceptance: `Activate only after .1 commits cleanly. Read .1, docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_AUDIT.md, AhbSubordinate.pm, all generated base/byte-lane/SEQ/HBURST/BUSY-park IAL1/IAL0/HDL selector families, generic priority/selector owners and tests, direct and aggregate runtime evidence, t1475/t1482/t1486/t1490/t1494/t1513-t1516/t1519/t1523/t1525, public reports/support/artifacts/semantic-MCP surfaces, roadmap, mdBook, Memory, and Knowledge Map. Select exact mutually exclusive transaction-idle/capture/hold/retire/enter/read/write/success/ERROR output modes or only provably redundant assignment removal in AhbSubordinate.pm; preserve initial capture, one-bank backpressure, wait, same-edge completion plus next capture, data, writes, success, two-cycle ERROR, SEQ, BUSY, IDLE, public syntax/ports/names/reports/support/artifacts/semantic-MCP surfaces, generic assertions, direct IAL0 seed ownership, protocols/backends/VHDL, and decision 0020. Freeze a separate implementation leaf with assertion-enabled base/rich direct plus one-/two-window paired gates, removal of --no-assert only where the generated endpoint is the final blocker, preservation, same-volume cleanup, authorized macOS host-max 100 / descendant 4096-MiB profile, exact Stats-compatible capacity plus separate kernel-pressure reporting, and rollback. Do not change shipped behavior in contract selection.`
  Verification: `Selected the smallest generated-IAL1 repair: remove only HRESP/HRDATA writes from ahb_phase_capture and ahb_phase_hold plus HRDATA from ahb_error_retire, while preserving every HREADYOUT write, error-retire HRESP OKAY, enter/read/write/ERROR drives, priorities, and generic assertions. A disposable richest-variant feasibility build changed exactly those five writes, lowered through public bin/fsmgen, compiled with Verilator, and passed the assertion-enabled t1519 runtime unchanged: two active captures/completions with storage 0x00002211, two ERROR-continuation captures/completions with storage 0x000000aa and two error cycles, and one ERROR-cancel capture/completion with zero storage and two error cycles. The reduced HRDATA-zero family has five sources and the explicit-OKAY HRESP family has ten; HREADYOUT is unchanged. All heavy commands used authorized host100/process4096 with no descendant trip; exact post-probe capacity was 40.8% (9.78/24.00 GiB), kernel pressure 1 normal, and the guard percentage was excluded. The repository-local workspace contained 47 files/52,853,130 bytes, was removed, and residue is none. Canonical contract, task/index/roadmap/mdBook/Memory/fact/Knowledge Map are synchronized; Knowledge Map passes at 1,015 facts/5,160 keys. mdBook builds; its 72-file/16,040,224-byte output was removed with no residue. Doctrines pass. No shipped behavior changed.`
  Commit: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.2: select endpoint arbitration contract`

- ID: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.3`
  Status: `done`
  Goal: `Implement the selected five-write generated endpoint arbitration repair and retire generated-endpoint assertion suppressions.`
  Acceptance: `Activate only from the clean .2 contract commit. In perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm remove exactly HRESP/HRDATA from ahb_phase_capture, HRESP/HRDATA from ahb_phase_hold, and HRDATA from ahb_error_retire; preserve all HREADYOUT ownership, error-retire HRESP OKAY, transaction defaults, enter/read/write/success/two-cycle-ERROR drives, priorities, names, ports, widths, and generic same-value/multi-value assertions. Add or update focused assertion-enabled base and richest direct plus one-window and two-window paired runtime gates for initial capture, wait/hold, same-edge success/ERROR completion plus next capture, data, writes, SEQ, BUSY, ERROR-to-IDLE cancellation, and exact capture/completion/storage counts. Remove --no-assert from t1513-t1516/t1519/t1523/t1525 only where the generated endpoint is the final blocker; retain t1520's boundary under proposed IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION. Preserve t1475/t1482/t1486/t1490/t1494 and relevant t1518/t248/t297 surfaces; prove strict/check/schedule/artifact/verifier, report/support/accounting, normalized semantic JSON, read-only MCP, public PPIF/AHB bytes, mdBook examples, Knowledge Map, doctrines, and no protocol/backend/VHDL/decision-0020 expansion. Use repository-derived same-volume storage, authorized host100/process4096, exact Stats-compatible capacity plus separate kernel pressure, exact cleanup census, and rollback.`
  Verification: `AhbSubordinate.pm removes exactly capture/hold HRESP+HRDATA and error-retire HRDATA; every HREADYOUT write, retirement OKAY, transaction default, enter/read/write/two-cycle-ERROR drive, priority, and generic assertion remains. Base HRDATA-zero/explicit-OKAY families are 5/4 sources and richest are 5/10; HREADYOUT is unchanged. Updated structural t1475 and direct base/rich assertion-enabled t1519 pass 3 top-level tests in 48 seconds, preserving exact success/SEQ and ERROR continuation/cancel counts/storage. Removed --no-assert from t1513-t1516/t1523/t1525; all six one-/two-window generic/alias exact-one/exact-two paired files pass 24 tests in 2,649 seconds with requester/fabric/endpoints/internal assertions enabled and exact runtime results unchanged. Generic t1211/t1219 pass 7 tests. Five generated variants plus t1518/t1520/t248/t297/t1444 pass a ten-file 6,943-test preservation cluster in 298 seconds; strict/check/schedule/artifact/verifier, support/accounting, normalized semantic JSON, and read-only MCP surfaces remain covered. Perl syntax passes; checked-in PPIF/AHB sources and direct IAL0 seed are unchanged, and t1520 keeps its separate --no-assert boundary. All heavy commands used host100/process4096 with no descendant trip; exact post-run capacity was 46.7% (11.21/24.00 GiB), kernel pressure 1 normal, and guard percentages were excluded. Implementation workspaces contained 3 files/60,768 bytes, were removed, and residue is none. Canonical behavior/current docs/README/roadmap/mdBook/facts/task/index/Memory are synchronized. Knowledge Map passes at 1,016 facts/5,166 keys. mdBook builds; its 72-file/16,044,477-byte output was removed with no residue. Doctrines pass.`
  Commit: `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.3: ship assertion-clean endpoint arbitration`

## Activation Gate

Satisfied. Parent selector `.814` committed cleanly at `ece98c002` after the
interconnect tree completed at `6eeac974c`; the separately parked scalability
requirement then committed without a priority pivot at clean boundary
`54964456f`. Leaf `.1` activates from that boundary as a documentation-only
slice. No source, generator, test, artifact, HDL, or runtime behavior changes
in activation.

Audit `.1` committed cleanly at `0dad690cb`. Selected contract leaf `.2`
activated from that handoff-ready boundary as a documentation-only slice. It
selects proposed implementation `.3`; the parked direct IAL0 seed task remains
proposed/inactive.

Contract `.2` committed cleanly at `ef14893f5`. Implementation `.3` activates
from that handoff-ready boundary as a documentation-only slice. No source,
generator, test, artifact, HDL, or runtime behavior changes in activation.

Implementation `.3` completes the selected repair and the tree. The generated
endpoint family and all paired aggregates are assertion-enabled; the direct
IAL0 seed remains proposed under its separate owner.

## Blockers

- None. The tree is complete.

## Rollback

Rollback of `.1` removes its audit/fact/index/direct-seed routing and restores
the pre-audit frontier. Rollback of `.2` removes the selected contract and
proposed `.3`; after implementation activates, rollback must restore the five
generated writes and assertion expectations together.
