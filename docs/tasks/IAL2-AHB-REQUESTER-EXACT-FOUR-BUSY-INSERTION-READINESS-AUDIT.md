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
  Children: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1`, `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.2`, `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.3`

- ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Prove or disprove exact-four readiness through the smallest safe counter-width boundary.`
  Acceptance: `Activate only after clean parent selector IAL2-FEATURE-COMPLETENESS-FRONTIER.822. Read the shipped requester generator/adapter, exact-one/two/three sources and tests, IAL1 width/assignment/lowering contracts, support/language/capability/current docs, semantic/read-only-MCP surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, and decision 0020. Recreate a repository-derived same-volume exact-four candidate with only identity/anchor/actor/(busy-beats 4) changes. Record strict/check/schedule/artifact/semantic/MCP/HDL/runtime behavior or the exact first rejection. Determine whether a bounded three-bit counter plus unchanged qualified rules is sufficient, whether reusable width derivation must land first, or whether another lower-layer prerequisite exists. If ready, select a separate public-contract leaf with exact syntax/range, generated artifact, runtime, support, diagnostic, docs, cleanup, rollback, and residue boundaries. Make no tracked parser/generator/source/support/test/artifact/semantic-MCP API/HDL/runtime/backend/protocol/verification-generation/HIAL-VIAL/VHDL/transaction behavior change in the audit. Use the authorized host-100/process-4096 profile, canonical Stats-compatible RAM capacity, separate kernel pressure, repository-local outputs, exact census, and residue proof.`
  Verification: `Activated only after clean parent selector commit db0990c9d through clean activation commit 08e970b3f. A one-file/2,313-byte repository-local exact-four public candidate changes only intent/object/anchor/actor/busy-beats and fails closed before generation with exactly one diagnostic, "AHB requester transfer.busy_beats must be a literal integer in 2..3 in this slice", success=false, unmatched support, and generated_output.emitted=false. Generated the exact-three IAL1, then changed only actor identity, ahb_busy_remaining_q width 2->3, and initializer 3->4 in a disposable copy; strict IAL1-to-IAL0/SystemVerilog lowering and public --verify-hdl pass with the current >1 decrement, ==1 final clear/address-pending SEQ handoff, whole-BUSY continuation, priorities, and assertions unchanged. Verilator 5.046 compiles one --timing assertion-enabled binary without --no-assert; continuous, 32-clock ready-low, and 32-clock grant-low runs each pass transfers=5/beats=4/BUSY episodes=1/qualified BUSY=4/final counter=0, directly observing 4->3->2->1->0 and stall stability with no BUSY data beat and stable pending state. Literal four is lower-layer ready on width three. The preserving public prerequisite is minimum unsigned counter width ceil(log2(busy_beats+1)): 2->2, 3->2, 4->3; hardcoded family-wide width three would needlessly change exact-two/three artifacts. Selected proposed no-behavior contract `.2`. The exact 32-file/2,510,723-byte workspace is removed with zero residue. Canonical audit record/fact are synchronized. Post-cleanup Stats-compatible capacity is 74.8% (17.952/24.000 GiB), kernel pressure is separately 1 (normal), and guard occupancy is excluded as capacity truth. Focused t1518+t1256+t1414 pass 3 files/22 tests; Knowledge Map generation/check reaches 1,033 facts/5,273 keys; mdBook builds exactly 72 files/16,221,633 bytes and its repository-local generated tree is removed with zero residue; Memory is 60 lines; diff and all six doctrine gates pass. No shipped behavior changed.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1: prove exact-four counter readiness`

- ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.2`
  Status: `done`
  Goal: `Select the exact public literal-four requester BUSY and minimum-width counter contract before implementation.`
  Acceptance: `Activate only after clean .1 audit commit. Reconcile the authoritative disposable 4->3->2->1->0 continuous/ready-low/grant-low proof with the shipped exact-one/two/three generic/alias family, AhbRequester normalization/lowering/report/residue, IAL1 width contracts, support/language/capability/current docs, normalized semantic/read-only-MCP surfaces, paired composition preservation, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, and decision 0020. Select or reject exactly one additive generic ppif/ahb_requester_busy_insert_four.ppif contract. If selected, freeze literal range 2..4 and diagnostics, absence-as-exact-one, minimum unsigned counter width ceil(log2(busy_beats+1)) preserving width two for counts two/three and selecting width three for four, exact source/intent/object/anchor/actor/module/artifact/support/coverage identities, numeric report and truthful residue, assertion-enabled continuous/32-ready-low/32-grant-low runtime, malformed/preservation/semantic/MCP/artifact/verifier/support-accounting gates, generic-first then separate alias cadence, docs/Knowledge Map, resource cap, cleanup, and rollback. Make no parser/generator/public source/support/test/artifact/semantic-MCP API/HDL/runtime/backend/protocol/verification-generation/HIAL-VIAL/VHDL/transaction behavior change in contract selection. Keep counts above four, arbitrary/runtime/policy/random counts, multiple insertion points, local bus-BUSY status, new burst/signal/topology behavior, generic priority, other protocols/backends, HIAL/VIAL activation, VHDL, verification generation, and decision 0020 separate.`
  Verification: `Activated only after clean .1 audit commit 74d91347e through clean activation commit ebcc89f0f. Selected one additive generic ppif/ahb_requester_busy_insert_four.ppif with intent/object/anchor/actor/module/artifact/support/coverage identities frozen in docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_CONTRACT_SELECTION.md. Public normalization will accept literal 2..4 with exact diagnostic; absence remains exact-one and 0/1/5+/symbolic/non-literal/missing-prerequisite/duplicate forms fail closed. Selected local integer-loop _counter_width semantics equivalent to ceil(log2(max+1)): exact-two and exact-three remain width two, exact-four uses width three, and current >1/==1 rules, priorities, owners, and IAL1 language remain unchanged. Froze numeric report/residue truth, normalized semantic/read-only shell-disabled MCP parity, t1535 plus fixture with assertion-enabled continuous/32-ready-low/32-grant-low 4->3->2->1->0 runtime, strict/schedule/artifact/outdir/verifier/diagnostic/preservation gates, generic-first alias separation, projected 327 protocol/368 supported+strict/51 AHB split 26 .ppif/25 .ahb, same-volume cleanup, authorized resource profile, and rollback. Selected proposed `.3` implementation. Focused t1518+t1256+t1414 pass 3 files/22 tests; Knowledge Map reaches 1,034 facts/5,278 keys; mdBook builds exactly 72 files/16,231,368 bytes and its repository-local generated tree is removed with zero residue; Memory is 59 lines; diff and all six doctrine gates pass. Canonical Stats-compatible RAM is 69.2% (16.608/24.000 GiB), kernel pressure is separately 1 (normal), and guard occupancy is excluded as capacity truth. Contract selection changes no shipped behavior.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.2: select exact-four BUSY contract`

- ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.3`
  Status: `done`
  Goal: `Ship the additive generic exact-four requester BUSY source with preserving minimum-width lowering.`
  Acceptance: `Activate only after clean .2 contract commit. Implement docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_CONTRACT_SELECTION.md exactly: add ppif/ahb_requester_busy_insert_four.ppif with selected intent/object/anchor/actor/module/artifacts and support intent.ppif_ahb_requester_busy_insert_four / ial2_ppif_ahb_requester_busy_insert_four_pipeline_cli as ppif/protocol_fixture/supported_smoke+strict/root fsm. Broaden AhbRequester normalization only from literal 2..3 to 2..4 with the selected diagnostic; add local integer-loop _counter_width semantics equivalent to ceil(log2(max+1)) and use it only for the multiple-BUSY actor storage so exact-two/three stay width two and exact-four is width three. Preserve exact-one no-counter behavior and all existing >1 decrement, ==1 clear/address-pending SEQ handoff, whole-BUSY continuation, priorities, owners, syntax, and IAL1 language. Update static rule and exact-one/two/three/four residue truth. Add t/1535-ial2-ahb-requester-four-busy-insert.t plus t/data/ahb_requester_four_busy_insert_tb.svt covering identities, literal/range diagnostics, reports, exact IAL1/IAL0, strict/check/schedule, repository-local outdir, --verify-hdl, normalized semantic, real repo-relative read-only shell-disabled MCP, and one Verilator --timing binary without --no-assert proving continuous/32-ready-low/32-grant-low exact 4->3->2->1->0, four qualified events, five presentations, four byte INCR4 data beats, stall stability, stable pending ownership, no BUSY data/response completion, one resumed SEQ, and zero final counter. Preserve every existing generic/alias/paired source byte and prove exact-two/three width-two output plus representative affected t1498/t1512/t1521-t1534; update RegressionCorpus/language/capability/current docs/README/roadmap/mdBook/facts/task/Memory/Knowledge Map to exact 327/368/51 split 26 .ppif/25 .ahb. Use repository-derived same-volume outputs, authorized host100/process4096, canonical Stats-compatible RAM and separate kernel pressure, exact cleanup census, focused/broader/doctrine gates, rollback, and a clean commit. Do not add the .ahb alias, counts above four, arbitrary/runtime/policy/random counts, multiple points, local bus-BUSY status, new burst/signal/topology behavior, generic priority, other protocols/backends, HIAL/VIAL activation, VHDL, verification generation, or decision 0020 behavior.`
  Verification: `Activated only after clean .2 contract commit 58efc8aff through clean activation commit 8baf0abc8. Added only ppif/ahb_requester_busy_insert_four.ppif with the frozen identities plus support intent.ppif_ahb_requester_busy_insert_four / ial2_ppif_ahb_requester_busy_insert_four_pipeline_cli. Normalization accepts literal 2..4 with the exact selected diagnostic. Local integer-loop _counter_width semantics preserve width two for exact-two/three and emit width three for exact-four; exact-one remains counter-free and the existing >1/==1 rules, whole-BUSY continuation, priorities, owners, syntax, and IAL1 language are unchanged. Focused assertion-enabled t1535 passes 5 top-level subtests/91 nested assertions in 48 s: strict/check/schedule/exact artifacts/repository-local output/public verifier/normalized semantic/real read-only shell-disabled MCP, malformed 0/1/5/symbolic/duplicate forms, exact-one/two/three/base preservation, and one Verilator 5.046 --timing binary without --no-assert proving continuous/32-ready-low/32-grant-low exact 4->3->2->1->0, four qualified events, five presentations, four data beats, stable pending ownership, one resumed SEQ, and zero final counter. Requester generics t1498+t1521+t1528 pass 3 files/15 top-level subtests in 108 s; requester aliases t1512+t1522+t1529 pass 3/12 in 127 s; representative exact-three paired t1531+t1533 pass 2/7 with one- and two-window assertion-enabled runtime in 952 s; t1523-t1534 all syntax-check. Support/capability t248+t297 pass 2 files/6,971 assertions. Current-doc t1518 plus t1256+t1414 pass 3 files/22 tests. Accounting is exactly 327 protocol/368 supported+strict/51 AHB split 26 .ppif/25 .ahb. Existing generic/alias/paired PPIF bytes are untouched; only the exact-four source is new. Canonical behavior/fact/current docs, roadmap, README, mdBook, HIAL/VIAL parking, task/index, and 57-line Memory are synchronized. Knowledge Map generation/check passes at 1,035 facts/5,284 keys. mdBook builds exactly 72 files/16,255,132 bytes; the exact generated tree is removed with zero residue. Canonical Stats-compatible capacity is 65.2% (15.651/24.000 GiB), kernel pressure is separately 1 (normal), and guard occupancy is excluded as capacity truth. Diff, residue, frozen-blob, and all six doctrine gates pass. Selected proposed no-behavior `.4` for a separate exact-four `.ahb` alias contract; no alias ships in `.3` and all broader deferrals remain inactive.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.3: ship generic exact-four BUSY`

- ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.4`
  Status: `done`
  Goal: `Select the matching exact-four requester .ahb alias contract after generic shipment.`
  Acceptance: `Activate only after the clean .3 behavior commit. Audit the shipped generic exact-four source, existing exact-one/two/three requester aliases and parity tests, suffix normalization, support/language/capability/current docs, semantic/read-only-MCP surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, and decision 0020. Select or reject exactly one byte-identical ppif/ahb_requester_busy_insert_four.ahb alias through existing machinery. If selected, freeze support id intent.ahb_profile_alias_requester_busy_insert_four, coverage ial2_ahb_profile_alias_requester_busy_insert_four_pipeline_cli, source kind ial2_profile_alias, exact artifact/report/semantic/verifier parity, alias-only residue removal, t1536 focused parity without a second simulation, t1535 as sole shared assertion-enabled runtime, projected 328 protocol/369 supported+strict/52 AHB split 26 .ppif/26 .ahb, same-volume cleanup, authorized resource profile, docs/fact/task/Memory gates, deferrals, and rollback. Make no public parser/generator/HDL/runtime/transaction behavior change in contract selection. Keep paired exact-four compositions, counts above four, runtime/policy/random counts, multiple insertion points, local bus-BUSY status, new burst/signal/topology behavior, HIAL/VIAL activation, VHDL, verification generation, and decision 0020 separate.`
  Verification: `Activated only after clean .3 behavior commit 95bfb7e4b through clean activation commit 6d6976f3e. Reconciled generic exact-four behavior/t1535, exact-one/two/three requester alias precedents t1512/t1522/t1529, PPIF suffix validation/residue cleanup, support/language/capability/current docs, normalized semantic/read-only MCP surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, and decision 0020. A warning-free in-memory reserved-label probe parses identical source text as generic and future alias with kind requester, mode requester, byte-identical IAL1/IAL0, numeric beats=4, width-three ahb_busy_remaining_q, identical BUSY-support residue, and only ahb_profile_alias_deferred removed. Separate probes reproduce targeted wrong-profile and wrong-object rejection. No parser/generator repair is needed. Selected proposed `.5` with alias ppif/ahb_requester_busy_insert_four.ahb, support intent.ahb_profile_alias_requester_busy_insert_four, coverage ial2_ahb_profile_alias_requester_busy_insert_four_pipeline_cli, source kind ial2_profile_alias, semantic root fsm, focused t1536 parity without simulation, t1535 sole shared runtime, and projected 328/369/52 split 26 .ppif/26 .ahb. Canonical contract/fact/current generic behavior, README, roadmap, mdBook, HIAL/VIAL parking, task/index, and 58-line Memory are synchronized. Focused t1518+t1256+t1414 pass 3 files/22 tests; Knowledge Map generation/check reaches 1,036 facts/5,290 keys; mdBook builds exactly 72 files/16,261,674 bytes and its repository-local generated tree is removed with zero residue; diff and all six doctrine gates pass. Canonical Stats-compatible RAM is 63.6% (15.259/24.000 GiB), kernel pressure is separately 1 (normal), and guard occupancy is excluded as capacity truth. No public or runtime behavior changes; the alias remains unshipped until `.5` implementation.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.4: select exact-four BUSY alias contract`

- ID: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.5`
  Status: `active`
  Goal: `Ship the matching byte-identical exact-four requester .ahb alias without another runtime.`
  Acceptance: `Activate only after the clean .4 contract-selection commit. Implement docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md exactly: add byte-identical ppif/ahb_requester_busy_insert_four.ahb through existing suffix/generator machinery with support intent.ahb_profile_alias_requester_busy_insert_four / ial2_ahb_profile_alias_requester_busy_insert_four_pipeline_cli as ial2_profile_alias/protocol_fixture/supported_smoke+strict/root fsm. Preserve exact width-three IAL1, IAL0/HDL, numeric reports, rules, priorities, owners, and semantics; remove only alias-deferred residue. Add t1536 proving byte/report/strict/schedule/artifact/repository-local-output/normalized-semantic/real read-only shell-disabled MCP/HDL-verifier/diagnostic/preservation parity without a second simulation; t1535 remains sole shared assertion-enabled runtime. Update support/language/capability/current docs/README/roadmap/mdBook/behavior/facts/task/Memory/Knowledge Map to exact 328/369/52 split 26 .ppif/26 .ahb. Use repository-derived same-volume outputs, authorized host100/process4096, canonical Stats-compatible RAM and separate kernel pressure, exact cleanup census, focused/broader/doctrine gates, rollback, and a clean commit. Do not change PPIF.pm, AhbRequester.pm, syntax, lowering, artifacts, HDL/runtime, paired compositions, counts above four, runtime/policy/random counts, multiple insertion points, local bus-BUSY status, new burst/signal/topology behavior, other protocols/backends, HIAL/VIAL activation, VHDL, verification generation, or decision 0020.`
  Verification: `Activated only after clean .4 contract-selection commit 3370e15cd. Activation changes task/index/Memory/roadmap/mdBook/HIAL-VIAL continuity state only. The generic exact-four source remains at 327/368/51 split 26 .ppif/25 .ahb; the exact-four alias/support/t1536 remain absent and no parser/generator/report/residue/semantic-MCP API/artifact/HDL/runtime behavior changes. Focused t1518+t1256+t1414 pass 22 assertions; the Knowledge Map remains synchronized at 1036 facts/5290 keys; guarded mdBook build passes and its exact 72-file/16,263,487-byte output is removed; canonical Stats-compatible RAM is 64.2% (15.404/24.000 GiB) with separate normal kernel pressure 1. Implementation evidence remains pending.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.5: activate exact-four BUSY alias`

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
- `2026-07-29`: Clean audit commit `74d91347e` activates `.2` for public
  contract selection; no public or generated behavior changes.
- `2026-07-29`: `.2` selects proposed generic implementation `.3` with literal
  range `2..4`, minimum-width lowering, exact identities, and t1535 ownership.
- `2026-07-29`: Clean contract commit `58efc8aff` activates `.3`; no public or
  generated behavior changes in activation.
- `2026-07-29`: `.3` reserves proposed `.4` for a separate exact-four `.ahb`
  alias contract selector; no alias ships with the generic implementation.
- `2026-07-29`: `.3` ships generic exact-four with literal `2..4`, preserving
  minimum widths `2/2/3`, assertion-enabled t1535 runtime, and 327/368/51;
  proposed no-behavior `.4` is the next clean activation.
- `2026-07-29`: Clean behavior commit `95bfb7e4b` activates no-behavior alias
  contract selector `.4`; generic exact-four remains the sole count-four path.
- `2026-07-29`: `.4` selects proposed `.5`, a byte-identical exact-four `.ahb`
  alias with t1536 parity, t1535 shared runtime, and projected 328/369/52.
- `2026-07-29`: Clean contract commit `3370e15cd` activates data-only `.5`;
  the alias remains absent until implementation.
