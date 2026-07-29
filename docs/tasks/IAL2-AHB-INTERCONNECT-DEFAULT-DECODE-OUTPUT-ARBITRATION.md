# IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION: Repair Interconnect Output Arbitration

## Metadata

- Tree ID: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION`
- Status: `active`
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
  Status: `active`
  Goal: `Repair generated AHB interconnect default/decode output arbitration.`
  Children: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1, IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.2`

- ID: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1`
  Status: `done`
  Goal: `Audit the exact selector-overlap set and select the smallest repair owner.`
  Acceptance: `Starting only from a clean tree after the requester BUSY work dries out, reproduce base mapped address-zero/nonzero conflicts with assertions enabled, map every affected output selector through generated IAL0/HDL, distinguish AHB-generator versus generic-lowering ownership, and select an exact contract or repair leaf without changing behavior.`
  Verification: `Fresh base ppif/ahb_interconnect.ppif generation and an assertion-enabled Verilator harness reproduced selector multi-value conflict: HADDR_REGS at cycle 315 for separate mapped +ADDR=0 and +ADDR=2 runs. Address zero proves independently enabled 0 versus HADDR families conflict even when their values happen to agree. Fresh generated metadata reports eight one-window selector targets and eleven two-window targets. The actual overlapping output set is five for one window (HADDR_REGS, HSEL_REGS, HRDATA, HREADY, HRESP) and seven for two windows (HADDR_STATUS/HSEL_STATUS, HADDR_CONTROL/HSEL_CONTROL, HRDATA, HREADY, HRESP). HGRANT, ahb_data_owner_N_q, and next_state are instrumented but state/condition-exclusive. AhbInterconnect.pm authors the overlaps; LoweredRTLIRBuilder and GeneratedModuleEmitter correctly preserve the independent families and emit onehot0 assertions, so generic lowering is not the repair owner and assertions must not be weakened. Git history audit attributes the original one-window shape to ab4838dd5, two-window replication to 700ff29dd, and retained-owner response mux extension to 3e1dcc930; later t1513/t1515/t1523/t1525 compile with --no-assert. Canonical audit/fact record the exact evidence and select proposed .2 for generator-local mutually exclusive arbitration contract selection. Initial guarded attempts stopped safely at 97.3% host pressure; after the unrelated external compiler released memory, all generation/compile/runtime/metadata commands ran under the unchanged 88%/4096-MiB guard, with admitted start metrics from 65.6% through 85.5%. The exact 45-file/2,663,969-byte disposable workspace was removed and a residue census returned none. Knowledge Map generation/check passes at 1,008 facts/5,124 question keys; mdBook build, memory architecture, relative-doc paths, README entry point, project-data locality, diff/fact-reverify, and all doctrine gates pass; generated book output was removed. No behavior changed.`
  Commit: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1: audit interconnect selector overlap`

- ID: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.2`
  Status: `active`
  Goal: `Freeze the exact generated-IAL0 mutually exclusive arbitration contract and implementation gates.`
  Acceptance: `Activate only after .1 commits cleanly. Read .1, docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_AUDIT.md, the current one-/two-window interconnect sources, AhbInterconnect.pm, generated IAL1/IAL0/HDL selector metadata, LoweredRTLIRBuilder, GeneratedModuleEmitter, t1478/t1480 and affected paired runtimes t1513-t1516/t1523/t1525, current reports/artifacts/normalized semantic JSON/read-only MCP surfaces, README, ROADMAP_V2, mdBook, Memory, Knowledge Map, and the existing mapped-owner-to-unmapped non-promise. Select the exact generator-local IAL0 contract: mutually exclusive per-window mapped-hit/not-hit HSEL/HADDR drives; mutually exclusive retained-owner/unmapped-first-cycle/ordinary-default HREADY/HRESP/HRDATA drives; no priority masking of impossible multiple owners; unchanged HGRANT/input visibility, owner capture/clear/same-edge mapped replacement, next_state, unmapped_error_complete, decode windows, local translation, wait/response behavior, public syntax/ports/reports/support/artifacts/semantic-MCP surfaces; unchanged generic selector analysis and assertions. Freeze a separate implementation leaf, focused t1530 assertion-enabled one-/two-window mapped-zero/nonzero/success/wait/subordinate-ERROR/unmapped-ERROR proof, removal of --no-assert from the affected exact-one/exact-two paired runtime family, preservation/accounting/docs/doctrine gates, same-volume disposable paths, unchanged 88% host/4096-MiB descendant cap, and rollback. Do not change code, parser, generator, public source, support, test, artifact, report/schema, semantic/MCP API, HDL/runtime, backend, protocol, VHDL, or transaction-layer behavior in this contract slice. Keep the generic ISF priority owner and decision 0020 inactive.`
  Verification: `pending`
  Commit: `pending`

## Activation Gate

Completed parent selector `.813` committed cleanly at `347a85f80`, and child
`.1` activated from that clean boundary at `70eeeab70`. The audit is now
complete at clean commit `c32255645`, so `.2` is active. This activation
changes only task/index/Memory/roadmap/mdBook/Knowledge Map state; exact
contract selection remains the next action and no behavior changes in this
boundary.

## Rollback

Before activation, rollback removes this proposed owner and its fact/index
entry only. After activation, rollback follows the selected child contract and
must restore generator plus assertion expectations together.
