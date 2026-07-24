# IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT: Audit Bounded Multiple BUSY Presentations

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT`
- Status: `active`
- Roadmap lane: `IAL2 / AHB requester BUSY policy`
- Created: `2026-07-23`
- Last updated: `2026-07-24`
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
  Status: `active`
  Goal: `Audit bounded multiple requester BUSY presentations before selecting behavior.`
  Children: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1`, `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.2`, `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.3`

- ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Establish the exact ready/acceptance, state, public-contract, and proof boundary for more than one requester BUSY presentation.`
  Acceptance: `Starting only after the clean .808 selector commit, read the canonical single-BUSY requester/alias/paired behavior and facts, current PPIF parser plus AhbRequester generated IAL1/report implementation, t1498/t1512/t1513/t1515/t1519, public sources, support/language/capability surfaces, mdBook/roadmap/Memory/Knowledge Map, and relevant decisions. Probe a bounded literal count at one insertion point, including HREADY-high consecutive acceptance and HREADY-low hold behavior; prove BUSY does not consume a data beat or response, the same pending SEQ resumes exactly once, address/control/data ownership stays stable, final transfer/beat/status counts are exact, and no lowering/lint prerequisite is hidden. Select a separate contract/repair leaf only from evidence. Make no shipped behavior change in the audit.`
  Verification: `The repo-local Arm AHB specification corrects the initial ready-low hypothesis: fixed-length BUSY may change to SEQ while HREADY is low, after which SEQ must hold until ready. Disposable current generated HDL with HGRANT=HREADY=1 exposes one BUSY transition episode but ten ready-qualified BUSY edges, contradicting report beats=single; t1498/t1513/t1515 count only HTRANS changes. Assertion-enabled disposable candidates prove (a) one event-owned BUSY acceptance and (b) a width-two remaining counter with exactly two qualified BUSY edges, each under continuously-ready and 32-clock ready-low-then-ready scenarios, with stable fields/counters, the same resumed SEQ, four data beats, and no response/address alias. A rejected concurrent output-hold rule proved declared rule-over-transaction priority does not mask different-value output selectors; its generated assertion fails and proposed inactive ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT owns that general gap. Selected .2 single-BUSY event-cardinality repair contract selection before multiple-BUSY syntax/behavior. Canonical record docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md and fact ial2-ahb-requester-multi-busy-insertion-readiness-audit. Guarded t1518 passes 4/4 current-surface tests; mdBook build, Knowledge Map generation/check at 981 facts/4968 question keys, memory architecture, docs paths, diff, and doctrine gates pass. Disposable candidate/spec-text/book outputs were removed. No shipped behavior changed.`
  Commit: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1: prove current single-BUSY cardinality`

- ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.2`
  Status: `done`
  Goal: `Select the exact current single-BUSY ready/grant-qualified event-cardinality repair contract before multiple-BUSY work resumes.`
  Acceptance: `Starting only after .1 commits cleanly, freeze busy_insertion.beats=single as exactly one HGRANT && HREADY && HTRANS==BUSY event rather than one signal-transition episode or generated-microstate duration. Select the smallest BUSY pending/remaining ownership state, acceptance rule, outer-loop gate, priority, reset/command initialization, ready-low policy, and address-pending SEQ handoff using assertion-enabled generated-HDL evidence. Freeze tracked t1498 continuously-ready edge count plus ready-low scenario, .ahb alias and every paired generic/alias one-/two-subordinate preservation path, report/support/artifact/public syntax stability, current docs/facts correction, resource cap, validation, and rollback. Make no shipped behavior change in contract selection. Multiple-BUSY syntax/count behavior remains deferred until the repair implementation commits cleanly.`
  Verification: `Selected beats=single as exactly one rising HGRANT && HREADY && HTRANS==BUSY event. Conditional generated IAL1 adds priority ahb_busy_accept over ahb_request, a BUSY accept rule that arms existing ahb_address_pending_q and drives the same pending transfer as SEQ for the following clock, and an outer continue-when (!HREADY && HTRANS==BUSY) gate; the existing no-grant gate, registered BUSY output, and one-bit busy_inserted_q complete ownership with no new counter/storage/public field. Selected the stronger legal stable-BUSY-until-qualified policy. Assertion-enabled disposable continuously-ready and 32-clock ready-low proofs from .1 pass exact one event/four data beats; .2 adds public first-visible-BUSY 32-clock grant-low and ready-low proofs, both exact one/four with no generated state-number dependency or selector assertion. Selected t1498 structural and three-scenario edge-count/stability proof, t1512 parity, t1513-t1516 embedded qualified-edge counts, t1518/t1519 preservation, accounting/capability/strict/verify/docs/KM/doctrine gates, 4-GiB cap, and rollback. Public syntax/report/support/ports/artifacts and broader residue remain unchanged. Guarded t1518 passes 4/4; mdBook build, Knowledge Map generation/check at 982 facts/4974 question keys, memory architecture, docs paths, diff, and doctrine gates pass. Generated book output and the 7.7-MB disposable candidate directory were removed. Selected .3 implementation; multiple count remains deferred. Canonical record docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR_CONTRACT_SELECTION.md and fact ial2-ahb-requester-single-busy-event-cardinality-repair-contract-selection.`
  Commit: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.2: select single-BUSY event repair`

- ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.3`
  Status: `pending`
  Goal: `Implement exact one-event requester BUSY retirement and lock every generic/alias/paired embedding to ready-qualified cardinality.`
  Acceptance: `Starting only after .2 commits cleanly, implement exactly the selected conditional AhbRequester generated-IAL1 delta: priority ahb_busy_accept over ahb_request, rule guarded by HGRANT && HREADY && HTRANS==BUSY that sets ahb_address_pending_q=1 and HTRANS=SEQ, and the outer !HREADY && HTRANS==BUSY continue gate. Preserve transfer_busy, one-bit busy_inserted_q, all public syntax/diagnostics/ports/report/support/source/artifact/module identities, base requester output, address/data/response ownership, burst/address/data progression, status, and residue. Extend t1498 structural checks and assertion-enabled generated-HDL runtime using public first-visible BUSY stall injection for continuously-qualified, 32-clock ready-low, and 32-clock grant-low scenarios; require exactly one qualified BUSY event, stable fields/counters, the same resumed SEQ, exactly four data beats, and zero remaining. Update paired one-/two-subordinate generic/alias harnesses t1513-t1516 to count one ready-qualified embedded BUSY event per command while preserving parking/mapping/storage/status. Run requester/base/alias/paired/current-surface/phase preservation, t248/t297, strict/report/artifact/verify gates, mdBook/README/roadmap/current behavior/facts/task/Memory/Knowledge Map sync, diff/docs/doctrine gates, and 4-GiB resource cap. Do not add multiple-BUSY syntax/counter/report, runtime/policy throttling, local bus-BUSY status, broader bursts/signals/managers, queues, direct seeds/backends, AXI/APB/VHDL, general output-priority work, or decision 0020.`
  Verification: `pending`
  Commit: `pending`

## Activation Gate

This tree remains proposed until
`IAL2-FEATURE-COMPLETENESS-FRONTIER.808` commits cleanly. Activation changes
only task/index/Memory state; implementation cannot begin before `.1` closes
and selects an exact owner.

Activation condition satisfied: `.808` committed cleanly at `5d0effaca`.
`.1` completed the no-behavior ready/acceptance and lowering-feasibility audit
and selected `.2`. Activation condition satisfied: `.1` committed cleanly at
`512e65b7e`; `.2` completed the no-behavior repair contract selection and
selected `.3`, which cannot activate until `.2` commits cleanly.

## Rollback

Before activation, rollback removes this proposed tree and restores `.808` to
the candidate-comparison state. After activation, rollback follows the active
leaf's own evidence and preserves the shipped single-BUSY behavior unchanged.
