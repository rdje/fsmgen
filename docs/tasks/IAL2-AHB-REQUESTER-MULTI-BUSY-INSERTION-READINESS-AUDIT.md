# IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT: Audit Bounded Multiple BUSY Presentations

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT`
- Status: `proposed`
- Roadmap lane: `IAL2 / AHB requester BUSY policy`
- Created: `2026-07-23`
- Last updated: `2026-07-23`
- Owner: repo-local workflow

## Goal

Audit the smallest bounded extension from the shipped single requester
`HTRANS=BUSY` insertion to more than one consecutive BUSY presentation at one
literal insertion point, before selecting public syntax or behavior.

## Origin And Evidence

`IAL2-FEATURE-COMPLETENESS-FRONTIER.808` selects this audit after the generated
and direct AHB completion-edge phase repairs close cleanly. The shipped
requester source uses literal `busy-before-beat`, a one-bit `busy_inserted_q`
flag, and report value `busy_insertion.beats = single`. t/1498 proves five
presentations, four accepted data beats, and one BUSY; paired t/1513 and t/1515
prove subordinate BUSY parking across one insertion in one- and two-window
compositions. The requester residue explicitly defers requester BUSY beyond one
held presentation, multi-presentation/policy-driven throttling, and runtime
insertion points.

## Non-Goals

- Do not activate until `.808` commits cleanly.
- Do not preselect syntax, a counter shape, a maximum, or whether the count is
  per accepted BUSY presentation versus raw clock cycles; establish those from
  AHB ready/acceptance timing and generated-HDL evidence.
- Do not add runtime-selected throttling, random policy, multiple insertion
  points, a new local bus-BUSY status port, larger/multi-word bursts, optional
  AHB signals, queues/outstanding transfers, or broader fabrics.
- Do not activate decision 0020 or its transaction-layer horizon.

## Acceptance Criteria

- Reconcile the current PPIF grammar/parser, `AhbRequester` normalization,
  generated IAL1/IAL0 state, report/residue, t/1498 requester proof, t/1513 and
  t/1515 paired proofs, and the completion-edge phase contract.
- Distinguish a BUSY presentation accepted while `HREADY=1` from a BUSY value
  held across `HREADY=0`; any selected count must be protocol-event based and
  must not consume or complete a data beat.
- Feasibility-probe the smallest literal-count contract and determine whether
  current lowering can use a bounded counter without response/address/data
  ownership aliasing, extra accepted data beats, or combinational-loop lint.
- Decide whether the next owner is public contract selection, a smaller
  substrate repair, exact deferral, or audit closure.
- Freeze preservation, generated-HDL scenarios, source/alias/composition
  sequencing, report/support/docs effects, resource cap, validation, and
  rollback before any behavior change.

## Task Tree

- ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT`
  Status: `proposed`
  Goal: `Audit bounded multiple requester BUSY presentations before selecting behavior.`
  Children: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1`

- ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1`
  Status: `pending`
  Goal: `Establish the exact ready/acceptance, state, public-contract, and proof boundary for more than one requester BUSY presentation.`
  Acceptance: `Starting only after the clean .808 selector commit, read the canonical single-BUSY requester/alias/paired behavior and facts, current PPIF parser plus AhbRequester generated IAL1/report implementation, t1498/t1512/t1513/t1515/t1519, public sources, support/language/capability surfaces, mdBook/roadmap/Memory/Knowledge Map, and relevant decisions. Probe a bounded literal count at one insertion point, including HREADY-high consecutive acceptance and HREADY-low hold behavior; prove BUSY does not consume a data beat or response, the same pending SEQ resumes exactly once, address/control/data ownership stays stable, final transfer/beat/status counts are exact, and no lowering/lint prerequisite is hidden. Select a separate contract/repair leaf only from evidence. Make no shipped behavior change in the audit.`
  Verification: `pending`
  Commit: `pending`

## Activation Gate

This tree remains proposed until
`IAL2-FEATURE-COMPLETENESS-FRONTIER.808` commits cleanly. Activation changes
only task/index/Memory state; implementation cannot begin before `.1` closes
and selects an exact owner.

## Rollback

Before activation, rollback removes this proposed tree and restores `.808` to
the candidate-comparison state. After activation, rollback follows the active
leaf's own evidence and preserves the shipped single-BUSY behavior unchanged.
