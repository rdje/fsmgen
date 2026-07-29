# IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT: Audit Literal-Three Requester BUSY Reuse

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT`
- Status: `done`
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
  Status: `done`
  Goal: `Audit literal-three requester BUSY reuse before selecting public behavior.`
  Children: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.1`, `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.2`, `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.3`, `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.4`, `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.5`

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
  Status: `done`
  Goal: `Ship the additive generic exact-three requester BUSY source through the proven existing lowering.`
  Acceptance: `Activate only after .2 commits cleanly. Add only ppif/ahb_requester_busy_insert_three.ppif with intent ahb_requester_busy_insert_three, object fsmgen-ahb-requester-busy-insert-three, anchor bounded-requester-three-busy-insertion, actor/module amba_requester_busy_insert_three, artifacts amba_requester_busy_insert_three.isf/.fsm, support intent.ppif_ahb_requester_busy_insert_three / ial2_ppif_ahb_requester_busy_insert_three_pipeline_cli, protocol_fixture/supported_smoke+strict, ppif, semantic root fsm. Broaden AhbRequester normalization only from exact literal 2 to literal integers 2..3 with diagnostic 'AHB requester transfer.busy_beats must be a literal integer in 2..3 in this slice'; PPIF syntax is unchanged. Reuse the width-two actor-owned ahb_busy_remaining_q, literal initialization, qualified >1 decrement, ==1 clear/address-pending SEQ handoff, whole-BUSY continuation, final-over-nonfinal and both-over-request priorities, busy_inserted_q, and all owners unchanged. Report numeric beats=3 and make exact-one/two/three shared residue truthful while preserving existing alias suffix cleanup. Add t/1528-ial2-ahb-requester-three-busy-insert.t plus t/data/ahb_requester_three_busy_insert_tb.svt with one assertion-enabled Verilator binary proving continuous/32-ready-low/32-grant-low one episode, three qualified BUSY events, direct internal 3->2->1->0 plus stall stability, one resumed SEQ, four accepted byte INCR4 data beats, stable pending ownership, no BUSY data/response completion, and zero final count. Strengthen t1521 to directly observe exact-two internal 2->1->0. Reject 0/1/4/symbolic/missing-prerequisite/duplicate forms; preserve exact-one, exact-two generic/alias, paired exact-two, base, strict/schedule/report/artifacts/normalized semantic/real read-only MCP/outdir/verifier/diagnostic/language surfaces. Update accounting to 321 protocol / 362 supported+strict / 45 AHB paths split 23 .ppif/22 .ahb. Run focused t1498/t1512/t1521-t1526/t1528/t1518/t248/t297 as affected, syntax/docs/Knowledge Map/doctrine gates under the unchanged RAM guard where broad, remove generated artifacts, and leave a clean tree. Do not add the exact-three .ahb alias, counts above three, generalized width, policy/runtime/random or multiple insertion points, local bus-BUSY status, exact-three compositions, broader bursts/signals/managers/fabrics, selector repairs, AXI/APB/VHDL, or decision 0020 behavior.`
  Verification: `Shipped ppif/ahb_requester_busy_insert_three.ppif with the frozen intent/object/anchor/module/artifact identities and exact support intent.ppif_ahb_requester_busy_insert_three / ial2_ppif_ahb_requester_busy_insert_three_pipeline_cli. AhbRequester normalization now accepts only literal integers 2..3 with the selected diagnostic and numeric report; absence stays exact-one, two stays exact-two, and 0/1/4/symbolic/missing-prerequisite/duplicate forms fail closed. The generated branch reuses unchanged width-two actor-owned ahb_busy_remaining_q, literal initialization, qualified >1 decrement, ==1 clear/address-pending SEQ handoff, whole-BUSY continuation, priorities, busy_inserted_q, and owners. Assertion-enabled t1528 passes 5 top-level subtests/87 nested assertions in 48 seconds: one compiled requester proves continuous, 32-ready-low, and 32-grant-low internal 3 -> 2 -> 1 -> 0 retirement, stall stability, one BUSY episode, three qualified events, one resumed SEQ, four byte INCR4 data beats, and zero final count; strict/check/schedule/artifacts/outdir/verifier/normalized semantic/real read-only shell-disabled MCP also pass. Guarded t1498+t1521 pass 10 top-level subtests in 62 seconds, directly locking exact-two 2 -> 1 -> 0. Preservation passes t1512 4/4 in 24 seconds, t1522 4/4 in 47 seconds, t1523 4/4 in 327 seconds, t1524 4/4 in 368 seconds, t1525 3/3 in 603 seconds, and t1526 4/4 in 722 seconds. Two t1526 attempts were safely stopped when an unrelated pgen compiler drove host memory above the 88% cutoff; the complete rerun started at 65.1% and passed under the unchanged 4-GiB descendant cap. t248+t297 pass 6,899 assertions; strengthened t1518 passes 5 top-level subtests and locks exact-one/two/three, alias, paired, mdBook, and fact truth. Current accounting is 321 protocol / 362 supported+strict / 45 AHB paths split 23 .ppif/22 .ahb. Canonical behavior docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_BEHAVIOR.md and fact ial2-ahb-requester-exact-three-busy-event-behavior; historical current exact-one/two/paired docs/facts were reconciled to the new ceiling/accounting. Modified Perl/tests are syntax-clean; the actual AHB inventory is 45 split 23/22; mdBook build, Knowledge Map generation/check at 1004 facts/5102 keys, memory architecture, relative-doc paths, README entry point, project-data locality, diff, and all doctrine gates pass; generated book output and two exact guard-abort lowering temporaries were removed. Selected pending .4 matching exact-three .ahb alias contract selection; no alias ships in .3.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.3: ship generic exact-three BUSY`

