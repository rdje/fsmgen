# ISF-MINIMUM-HOLD-EVENT-ORDER: SPECFORGE temporal verification request

## Metadata

- Tree ID: `ISF-MINIMUM-HOLD-EVENT-ORDER`
- Status: `active`
- Roadmap lane: `R14 / ISF verification; R13 / public reports`
- Created: `2026-11-02`
- Last updated: `2026-11-02`
- Owner: repo-local workflow

## Goal

Deliver required R1-R4 of SPECFORGE `FSMGEN-REQUESTS.15`,
`sf-isf-minimum-hold-event-order`. Intake is selected by publication `.24`.
After intake, implementation waits behind current publication and the existing
required reductions, aggregate ports, durations and timers under decision0121.
Coordinate unconditional placement with SEM `.33.6`; do not invent a transaction.

## Non-Goals

Dynamic timer expressions, runtime windows, outstanding queues and changes to
other repositories/submodule pins are excluded. Optional R5 cannot delay R1-R4.
Provider corpus/signoff results are third-party evidence, not FSMGen execution.

## Acceptance Criteria

- Preserve complete-cycle duration, inclusive equality, logical assertion/negation,
  polarity, physical rose/fell, clock/edge and source provenance.
- Carry required behavior through ordinary scheduling, IAL0, SystemVerilog
  verification, documented supported corpus and bounded semantic/schedule API/MCP
  contracts; no eventual-truth substitute, invented anchor or rearm-failure monitor.
- Refuse unsupported/malformed signals, durations, events, polarity and clocking.
  Existing bounded-eventually/stage behavior remains independently checked.
- Small meaningful checks and normal commits per slice. Full feature/corpus/HDL
  qualification activates only after required implementation; no partial delivery
  or skipped assertion is called verified. Split unsafe leaves before implementation.

## Task Tree

- ID: `ISF-MINIMUM-HOLD-EVENT-ORDER`
  Status: `active`
  Goal: `Deliver minimum holds and inclusive event order with exact public semantics.`
  Children: `ISF-MINIMUM-HOLD-EVENT-ORDER.1, ISF-MINIMUM-HOLD-EVENT-ORDER.2, ISF-MINIMUM-HOLD-EVENT-ORDER.3, ISF-MINIMUM-HOLD-EVENT-ORDER.4, ISF-MINIMUM-HOLD-EVENT-ORDER.5, ISF-MINIMUM-HOLD-EVENT-ORDER.6, ISF-MINIMUM-HOLD-EVENT-ORDER.7`

- ID: `ISF-MINIMUM-HOLD-EVENT-ORDER.1`
  Status: `done`
  Goal: `Retain exact request/provenance and reproduce current positive/refusal boundaries.`
  Acceptance: `Read full request/signoff/expected notes, typed excerpt and four exact actors. Verify retained packet hashes and same-volume local copies; never run foreign scripts. Fresh public strict checks: bounded-eventually accepts, three unsupported forms refuse. Positive HDL retains its monitor/assertion. Record required/optional contracts, reset non-vacuity and dependency order; sync book/feedback/knowledge and commit. No temporal feature is shipped by intake.`
  Verification: `Exact local actors match retained packet hashes. Fresh public statuses0/1/1/1; known-good HDL0 retains pending/age/fail and reset-disabled posedge assertion. Complete outputs/HDL/source identities and owned reset risk retain in request15 receiver intake. No native HDL execution or feature implementation credit.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.24: own SPECFORGE minimum holds and event ordering`

- ID: `ISF-MINIMUM-HOLD-EVENT-ORDER.2`
  Status: `pending`
  Goal: `Select precise level/event/clock/reset and repeated-event semantics.`
  Acceptance: `After existing required delivery/publication, reconcile canonical verification contracts and SEM .33.6 actor placement. Define N complete cycles, assertion/negation and active polarity, qualifying edges, inclusive equality, missing history, repeated-event pairing and end-of-observation meaning. The target RST_I is also reset: blanket disable/clear must not make its hold vacuous. Independently distinguish sufficient hold, short pulse and reset-edge violations without fabricated activation; define diagnostic and public provenance contracts before implementation. Own unresolved choices explicitly.`
  Verification: `Future contract risk retained in request15-contract-risk-20261101; no current unshipped-feature defect claimed.`
  Commit: `pending`

