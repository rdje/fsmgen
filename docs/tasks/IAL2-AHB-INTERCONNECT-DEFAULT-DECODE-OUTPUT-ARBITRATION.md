# IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION: Repair Interconnect Output Arbitration

## Metadata

- Tree ID: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION`
- Status: `done`
- Roadmap lane: `IAL2 / AHB interconnect correctness`
- Created: `2026-07-24`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Repair the generated AHB interconnect's overlapping default and mapped-decode
output selectors so aggregate HDL can run with generated selector assertions
enabled.

## Origin And Evidence

`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.3` enabled generated
assertions while propagating exact requester BUSY cardinality into the paired
aggregate. The requester passed all assertion-enabled continuous, ready-low,
and grant-low scenarios. The first mapped paired transfer instead stopped in
the unchanged interconnect with:

```text
selector multi-value conflict: HADDR_REGS
```

The generated interconnect unconditionally enables the state-default
`HADDR_REGS <- 0` selector and simultaneously enables
`HADDR_REGS <- HADDR` for every mapped active transfer. The overlap follows
directly from `AhbInterconnect.pm`'s idle-state default assignments plus its
conditional mapped-hit block, is present in the base non-BUSY aggregate, and
does not depend on the requester repair. Existing paired and phase-pipeline
runtime tests deliberately compile with `--no-assert`, so this was not a new
regression.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.813` later reconciled the complete
exact-one/two/three requester and exact-two paired lineage and selected this
audit as the next proposed correctness owner. Exact-three paired expansion
would otherwise extend the same public aggregate family while its generated
selector assertions remain disabled.

## Non-Goals

- Do not activate or repair this while the requester BUSY `.3` worktree is
  dirty; finish that tree and restore a clean handoff first.
- Do not change AHB decode windows, data-phase ownership, response mapping,
  unmapped two-cycle ERROR behavior, requester BUSY behavior, or public source
  syntax as part of the audit.
- Do not conflate this same-state default/conditional overlap with the
  separately tracked ISF rule-versus-transaction priority gap.

## Acceptance Criteria

- Reproduce the conflict from a base non-BUSY mapped aggregate at address zero
  and a nonzero in-window address with generated assertions enabled.
- Trace `HADDR_REGS`, `HSEL_REGS`, `HREADY`, `HRESP`, and `HRDATA` default,
  mapped-hit, data-owner, and unmapped selector families through generated
  IAL0 and HDL; determine the complete affected-output set.
- Decide whether the smallest honest repair belongs in AHB generated IAL0,
  generic FSM output-priority lowering, or shared selector-conflict analysis.
- Freeze exact assertion-enabled base/one-window/two-window runtime gates,
  public/report/artifact preservation, validation, resource cap, and rollback
  before any behavior change.

## Task Tree

- ID: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION`
  Status: `done`
  Goal: `Repair generated AHB interconnect default/decode output arbitration.`
  Children: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1, IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.2, IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.3`

- ID: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1`
  Status: `done`
  Goal: `Audit the exact selector-overlap set and select the smallest repair owner.`
  Acceptance: `Starting only from a clean tree after the requester BUSY work dries out, reproduce base mapped address-zero/nonzero conflicts with assertions enabled, map every affected output selector through generated IAL0/HDL, distinguish AHB-generator versus generic-lowering ownership, and select an exact contract or repair leaf without changing behavior.`
  Verification: `Fresh base ppif/ahb_interconnect.ppif generation and an assertion-enabled Verilator harness reproduced selector multi-value conflict: HADDR_REGS at cycle 315 for separate mapped +ADDR=0 and +ADDR=2 runs. Address zero proves independently enabled 0 versus HADDR families conflict even when their values happen to agree. Fresh generated metadata reports eight one-window selector targets and eleven two-window targets. The actual overlapping output set is five for one window (HADDR_REGS, HSEL_REGS, HRDATA, HREADY, HRESP) and seven for two windows (HADDR_STATUS/HSEL_STATUS, HADDR_CONTROL/HSEL_CONTROL, HRDATA, HREADY, HRESP). HGRANT, ahb_data_owner_N_q, and next_state are instrumented but state/condition-exclusive. AhbInterconnect.pm authors the overlaps; LoweredRTLIRBuilder and GeneratedModuleEmitter correctly preserve the independent families and emit onehot0 assertions, so generic lowering is not the repair owner and assertions must not be weakened. Git history audit attributes the original one-window shape to ab4838dd5, two-window replication to 700ff29dd, and retained-owner response mux extension to 3e1dcc930; later t1513/t1515/t1523/t1525 compile with --no-assert. Canonical audit/fact record the exact evidence and select proposed .2 for generator-local mutually exclusive arbitration contract selection. Initial guarded attempts stopped safely at 97.3% host pressure; after the unrelated external compiler released memory, all generation/compile/runtime/metadata commands ran under the unchanged 88%/4096-MiB guard, with admitted start metrics from 65.6% through 85.5%. The exact 45-file/2,663,969-byte disposable workspace was removed and a residue census returned none. Knowledge Map generation/check passes at 1,008 facts/5,124 question keys; mdBook build, memory architecture, relative-doc paths, README entry point, project-data locality, diff/fact-reverify, and all doctrine gates pass; generated book output was removed. No behavior changed.`
  Commit: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1: audit interconnect selector overlap`