- ID: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.4`
  Status: `done`
  Goal: `Select the matching exact-three requester .ahb profile-alias contract after generic behavior ships.`
  Acceptance: `Activate only after .3 commits cleanly. Reconcile shipped ppif/ahb_requester_busy_insert_three.ppif with existing .ahb suffix/profile handling and exact-one/exact-two alias precedent. Select or reject one byte-identical data-only ppif/ahb_requester_busy_insert_three.ahb alias; if selected, freeze support intent.ahb_profile_alias_requester_busy_insert_three / ial2_ahb_profile_alias_requester_busy_insert_three_pipeline_cli, source kind ial2_profile_alias, actor/module amba_requester_busy_insert_three, semantic root fsm, alias-only residue cleanup, numeric beats=3, exact IAL1/IAL0/HDL identity, projected 322 protocol / 363 supported+strict / 46 AHB paths split 23 .ppif/23 .ahb, focused t1529 check/schedule/report/artifact/semantic/read-only MCP/outdir/verifier/diagnostic/preservation contract, retained assertion-enabled t1528 as the sole shared runtime, docs/Knowledge Map/doctrine gates, unchanged 4-GiB cap, and rollback. Make no parser, generator, public source, support entry, test, artifact, semantic/MCP API, HDL/runtime, backend, protocol, or transaction-layer behavior change in contract selection. Do not add the alias itself, a second runtime, counts above three, generalized width, policy/runtime/random or multiple insertion points, local bus-BUSY status, exact-three compositions, broader bursts/signals/managers/fabrics, selector repairs, AXI/APB/VHDL, or decision 0020 behavior.`
  Verification: `Selected proposed .5, a byte-identical data-only ppif/ahb_requester_busy_insert_three.ahb implementation. An in-memory reserved-label probe over the shipped generic text confirmed protocol_intent.ahb_requester/requester mode, source object fsmgen-ahb-requester-busy-insert-three and intent ahb_requester_busy_insert_three, exact amba_requester_busy_insert_three.isf plus identical IAL1 text and IAL0 files, numeric beats=3, removal only of ahb_profile_alias_deferred, and identical shared BUSY-support residue. A second exact-three probe confirmed targeted non-AHB-profile and non-requester-object diagnostics; the future alias path/support identity remain absent. Existing exact-one/exact-two aliases and t1512/t1522 establish shared-runtime precedent; no parser/generator change is needed. Froze support intent.ahb_profile_alias_requester_busy_insert_three / coverage ial2_ahb_profile_alias_requester_busy_insert_three_pipeline_cli, ial2_profile_alias, amba_requester_busy_insert_three, semantic root fsm, projected 322/363/46 split 23/23, focused t1529 parity with no second runtime, and t1528 as the sole shared assertion-enabled runtime. Focused t1518 passes 5 top-level subtests including its 34-assertion exact-one/two/three truth lock. Knowledge Map generation/check passes at 1005 facts/5108 question keys; mdBook build, memory architecture, relative-doc paths, README entry-point, project-data locality, diff, and doctrine gates pass, and generated book output was removed. Canonical record docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md and fact ial2-ahb-requester-exact-three-busy-event-profile-alias-contract-selection. No source/support/test/parser/generator/artifact/semantic-MCP API/HDL/runtime/backend/protocol/transaction-layer behavior changed.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.4: select exact-three AHB alias contract`

- ID: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.5`
  Status: `done`
  Goal: `Ship the selected byte-identical exact-three requester .ahb profile alias.`
  Acceptance: `Activate only after .4 commits cleanly. Add only ppif/ahb_requester_busy_insert_three.ahb as a byte-identical mirror of the shipped generic source; support-account it exactly as intent.ahb_profile_alias_requester_busy_insert_three / ial2_ahb_profile_alias_requester_busy_insert_three_pipeline_cli, source kind ial2_profile_alias, supported_smoke+strict, module amba_requester_busy_insert_three, semantic root fsm. Preserve exact IAL1/IAL0/HDL output, numeric beats=3, width-two 3->2->1->0 qualified retirement, ports/state/runtime behavior, and shared BUSY support residue; remove only ahb_profile_alias_deferred through existing suffix handling. Add t/1529-ial2-ahb-requester-three-busy-insert-profile-alias.t for byte/report/lowering/strict-check/schedule/semantic/real read-only shell-disabled MCP/outdir/verifier/targeted-diagnostic and generic/exact-two/exact-one/paired/base preservation parity. Compile no second simulation and retain assertion-enabled t1528 as the sole shared continuous/32-ready-low/32-grant-low runtime proof. Update support/language/capability/t248/t297/t1518/current docs/mdBook/behavior/fact/task/Memory/Knowledge Map to 322 protocol / 363 supported+strict / 46 AHB paths split 23 .ppif/23 .ahb; run focused/preservation/docs/doctrine gates under the unchanged RAM guard and remove generated artifacts. Do not change parser/generator/report/semantic-MCP APIs, public syntax, counter/rules, add runtime or counts above three/generalized width/policy/runtime/random/multiple points/local bus-BUSY status/exact-three compositions/broader bursts/signals/managers/fabrics/backends/protocols/VHDL/transaction behavior, repair selectors, or activate decision 0020.`
  Verification: `Shipped ppif/ahb_requester_busy_insert_three.ahb as a byte-identical mirror of the generic .ppif source with exact support intent.ahb_profile_alias_requester_busy_insert_three / coverage ial2_ahb_profile_alias_requester_busy_insert_three_pipeline_cli, source kind ial2_profile_alias, supported-smoke+strict, module amba_requester_busy_insert_three, and semantic root fsm. Existing suffix handling removes only ahb_profile_alias_deferred while preserving numeric beats=3, exact IAL1/IAL0/HDL, width-two counter/rules, ports/state/runtime behavior, and shared BUSY-support residue; no parser/generator/report/semantic-MCP API changed. Focused t1529 passes four top-level subtests/72 nested assertions in 53 seconds under the unchanged RAM guard: byte/parse/report/lowering parity, strict check, schedule, artifacts/outdir, normalized semantic JSON, real read-only shell-disabled fsmgen_semantic_introspect, verifier, targeted profile/object diagnostics, and generic exact-three/exact-two alias/exact-one alias/base preservation. It compiles no simulation; assertion-enabled t1528 remains the sole shared continuous/32-ready-low/32-grant-low runtime proof. Guarded t248+t297 pass 6,911 assertions and strengthened t1518 passes five top-level truth-lock subtests. RegressionCorpus, LanguageSurfaceSection, README, ROADMAP_V2, canonical behavior/fact, mdBook navigation/backlog/AHB chapter, task/index/Memory, and Knowledge Map synchronize current accounting to 322 protocol / 363 supported+strict / 46 AHB paths split 23 .ppif/23 .ahb. All four affected Perl/test files are syntax-clean, the alias is byte-identical, and the actual AHB inventory is 46 split 23/23. Knowledge Map generation/check passes at 1006 facts/5114 question keys; mdBook build, memory architecture, relative-doc paths, README entry point, and project-data locality pass, and generated book output is removed. Diff, doctrine, and artifact-cleanup closeout evidence is recorded by this commit. The completed child tree hands the next parent selection to pending IAL2-FEATURE-COMPLETENESS-FRONTIER.813. No counts above three, generalized width, policy/points/status/compositions/broader protocols/backends/VHDL/decision-0020 behavior changed.`
  Commit: `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.5: ship exact-three AHB alias`

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
- `2026-07-29`: Activation condition satisfied: `.2` committed cleanly at
  `5623b975a`; `.3` is active for only the selected generic exact-three
  implementation and preservation gates.
