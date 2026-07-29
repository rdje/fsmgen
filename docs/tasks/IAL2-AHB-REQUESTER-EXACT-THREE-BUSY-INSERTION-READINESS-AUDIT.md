# IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT: Audit Literal-Three Requester BUSY Reuse

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT`
- Status: `active`
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
  Status: `active`
  Goal: `Audit literal-three requester BUSY reuse before selecting public behavior.`
  Children: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.1`, `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.2`, `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.3`

- ID: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Runtime-prove or disprove literal-three reuse of the shipped width-two requester BUSY counter.`
  Acceptance: `Starting only after clean .812 selector commit, create a same-volume repo-local disposable candidate from the shipped exact-two requester, admit only literal busy-beats 3 in that candidate, preserve width-two ahb_busy_remaining_q and current qualified >1/==1 retirement rules, and run assertion-enabled continuous/32-ready-low/32-grant-low generated-HDL scenarios. Prove exactly one BUSY episode, three qualified BUSY events, no stall-time count consumption or BUSY data/response completion, stable address/control/write-data/beat ownership, one resumed pending SEQ, four accepted byte INCR4 data beats, zero final remaining count, and no exact-one/exact-two regression. Reconcile strict/schedule/report/artifacts/normalized semantic/read-only MCP surfaces and select a separate contract, prerequisite, deferral, or closure leaf from evidence. Remove all disposable artifacts. Make no shipped behavior change.`
  Verification: `A same-volume disposable overlay admitted bounded literals 2/3 while preserving the shipped width-two counter, current >1 decrement, ==1 clear/address-pending SEQ handoff, whole-BUSY continuation, and checker priorities. Candidate strict check, numeric beats=3 schedule/report, exact amba_requester_busy_insert_three.isf/.fsm artifacts, normalized semantic JSON, generated HDL, and real common read-only shell-disabled fsmgen_semantic_introspect all passed with truthfully unmatched support. One assertion-enabled Verilator binary passed continuously-qualified, 32-clock ready-low, and 32-clock grant-low scenarios: each had one BUSY episode, exactly three qualified BUSY events, five non-IDLE presentations, four accepted byte INCR4 data beats, no BUSY data/response completion, stable address/control/write-data/beat ownership, one resumed SEQ, and zero public burst remaining. The primary guarded test passed 4 top-level subtests/59 nested assertions in 33 seconds. Review found its zero check did not directly observe the private BUSY counter, so a strengthened guarded run hierarchically proved internal ahb_busy_remaining_q values 3 -> 2 -> 1 -> 0 and stall-time stability, passing 8/8 in 10 seconds; this stronger proof is authoritative. Exact-two stayed numeric two/init two, exact-one stayed single without a counter, base stayed BUSY-free, and 0/1/4/symbolic values failed closed. No lower-layer repair is required; selected proposed .2 exact-three public contract selection before implementation. An initial guard attempt stopped at 99.5% while unrelated pgen rustc held about 10 GiB; it exited without intervention, then complete runs started at 61.6% and 64.0% under the unchanged 4-GiB descendant cap. Primary and strengthened workspaces contained 5 files/136849 bytes and 5 files/128911 bytes; tempdirs self-cleaned and both exact workspaces were deleted with no residue. Canonical record docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md and fact ial2-ahb-requester-exact-three-busy-insertion-readiness-audit. Knowledge Map generation/check passes at 1002 facts/5090 question keys; mdBook build, memory architecture, relative-doc paths, README entry-point, project-data locality, diff, and all doctrine gates pass; generated book output was removed. No shipped behavior changed.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.1: prove exact-three BUSY readiness`

- ID: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.2`
  Status: `done`
  Goal: `Select the exact public literal-three requester BUSY contract before implementation.`
  Acceptance: `Starting only after clean .1 audit commit, reconcile the authoritative disposable 3->2->1->0 continuous/ready-low/grant-low proof with the shipped exact-one/exact-two generic/alias contracts and current AhbRequester parser/report/residue/support/language/capability/semantic-MCP surfaces. Select or reject exactly one additive generic ppif/ahb_requester_busy_insert_three.ppif contract. If selected, freeze accepted busy-beats literals and diagnostics, source/intent/object/anchor/actor/support/coverage/module/artifact identities, unchanged width-two counter and qualified retirement/priority/SEQ ownership, numeric report/residue truth for exact-one/two/three, assertion-enabled focused runtime and malformed/preservation gates, normalized semantic/read-only MCP parity, projected support accounting, generic-first then separate .ahb alias cadence, docs/Knowledge Map, resource cap, and rollback. Make no parser, generator, public source, support, test, artifact, semantic/MCP API, HDL/runtime, backend, protocol, or transaction-layer behavior change in contract selection. Keep counts above three, generalized count width, runtime/policy/random or multiple-point insertion, local bus-BUSY status, exact-three compositions, broader bursts/signals/managers/fabrics, selector repairs, AXI/APB/VHDL, and decision 0020 separate/inactive.`
  Verification: `Selected proposed .3 additive generic implementation after reconciling the authoritative guarded internal 3 -> 2 -> 1 -> 0 proof with shipped exact-one/exact-two generic/alias contracts, AhbRequester parser/lowering/report/residue, support/language/capability/semantic-MCP surfaces, focused tests, docs, facts, and accounting. Public normalization will accept only literal busy-beats values 2..3; absence stays canonical exact-one, and 0/1/4+/symbolic/non-literal/missing-prerequisite/duplicate forms fail closed with the selected range diagnostic. Froze ppif/ahb_requester_busy_insert_three.ppif, intent/object/anchor/actor/module/artifact/support/coverage identities, unchanged width-two actor counter and qualified >1/==1 retirement/priorities/SEQ ownership, numeric beats=3 report, truthful exact-one/two/three residue, normalized semantic/read-only MCP parity, and projected 321 protocol / 362 supported+strict / 45 AHB paths split 23 .ppif/22 .ahb. .3 must add t1528 with direct 3->2->1->0 continuous/32-ready-low/32-grant-low observation and strengthen t1521 to directly prove 2->1->0; exact-one/base/exact-two aliases and paired report preservation remain gates. The matching exact-three .ahb alias follows only through a later separate selector. Canonical record docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_CONTRACT_SELECTION.md and fact ial2-ahb-requester-exact-three-busy-event-contract-selection. Knowledge Map generation/check, mdBook build, memory architecture, relative-doc paths, README entry-point, project-data locality, diff, and doctrine gates pass; generated book output was removed. No parser/generator/source/support/test/artifact/semantic-MCP API/HDL/runtime/backend/protocol/transaction-layer behavior changed.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.2: select exact-three BUSY contract`

