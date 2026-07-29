# IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION: Repair Interconnect Output Arbitration

## Metadata

- Tree ID: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION`
- Status: `active`
- Roadmap lane: `IAL2 / AHB interconnect correctness`
- Created: `2026-07-24`
- Last updated: `2026-07-24`
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
  Children: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1`

- ID: `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1`
  Status: `active`
  Goal: `Audit the exact selector-overlap set and select the smallest repair owner.`
  Acceptance: `Starting only from a clean tree after the requester BUSY work dries out, reproduce base mapped address-zero/nonzero conflicts with assertions enabled, map every affected output selector through generated IAL0/HDL, distinguish AHB-generator versus generic-lowering ownership, and select an exact contract or repair leaf without changing behavior.`
  Verification: `pending`
  Commit: `pending`

## Activation Gate

Completed parent selector `.813` committed cleanly at `347a85f80`. Child `.1`
is now active from that clean boundary. This activation changes only
task/index/Memory/roadmap/mdBook/Knowledge Map state; reproduction, audit
findings, and repair-owner selection remain the next task.

## Rollback

Before activation, rollback removes this proposed owner and its fact/index
entry only. After activation, rollback follows the selected child contract and
must restore generator plus assertion expectations together.