- `2026-07-29`: `.3` ships the generic exact-three source at 321/362/45 with
  unchanged width-two lowering and selects pending `.4`, a separate no-behavior
  contract selection for the matching byte-identical `.ahb` alias. `.4` cannot
  activate before `.3` commits cleanly.
- `2026-07-29`: Activation condition satisfied: `.3` committed cleanly at
  `325f21267`; `.4` is active for matching exact-three `.ahb` alias contract
  selection only and changes no shipped behavior until a later implementation
  leaf is separately selected and committed.
- `2026-07-29`: `.4` selects proposed `.5`, the byte-identical exact-three
  requester `.ahb` alias implementation. Existing suffix handling preserves
  exact lowering, numeric `beats=3`, shared runtime/report semantics, and
  normalized semantic/MCP behavior while removing only alias residue. Projected
  accounting is 322/363/46 split 23/23; focused t1529 owns parity without a
  second simulation and t1528 remains the sole shared runtime proof.
- `2026-07-29`: Activation condition satisfied: `.4` committed cleanly at
  `b7c62d2b6`; `.5` is active for only the selected data-only alias, support
  entry, focused parity test, accounting, and synchronized documentation. No
  source, support, test, generated artifact, API, HDL, or behavior changes in
  activation.
- `2026-07-29`: `.5` ships the byte-identical exact-three requester `.ahb`
  alias at 322/363/46 split 23/23. Focused t1529 proves full parity without a
  second simulation, t1528 remains shared runtime, and all five child leaves
  are complete. Pending parent leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.813`
  owns the next post-alias selection after this task commits cleanly.

## Blockers

- None. If a future guarded run stops on host pressure, do not raise the cutoff
  or kill unrelated processes.
