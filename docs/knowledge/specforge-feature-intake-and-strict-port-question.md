---
id: specforge-feature-intake-and-strict-port-question
title: SPECFORGE requests and controls
answers:
  - "where is the response to SPECFORGE's six feature requests and strict-port question?"
  - "does accepting an unknown interface-port clause mean it is supported?"
  - "do actor width parameters currently resize HDL ports on override?"
  - "why does an undriven positive-width actor output disappear?"
  - "where is the SPECFORGE storage-register-access request owned?"
  - "why does read-only actor storage status appear as an HDL input?"
  - "why do generated transaction children duplicate or export actor storage?"
  - "why did the SPECFORGE handoff gate fail?"
  - "where is SPECFORGE request15 owned?"
  - "does ISF support minimum holds or no-later/no-earlier event order?"
  - "can bounded-eventually express reset hold duration?"
date: 2026-11-02
status: current
tags: [specforge, isf, parameters, interface, verification, semantic-api, mcp, storage, register-access]
evidence: t/1904-isf-generated-child-storage-reads.t; docs/audits/generated-child-storage-ownership-20260926.json; docs/decisions/0107-actor-storage-has-one-owner-across-generated-children.md; t/1903-isf-internal-storage-ownership.t; docs/audits/specforge-storage-register-access-intake-20260926.json; docs/SPECFORGE_FEEDBACK_RESPONSE.md; docs/audits/specforge-feature-intake-20260926.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/replay-specforge-feature-intake.py .artifacts/specforge-intake-recheck-new && scripts/run_with_ram_guard.sh -- python3 -B docs/audits/replay-specforge-feature-intake.py .artifacts/storage-access-recheck-new --storage-access
---

`docs/SPECFORGE_FEEDBACK_RESPONSE.md` records September 26 configuration, verification and
phase-metadata required/optional scopes, dependencies and order. Parent `.33` owns them;
intake `.33.1` implements none.

The October 21 handoff acknowledges `.7`–`.10` and `.12` (SEM `.92`).
Durations/timers remain absent. Reset was answered at
`f6c44aa5a4517967632d25c2a190d2f1c2e22f59`. Record inputs were admitted at
`25c01f0127144922ade78951b91439e1d9221c08`; selected inputs are qualified.
Output/copy admission is bounded; generated outputs, member writes,
runtime and full consumer delivery remain open. Root-list ports/variants are
optional. Publication/caller integration are separate; its register is read-only.
Book subsets agree; old refusals stay historical. Replies belong in the tracked response.

Handoff gate: SEM `.93` owns unattributed query timeout, current passes and observer
failure; complete evidence: `docs/audits/specforge-request-status-20261021/`.
No limits changed; current passes do not prove historical repair.

At `a7bf398ac3c1008b996bf0a92bdd18c9464d9fda`, native strict checks accepted `bogus-clause` and
unsupported `present` port options and emitted the same HDL as the clause-free control except its
date header. `_parse_interface` ignored malformed shapes and lacked final unknown-option rejection.
`.33.2` repairs this defect through the shared parser/native/API/MCP boundary: T1898 rejects
unsupported/malformed options in default and strict modes, preserving valid metadata.

Generic widths differ from derived widths (`.32.3`). At a7bf398ac, erased width
dependencies kept WDATA at 32 under a 64-bit override; regeneration at 64 gave 64.
Actor/child scoped carriers and eligible SV now preserve names; parser/reports stay numeric.
T1336/T1368 distinguish these scopes; `.33.3` owns forwarding/library/override/runtime and legality/optional-port dependencies.

The positive-width undriven AWMECID and literal control lost their output role; a driven control
kept it. The FSM retained width but no role/drive marker, so unused-signal inference omitted it.
`.33.9` now carries both directions through `+interface`; T1900 qualifies native/API/MCP inventories
and HDL declarations. `.35` repairs the separate reset-only metadata-without-assignment gap, with
T1901 runtime proof.

The storage-register-access packet is retained in
`docs/audits/specforge-storage-register-access-intake-20260926.json`. Intake `.37` confirms
word-access refusal; `.38.1` owns independent scalar metadata and `.38.2` optional banks. Immediate
`.39.2.1` repairs ordinary/domain storage using the `.39.1` internal-role carrier. T1903 checks the
retained controls, direct FSM replay, exact interfaces, complete native/API/MCP parity, typed/unused
storage, bank elements and independent reset/write/read/hold behavior. The audit keeps the original
input/reset defect for falsification. T1904 qualifies ordinary/single-domain scalar/bank live reads,
exact interfaces and repeat activation. T1911 qualifies aggregate shapes; T1916 qualifies
independent-domain live reads and reset isolation. T1917/T1918 qualify sole scalar child writes
including independent domains; T1919 qualifies whole-record/list writers.
Partial/bank and competing writer qualification remains owned by .39.2.2.4.
Resolved reset widths reject overflow without
warnings. Explicit bindings and local state remain separate; decision `0107` owns shared semantics.

Audits retain caller bytes/hashes, native reports, output-role controls and an independent
HDL width oracle. Replay needs a fresh repository-relative same-volume destination each time;
it captures current outcomes without signing off changed behavior. Caller-wide counts remain
unmeasured; controls do not qualify the whole corpus, future features or four-state knownness.

Request15: `ISF-MINIMUM-HOLD-EVENT-ORDER` owns R1-R4 minimum complete-cycle
holds, inclusive event order, clock/edge/polarity/provenance, scheduling/SV
and precise refusals; R5 assumption/assertion role is optional. Implementation
follows prior required delivery/publication and SEM .33.6 actor placement.
Fresh exact bounded-eventually control accepts/generates; hold and both orders
refuse unsupported operators. Generation proves no hold behavior. RST_I is also
reset: .2 owns non-vacuous sampling/repeated events; no eventual-truth, invented
anchor or synthetic host substitutes. Exact sources/results/HDL:
`docs/audits/push-readiness-20261025/request15-receiver-intake-20261102.json.gz`.