- ID: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.2`
  Status: `done`
  Goal: `Freeze the exact generated-IAL0 mutually exclusive arbitration contract and implementation gates.`
  Acceptance: `Activate only after .1 commits cleanly. Read .1, docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_AUDIT.md, the current one-/two-window interconnect sources, AhbInterconnect.pm, generated IAL1/IAL0/HDL selector metadata, LoweredRTLIRBuilder, GeneratedModuleEmitter, t1478/t1480 and affected paired runtimes t1513-t1516/t1523/t1525, current reports/artifacts/normalized semantic JSON/read-only MCP surfaces, README, ROADMAP_V2, mdBook, Memory, Knowledge Map, and the existing mapped-owner-to-unmapped non-promise. Select the exact generator-local IAL0 contract: mutually exclusive per-window mapped-hit/not-hit HSEL/HADDR drives; mutually exclusive retained-owner/unmapped-first-cycle/ordinary-default HREADY/HRESP/HRDATA drives; no priority masking of impossible multiple owners; unchanged HGRANT/input visibility, owner capture/clear/same-edge mapped replacement, next_state, unmapped_error_complete, decode windows, local translation, wait/response behavior, public syntax/ports/reports/support/artifacts/semantic-MCP surfaces; unchanged generic selector analysis and assertions. Freeze a separate implementation leaf and focused t1530 assertion-enabled one-/two-window mapped-zero/nonzero/success/wait/subordinate-ERROR/unmapped-ERROR proof. Feasibility-probe whether the affected exact-one/exact-two paired runtime family can remove --no-assert; remove it only if requester, fabric, and subordinate assertions all pass, otherwise retain the boundary and route the independent failure to a durable proposed owner. Require preservation/accounting/docs/doctrine gates, same-volume disposable paths, unchanged 88% host/4096-MiB descendant cap, and rollback. Do not change code, parser, generator, public source, support, test, artifact, report/schema, semantic/MCP API, HDL/runtime, backend, protocol, VHDL, or transaction-layer behavior in this contract slice. Keep the generic ISF priority owner and decision 0020 inactive.`
  Verification: `Selected the exact AhbInterconnect.pm generated-IAL0 repair: each window gets complementary mapped-hit/not-hit HSEL/HADDR drives; global HREADY/HRESP/HRDATA get retained-owner, first-cycle unmapped-error, or ordinary-default modes where ordinary is (! any_owner) && (! unmapped_address); owner blocks remain independent so impossible multiple ownership still trips generic assertions. HGRANT/input visibility, owner capture/hold/clear/same-edge mapped replacement, next_state, two-cycle unmapped completion, decode/local translation, wait/response, public/report/support/artifact/semantic-MCP surfaces, generic selector analysis, and the mapped-owner-to-unmapped non-promise remain unchanged. Proposed .3 owns implementation and direct generated-fabric t1530 assertion-enabled one-/two-window mapped-zero/nonzero/success/wait/subordinate-ERROR/unmapped-ERROR proof. A same-volume feasibility run disabled only the disposable fabric assertion block and compiled the existing one-window paired harness without --no-assert; definitive guarded runtime admitted at 70.9% stopped at cycle 345 in dut.regs with selector same-value conflict: HRDATA_REGS 0 enables=01100000. The vector proves the subordinate transaction idle-state HRDATA_REGS<-0 and ahb_phase_capture rule HRDATA_REGS<-0 overlap, independently of the fabric. Therefore .3 retains --no-assert in t1513-t1516/t1523/t1525 and proposed IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1 owns the endpoint audit. Earlier attempts were safely refused above the fixed host cutoff; no cutoff was raised and no unrelated process was disturbed. The exact disposable workspace contained 45 files/53,032,662 bytes, was deleted, and residue is none. Canonical contract/facts/task, roadmap, task index, README, mdBook, Memory, and Knowledge Map are synchronized; validation is recorded by this commit. No shipped behavior changed.`
  Commit: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.2: select mutually exclusive arbitration contract`