- ID: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.3`
  Status: `proposed`
  Goal: `Ship the additive generic exact-three requester BUSY source through the proven existing lowering.`
  Acceptance: `Activate only after .2 commits cleanly. Add only ppif/ahb_requester_busy_insert_three.ppif with intent ahb_requester_busy_insert_three, object fsmgen-ahb-requester-busy-insert-three, anchor bounded-requester-three-busy-insertion, actor/module amba_requester_busy_insert_three, artifacts amba_requester_busy_insert_three.isf/.fsm, support intent.ppif_ahb_requester_busy_insert_three / ial2_ppif_ahb_requester_busy_insert_three_pipeline_cli, protocol_fixture/supported_smoke+strict, ppif, semantic root fsm. Broaden AhbRequester normalization only from exact literal 2 to literal integers 2..3 with diagnostic 'AHB requester transfer.busy_beats must be a literal integer in 2..3 in this slice'; PPIF syntax is unchanged. Reuse the width-two actor-owned ahb_busy_remaining_q, literal initialization, qualified >1 decrement, ==1 clear/address-pending SEQ handoff, whole-BUSY continuation, final-over-nonfinal and both-over-request priorities, busy_inserted_q, and all owners unchanged. Report numeric beats=3 and make exact-one/two/three shared residue truthful while preserving existing alias suffix cleanup. Add t/1528-ial2-ahb-requester-three-busy-insert.t plus t/data/ahb_requester_three_busy_insert_tb.svt with one assertion-enabled Verilator binary proving continuous/32-ready-low/32-grant-low one episode, three qualified BUSY events, direct internal 3->2->1->0 plus stall stability, one resumed SEQ, four accepted byte INCR4 data beats, stable pending ownership, no BUSY data/response completion, and zero final count. Strengthen t1521 to directly observe exact-two internal 2->1->0. Reject 0/1/4/symbolic/missing-prerequisite/duplicate forms; preserve exact-one, exact-two generic/alias, paired exact-two, base, strict/schedule/report/artifacts/normalized semantic/real read-only MCP/outdir/verifier/diagnostic/language surfaces. Update accounting to 321 protocol / 362 supported+strict / 45 AHB paths split 23 .ppif/22 .ahb. Run focused t1498/t1512/t1521-t1526/t1528/t1518/t248/t297 as affected, syntax/docs/Knowledge Map/doctrine gates under the unchanged RAM guard where broad, remove generated artifacts, and leave a clean tree. Do not add the exact-three .ahb alias, counts above three, generalized width, policy/runtime/random or multiple insertion points, local bus-BUSY status, exact-three compositions, broader bursts/signals/managers/fabrics, selector repairs, AXI/APB/VHDL, or decision 0020 behavior.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-29`: Keep the tree proposed until `.812` commits cleanly. Static
  representability is enough to justify a runtime audit, not public behavior.
- `2026-07-29`: Bound the first audit to literal three at the existing single
  insertion point. Wider/general counts and policy-selected points are larger
  independent contracts.
- `2026-07-29`: Activation condition satisfied: `.812` committed cleanly at
  `37f17ff00`; `.1` is active and still changes no shipped behavior until its
  evidence selects a separate contract or repair owner.
- `2026-07-29`: `.1` proves no lower-layer repair is required: the unchanged
  width-two counter retires internal `3 -> 2 -> 1 -> 0` exactly across
  continuous, 32-ready-low, and 32-grant-low generated-HDL scenarios. Select
  proposed `.2` public contract selection; direct implementation remains
  forbidden until `.2` commits and chooses it.
- `2026-07-29`: Activation condition satisfied: `.1` committed cleanly at
  `91dbc63b1`; `.2` is active for public contract selection only.
- `2026-07-29`: `.2` selects proposed `.3`, the additive generic exact-three
  source. Public `busy-beats` becomes the bounded literal range `2..3` while
  absence remains exact-one; width-two lowering is unchanged, projected
  accounting is 321/362/45 split 23 generic/22 aliases, and the matching
  exact-three `.ahb` alias remains separately owned after generic shipment.

## Blockers

- None. If a future guarded run stops on host pressure, do not raise the cutoff
  or kill unrelated processes.
