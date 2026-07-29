# IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT: Exact-Four AHB Requester BUSY Readiness

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT`
- Status: `active`
- Roadmap lane: `IAL2 / AHB requester BUSY policy`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Determine the smallest correct counter-width and public-contract prerequisite
for literal `(busy-beats 4)` before extending the shipped exact-one/two/three
AHB requester family.

## Non-Goals

- Do not ship an exact-four public source or alias in the readiness audit.
- Do not change parser/generator/report/semantic/MCP/HDL/runtime behavior in the
  selector or audit.
- Do not generalize to arbitrary, runtime-selected, policy-selected, random, or
  multiple-point BUSY insertion.
- Do not change bus-BUSY status, burst semantics, optional AHB signals,
  interconnect topology, backends, VHDL, verification generation, HIAL/VIAL,
  or decision `0020`.

## Acceptance Criteria

- Reconcile the shipped literal `2..3` normalization, width-two requester
  storage, qualified decrement/final-accept rules, exact-one/two/three runtime,
  public parser/report/residue, semantic/read-only-MCP surfaces, and paired
  composition cadence.
- Recreate only a repository-derived same-volume exact-four candidate and
  record the exact current fail-closed boundary.
- Determine whether literal four can reuse the existing rules with a bounded
  three-bit counter, needs a reusable width-derivation prerequisite, or exposes
  another IAL1/IAL0/SystemVerilog blocker.
- If ready, freeze the exact next public-contract owner, runtime scenarios,
  support/report/semantic/MCP expectations, diagnostics, preservation,
  cleanup, rollback, and explicit residue before behavior changes.
- Focused docs, Knowledge Map, mdBook, doctrine, resource, and same-volume
  cleanup gates pass; each leaf commits through `COMMIT.md`.

## Task Tree

- ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT`
  Status: `active`
  Goal: `Audit literal-four AHB requester BUSY insertion and its first required counter-width contract.`
  Children: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1`, `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.2`

- ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Prove or disprove exact-four readiness through the smallest safe counter-width boundary.`
  Acceptance: `Activate only after clean parent selector IAL2-FEATURE-COMPLETENESS-FRONTIER.822. Read the shipped requester generator/adapter, exact-one/two/three sources and tests, IAL1 width/assignment/lowering contracts, support/language/capability/current docs, semantic/read-only-MCP surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, and decision 0020. Recreate a repository-derived same-volume exact-four candidate with only identity/anchor/actor/(busy-beats 4) changes. Record strict/check/schedule/artifact/semantic/MCP/HDL/runtime behavior or the exact first rejection. Determine whether a bounded three-bit counter plus unchanged qualified rules is sufficient, whether reusable width derivation must land first, or whether another lower-layer prerequisite exists. If ready, select a separate public-contract leaf with exact syntax/range, generated artifact, runtime, support, diagnostic, docs, cleanup, rollback, and residue boundaries. Make no tracked parser/generator/source/support/test/artifact/semantic-MCP API/HDL/runtime/backend/protocol/verification-generation/HIAL-VIAL/VHDL/transaction behavior change in the audit. Use the authorized host-100/process-4096 profile, canonical Stats-compatible RAM capacity, separate kernel pressure, repository-local outputs, exact census, and residue proof.`
  Verification: `Activated only after clean parent selector commit db0990c9d through clean activation commit 08e970b3f. A one-file/2,313-byte repository-local exact-four public candidate changes only intent/object/anchor/actor/busy-beats and fails closed before generation with exactly one diagnostic, "AHB requester transfer.busy_beats must be a literal integer in 2..3 in this slice", success=false, unmatched support, and generated_output.emitted=false. Generated the exact-three IAL1, then changed only actor identity, ahb_busy_remaining_q width 2->3, and initializer 3->4 in a disposable copy; strict IAL1-to-IAL0/SystemVerilog lowering and public --verify-hdl pass with the current >1 decrement, ==1 final clear/address-pending SEQ handoff, whole-BUSY continuation, priorities, and assertions unchanged. Verilator 5.046 compiles one --timing assertion-enabled binary without --no-assert; continuous, 32-clock ready-low, and 32-clock grant-low runs each pass transfers=5/beats=4/BUSY episodes=1/qualified BUSY=4/final counter=0, directly observing 4->3->2->1->0 and stall stability with no BUSY data beat and stable pending state. Literal four is lower-layer ready on width three. The preserving public prerequisite is minimum unsigned counter width ceil(log2(busy_beats+1)): 2->2, 3->2, 4->3; hardcoded family-wide width three would needlessly change exact-two/three artifacts. Selected proposed no-behavior contract `.2`. The exact 32-file/2,510,723-byte workspace is removed with zero residue. Canonical audit record/fact are synchronized. Post-cleanup Stats-compatible capacity is 74.8% (17.952/24.000 GiB), kernel pressure is separately 1 (normal), and guard occupancy is excluded as capacity truth. Focused t1518+t1256+t1414 pass 3 files/22 tests; Knowledge Map generation/check reaches 1,033 facts/5,273 keys; mdBook builds exactly 72 files/16,221,633 bytes and its repository-local generated tree is removed with zero residue; Memory is 60 lines; diff and all six doctrine gates pass. No shipped behavior changed.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1: prove exact-four counter readiness`

- ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.2`
  Status: `proposed`
  Goal: `Select the exact public literal-four requester BUSY and minimum-width counter contract before implementation.`
  Acceptance: `Activate only after clean .1 audit commit. Reconcile the authoritative disposable 4->3->2->1->0 continuous/ready-low/grant-low proof with the shipped exact-one/two/three generic/alias family, AhbRequester normalization/lowering/report/residue, IAL1 width contracts, support/language/capability/current docs, normalized semantic/read-only-MCP surfaces, paired composition preservation, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, and decision 0020. Select or reject exactly one additive generic ppif/ahb_requester_busy_insert_four.ppif contract. If selected, freeze literal range 2..4 and diagnostics, absence-as-exact-one, minimum unsigned counter width ceil(log2(busy_beats+1)) preserving width two for counts two/three and selecting width three for four, exact source/intent/object/anchor/actor/module/artifact/support/coverage identities, numeric report and truthful residue, assertion-enabled continuous/32-ready-low/32-grant-low runtime, malformed/preservation/semantic/MCP/artifact/verifier/support-accounting gates, generic-first then separate alias cadence, docs/Knowledge Map, resource cap, cleanup, and rollback. Make no parser/generator/public source/support/test/artifact/semantic-MCP API/HDL/runtime/backend/protocol/verification-generation/HIAL-VIAL/VHDL/transaction behavior change in contract selection. Keep counts above four, arbitrary/runtime/policy/random counts, multiple insertion points, local bus-BUSY status, new burst/signal/topology behavior, generic priority, other protocols/backends, HIAL/VIAL activation, VHDL, verification generation, and decision 0020 separate.`
  Verification: `pending activation after clean .1 audit commit`
  Commit: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.2: select exact-four BUSY contract`

## Decisions

- `2026-07-29`: Parent selector `.822` chooses exact-four readiness because it
  is the smallest adjacent extension that reuses public `busy-beats` syntax;
  it requires an explicit width audit before any range or source change.
- `2026-07-29`: Exact four is lower-layer ready with a 3-bit counter and the
  current qualified rules. Select proposed `.2` to freeze a public minimum-
  width derivation contract, preserving width two for exact two/three.

## Open Questions

- None in the readiness audit. Proposed `.2` owns public contract selection.

## Blockers

- None.

## Changelog

- `2026-07-29`: Created as a proposed child of parent selector `.822`.
- `2026-07-29`: Clean parent selector commit `db0990c9d` activates `.1`.
- `2026-07-29`: `.1` proves lower-layer/runtime readiness with a 3-bit
  exact-four counter and selects proposed `.2` with minimum-width derivation.
