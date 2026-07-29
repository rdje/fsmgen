# IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT: Audit Literal-Three Requester BUSY Reuse

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT`
- Status: `proposed`
- Roadmap lane: `IAL2 / AHB requester BUSY policy`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Runtime-prove or disprove whether the shipped exact-two requester's two-bit
qualified-event counter can safely support the smallest additional literal
`(busy-beats 3)` before selecting any public contract or implementation.

## Origin And Evidence

`IAL2-FEATURE-COMPLETENESS-FRONTIER.812` selects this proposed audit after the
complete exact-two requester and one-/two-subordinate paired `.ppif`/`.ahb`
lineage ships at 320 protocol / 361 supported-smoke+strict / 44 AHB paths. The
current parser admits only literal two. The generated requester already uses a
width-two remaining counter, qualified `> 1` decrement, qualified `== 1`
clear-and-`SEQ` handoff, and a whole-BUSY continuation gate. Static inspection
shows literal three fits that representation, but only literal two has
assertion-enabled continuous/ready-low/grant-low runtime proof.

## Non-Goals

- Do not activate until `.812` commits cleanly.
- Do not change shipped parser, generator, source, support, test, report,
  artifacts, semantic/MCP API, HDL/runtime, backend, or protocol behavior in
  the audit.
- Do not preselect public source/support names, exact parser diagnostics,
  report wording, alias cadence, paired exact-three composition, or an upper
  count bound; establish them only after runtime evidence.
- Do not add generalized count widths, values above three, runtime/policy/
  random throttling, multiple insertion points, local bus-BUSY status, broader
  bursts/signals/managers/fabrics, AXI/APB/VHDL, or decision 0020 behavior.

## Acceptance Criteria

- Reconcile the exact-two public contract/behavior, `AhbRequester` parser,
  two-bit storage/rules/report/residue, t/1521/t/1522, paired preservation,
  support/language/capability/semantic/MCP surfaces, roadmap, mdBook, Memory,
  Knowledge Map, and relevant decisions.
- Build only a disposable candidate beneath a repository-derived
  `.artifacts/` workspace; admit literal three there while keeping width two
  and the current non-final/final BUSY rules.
- Run assertion-enabled generated HDL for continuously-ready, 32-clock
  ready-low, and 32-clock grant-low scenarios under the repository RAM guard.
- Require one BUSY episode with exactly three
  `HGRANT && HREADY && HTRANS == BUSY` events, no stall-time consumption, no
  BUSY data/response completion, stable pending fields/beat counters, exactly
  one resumed pending `SEQ`, four accepted byte `INCR4` data beats, and final
  remaining count zero.
- Reconcile strict check, schedule/report, exact generated IAL1/IAL0 artifacts,
  normalized semantic JSON, and the existing read-only
  `fsmgen_semantic_introspect` contract without feature-specific APIs or raw
  private payloads.
- Select exactly one separate next owner: exact-three public contract
  selection, a smaller prerequisite repair, evidence-backed deferral, or audit
  closure. Freeze preservation, validation, resource, documentation, rollback,
  and generic/alias sequencing before any behavior change.

## Task Tree

- ID: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT`
  Status: `proposed`
  Goal: `Audit literal-three requester BUSY reuse before selecting public behavior.`
  Children: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.1`

- ID: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.1`
  Status: `proposed`
  Goal: `Runtime-prove or disprove literal-three reuse of the shipped width-two requester BUSY counter.`
  Acceptance: `Starting only after clean .812 selector commit, create a same-volume repo-local disposable candidate from the shipped exact-two requester, admit only literal busy-beats 3 in that candidate, preserve width-two ahb_busy_remaining_q and current qualified >1/==1 retirement rules, and run assertion-enabled continuous/32-ready-low/32-grant-low generated-HDL scenarios. Prove exactly one BUSY episode, three qualified BUSY events, no stall-time count consumption or BUSY data/response completion, stable address/control/write-data/beat ownership, one resumed pending SEQ, four accepted byte INCR4 data beats, zero final remaining count, and no exact-one/exact-two regression. Reconcile strict/schedule/report/artifacts/normalized semantic/read-only MCP surfaces and select a separate contract, prerequisite, deferral, or closure leaf from evidence. Remove all disposable artifacts. Make no shipped behavior change.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-29`: Keep the tree proposed until `.812` commits cleanly. Static
  representability is enough to justify a runtime audit, not public behavior.
- `2026-07-29`: Bound the first audit to literal three at the existing single
  insertion point. Wider/general counts and policy-selected points are larger
  independent contracts.

## Blockers

- None before activation. The guarded runtime may stop on host pressure; do
  not raise the cutoff or kill unrelated processes.
