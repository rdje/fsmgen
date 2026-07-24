# IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT: Audit Exact-Two Requester/Subordinate BUSY Composition

## Metadata

- Tree ID: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- Status: `active`
- Roadmap lane: `IAL2 / AHB requester-subordinate composition`
- Created: `2026-07-24`
- Last updated: `2026-07-24`
- Owner: repo-local workflow

## Goal

Audit the smallest one-requester/one-subordinate aggregate that composes the
shipped exact-two BUSY requester with the shipped HBURST-aware byte-lane
subordinate whose burst context parks across BUSY, before selecting a public
source or runtime contract.

## Origin And Evidence

`IAL2-FEATURE-COMPLETENESS-FRONTIER.809` selects this audit after the bounded
requester multiple-BUSY child tree closes at clean commit `ca07927c4`. The
current exact-one paired `.ppif`/`.ahb` sources and t/1513-t/1514 already prove
one qualified requester BUSY event parked by one subordinate. The standalone
exact-two requester `.ppif`/`.ahb` and assertion-enabled t/1521 now prove two
qualified BUSY events, but no aggregate combines those endpoints yet.

An in-memory candidate derived from the exact-one paired source parses and
generates without a new substrate: it keeps three children and top `ahb_tb`,
uses `amba_requester_busy_insert_two.isf/.fsm`, reports numeric requester
`busy_insertion.beats=2`, and retains both subordinate and aggregate-propagated
`parks_on=[busy]`. Static generation does not prove that two qualified BUSY
events preserve continuation/storage ownership and resume the same `SEQ`
exactly once, so runtime readiness must be audited before public naming or
implementation.

## Non-Goals

- Do not activate before `.809` commits cleanly.
- Do not preselect the public source/object/support names, alias cadence, or
  whether one- and two-subordinate shapes ship in one family.
- Do not add counts beyond exact two, policy/runtime/random throttling,
  multiple insertion points, distinct local bus-BUSY status, broader bursts,
  optional signals, queues/outstanding transfers, managers, or fabrics.
- Do not repair the separately tracked interconnect default/decode selector
  overlap inside this audit.
- Do not activate decision 0020 or its director-owned transaction-layer
  horizon.

## Acceptance Criteria

- Reconcile the exact-one paired generic/alias behavior and t/1513-t/1514,
  exact-two requester generic/alias behavior and t/1521-t/1522, current
  `PPIF.pm`/`AhbRequester`/`AhbSubordinate`/`AhbInterconnect` lowering,
  completion-edge phase ownership, report/residue, support/language/capability
  surfaces, mdBook, Knowledge Map, Memory, and relevant decisions.
- Build a disposable one-subordinate exact-two aggregate candidate through the
  normal IAL2 -> IAL1 -> IAL0 -> HDL path. Preserve three children, one
  zero-base four-byte window, byte `INCR4`, the existing phase bank/data owner,
  requester `busy_insertion.beats=2`, and subordinate plus propagated
  `parks_on=[busy]`.
- Run generated-HDL evidence that distinguishes one BUSY transition episode
  from two `HGRANT && HREADY && HTRANS==BUSY` events. Require stable requester
  pending fields/counters, stable subordinate continuation/storage, no BUSY
  data completion, one resumed pending `SEQ`, exactly four data beats, clean
  status, and final storage `32'h44332211`.
- Record the existing paired `--no-assert` boundary caused by the separately
  owned interconnect selector overlap; do not weaken standalone exact-two
  requester assertion coverage.
- Determine whether the next owner is public contract selection, a smaller
  substrate repair, exact deferral, or audit closure. If behavior is selected,
  freeze generic-first/alias-later sequencing and keep two-subordinate
  exact-two composition separate.
- Require any future support-accounted source to expose bounded check,
  schedule, normalized semantic JSON, and read-only
  `fsmgen_semantic_introspect` MCP output through the existing stable contract,
  without a feature-specific API fork or raw private internals.
- Freeze preservation, support/accounting, docs/Knowledge Map, resource cap,
  validation, and rollback before behavior changes.

## Task Tree