- ID: `ISF-MINIMUM-HOLD-EVENT-ORDER.3`
  Status: `pending`
  Goal: `Implement R1 minimum complete-cycle level hold and its R3/R4 contracts.`
  Acceptance: `After .2, preserve exact level and N>=1 through source/lowering/IAL0/SV and public semantic/schedule/API/MCP/corpus surfaces. Independent N=1/larger boundary, enough/short/midcycle/reset/polarity controls must distinguish duration from eventual truth and vacuous reset suppression. Zero/negative/unknown/dynamic counts and unknown signals refuse precisely; existing monitor/stage retains meaning. Sync canonical book13d/matrix/spec/feedback with runnable clean examples and focused checks; split bounded source/report/backend work if needed.`
  Verification: `Not implemented.`
  Commit: `pending`

- ID: `ISF-MINIMUM-HOLD-EVENT-ORDER.4`
  Status: `active`
  Goal: `Implement R2 inclusive event order with R3/R4 projection and diagnostics.`
  Children: `ISF-MINIMUM-HOLD-EVENT-ORDER.4.1, ISF-MINIMUM-HOLD-EVENT-ORDER.4.2`

- ID: `ISF-MINIMUM-HOLD-EVENT-ORDER.4.1`
  Status: `pending`
  Goal: `Implement no-later-than without changing event or anchor meaning.`
  Acceptance: `After .2, preserve event/reference identity, logical assertion, active polarity, rose/fell and one explicit qualifying clock/edge. Independent earlier/equal/later and reset/repeated-event controls prove inclusive order. Unknown polarity/signals, missing/mixed clock and unsupported events refuse. Carry ordinary scheduling/SV/provenance/public API/MCP/corpus and runnable book/spec/feedback in each safe focused slice. No start-of-run timeout or synthetic host.`
  Verification: `Not implemented.`
  Commit: `pending`

- ID: `ISF-MINIMUM-HOLD-EVENT-ORDER.4.2`
  Status: `pending`
  Goal: `Implement no-earlier-than including logical negation and physical polarity.`
  Acceptance: `After .2, preserve exact event/reference and qualifying clock. Prove equal/later accepted and earlier rejected, including active-low assertion/negation, reset/repetition and history boundaries independently of .4.1. Same source/IAL0/SV/provenance/public/API/MCP/corpus/refusal/doc obligations apply; no converse substitution that loses event meaning.`
  Verification: `Not implemented.`
  Commit: `pending`

- ID: `ISF-MINIMUM-HOLD-EVENT-ORDER.5`
  Status: `pending`
  Goal: `Run deferred complete required-feature qualification after implementation.`
  Acceptance: `Only after .3/.4 complete, qualify all R1-R4 through full supported corpus/native/API/newline MCP, independent non-skipped HDL timing/polarity/reset/provenance controls and existing monitor/stage regressions. Confirm distinct short-duration/wrong-order failures and no synthetic transaction. Reconcile every request clause and explicit target limitation. Full CI before authorized publication; never promote focused checks to this result.`
  Verification: `Deferred; required implementation is incomplete.`
  Commit: `pending`

- ID: `ISF-MINIMUM-HOLD-EVENT-ORDER.6`
  Status: `pending`
  Goal: `Publish qualified required behavior and immutable downstream handoff.`
  Acceptance: `After .5, synchronize book/spec/feedback, commit and normal authorized push; all required exact-SHA hosted jobs and rendered Pages must succeed. Name local/published qualification and remaining limits explicitly. Never edit SPECFORGE records or pins; downstream integration remains its owner.`
  Verification: `Pending implementation and qualification.`
  Commit: `pending`

- ID: `ISF-MINIMUM-HOLD-EVENT-ORDER.7`
  Status: `pending`
  Goal: `Own optional R5 assumption-versus-assertion role selection separately.`
  Acceptance: `After required delivery unless already supplied without expansion by canonical actor verification, distinguish input assumptions from output guarantees, ownership/reset/polarity and report provenance. Coordinate SEM .33.6 and qualify actual projection/runtime/refusals. Never silently turn reset assumptions into actor guarantees or delay required delivery.`
  Verification: `Optional, not implemented or required for R1-R4 closure.`
  Commit: `pending`

## Current Frontier

Intake .1 is complete under publication .24. Contract .2 waits for the
existing required-request/publication order; active container does not mean
feature implementation has started. PUBLICATION .25/.27/.26/.13 remain next.

## Decisions

- `2026-11-02`: Accept required R1-R4 for scheduled delivery; optional R5 separate.
  Proposed spellings are inputs for contract selection, not admitted syntax.

## Blockers

- Implementation depends on existing required-request/publication priorities.
- .2 owns reset non-vacuity and repeated-event semantics before implementation.
