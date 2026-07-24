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
  Children: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1`, `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.2`, `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.3`, `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.4`, `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.5`, `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.6`, `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.7`

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
  Status: `done`
  Goal: `Implement exact one-event requester BUSY retirement and lock every generic/alias/paired embedding to ready-qualified cardinality.`
  Acceptance: `Starting only after .2 commits cleanly, implement exactly the selected conditional AhbRequester generated-IAL1 delta: priority ahb_busy_accept over ahb_request, rule guarded by HGRANT && HREADY && HTRANS==BUSY that sets ahb_address_pending_q=1 and HTRANS=SEQ, and the outer !HREADY && HTRANS==BUSY continue gate. Preserve transfer_busy, one-bit busy_inserted_q, all public syntax/diagnostics/ports/report/support/source/artifact/module identities, base requester output, address/data/response ownership, burst/address/data progression, status, and residue. Extend t1498 structural checks and assertion-enabled generated-HDL runtime using public first-visible BUSY stall injection for continuously-qualified, 32-clock ready-low, and 32-clock grant-low scenarios; require exactly one qualified BUSY event, stable fields/counters, the same resumed SEQ, exactly four data beats, and zero remaining. Update paired one-/two-subordinate generic/alias harnesses t1513-t1516 to count one ready-qualified embedded BUSY event per command while preserving parking/mapping/storage/status. Run requester/base/alias/paired/current-surface/phase preservation, t248/t297, strict/report/artifact/verify gates, mdBook/README/roadmap/current behavior/facts/task/Memory/Knowledge Map sync, diff/docs/doctrine gates, and 4-GiB resource cap. Do not add multiple-BUSY syntax/counter/report, runtime/policy throttling, local bus-BUSY status, broader bursts/signals/managers, queues, direct seeds/backends, AXI/APB/VHDL, general output-priority work, or decision 0020.`
  Verification: `AhbRequester.pm conditionally emits priority ahb_busy_accept over ahb_request, a HGRANT && HREADY && HTRANS==BUSY accept rule that arms existing ahb_address_pending_q and drives SEQ, and the selected ready-low BUSY continue gate; base requester generated IAL1 remains free of all BUSY machinery. Assertion-enabled t1498 passes five subtests, including continuous, 32-clock ready-low, and 32-clock grant-low runs, each exact transfers=5/beats=4/busy=1/qualified_busy=1 with stable pending fields/counters and no BUSY data completion. Generic/alias paired t1513/t1514 pass four/five subtests with exact one qualified event, four beats, and storage 44332211; two-window generic/alias t1515/t1516 pass three/five subtests with exact two qualified events, eight beats, and status/control 44332211/88776655. Paired tests retain their prior --no-assert boundary because enabling assertions exposed an unchanged interconnect default-plus-mapped HADDR selector conflict; proposed inactive IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION and fact ial2-ahb-interconnect-default-decode-output-arbitration-gap own it, while requester-only assertions pass. Guarded t1510/t1511/t1512/t1518/t1519 preservation passes 15/15; t248/t297 pass 6815/6815. Final t1518 passes 4/4. Modified Perl sources/tests are syntax-clean; mdBook build, Knowledge Map generation/check at 984 facts/4984 question keys, memory architecture, relative-doc paths, diff, and doctrine gates pass. Generated book output and disposable inspection artifacts were removed. Canonical record docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR.md and fact ial2-ahb-requester-single-busy-event-cardinality-repair.`
  Commit: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.3: enforce single-BUSY event cardinality`

- ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.4`
  Status: `done`
  Goal: `Select the smallest public exact-two requester BUSY event contract after the single-event substrate repair.`
  Acceptance: `Starting only after .3 commits cleanly, reconcile the exact-two disposable candidate from .1 with the now-shipped single-event accept/hold substrate and select one bounded literal public contract. Freeze syntax and diagnostics, whether count extends busy-before-beat or uses a separate clause, minimum/maximum and width, per-qualified-event meaning through ready/grant stalls, counter initialization/retirement, address-pending SEQ handoff, report/support/residue changes, base/single preservation, generic/alias/paired generated-HDL gates, assertion boundary, resource cap, validation, and rollback. Make no shipped behavior change in contract selection. Keep runtime/policy/random throttling, multiple insertion points, local bus-BUSY status, broader bursts/signals/managers, queues/outstanding transfers, direct seeds/backends, AXI/APB/VHDL, separate output-selector repairs, and decision 0020 deferred.`
  Verification: `Selected optional transfer literal (busy-beats 2), with absence preserving canonical exact-one and any other value rejected. Selected additive generic source ppif/ahb_requester_busy_insert_two.ppif, actor/module/artifacts amba_requester_busy_insert_two, support intent.ppif_ahb_requester_busy_insert_two / ial2_ppif_ahb_requester_busy_insert_two_pipeline_cli, projected 315 protocol / 356 supported-smoke+strict / 39 AHB IAL2 sources. Selected width-two ahb_busy_remaining_q initialized before BUSY visibility, non-final qualified decrement, final clear/address-pending/SEQ handoff, outer BUSY gate, stable ready/grant holds, existing busy_inserted_q one-shot, report beats numeric 2 while current single remains unchanged, source-specific truthful residue, assertion-enabled t1521 continuous/32-ready-low/32-grant-low exact-two/four-beat runtime, current generic/alias/paired preservation, 4-GiB cap, and rollback. Canonical record docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_CONTRACT_SELECTION.md and fact ial2-ahb-requester-exact-two-busy-event-contract-selection. t1518 passes 4/4; mdBook build, Knowledge Map generation/check at 985 facts/4990 question keys, memory architecture, relative-doc paths, diff, and doctrine gates pass. Generated book output was removed. No shipped behavior changes. Selected .5 implementation.`
  Commit: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.4: select exact-two BUSY event contract`

- ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.5`
  Status: `done`
  Goal: `Ship the additive exact-two requester BUSY source and assertion-enabled qualified-event runtime.`
  Acceptance: `Starting only after .4 commits cleanly, add optional exact literal busy-beats=2 parsing/normalization, preserve absent-clause exact-one generated behavior, implement the selected width-two remaining counter and non-final/final BUSY retirement rules with initialization before BUSY visibility and the existing address-pending SEQ handoff, add ppif/ahb_requester_busy_insert_two.ppif plus support/language/capability/accounting surfaces, emit numeric busy_insertion.beats=2 and truthful source-specific residue, and add t1521 continuous/32-clock-ready-low/32-clock-grant-low generated-HDL proofs with assertions enabled, exactly two qualified BUSY events, stable fields/counters, one resumed SEQ, four data beats, and zero remaining. Run base/exact-one generic+alias/paired/current-surface/phase preservation, strict/report/artifact/verify gates, t248/t297, mdBook/README/roadmap/current behavior/facts/task/Memory/Knowledge Map sync, diff/docs/doctrine gates, and 4-GiB resource cap. Do not add a new .ahb alias or paired exact-two source, generalized count beyond literal two, multiple insertion points, runtime/policy/random throttling, local bus-BUSY status, broader bursts/signals/managers, queues/outstanding transfers, direct seeds/backends, AXI/APB/VHDL, separate selector repairs, or decision 0020.`
  Verification: `PPIF.pm accepts optional transfer busy-beats and AhbRequester normalization accepts only exact literal 2 with the selected prerequisite/duplicate diagnostics. The exact-two conditional branch adds actor-owned reset storage ahb_busy_remaining_q width 2, initializes it before BUSY visibility, emits non-final decrement and final clear/address-pending/SEQ rules plus explicit accept/continue-over-request and accept-over-continue priorities, and holds the transaction through the whole HTRANS BUSY episode. Direct strict probing initially exposed isf_conflicting_rule_writes because the current checker does not prove >1 versus ==1 guards disjoint; the explicit selected priority repairs checking without changing public semantics. Current exact-one generated IAL1 keeps no counter/continue rule. New ppif/ahb_requester_busy_insert_two.ppif, support identity intent.ppif_ahb_requester_busy_insert_two / ial2_ppif_ahb_requester_busy_insert_two_pipeline_cli, numeric report beats=2, source-specific residue, and 315 protocol / 356 supported+strict / 39 AHB-path accounting ship through the existing generator. Assertion-enabled guarded t1521 passes five subtests: structure, malformed inputs, strict/check/semantic/schedule/artifacts/verify, continuous exact-two, 32-clock ready-low, 32-clock grant-low, exact-one preservation, and base preservation; every runtime is transfers=5/beats=4/busy=1/qualified_busy=2. Guarded t1498 and t1512 preserve exact-one generic/alias behavior; corrected t1518 passes 5/5 current-surface tests. Guarded t1513-t1516 pass 17/17 across generic/alias one-/two-window paired exact-one runtimes in 1710 seconds; t1519 passes 2/2 phase-pipeline tests. t248/t297 pass 6827/6827 accounting/capability tests. Direct t1520 is not warranted because no direct seed changed; generated requester and paired phase paths are exercised. Canonical behavior docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_BEHAVIOR.md and fact ial2-ahb-requester-exact-two-busy-event-behavior record the implementation, including the actor-storage/checker-priority correction to the .4 lowering description. README, ROADMAP_V2, current behavior, mdBook navigation/AHB guide/backlog, task/index/Memory, support/capability, and Knowledge Map are aligned. Both modified Perl modules are syntax-clean; mdBook builds; Knowledge Map generation/check passes at 986 facts/4996 question keys; memory architecture, relative-doc paths, diff, and the authoritative doctrine gate pass. Generated book/probe artifacts are removed. Selected pending .6 matching exact-two .ahb alias contract selection; no alias ships in .5.`
  Commit: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.5: ship exact-two BUSY requester`

- ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.6`
  Status: `done`
  Goal: `Select the matching exact-two requester .ahb profile-alias contract after generic behavior ships.`
  Acceptance: `Starting only after .5 commits cleanly, reconcile shipped ppif/ahb_requester_busy_insert_two.ppif with existing .ahb suffix/profile handling and current exact-one alias precedent. Select or reject one byte-identical data-only ppif/ahb_requester_busy_insert_two.ahb alias; if selected, freeze source/support/coverage identities, alias-only residue cleanup, report/artifact/semantic/check parity, projected 316 protocol / 357 supported-smoke+strict / 40 AHB-path accounting, focused t1522 contract, retained assertion-enabled t1521 runtime, current generic/exact-one/paired preservation, docs/Knowledge Map/doctrine gates, 4-GiB cap, and rollback. Make no shipped behavior change in contract selection. Do not change the requester generator/parser, add a second runtime, paired exact-two sources, counts beyond two, multiple insertion points, policy/runtime/random throttling, local bus-BUSY status, broader bursts/signals/managers, queues/outstanding transfers, direct seeds/backends, AXI/APB/VHDL, separate selector repairs, or decision 0020.`
  Verification: `Selected .7 data-only implementation of byte-identical ppif/ahb_requester_busy_insert_two.ahb with support identity intent.ahb_profile_alias_requester_busy_insert_two, coverage ial2_ahb_profile_alias_requester_busy_insert_two_pipeline_cli, source kind ial2_profile_alias, actor/module amba_requester_busy_insert_two, semantic root fsm, and projected 316 protocol / 357 supported+strict / 40 AHB-path accounting. An in-memory reserved .ahb-label probe over the generic exact-two bytes preserves kind protocol_intent.ahb_requester, amba_requester_busy_insert_two.isf text, all generated IAL0 files, numeric busy_insertion.beats=2, and identical ahb_requester_busy_insert_support while removing only ahb_profile_alias_deferred. Existing PPIF.pm suffix/profile handling makes the alias data-only; no parser/generator/API/runtime change is selected. Focused t1522 owns byte/parse/report/check/schedule/semantic/outdir/verify/support parity, malformed alias probes, and an existing read-only fsmgen_semantic_introspect MCP call; assertion-enabled t1521 remains the sole shared runtime proof. Canonical record docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md and fact ial2-ahb-requester-exact-two-busy-event-profile-alias-contract-selection. Guarded t1518 passes 5/5; mdBook build, relative-doc paths, Perl adapter syntax, diff, Knowledge Map generation/check at 987 facts/5002 question keys, memory architecture, and the authoritative doctrine gate pass. Generated book output was removed. No shipped source/support/report/artifact/semantic/MCP/HDL/runtime behavior changed.`
  Commit: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.6: select exact-two AHB alias contract`

- ID: `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.7`
  Status: `pending`
  Goal: `Ship the byte-identical exact-two requester .ahb profile alias with semantic/MCP parity and no new runtime behavior.`
  Acceptance: `Starting only after .6 commits cleanly, add ppif/ahb_requester_busy_insert_two.ahb as a byte-identical mirror of the generic exact-two source; support-account it as intent.ahb_profile_alias_requester_busy_insert_two / ial2_ahb_profile_alias_requester_busy_insert_two_pipeline_cli with source kind ial2_profile_alias, module amba_requester_busy_insert_two, and semantic root fsm; preserve numeric busy_insertion.beats=2, generated IAL1/IAL0/HDL identity, exact-two support residue, and remove only ahb_profile_alias_deferred through existing suffix handling. Add focused t1522 for source/parse/report/check/schedule/semantic/outdir/verify/support parity, malformed profile-alias probes, generic/exact-one/base preservation, and a read-only fsmgen_semantic_introspect MCP call; retain assertion-enabled t1521 as the shared runtime proof without compiling a second simulation. Update accounting to 316 protocol / 357 supported-smoke+strict / 40 AHB paths, language/capability/current docs/facts/task/Memory/Knowledge Map, and run focused/accounting/docs/doctrine gates under the 4-GiB cap. Do not change parser/generator algorithms or public exact-two behavior, add paired exact-two sources, another runtime, broader counts/points/policies/status/bursts/signals/managers/queues/backends, AXI/APB/VHDL, selector repairs, or decision 0020.`
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
selected `.3`. Activation condition satisfied: `.2` committed cleanly at
`41cab81fb`; `.3` completed the exact-one requester BUSY repair and its
generic/alias paired regression locks and committed cleanly at `a4cabc875`.
`.4` completed exact-two public contract selection and selected `.5`; `.5`
activated after `.4` committed cleanly at `bb6d35523`. `.5` now ships the
generic exact-two requester and selects pending `.6`; `.6` cannot activate
until `.5` commits cleanly. Activation condition satisfied: `.5` committed
cleanly at `ed968926e`; `.6` is active for matching alias contract selection
and has now completed by selecting pending `.7` implementation, which cannot
activate until `.6` commits cleanly.

## Rollback

Before activation, rollback removes this proposed tree and restores `.808` to
the candidate-comparison state. After activation, rollback follows the active
leaf's own evidence and preserves the shipped single-BUSY behavior unchanged.