- ID: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.3`
  Status: `done`
  Goal: `Implement assertion-clean generated AHB interconnect output arbitration.`
  Acceptance: `Activate only after .2 commits cleanly. Change only AhbInterconnect.pm generated IAL0 construction so each window has complementary mapped-hit/not-hit HSEL/HADDR and global HREADY/HRESP/HRDATA have exclusive retained-owner, first-cycle-unmapped, or ordinary-default modes; preserve independent owner blocks, HGRANT/input visibility, owner capture/hold/clear/same-edge mapped replacement, next_state, unmapped_error_complete, decode/local translation, wait/response behavior, the mapped-owner-to-unmapped non-promise, generic selector analysis/assertions, public sources/ports/support/reports/artifacts/semantic-MCP surfaces, backends/VHDL, and transaction behavior. Update t1478/t1480 and add t1530 plus task-owned harness data that directly instantiates generated one-/two-window ahb_interconnect modules and runs without --no-assert across mapped zero/nonzero/success/wait/subordinate-ERROR/unmapped-ERROR/status/control/same-edge mapped replacement. Keep --no-assert in t1513-t1516/t1523/t1525 because the independently tracked subordinate idle/phase-capture overlap remains; rerun that family for functional preservation. Require strict/check/schedule/artifact/verifier/semantic-MCP, t1518, t248/t297, docs/mdBook/Knowledge Map/doctrine, same-volume cleanup, the unchanged 4096-MiB descendant guard, and rollback. Director authorization on 2026-07-29 supersedes this leaf's original 88% macOS host setting only: use the canonical host-max-pct 100 / process-max-rss-mb 4096 verification profile because the tracked macOS metric counts reclaimable cache as pressure. Report capacity with the Stats-compatible Mach formula (active + inactive + speculative + wired + compressed - purgeable - external) / physical memory, and report kern.memorystatus_vm_pressure_level separately as the safety state; do not substitute the guard percentage, the earlier inactive/purgeable approximation, or memory_pressure's free percentage. Do not change the guard implementation while this tree is dirty. Do not repair the subordinate, generic ISF priority, mapped-owner-to-unmapped, broader AHB/protocol/backend/VHDL behavior, or decision 0020.`
  Verification: `AhbInterconnect.pm emits complementary per-window hit/not-hit HSEL/HADDR modes and an ordinary global response mode guarded by (! any_owner) && (! unmapped_address), while independent owner blocks preserve impossible-multiple-owner assertion visibility. Updated t1478/t1480 pass. New direct-fabric assertion-enabled t1530 passes one- and two-window mapped-zero/nonzero, local translation, wait, success, subordinate ERROR, same-edge mapped replacement, and two-cycle unmapped ERROR. Preservation t1513-t1516, t1523, and the full unmodified t1525 pass with the existing subordinate-owned --no-assert boundary; t1525 passes 3 top-level subtests in 646 seconds. Guarded t1518 passes 5/5, and t248/t297 pass 6,911 tests. Strict/check/schedule/artifact/verifier/semantic-MCP coverage is retained through those focused and preservation gates. Initial retries stopped only because the macOS guard's free+speculative formula over-reports reclaimable cache. Source inspection of Stats 3.0.9 established the exact capacity formula active+inactive+speculative+wired+compressed-purgeable-external; a same-period vm_stat sample calculated 49.9% against the director's rapidly changing approximately 47% display, with later exact samples at 54.4% and 59.2%. kern.memorystatus_vm_pressure_level remained 1 (normal); memory_pressure -Q's free percentage is a different efficiency signal. Final heavy gates therefore used the authorized host-max 100 / descendant 4096-MiB profile while reporting exact capacity plus kernel state. The temporary t1525 sharding from the false diagnosis was removed and t1525 remained byte-identical to HEAD. No project shutdown or claimed 70% baseline is warranted. The exact same-volume implementation workspace contained 68 files/2,961,033 bytes after final direct builds; it was removed and both task-workspace and t1530 residue censuses are empty. Canonical behavior/docs/README/roadmap/mdBook/facts/task/index/Memory are synchronized. Knowledge Map generation/check passes at 1,011 facts/5,142 question keys; mdBook builds; Perl syntax, diff, memory architecture, relative-doc paths, README entrypoint, project-data locality, and all doctrine gates pass. The exact generated mdBook output contained 72 files/16,011,113 bytes, was removed, and residue is none.`
  Commit: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.3: ship assertion-clean interconnect arbitration`

## Activation Gate

Completed parent selector `.813` committed cleanly at `347a85f80`, and child
`.1` activated from that clean boundary at `70eeeab70`. The audit is now
complete at clean commit `c32255645`, so `.2` activated and is now complete.
It selected implementation child `.3` while routing a separately exposed
subordinate assertion overlap to proposed task
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION`. Contract commit
`3883c3a0d` was clean, so `.3` activated from that handoff-ready boundary and
now completes the interconnect repair with direct assertion-enabled proof.

## Rollback

Before activation, rollback removes this proposed owner and its fact/index
entry only. After activation, rollback follows the selected child contract and
must restore generator plus assertion expectations together.
