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
  Children: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1, IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2, IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3, IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.4`

- ID: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Establish exact-two paired BUSY runtime/lowering readiness and select the next exact owner.`
  Acceptance: `Starting only after clean .809 commit, read the exact-one paired generic/alias and exact-two requester generic/alias behavior/facts/sources/tests, PPIF/AhbRequester/AhbSubordinate/AhbInterconnect lowering and phase ownership, reports/residue/support/language/capability/semantic-MCP surfaces, mdBook/roadmap/Memory/Knowledge Map, selector repairs, and decision 0020. Build a disposable one-subordinate exact-two aggregate without selecting public names; prove normal IAL2->IAL1->IAL0->HDL generation, numeric child beats=2, parks_on=[busy], exact two qualified BUSY events in one episode, stable requester/subordinate/interconnect ownership and storage, no BUSY data completion, one resumed SEQ, four data beats, clean completion, and final 44332211. Retain the paired --no-assert boundary while keeping standalone requester assertions authoritative. Select contract work, a prerequisite repair, deferral, or closure only from evidence; require future check/schedule/semantic JSON/read-only MCP parity. Make no shipped behavior change in the audit.`
  Verification: `A disposable candidate derived from the shipped one-subordinate exact-one paired source changed only the embedded requester/child reference to amba_requester_busy_insert_two and added (busy-beats 2), while retaining provisional source identity so no public name was selected. Existing PPIF/AhbRequester/AhbSubordinate/AhbInterconnect lowering produced schema fsmgen.ial2.protocol_intent.ahb_interconnect.v1, three children, top ahb_tb, exact amba_requester_busy_insert_two plus subordinate/interconnect IAL1/IAL0 and ahb_tb.fsm artifacts, numeric requester child busy_insertion.before_beat=2/beats=2, and subordinate plus aggregate parks_on=[busy]. Generated HDL compiled with Verilator --no-assert under the 4-GiB descendant-RSS cap and passed transfers=5 beats=4 busy=1 qualified_busy=2 resumed_seq=1 storage=44332211. The harness required stable requester address/control/data/beat counters; ahb_busy_remaining_q values 2 then 1 then 0; stable subordinate SEQ continuation, phase pending, and storage; stable interconnect one-hot data owner; no BUSY beat_done; exactly one resumed SEQ; zero remaining and clean status. Existing t1513 plus assertion-enabled t1521 pass 9/9 in 307 seconds. No lower-layer, semantic/MCP, or HDL repair is required. Selected pending .2 public contract selection, generic-first with alias and two-subordinate exact-two separate; future support-accounted behavior must preserve strict check/schedule/normalized semantic JSON/read-only fsmgen_semantic_introspect parity without feature APIs/raw internals. Canonical record docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md and fact ial2-ahb-exact-two-paired-busy-composition-readiness-audit. t1518 passes 5/5; mdBook builds; Knowledge Map generation/check passes at 990 facts/5018 question keys; memory architecture, relative-doc paths, diff, and doctrine gates pass; generated book output was removed. No shipped behavior changed.`
  Commit: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1: prove exact-two paired BUSY readiness`

- ID: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`
  Status: `done`
  Goal: `Select the first public one-subordinate exact-two paired BUSY composition contract.`
  Acceptance: `Starting only after .1 commits cleanly, freeze one generic .ppif source before any matching .ahb alias: exact source/intent/source-object/anchor/requester/support/coverage/test names, unchanged three-child ahb_tb architecture and generated IAL1/IAL0 set, numeric requester-child busy_insertion.beats=2, subordinate and propagated parks_on=[busy], truthful residue, support/accounting/capability/language surfaces, diagnostics, and rollback. Freeze a generated-HDL proof with one BUSY episode/two qualified BUSY events/stable requester-subordinate-interconnect ownership/no BUSY data completion/one resumed SEQ/four byte data beats/clean status/final 44332211, retain the paired --no-assert and standalone assertion-enabled boundaries, and preserve base/exact-one paired/standalone exact-two/aliases/two-subordinate exact-one. Require strict check, schedule, normalized semantic JSON, and existing read-only fsmgen_semantic_introspect MCP parity without a feature-specific API or raw private internals. Make no shipped behavior change. Keep the matching alias, two-subordinate exact-two sibling, broader counts/policy/status/bursts/signals/queues/managers/backends/protocols, separate selector repairs, and decision 0020 deferred.`
  Verification: `Selected one additive generic source ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif with matching intent/source-object/anchor stem, embedded/requester-child amba_requester_busy_insert_two, support identity intent.ppif_ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park, coverage ial2_ppif_ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli, source kind ppif, module ahb_tb, semantic root top, and three composition children. Selected reuse of the existing exact-two requester, HBURST byte-lane BUSY-parking subordinate, interconnect, and top generators with exact IAL1/IAL0 artifacts from .1; no parser/generator/API change. Selected requester-child numeric busy_insertion.before_beat=2/beats=2, subordinate plus propagated parks_on=[busy], no duplicate top busy_flow, unchanged top/interconnect/subordinate residue, exact-two requester support residue, and generic aggregate alias deferral. Selected t1523 plus ahb_exact_two_paired_busy_composition_tb.svt for source/report/artifact/check/schedule/normalized semantic JSON/real read-only fsmgen_semantic_introspect/outdir/verify and --no-assert runtime, with one episode/two qualified BUSY events/stable requester-subordinate-interconnect ownership/2-to-1-to-0 BUSY counter/no BUSY beat completion/one resumed SEQ/four beats/clean status/44332211; t1521 remains assertion-enabled. Current direct count is 316 protocol / 357 supported+strict / 40 AHB paths split 20/20; projected generic implementation is 317 / 358 / 41 split 21 .ppif and 20 .ahb. Selected generic-first, proposed .3 implementation, separate alias and two-subordinate exact-two work, 4-GiB attached monitoring, preservation/docs/Knowledge Map/accounting/rollback gates, and no feature-specific/raw semantic API. Canonical record docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md and fact ial2-ahb-exact-two-paired-busy-composition-contract-selection. t1518 passes 5/5; mdBook builds; Knowledge Map generation/check passes at 991 facts/5023 question keys; memory architecture passes and generated book output was removed. No shipped behavior changed.`
  Commit: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2: select exact-two paired BUSY contract`

- ID: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`
  Status: `done`
  Goal: `Ship the selected generic one-subordinate exact-two paired BUSY composition with runtime and semantic/MCP proof.`
  Acceptance: `Starting only after .2 commits cleanly, implement exactly the selected contract: add ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif as the exact source-data delta from the existing exact-one paired source; add its RegressionCorpus support identity/coverage/source kind/module/top-root/three-child expectations; preserve existing generators and emit exact amba_requester_busy_insert_two, ahb_lite_subordinate_byte_lane_hburst_seq, ahb_interconnect, and ahb_tb IAL1/IAL0 artifacts. Add t1523 and ahb_exact_two_paired_busy_composition_tb.svt to prove source/report/artifacts, strict check, schedule, normalized semantic JSON, real read-only fsmgen_semantic_introspect, outdir, verify-hdl, and generated-HDL one BUSY episode/two qualified events/stable requester-subordinate-interconnect ownership/ahb_busy_remaining_q 2-to-1-to-0/no BUSY data completion/one resumed SEQ/four beats/clean status/final 44332211 under the paired --no-assert boundary while t1521 remains assertion-enabled. Update accounting to 317 protocol / 358 supported-smoke+strict / 41 AHB paths split 21 .ppif and 20 .ahb, support/capability/language/current docs/mdBook/behavior/fact/task/Memory/Knowledge Map, and run focused/preservation/t248/t297/docs/doctrine gates under the 4-GiB cap. Do not add an .ahb alias, two-subordinate exact-two source, parser/generator algorithm or semantic/MCP API change, broader counts/points/policies/status/bursts/signals/queues/managers/fabrics/backends/protocols, separate selector repair, or decision 0020.`
  Verification: `Shipped ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif as the selected source-data-only delta: embedded/requester child amba_requester_busy_insert_two with busy-before-beat=2 and busy-beats=2, unchanged BUSY-parking subordinate, interconnect, and ahb_tb top. Existing generators emit exact amba_requester_busy_insert_two, ahb_lite_subordinate_byte_lane_hburst_seq, ahb_interconnect IAL1/IAL0 plus ahb_tb.fsm; no parser/generator algorithm or semantic/MCP API changed. Support-accounted as intent.ppif_ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park / ial2_ppif_ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli, source kind ppif, module ahb_tb, semantic root top, child count three. Focused t1523 passes 4/4 in 353 seconds: exact source/report/artifacts, strict check, schedule, normalized semantic JSON, real read-only fsmgen_semantic_introspect with shell_access=false, outdir, verify-hdl, and generated-HDL one BUSY episode/two qualified events/stable requester-subordinate-interconnect ownership/counter 2-to-1-to-0/no BUSY beat completion/one resumed SEQ/four clean beats/final 44332211 under the retained --no-assert boundary. Accounting is 317 protocol / 358 supported-smoke+strict; the mdBook inventory is exactly 41 AHB paths split 21 .ppif/20 .ahb. t248 passes 6847/6847 and t297 passes; t1518 first exposed only two expected stale navigation/accounting locks, corrected rerun passes 5/5. Guarded preservation t1513+t1521+t1522 passes 13/13 in 353 seconds, retaining exact-one paired runtime, assertion-enabled exact-two requester continuous/32-clock ready-low/32-clock grant-low runtime, and requester-alias semantic/MCP parity. Canonical behavior docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md and fact ial2-ahb-exact-two-paired-busy-composition-behavior explicitly preserve ongoing check/schedule/normalized semantic/read-only MCP parity. Perl files/tests are syntax-clean; mdBook builds and generated output was removed; Knowledge Map generation/check passes at 992 facts/5029 question keys; memory architecture, relative-doc paths, diff, and authoritative doctrine gates pass. Selected proposed .4 matching alias contract selection after clean .3, with shared t1523 runtime and no second simulation; two-subordinate exact-two and decision 0020 remain separate/inactive.`
  Commit: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3: ship exact-two paired BUSY composition`

- ID: `IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.4`
  Status: `proposed`
  Goal: `Select or reject the matching one-subordinate exact-two paired BUSY .ahb profile-alias contract.`
  Acceptance: `Activate only after .3 commits cleanly. Read the shipped generic exact-two paired behavior/source/support/t1523, the exact-one paired generic/alias precedents and tests, the standalone exact-two requester alias lineage, current .ahb suffix handling and aggregate/child residue suppression, support/language/capability/current docs, normalized semantic/MCP contracts, Memory, Knowledge Map, and decision 0020. Select or reject exactly one byte-identical ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb alias. If selected, freeze support identity intent.ahb_profile_alias_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park, coverage ial2_ahb_profile_alias_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli, source kind ial2_profile_alias, module ahb_tb, semantic root top, child count three, unchanged IAL1/IAL0 artifacts, numeric requester child beats=2, subordinate/propagated parks_on=[busy], alias-only residue cleanup, projected 318 protocol / 359 supported+strict / 42 AHB paths split 21/21, focused t1524 source/report/check/schedule/normalized semantic JSON/real read-only MCP/outdir/verify parity, and shared t1523 runtime without a second simulation. Select a separate implementation leaf only from evidence and make no shipped behavior change. Do not add the alias fixture/support/test, a second runtime, a two-subordinate exact-two source, parser/generator or semantic/MCP API changes, broader counts/points/policies/status/bursts/signals/queues/managers/fabrics/backends/protocols, selector repairs, or decision 0020.`
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

`.2` completed the no-behavior generic public contract selection and selected
`.3` implementation. Activation condition satisfied: `.2` committed cleanly
at `34ccdc40e`; `.3` is active. This activation changes only task/index/Memory
state.

`.3` now ships the selected generic source and selects proposed `.4` matching
profile-alias contract selection. `.4` must remain proposed until `.3` commits
cleanly; activating it earlier would violate the clean-tree pivot rule.

## Rollback

Before activation, rollback removes this proposed tree and restores `.809` to
candidate selection. After activation, rollback follows the active leaf's
evidence while preserving all shipped exact-one/exact-two requester and paired
exact-one behavior. The disposable `.1` candidate lives outside the repository
and has no shipped rollback surface.
