# IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT: Audit Exact-Two Requester/Subordinate BUSY Composition

## Metadata

- Tree ID: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- Status: `proposed`
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
  Status: `proposed`
  Goal: `Audit one-subordinate exact-two requester BUSY insertion plus subordinate BUSY parking before selecting public composition behavior.`
  Children: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

- ID: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `proposed`
  Goal: `Establish exact-two paired BUSY runtime/lowering readiness and select the next exact owner.`
  Acceptance: `Starting only after clean .809 commit, read the exact-one paired generic/alias and exact-two requester generic/alias behavior/facts/sources/tests, PPIF/AhbRequester/AhbSubordinate/AhbInterconnect lowering and phase ownership, reports/residue/support/language/capability/semantic-MCP surfaces, mdBook/roadmap/Memory/Knowledge Map, selector repairs, and decision 0020. Build a disposable one-subordinate exact-two aggregate without selecting public names; prove normal IAL2->IAL1->IAL0->HDL generation, numeric child beats=2, parks_on=[busy], exact two qualified BUSY events in one episode, stable requester/subordinate/interconnect ownership and storage, no BUSY data completion, one resumed SEQ, four data beats, clean completion, and final 44332211. Retain the paired --no-assert boundary while keeping standalone requester assertions authoritative. Select contract work, a prerequisite repair, deferral, or closure only from evidence; require future check/schedule/semantic JSON/read-only MCP parity. Make no shipped behavior change in the audit.`
  Verification: `pending`
  Commit: `pending`

## Activation Gate

This tree remains proposed until
`IAL2-FEATURE-COMPLETENESS-FRONTIER.809` commits cleanly. Activation changes
only task/index/Memory state; no source, parser, generator, support, test,
artifact, semantic/MCP API, HDL, or runtime behavior may change before `.1`
becomes active from a clean tree.

## Rollback

Before activation, rollback removes this proposed tree and restores `.809` to
candidate selection. After activation, rollback follows the active leaf's
evidence while preserving all shipped exact-one/exact-two requester and paired
exact-one behavior.
