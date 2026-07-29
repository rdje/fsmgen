# IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT: Exact-Four AHB Requester BUSY Readiness

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT`
- Status: `proposed`
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
  Status: `proposed`
  Goal: `Audit literal-four AHB requester BUSY insertion and its first required counter-width contract.`
  Children: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1`

- ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1`
  Status: `proposed`
  Goal: `Prove or disprove exact-four readiness through the smallest safe counter-width boundary.`
  Acceptance: `Activate only after clean parent selector IAL2-FEATURE-COMPLETENESS-FRONTIER.822. Read the shipped requester generator/adapter, exact-one/two/three sources and tests, IAL1 width/assignment/lowering contracts, support/language/capability/current docs, semantic/read-only-MCP surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, and decision 0020. Recreate a repository-derived same-volume exact-four candidate with only identity/anchor/actor/(busy-beats 4) changes. Record strict/check/schedule/artifact/semantic/MCP/HDL/runtime behavior or the exact first rejection. Determine whether a bounded three-bit counter plus unchanged qualified rules is sufficient, whether reusable width derivation must land first, or whether another lower-layer prerequisite exists. If ready, select a separate public-contract leaf with exact syntax/range, generated artifact, runtime, support, diagnostic, docs, cleanup, rollback, and residue boundaries. Make no tracked parser/generator/source/support/test/artifact/semantic-MCP API/HDL/runtime/backend/protocol/verification-generation/HIAL-VIAL/VHDL/transaction behavior change in the audit. Use the authorized host-100/process-4096 profile, canonical Stats-compatible RAM capacity, separate kernel pressure, repository-local outputs, exact census, and residue proof.`
  Verification: `Pending clean selector commit and separate activation. Parent selector evidence: a one-file/2,313-byte same-volume exact-four transform fails closed before generation with exactly one diagnostic, "AHB requester transfer.busy_beats must be a literal integer in 2..3 in this slice"; the candidate is removed without residue. The generator also hardcodes ahb_busy_remaining_q width 2, so literal four is the first count that cannot be represented by the shipped counter.`
  Commit: `pending activation`

## Decisions

- `2026-07-29`: Parent selector `.822` chooses exact-four readiness because it
  is the smallest adjacent extension that reuses public `busy-beats` syntax;
  it requires an explicit width audit before any range or source change.

## Open Questions

- Should the next contract select only literal four with width three, or derive
  the minimum counter width from every supported literal? The readiness audit
  must answer this before implementation.

## Blockers

- None before activation.

## Changelog

- `2026-07-29`: Created as a proposed child of parent selector `.822`.