- ID: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
  Status: `active`
  Goal: `Audit one-subordinate exact-two requester BUSY insertion plus subordinate BUSY parking before selecting public composition behavior.`
  Children: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1, IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`

- ID: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Establish exact-two paired BUSY runtime/lowering readiness and select the next exact owner.`
  Acceptance: `Starting only after clean .809 commit, read the exact-one paired generic/alias and exact-two requester generic/alias behavior/facts/sources/tests, PPIF/AhbRequester/AhbSubordinate/AhbInterconnect lowering and phase ownership, reports/residue/support/language/capability/semantic-MCP surfaces, mdBook/roadmap/Memory/Knowledge Map, selector repairs, and decision 0020. Build a disposable one-subordinate exact-two aggregate without selecting public names; prove normal IAL2->IAL1->IAL0->HDL generation, numeric child beats=2, parks_on=[busy], exact two qualified BUSY events in one episode, stable requester/subordinate/interconnect ownership and storage, no BUSY data completion, one resumed SEQ, four data beats, clean completion, and final 44332211. Retain the paired --no-assert boundary while keeping standalone requester assertions authoritative. Select contract work, a prerequisite repair, deferral, or closure only from evidence; require future check/schedule/semantic JSON/read-only MCP parity. Make no shipped behavior change in the audit.`
  Verification: `A disposable candidate derived from the shipped one-subordinate exact-one paired source changed only the embedded requester/child reference to amba_requester_busy_insert_two and added (busy-beats 2), while retaining provisional source identity so no public name was selected. Existing PPIF/AhbRequester/AhbSubordinate/AhbInterconnect lowering produced schema fsmgen.ial2.protocol_intent.ahb_interconnect.v1, three children, top ahb_tb, exact amba_requester_busy_insert_two plus subordinate/interconnect IAL1/IAL0 and ahb_tb.fsm artifacts, numeric requester child busy_insertion.before_beat=2/beats=2, and subordinate plus aggregate parks_on=[busy]. Generated HDL compiled with Verilator --no-assert under the 4-GiB descendant-RSS cap and passed transfers=5 beats=4 busy=1 qualified_busy=2 resumed_seq=1 storage=44332211. The harness required stable requester address/control/data/beat counters; ahb_busy_remaining_q values 2 then 1 then 0; stable subordinate SEQ continuation, phase pending, and storage; stable interconnect one-hot data owner; no BUSY beat_done; exactly one resumed SEQ; zero remaining and clean status. Existing t1513 plus assertion-enabled t1521 pass 9/9 in 307 seconds. No lower-layer, semantic/MCP, or HDL repair is required. Selected pending .2 public contract selection, generic-first with alias and two-subordinate exact-two separate; future support-accounted behavior must preserve strict check/schedule/normalized semantic JSON/read-only fsmgen_semantic_introspect parity without feature APIs/raw internals. Canonical record docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md and fact ial2-ahb-exact-two-paired-busy-composition-readiness-audit. t1518 passes 5/5; mdBook builds; Knowledge Map generation/check passes at 990 facts/5018 question keys; memory architecture, relative-doc paths, diff, and doctrine gates pass; generated book output was removed. No shipped behavior changed.`
  Commit: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1: prove exact-two paired BUSY readiness`

- ID: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`
  Status: `active`
  Goal: `Select the first public one-subordinate exact-two paired BUSY composition contract.`
  Acceptance: `Starting only after .1 commits cleanly, freeze one generic .ppif source before any matching .ahb alias: exact source/intent/source-object/anchor/requester/support/coverage/test names, unchanged three-child ahb_tb architecture and generated IAL1/IAL0 set, numeric requester-child busy_insertion.beats=2, subordinate and propagated parks_on=[busy], truthful residue, support/accounting/capability/language surfaces, diagnostics, and rollback. Freeze a generated-HDL proof with one BUSY episode/two qualified BUSY events/stable requester-subordinate-interconnect ownership/no BUSY data completion/one resumed SEQ/four byte data beats/clean status/final 44332211, retain the paired --no-assert and standalone assertion-enabled boundaries, and preserve base/exact-one paired/standalone exact-two/aliases/two-subordinate exact-one. Require strict check, schedule, normalized semantic JSON, and existing read-only fsmgen_semantic_introspect MCP parity without a feature-specific API or raw private internals. Make no shipped behavior change. Keep the matching alias, two-subordinate exact-two sibling, broader counts/policy/status/bursts/signals/queues/managers/backends/protocols, separate selector repairs, and decision 0020 deferred.`
  Verification: `pending`
  Commit: `pending`

## Activation Gate

Satisfied: `IAL2-FEATURE-COMPLETENESS-FRONTIER.809` committed cleanly as
`9107ee297`. This activation changes only task/index/Memory state; no source,
parser, generator, support, test, artifact, semantic/MCP API, HDL, or runtime
behavior changes in the activation slice.

`.1` completed the disposable static and generated-HDL runtime audit and
selected `.2` public contract work. Activation condition satisfied: `.1`
committed cleanly at `6fd06dc9e`; `.2` is active. This activation changes only
task/index/Memory state.

## Rollback

Before activation, rollback removes this proposed tree and restores `.809` to
candidate selection. After activation, rollback follows the active leaf's
evidence while preserving all shipped exact-one/exact-two requester and paired
exact-one behavior. The disposable `.1` candidate lives outside the repository
and has no shipped rollback surface.
