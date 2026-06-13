# IAL2-FEATURE-COMPLETENESS-FRONTIER: IAL2 Feature Completeness Frontier

## Metadata

- Tree ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER`
- Status: `active`
- Roadmap lane: `IAL2 / SV-backed feature completeness`
- Created: `2026-06-12`
- Last updated: `2026-06-13`
- Owner: repo-local workflow

## Goal

Drive IAL2 toward feature completeness on the SystemVerilog-backed lowering
path before reopening VHDL backend or VHDL rerouting work.

## Non-Goals

- Do not implement VHDL backend or VHDL reroute work from this tree.
- Do not claim IAL2 is feature complete until all selected protocol/platform
  intent surfaces, diagnostics, generated IAL1/IAL0 review artifacts, HDL
  generation, reports, and mdBook documentation are task-tree owned and
  verified.
- Do not bypass the required `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering
  chain.
- Do not widen `.isf` with IAL2 source forms by accident; any IAL1 feature
  required by IAL2 must be explicitly selected, task-tree owned, documented,
  and regression-backed.
- Do not describe IAL0, IAL1, IAL2, or the mdBook as Perl-only APIs. They are
  backend-language-neutral contracts for the current Perl reference
  implementation plus future Rust, Rust/Wasm, browser-capable JavaScript, and
  Dart/web implementations; see `docs/decisions/0018`.

## Acceptance Criteria

- The first leaf audits shipped IAL2 surfaces and selects the next exact
  feature-completeness slice before behavior changes.
- The audit explicitly records any IAL1 or IAL0/SV prerequisites required by
  the selected IAL2 slice.
- Every implementation leaf preserves reviewable generated IAL1 and IAL0
  artifacts before SystemVerilog HDL generation.
- Public contracts, diagnostics, mdBook, roadmap, and Knowledge Map are kept in
  sync for each shipped IAL2 capability.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER`
  Status: `active`
  Goal: `Make IAL2 feature-complete on the SystemVerilog-backed path before VHDL work resumes.`
  Children: `IAL2-FEATURE-COMPLETENESS-FRONTIER.1, IAL2-FEATURE-COMPLETENESS-FRONTIER.2, IAL2-FEATURE-COMPLETENESS-FRONTIER.3, IAL2-FEATURE-COMPLETENESS-FRONTIER.4, IAL2-FEATURE-COMPLETENESS-FRONTIER.5, IAL2-FEATURE-COMPLETENESS-FRONTIER.6, IAL2-FEATURE-COMPLETENESS-FRONTIER.7, IAL2-FEATURE-COMPLETENESS-FRONTIER.8, IAL2-FEATURE-COMPLETENESS-FRONTIER.9, IAL2-FEATURE-COMPLETENESS-FRONTIER.10, IAL2-FEATURE-COMPLETENESS-FRONTIER.11, IAL2-FEATURE-COMPLETENESS-FRONTIER.12, IAL2-FEATURE-COMPLETENESS-FRONTIER.13, IAL2-FEATURE-COMPLETENESS-FRONTIER.14, IAL2-FEATURE-COMPLETENESS-FRONTIER.15, IAL2-FEATURE-COMPLETENESS-FRONTIER.16, IAL2-FEATURE-COMPLETENESS-FRONTIER.17, IAL2-FEATURE-COMPLETENESS-FRONTIER.18, IAL2-FEATURE-COMPLETENESS-FRONTIER.19, IAL2-FEATURE-COMPLETENESS-FRONTIER.20, IAL2-FEATURE-COMPLETENESS-FRONTIER.21, IAL2-FEATURE-COMPLETENESS-FRONTIER.22, IAL2-FEATURE-COMPLETENESS-FRONTIER.23, IAL2-FEATURE-COMPLETENESS-FRONTIER.24, IAL2-FEATURE-COMPLETENESS-FRONTIER.25, IAL2-FEATURE-COMPLETENESS-FRONTIER.26, IAL2-FEATURE-COMPLETENESS-FRONTIER.27, IAL2-FEATURE-COMPLETENESS-FRONTIER.28, IAL2-FEATURE-COMPLETENESS-FRONTIER.29, IAL2-FEATURE-COMPLETENESS-FRONTIER.30, IAL2-FEATURE-COMPLETENESS-FRONTIER.31, IAL2-FEATURE-COMPLETENESS-FRONTIER.32, IAL2-FEATURE-COMPLETENESS-FRONTIER.33, IAL2-FEATURE-COMPLETENESS-FRONTIER.34, IAL2-FEATURE-COMPLETENESS-FRONTIER.35, IAL2-FEATURE-COMPLETENESS-FRONTIER.36, IAL2-FEATURE-COMPLETENESS-FRONTIER.37, IAL2-FEATURE-COMPLETENESS-FRONTIER.38, IAL2-FEATURE-COMPLETENESS-FRONTIER.39, IAL2-FEATURE-COMPLETENESS-FRONTIER.40, IAL2-FEATURE-COMPLETENESS-FRONTIER.41, IAL2-FEATURE-COMPLETENESS-FRONTIER.42, IAL2-FEATURE-COMPLETENESS-FRONTIER.43, IAL2-FEATURE-COMPLETENESS-FRONTIER.44, IAL2-FEATURE-COMPLETENESS-FRONTIER.45, IAL2-FEATURE-COMPLETENESS-FRONTIER.46, IAL2-FEATURE-COMPLETENESS-FRONTIER.47, IAL2-FEATURE-COMPLETENESS-FRONTIER.48, IAL2-FEATURE-COMPLETENESS-FRONTIER.49, IAL2-FEATURE-COMPLETENESS-FRONTIER.50, IAL2-FEATURE-COMPLETENESS-FRONTIER.51, IAL2-FEATURE-COMPLETENESS-FRONTIER.52, IAL2-FEATURE-COMPLETENESS-FRONTIER.53, IAL2-FEATURE-COMPLETENESS-FRONTIER.54, IAL2-FEATURE-COMPLETENESS-FRONTIER.55, IAL2-FEATURE-COMPLETENESS-FRONTIER.56, IAL2-FEATURE-COMPLETENESS-FRONTIER.57, IAL2-FEATURE-COMPLETENESS-FRONTIER.58, IAL2-FEATURE-COMPLETENESS-FRONTIER.59, IAL2-FEATURE-COMPLETENESS-FRONTIER.60, IAL2-FEATURE-COMPLETENESS-FRONTIER.61, IAL2-FEATURE-COMPLETENESS-FRONTIER.62, IAL2-FEATURE-COMPLETENESS-FRONTIER.63`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.1`
  Status: `done`
  Goal: `Audit the shipped IAL2 surface and select the next exact feature-completeness slice.`
  Acceptance: `The selector records shipped IAL2 capabilities, missing feature-completeness surfaces, likely next slice, required IAL1/IAL0/SV prerequisites, validation gates, rollback boundary, docs/contracts to update, and any blockers before behavior changes.`
  Verification: `Read README.md, MEMORY_ARCHITECTURE.md, COMMIT.md, docs/TASK_TREE.md, relevant decisions, Knowledge Map fact cards, AXI/IAL2 design notes, mdBook IAL2 section, and focused PPIF/ValidReady code/tests; selected .2 as the next exact pre-code owner; doc/continuity gates passed.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.1: select next IAL2 slice`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.2`
  Status: `done`
  Goal: `Select the first post-Valid-Ready AXI manager rule subset and pre-code contract.`
  Acceptance: `The selector chooses one bounded source-anchored AXI manager subset from the rule matrix, records exact source anchors, authored .ppif/profile surface expectations, generated IAL1 .isf review artifact shape, generated IAL0 .fsm/HDL expectations, required IAL1 or IAL0/SV prerequisites, diagnostics/report contracts, mdBook/public contract updates, validation gates, explicit residue, and the rollback boundary before any manager behavior is implemented.`
  Verification: `Selected the AXI manager outstanding-capacity and acceptance/status subset, anchored to A1.1/A1.2/A5.1; recorded authored .ppif/profile expectations, generated IAL1/IAL0 artifact shape, likely IAL1/IAL0/SV prerequisites, report/diagnostic contracts, mdBook sync, validation gates, residue, and docs-only rollback boundary.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.2: select AXI manager capacity slice`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.3`
  Status: `done`
  Goal: `Audit readiness for the AXI manager capacity/status implementation slice.`
  Acceptance: `The audit reads the PPIF parser/generator, IAL2 Valid-Ready generator, IAL1 parser/lowerer/report emitters, IAL0/HDL emission surfaces, public contract metadata, and focused tests; decides whether the selected capacity/status subset can be implemented by existing IAL1 constructs or needs new IAL1/IAL0/SV prerequisites first; records exact implementation boundary, tests, report schema, mdBook updates, blockers, residue, and rollback before behavior changes.`
  Verification: `Audited the PPIF parser/CLI shape, Valid-Ready generator pattern, IAL1 storage/status/rule substrate, IAL0/SystemVerilog review-artifact path, support-accounting/language-surface metadata, mdBook, roadmap, and focused tests. Concluded the first capacity/status implementation can use existing IAL1 and IAL0/SV as an in-process generator first; public .ppif syntax remains a later exact owner.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.3: audit AXI manager capacity readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.4`
  Status: `done`
  Goal: `Implement the first in-process AXI manager capacity/status generator slice.`
  Acceptance: `A new in-process IAL2 generator accepts a structured AXI4 manager capacity/status contract with explicit read/write max-pending depths and try-policy abstract submit/complete events; emits reviewable generated .isf before generated .fsm; lowers through existing IAL1/IAL0 to SystemVerilog; reports schema fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1 with source anchors, generated artifacts, status outputs, capacity metadata, assumptions, static rules, and residue; rejects unsupported policies, ID/order/response/burst/channel-expansion requests, direct IAL2-to-IAL0 lowering, and name collisions; adds focused tests and mdBook/user-facing docs.`
  Verification: `Added FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus and t/1437-axi-ial2-manager-capacity-status-generator.t; proved generated .isf before .fsm, existing IAL1/IAL0 lowering, SystemVerilog reachability, capacity/status rule matrix behavior, report schema, fail-closed diagnostics, docs, mdBook, Knowledge Map, memory, and hygiene gates.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.4: ship AXI manager capacity generator`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.5`
  Status: `done`
  Goal: `Select the public .ppif AXI manager capacity/status syntax and readiness boundary.`
  Acceptance: `The selector/audit reads the shipped in-process capacity/status generator, PPIF parser/CLI paths, support-accounting corpus, capability/language-surface metadata, check JSON, semantic JSON, sample policy, mdBook, and focused tests; chooses the exact public .ppif manager object syntax and first parser/CLI slice boundary or records required prerequisites first; documents diagnostics, source-identity behavior, generated review artifacts, validation gates, residue, and rollback before any public parser behavior changes.`
  Verification: `Selected one public (manager-capacity-status ...) object under protocol-platform-intent/profile/source, mapped the syntax to the in-process generator contract, confirmed the existing single-object PPIF CLI path can carry the result shape, recorded required parser/CLI/sample/corpus/manifest/check JSON/semantic JSON/docs/test surfaces, and kept mixed objects, bundles, IDs, ordering, responses, bursts, queued/blocking policy, aliases, and VHDL deferred.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.5: select AXI capacity PPIF syntax`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.6`
  Status: `done`
  Goal: `Implement the public .ppif AXI manager capacity/status parser/CLI first slice.`
  Acceptance: `The PPIF adapter accepts exactly one selected (manager-capacity-status ...) object with profile axi4 and top-level source anchors; maps it to FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus; rejects mixed valid-ready/manager objects, multiple manager objects, unsupported aliases, IDs, ordering, response matching, bursts, queued/blocking policy, malformed clauses, and name collisions; bin/fsmgen supports --emit-schedule-json, --outdir, default HDL, --verify-hdl, --check --json, and --emit-semantic-json for the new sample while preserving generated .isf before .fsm and public .ppif source identity; support-accounting corpus, language-surface/capability manifest, focused tests, mdBook, docs, Knowledge Map, and memory are synced.`
  Verification: `Added parser dispatch for exactly one manager-capacity-status object, ppif/axi_manager_capacity_status.ppif, support-accounting entry intent.ppif_axi_manager_capacity_status, language-surface boundary text, parser/CLI/source-identity diagnostics, docs, mdBook, Knowledge Map, and focused tests proving schedule JSON, --outdir, HDL, --verify-hdl, check JSON, semantic JSON, generated .isf before .fsm, and fail-closed residue.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.6: ship AXI capacity PPIF parser`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.7`
  Status: `done`
  Goal: `Select the next AXI manager behavior subset after the shipped capacity/status .ppif slice.`
  Acceptance: `The selector reads the AXI manager rule matrix, ID/order evidence, shipped Valid-Ready surfaces, shipped capacity/status generator and .ppif parser, IAL1/IAL0/SV substrate, public diagnostics, support accounting, mdBook, and tests; chooses the next exact source-anchored AXI manager behavior subset or records a required IAL1/IAL0/SV prerequisite first; documents scope, non-goals, public syntax expectations, generated .isf/.fsm review artifact expectations, report/check/semantic JSON impacts, validation gates, residue, rollback boundary, and next implementation owner before behavior changes.`
  Verification: `Selected AXI manager ID-family declaration and static validation as the next subset after capacity/status, anchored to A5.1/A5.1.1/A5.5/A5.6; documented read/write ID width and signal-pair expectations, zero-width absence semantics, static diagnostics, report contract, generated artifact boundary, explicit residue, validation gates, and selected .8 as the readiness audit before implementation.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.7: select AXI ID family slice`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.8`
  Status: `done`
  Goal: `Audit readiness for the AXI manager ID-family/static-validation implementation slice.`
  Acceptance: `The audit reads the shipped capacity/status generator, PPIF parser, public sample, support-accounting corpus, report/check/semantic JSON surfaces, IAL1/IAL0/SystemVerilog paths, identifier/name-collision helpers, mdBook, and focused tests; decides whether the selected ID-family subset should be implemented as an additive capacity/status extension, a new manager object, or a prerequisite IAL1/IAL0/SV substrate slice; records exact implementation boundary, public syntax, report schema/versioning, diagnostics, validation gates, docs, residue, and rollback before behavior changes.`
  Verification: `Selected an additive optional id_families extension to the existing manager-capacity-status object; no IAL1/IAL0/SV prerequisite is required because the first ID-family slice is static/report metadata; documented public syntax, in-process contract shape, code owners, separate sample/support-accounting entry, report schema decision, diagnostics, validation gates, residue, and selected .9 as the implementation owner.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.8: audit AXI ID family readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.9`
  Status: `done`
  Goal: `Implement the additive AXI manager ID-family/static-validation slice.`
  Acceptance: `The capacity/status generator accepts optional structured id_families for separate read/write ID families; PPIF accepts an optional (id-families ...) clause under one manager-capacity-status object; widths in 0..32 are validated; positive widths require request/response ID signal names; zero widths reject ID signal names and report absent families; ID signal names participate in collision checks; report JSON additively emits id_families and updated residue without changing generated .isf/.fsm/HDL behavior; a separate public sample and support-accounting entry cover the feature; check JSON and semantic JSON preserve .ppif source identity; focused diagnostics, mdBook, docs, Knowledge Map, and memory are synced.`
  Verification: `Added optional structured id_families normalization to FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus, parsed (id-families ...) in FSM::Adapter::IAL2::PPIF, added ppif/axi_manager_capacity_status_id_family.ppif and support-accounting entry intent.ppif_axi_manager_capacity_status_id_family, emitted report-only id_families metadata while proving generated .isf/.fsm/HDL text stays unchanged, added fail-closed diagnostics for malformed widths/families/signals/collisions, and synced docs/mdBook/Knowledge Map/memory.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.9: ship AXI ID family metadata`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.10`
  Status: `done`
  Goal: `Select the next IAL2 feature-completeness slice after the shipped AXI manager ID-family metadata.`
  Acceptance: `The selector reads the shipped Valid-Ready, bundle, capacity/status, and ID-family .ppif surfaces; AXI rule matrix/evidence notes; IAL1/IAL0/SystemVerilog substrate; support accounting; diagnostics; public JSON surfaces; mdBook; and roadmap. It chooses one next exact IAL2 behavior subset or a required IAL1/IAL0/SV prerequisite before behavior changes, records source anchors, public syntax/report expectations, generated .isf/.fsm/HDL boundaries, diagnostics, validation gates, residue, rollback, and next implementation owner.`
  Verification: `Selected AXI manager logical read/write transaction-envelope/static validation as the next subset after shipped capacity/status and ID-family metadata; recorded source anchors, machine-readable AST/structural transaction roles, static validation expectations, report expectations, generated artifact boundary, explicit residue, and selected .11 as the readiness audit before implementation.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.10: select AXI transaction envelope slice`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.11`
  Status: `done`
  Goal: `Audit readiness for the AXI manager logical transaction-envelope/static-validation slice.`
  Acceptance: `The audit reads the shipped capacity/status and ID-family generator/parser paths, PPIF samples, report/check/semantic JSON surfaces, IAL1/IAL0/SystemVerilog substrate, AXI rule matrix/evidence, diagnostics, support accounting, mdBook, and tests; decides whether the first transaction-envelope implementation should extend manager-capacity-status, introduce a broader manager object, or land an IAL1/IAL0/SV prerequisite first; records exact public syntax, in-process contract shape, report schema impacts, generated .isf/.fsm/HDL boundaries, diagnostics, validation gates, docs, residue, rollback, and next implementation owner before behavior changes.`
  Verification: `Selected an additive optional transactions extension under the existing manager-capacity-status object; no IAL1/IAL0/SV prerequisite is required for the first static/report metadata slice because transaction request/completion bindings must reference the existing direction-level abstract events; documented public syntax, in-process AST/structural contract shape, report impacts, unchanged generated artifact boundary, diagnostics, validation gates, residue, and selected .12 as the implementation owner.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.11: audit AXI transaction envelope readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.12`
  Status: `done`
  Goal: `Implement the additive AXI manager transaction-envelope/static-validation metadata slice.`
  Acceptance: `The capacity/status generator accepts optional structured transactions; PPIF accepts an optional (transactions ...) clause under one manager-capacity-status object; transactions normalize to machine-readable AST/structural entries with name, kind, tag, direction-level request/completion event bindings, and id policy/value; concrete IDs validate against declared ID-family width/presence; report JSON additively emits transactions without changing generated .isf/.fsm/HDL behavior; a separate public sample and support-accounting entry cover the feature; check JSON and semantic JSON preserve .ppif source identity; focused diagnostics, mdBook, docs, Knowledge Map, and memory are synced.`
  Verification: `Added optional structured transactions normalization to FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus, parsed (transactions ...) in FSM::Adapter::IAL2::PPIF, added ppif/axi_manager_capacity_status_transaction_envelope.ppif and support-accounting entry intent.ppif_axi_manager_capacity_status_transaction_envelope, emitted report-only transactions metadata while proving generated .isf/.fsm/HDL text stays unchanged, added fail-closed diagnostics for malformed transaction clauses/events/IDs, and synced docs/mdBook/Knowledge Map/memory.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.12: ship AXI transaction metadata`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.13`
  Status: `done`
  Goal: `Select the next IAL2 feature-completeness slice after the shipped AXI manager transaction-envelope metadata.`
  Acceptance: `The selector reads the shipped Valid-Ready, bundle, capacity/status, ID-family, and transaction-envelope .ppif surfaces; AXI rule matrix/evidence notes; IAL1/IAL0/SystemVerilog substrate; support accounting; diagnostics; public JSON surfaces; mdBook; and roadmap. It chooses one next exact IAL2 behavior subset or a required IAL1/IAL0/SV prerequisite before behavior changes, records source anchors, public syntax/report expectations, generated .isf/.fsm/HDL boundaries, diagnostics, validation gates, residue, rollback, and next implementation owner.`
  Verification: `Selected AXI manager transaction event dispatch and direction fan-in as the next prerequisite after shipped structural transaction-envelope metadata; recorded why ID allocation and response matching need per-transaction event provenance first, candidate syntax, generated artifact expectations, diagnostics, validation gates, explicit residue, and selected .14 as the readiness audit before behavior changes.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.13: select AXI transaction event dispatch`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.14`
  Status: `done`
  Goal: `Audit readiness for the AXI manager transaction event dispatch and direction fan-in slice.`
  Acceptance: `The audit reads the shipped transaction-envelope metadata path, capacity/status generator, PPIF parser, IAL1 expression/lowering emitters, schedule-report surfaces, SystemVerilog backend, public samples, diagnostics, support accounting, mdBook, and tests; decides whether distinct per-transaction request/completion events can fan into the existing read/write capacity/status rule matrices directly, require an IAL1/IAL0/SV prerequisite first, or should be deferred behind another exact owner; records exact public syntax, in-process contract shape, generated .isf/.fsm/HDL impacts, report schema impacts, diagnostics, validation gates, docs, residue, rollback, and next implementation owner before behavior changes.`
  Verification: `Audited the shipped transaction-envelope metadata path, capacity/status generator restriction point, PPIF transaction parser, IAL1 rule guard expression validation, lowering expression preservation, schedule-report surfaces, SystemVerilog expression lowering, focused tests, public samples, support accounting, roadmap, and mdBook. A temporary runtime probe verified the exact OR fan-in guard shape through .isf -> .fsm -> SystemVerilog. Selected .15 as an additive implementation owner with no separate IAL1/IAL0/SV prerequisite first.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.14: audit AXI transaction dispatch readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.15`
  Status: `done`
  Goal: `Implement the additive AXI manager transaction event dispatch and direction fan-in slice.`
  Acceptance: `The capacity/status generator accepts distinct per-transaction request/completion events inside optional transactions; declares every unique event as a generated IAL1 input; computes per-direction request/completion fan-in expressions; preserves one-event scalar compatibility for existing capacity/status, ID-family, and transaction-envelope samples; emits OR fan-in guards only for multi-event groups; reports additive transaction_event_dispatch metadata; PPIF, support-accounting, check JSON, semantic JSON, generated review artifacts, SystemVerilog, diagnostics, mdBook, Knowledge Map, and memory are synced; ID allocation, response matching, ordering, bursts, queued/blocking policy, aliases, full manager syntax, and VHDL remain residue.`
  Verification: `Relaxed the transaction event restriction in FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus, derived per-direction request/completion fan-in, declared unique generated event inputs, emitted OR fan-in guards for multi-event groups, added additive transaction_event_dispatch report metadata, widened the IAL1 guard-conflict proof for bounded OR/negated-OR generated guards, added ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif, support-accounting and language-surface metadata, focused generator and PPIF/CLI tests, docs, mdBook, Knowledge Map, and memory sync.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.15: ship AXI transaction event dispatch`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.16`
  Status: `done`
  Goal: `Select the next IAL2 feature-completeness slice after shipped AXI manager transaction event dispatch.`
  Acceptance: `The selector reads the shipped Valid-Ready, bundle, capacity/status, ID-family, transaction-envelope, and transaction-event-dispatch .ppif surfaces; AXI rule matrix/evidence notes; IAL1/IAL0/SystemVerilog substrate; support accounting; diagnostics; public JSON surfaces; mdBook; roadmap; and prior residue. It chooses one next exact IAL2 behavior subset or a required IAL1/IAL0/SV prerequisite before behavior changes, records source anchors, public syntax/report expectations, generated .isf/.fsm/HDL boundaries, diagnostics, validation gates, residue, rollback, and next implementation owner.`
  Verification: `Selected AXI manager ID/response rule-engine readiness as the next exact subset after shipped transaction event provenance; recorded why ID allocation and response matching now need a source-anchored readiness audit over ID-family signals, transaction ID policies, response ID matching, in-flight state, IAL1/IAL0/SystemVerilog substrate, report metadata, diagnostics, validation gates, explicit residue, and selected .17 as the readiness audit before behavior changes.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.16: select AXI ID response readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.17`
  Status: `done`
  Goal: `Audit readiness for the AXI manager ID/response rule-engine slice.`
  Acceptance: `The audit reads the shipped capacity/status, ID-family, transaction-envelope, and transaction-event-dispatch generator and .ppif surfaces; AXI ID/order evidence and rule matrix; IAL1 input-width, storage, guard/action expression, equality, report, and SystemVerilog lowering substrate; support accounting; diagnostics; public JSON surfaces; mdBook; roadmap; and prior residue. It decides whether the first ID/response rule-engine implementation can extend the existing manager-capacity-status object, should select a narrower concrete-ID validation/matching boundary, requires an IAL1/IAL0/SV prerequisite first, or must be deferred behind another exact owner; records exact public syntax/report expectations, generated .isf/.fsm/HDL impacts, diagnostics, validation gates, residue, rollback, and next implementation owner before behavior changes.`
  Verification: `Audited the shipped ID-family, transaction-envelope, and transaction event dispatch surfaces; IAL1 width-bearing inputs, immediate assertions, equality/implication expressions, assertion-only transactions, generated .fsm +assert carriers, and SystemVerilog assertion emitter path; selected an additive concrete transaction ID assertion implementation boundary with no separate IAL1/IAL0/SystemVerilog prerequisite first.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.17: audit AXI ID response readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.18`
  Status: `done`
  Goal: `Implement the additive AXI manager concrete transaction ID assertion slice.`
  Acceptance: `The capacity/status generator emits concrete-ID request/response assertions for transactions with concrete requested IDs; declares the used positive-width ID-family request/response ID signals as generated IAL1 inputs; preserves capacity/status rule matrix behavior and samples without concrete ID assertions; generated .fsm exposes +assert carriers and ID signal +size entries; SystemVerilog emits verification-only concrete ID assertions through the existing assertion backend; report JSON additively emits ID/response rule-engine metadata; auto-ID allocation, ID release, same-ID ordering, response demux, bursts, queued/blocking policy, aliases, full manager syntax, and VHDL remain residue; focused generator, PPIF/CLI, check JSON, semantic JSON, mdBook, Knowledge Map, and memory are synced.`
  Verification: `Extended FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus with id_response_rule_engine normalization/reporting, generated width-bearing ID inputs, assertion-only IAL1 concrete ID checks, .fsm +assert carriers, fail-closed duplicate concrete-event diagnostics, focused generator and PPIF/CLI coverage, SystemVerilog assertion backend checks, language-surface metadata, docs, mdBook, Knowledge Map, and memory sync.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.18: ship AXI concrete ID assertions`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.19`
  Status: `done`
  Goal: `Select the next IAL2 feature-completeness slice after shipped AXI manager concrete transaction ID assertions.`
  Acceptance: `The selector reads the shipped Valid-Ready, bundle, capacity/status, ID-family, transaction-envelope, transaction-event-dispatch, and concrete-ID assertion .ppif surfaces; AXI rule matrix/evidence notes; IAL1/IAL0/SystemVerilog substrate; support accounting; diagnostics; public JSON surfaces; mdBook; roadmap; and prior residue. It chooses one next exact IAL2 behavior subset or a required IAL1/IAL0/SV prerequisite before behavior changes, records source anchors, public syntax/report expectations, generated .isf/.fsm/HDL boundaries, diagnostics, validation gates, residue, rollback, and next implementation owner.`
  Verification: `Selected AXI manager auto-ID lifecycle readiness as the next exact subset after concrete ID assertions; recorded why request-ID drive, ID busy/free state, completion release, diagnostics, report metadata, and IAL1/IAL0/SystemVerilog substrate must be audited before any auto-ID allocation or response demux behavior changes.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.19: select AXI auto-ID lifecycle`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.20`
  Status: `done`
  Goal: `Audit readiness for AXI manager auto-ID lifecycle and request-ID drive.`
  Acceptance: `The audit reads the shipped capacity/status, ID-family, transaction-envelope, transaction-event-dispatch, and concrete-ID assertion generator and .ppif surfaces; AXI ID/order evidence and rule matrix; IAL1 output/input direction, storage/update, guard/action expression, assertion, report, and SystemVerilog lowering substrate; support accounting; diagnostics; public JSON surfaces; mdBook; roadmap; and prior residue. It decides whether a first auto-ID lifecycle implementation can extend the existing manager-capacity-status object, should select a narrower request-ID drive or storage prerequisite, requires an IAL1/IAL0/SV prerequisite first, or must be deferred behind another exact owner; records exact public syntax/report expectations, generated .isf/.fsm/HDL impacts, diagnostics, validation gates, residue, rollback, and next implementation owner before behavior changes.`
  Verification: `Read the shipped AXI manager capacity/status, ID-family, transaction-envelope, transaction-event-dispatch, and concrete-ID assertion surfaces; AXI rule/evidence notes; IAL1/IAL0/SystemVerilog output, storage, rule, assertion, and report substrate; public JSON, mdBook, roadmap, and residue. Concluded that the substrate can carry a bounded scalar request-ID lifecycle, but automatic ID allocation must not be inferred directly from width or existing id auto syntax. Selected .21 to define the bounded auto-ID pool/request-ID drive contract before behavior changes.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.20: audit AXI auto-ID readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.21`
  Status: `done`
  Goal: `Select the bounded AXI auto-ID pool and request-ID drive contract.`
  Acceptance: `The selector reads the .20 readiness audit, shipped id_families, transactions, transaction_event_dispatch, and concrete-ID assertion surfaces; AXI rule/evidence notes; public .ppif syntax; report schema; IAL1 output/storage/rule/assertion substrate; mdBook; roadmap; and prior residue. It chooses the exact bounded public contract for auto-ID pools and request-ID drive, including whether existing (id auto) becomes behavior-bearing only with an explicit bounded pool or a new additive opt-in clause is required; records request-ID output direction, response-ID input direction, pool validation, selected-ID and busy/free storage, completion release boundary, no-ID-available behavior, report key/shape, diagnostics, generated .isf/.fsm/HDL impacts, validation gates, rollback, residue, and the next implementation owner before behavior changes.`
  Verification: `Selected an additive optional (auto-id-lifecycle ...) clause under manager-capacity-status with per-family bounded (pool ...) lists. Existing (id auto) remains structural/report-only when the clause is absent. The future behavior contract assigns request ID signals as generated outputs, response ID signals as generated inputs, uses deterministic first-free pool-order allocation, single-active logical transactions, completion-event release, and runtime assertion boundaries. Selected .22 to implement parser/report metadata and static validation first, without generated .isf/.fsm/HDL behavior changes.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.21: select AXI auto-ID pool contract`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.22`
  Status: `done`
  Goal: `Implement the additive AXI auto-id-lifecycle public .ppif parser/report metadata slice.`
  Acceptance: `The public .ppif parser accepts one optional (auto-id-lifecycle ...) clause under manager-capacity-status; validates read/write family names, required unique bounded (pool ...) lists, 1..4 pool-entry cap, positive ID-family widths, values within declared width, id-families/transactions prerequisites, and at least one auto-ID transaction per listed family; rejects unsupported/duplicate/malformed lifecycle clauses with focused diagnostics; the capacity/status generator normalizes and reports structural auto_id_lifecycle metadata with generated_behavior false, request_id_direction generated_output, response_id_direction generated_input, allocator, lifetime, release, no-id behavior, auto transactions, and residue; adds a runnable .ppif sample, focused generator and PPIF/CLI tests, check JSON/semantic JSON support accounting, docs, mdBook, Knowledge Map, and memory sync; generated .isf, .fsm, and HDL behavior remain unchanged.`
  Verification: `Added auto-id-lifecycle parsing to the public PPIF adapter; normalized and reported bounded-pool auto_id_lifecycle metadata in FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus; added ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif and support-accounting entry intent.ppif_axi_manager_capacity_status_auto_id_lifecycle; proved generated .isf/.fsm/HDL behavior remains unchanged against the transaction-event-dispatch sample; added focused generator and PPIF/CLI diagnostics and source-identity coverage; synced docs, mdBook, Knowledge Map, roadmap, and memory.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.22: ship AXI auto-ID lifecycle metadata`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.23`
  Status: `done`
  Goal: `Implement the bounded AXI auto-ID request-ID drive behavior first slice.`
  Acceptance: `The capacity/status generator uses explicit auto_id_lifecycle metadata to generate first-free request-ID drive for listed auto-ID families while preserving existing samples without the clause; request ID signals for listed families become generated IAL1 outputs with the declared ID-family width; generated state tracks selected ID/busy state for bounded pools and single-active auto transactions; no-ID-available is represented by a runtime assertion or fail-closed equivalent selected in the implementation; completion events release the selected ID according to the .21 contract; response ID signals remain generated inputs only when needed by concrete assertions or future response checks; generated .isf, .fsm, SystemVerilog, report JSON, diagnostics, runnable samples, mdBook, Knowledge Map, and memory are synced; same-ID ordering queues, response demux, read-data interleaving/reassembly, bursts, queued/blocking policy, aliases, full-manager syntax, and VHDL remain residue unless explicitly selected by this leaf.`
  Verification: `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus now generates explicit lifecycle request-ID outputs, selected-ID/busy storage, first-free allocation rules, completion release rules, generated priority edges, and runtime assertions for explicit auto-id-lifecycle families; SystemVerilog emits AWID and auto-ID state registers without derived-source warnings; reports set auto_id_lifecycle.generated_behavior true and remove shipped allocation/release residue; focused generator and PPIF/CLI tests, --verify-hdl coverage, docs, mdBook, Knowledge Map, roadmap, and memory were synced.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.23: ship AXI auto-ID request drive`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.24`
  Status: `done`
  Goal: `Select the next IAL2 feature-completeness slice after bounded AXI auto-ID request-ID drive.`
  Acceptance: `The selector reads the shipped Valid-Ready, bundle, capacity/status, ID-family, transaction-envelope, transaction-event-dispatch, concrete-ID assertion, auto-id-lifecycle metadata, and bounded request-ID drive surfaces; AXI rule matrix/evidence notes; IAL1/IAL0/SystemVerilog substrate; support accounting; diagnostics; public JSON surfaces; mdBook; roadmap; and prior residue. It chooses one next exact IAL2 behavior subset or a required IAL1/IAL0/SV prerequisite before behavior changes, records source anchors, public syntax/report expectations, generated .isf/.fsm/HDL boundaries, diagnostics, validation gates, residue, rollback, and next implementation owner.`
  Verification: `Selected AXI manager generated response-demux readiness as the next exact subset after bounded auto-ID request-ID drive; recorded why response-channel BID/RID ownership and completion-event direction must be audited before generated response matching, same-ID ordering, read-data interleaving/reassembly, burst, queued-policy, alias, full-manager, or VHDL behavior changes.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.24: select AXI response demux readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.25`
  Status: `done`
  Goal: `Audit readiness for AXI manager generated response demux after bounded auto-ID request-ID drive.`
  Acceptance: `The audit reads the shipped auto-id-lifecycle request-ID drive behavior, concrete-ID assertion behavior, ID-family metadata, transaction event dispatch, transaction-envelope metadata, AXI ID/order evidence, AXI rule matrix, IAL1/IAL0/SystemVerilog expression/storage/assertion/lowering substrate, support accounting, diagnostics, public JSON surfaces, mdBook, roadmap, and residue. It decides whether generated BID/RID response demux can extend the existing manager-capacity-status object directly, requires a small opt-in public clause first, requires an IAL1/IAL0/SV prerequisite, or must defer behind another exact owner; records source anchors, completion-event ownership, response ID input direction, generated .isf/.fsm/HDL impacts, report key/shape, diagnostics, validation gates, rollback, residue, and the next implementation owner before behavior changes.`
  Verification: `Read the shipped auto-id-lifecycle request-ID drive behavior, concrete-ID assertion behavior, ID-family and transaction-event dispatch substrate, AXI rule/evidence notes, PPIF parser surface, and IAL1/IAL0/SystemVerilog lowering capabilities. Concluded that a bounded write BID demux likely fits the current substrate, but the public contract must first define response handshake event ownership and whether transaction completion names remain external inputs or become generated demux signals. Selected .26 to choose that bounded write response-demux public contract before parser/report or generated behavior changes.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.25: audit AXI response demux readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.26`
  Status: `done`
  Goal: `Select the bounded AXI write response-demux public contract.`
  Acceptance: `The selector reads the .25 readiness audit, shipped auto-id-lifecycle request-ID drive, ID-family and transaction metadata, transaction-event dispatch, concrete-ID assertion report shape, AXI write response ordering evidence, PPIF parser surface, generated IAL1/IAL0/SystemVerilog boundaries, mdBook, roadmap, and residue. It chooses the exact public syntax and report contract for the first generated write BID response-demux slice, including response accepted event naming, response ID input direction, transaction completion ownership, generated demux signal naming, diagnostics, generated .isf/.fsm/HDL boundary, validation gates, rollback, residue, and the next parser/report or implementation owner before behavior changes.`
  Verification: `Selected an explicit optional (response-demux (write (response-event EVENT) (transaction-completion generated))) clause. In the first bounded contract EVENT must equal top-level write-complete, write response demux requires positive-width write id_families, write transactions, and write auto-id-lifecycle metadata, and transaction completion names become generated demux signals only under the opt-in clause. Selected .27 for parser/report metadata and static validation first, with generated .isf/.fsm/HDL behavior unchanged.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.26: select AXI write response demux contract`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.27`
  Status: `done`
  Goal: `Implement the additive AXI write response-demux public .ppif parser/report metadata slice.`
  Acceptance: `The public .ppif parser accepts one optional (response-demux (write (response-event EVENT) (transaction-completion generated))) clause under manager-capacity-status; validates the first-slice write-only family, response-event equality with top-level write-complete, required generated transaction completion ownership, positive-width write id_families, transactions, write auto-id-lifecycle, at least one write auto-ID transaction, and collision-free generated demux/report names; rejects unsupported/duplicate/malformed response-demux clauses with focused diagnostics; the capacity/status generator normalizes and reports structural response_demux metadata with generated_behavior false, response ID input direction, generated transaction completion source, auto transactions, and residue; adds or updates a runnable .ppif sample, focused generator and PPIF/CLI tests, check JSON/semantic JSON support accounting, docs, mdBook, Knowledge Map, and memory sync; generated .isf, .fsm, and HDL behavior remain unchanged.`
  Verification: `FSM::Adapter::IAL2::PPIF now parses optional write-only (response-demux ...) syntax; FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus normalizes and reports response_demux metadata with generated_behavior false; ppif/axi_manager_capacity_status_response_demux.ppif and support-accounting entry intent.ppif_axi_manager_capacity_status_response_demux cover check JSON and semantic JSON; focused generator and PPIF/CLI tests prove generated .isf/.fsm behavior remains unchanged and diagnostics fail closed.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.27: ship AXI response demux metadata`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.28`
  Status: `done`
  Goal: `Audit readiness for generated AXI write response-demux behavior after parser/report metadata.`
  Acceptance: `The audit reads the shipped response_demux parser/report metadata, auto-id-lifecycle request-ID drive behavior, transaction event dispatch and capacity fan-in behavior, concrete ID assertion path, IAL1 guard/action/storage semantics, generated .fsm scheduling behavior, SystemVerilog input/output/assertion lowering, support accounting, diagnostics, mdBook, roadmap, and residue. It decides whether generated write BID demux can be implemented directly, requires a small IAL1/IAL0/SystemVerilog prerequisite, should lower by rewriting completion guards instead of generating intermediate completion signals, or must defer behind another owner; records exact generated .isf/.fsm/HDL boundary, report additions, diagnostics, validation gates, rollback, residue, and next implementation owner before behavior changes.`
  Verification: `Read the shipped response_demux metadata, auto-id-lifecycle selected-ID/busy state and release rules, transaction event fan-in, concrete-ID assertion path, IAL1 rule/action lowering, .fsm delayed-pulse semantics, SystemVerilog assertion path, mdBook, roadmap, and Knowledge Map. Concluded generated write BID demux needs a small IAL1 rule-owned one-cycle pulse action before behavior implementation because ordinary rule actions are sticky flopped assignments and transaction completion signals must be pulse-shaped. Selected .29 as that IAL1 prerequisite owner.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.28: audit AXI response demux behavior`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.29`
  Status: `done`
  Goal: `Implement the minimal IAL1 rule-pulse action prerequisite for generated AXI write response-demux completions.`
  Acceptance: `IAL1 accepts a bounded rule action (pulse TARGET) for scalar generated/event-style pulse targets; the ISF parser validates malformed pulse actions fail closed; the lowerer emits a one-cycle delayed-pulse .fsm assignment using the existing <1 pulse family rather than a sticky flopped rule assignment; rule-pulse actions participate in existing conflict analysis as pulse-domain assignments; focused tests prove parsing, scheduled .fsm, generated HDL reachability, and compatibility with existing rule trigger/priority behavior; docs/ISF spec/mdBook describe the pulse action as an IAL1 prerequisite for generated IAL2 response-demux completion signals; roadmap, task tree, Knowledge Map, and memory stay synced.`
  Verification: `FSM::Adapter::ISF::Parser accepts bounded (pulse TARGET) rule actions, rejects malformed pulse actions and input/non-output/non-storage targets, and preserves the action in the rule shell. FSM::Scheduler::ISF::LoweringIR emits rule_pulse_action assignments as <1 pulse-domain records. Focused tests cover parser shape, scheduled .fsm/HDL reachability, assignment provenance, and compatible pulse fan-in with completion pulses. ISF spec and mdBook document the action as a one-cycle pulse prerequisite for generated response-demux completion outputs.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.29: ship IAL1 rule pulse action`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.30`
  Status: `done`
  Goal: `Implement generated AXI write BID response-demux behavior using IAL1 rule-pulse completions.`
  Acceptance: `For explicit write response-demux contracts, the IAL2 generator adds the write response ID signal as a generated IAL1 input with the declared write ID width; treats transaction completion names as generated demux pulse outputs instead of authored event inputs; emits one guarded IAL1 rule per auto-ID write transaction using response_event && busy && BID == selected_id and (pulse COMPLETION); keeps capacity release and auto-ID release driven by those generated completion pulses; emits unmatched/inactive response assertions; reports generated demux rules/completion signals/assertions and response_demux.generated_behavior true while removing generated_write_bid_demux residue; focused generator/PPIF/CLI tests prove .isf/.fsm/SystemVerilog reachability, diagnostics, report shape, and unchanged out-of-scope read/order/burst/VHDL residue; docs/mdBook/Knowledge Map/memory stay synced.`
  Verification: `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus now emits generated write response ID inputs, generated transaction completion pulse outputs, guarded IAL1 response-demux rules using (pulse COMPLETION), active/unique match assertions, response_demux.generated_behavior true report metadata, generated rule/completion/assertion report lists, and updated residue. Focused generator and PPIF/CLI tests prove .isf/.fsm/SystemVerilog reachability, schedule JSON, --verify-hdl, and unchanged read/order/burst/VHDL residue; docs, mdBook, Knowledge Map, roadmap, and memory were synced.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.30: ship AXI response demux behavior`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.31`
  Status: `done`
  Goal: `Select the next IAL2 feature-completeness slice after generated AXI write BID response-demux behavior.`
  Acceptance: `The selector reads the shipped IAL2 Valid-Ready, bundle, AXI manager capacity/status, ID-family, transaction-envelope, transaction-event-dispatch, concrete-ID assertion, auto-ID lifecycle, request-ID drive, response-demux metadata, IAL1 rule-pulse, and generated write response-demux behavior surfaces; reads current AXI manager residue, reports, diagnostics, generated .isf/.fsm/SystemVerilog artifacts, mdBook, roadmap, and Knowledge Map; chooses one next exact IAL2 behavior subset or prerequisite before any behavior changes; records scope, non-goals, public syntax/report expectations, generated artifact expectations, diagnostics, validation gates, residue, rollback, docs, and VHDL deferral.`
  Verification: `Read shipped response-demux behavior docs, readiness/contract/metadata notes, AXI ID/order evidence, rule matrix, mdBook, roadmap, generator report code, and the response-demux PPIF report. Found response_demux and id_response_rule_engine residues aligned after .30, but auto_id_lifecycle.residue still lists response_demux even though generated demux completions now drive auto-ID release. Selected .32 as the narrow report-contract alignment slice before same-ID ordering, read RID demux, interleaving, bursts, aliases, full-manager, or VHDL work.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.31: select AXI residue alignment`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.32`
  Status: `done`
  Goal: `Align AXI auto-ID lifecycle report residue after generated write BID response-demux behavior.`
  Acceptance: `When explicit response_demux.generated_behavior is true, the capacity/status report removes response_demux from auto_id_lifecycle.residue because generated demux completion pulses now drive auto-ID release; samples without generated response-demux keep existing residue; generated .isf, .fsm, and SystemVerilog HDL text remain unchanged; focused generator and PPIF/CLI tests prove report shape, no generated-artifact drift, and unchanged out-of-scope same-ID ordering, read RID demux, read-data interleaving, bursts, queued/blocking policy, aliases, full-manager, and VHDL residue; docs/mdBook/Knowledge Map/roadmap/memory stay synced.`
  Verification: `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus now removes response_demux from the emitted auto_id_lifecycle.residue only when explicit response_demux.generated_behavior is true. Plain auto-ID lifecycle reports keep response_demux residue. Focused generator and PPIF/CLI tests prove the aligned report shape while generated response-demux .isf/.fsm/SystemVerilog behavior remains covered by the existing .30 checks; docs, mdBook, Knowledge Map, roadmap, and memory were synced.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.32: align AXI auto-ID residue`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.33`
  Status: `done`
  Goal: `Select the next IAL2 feature-completeness slice after auto-ID response-demux residue alignment.`
  Acceptance: `The selector reads the shipped IAL2 Valid-Ready, bundle, AXI manager capacity/status, ID-family, transaction-envelope, transaction-event-dispatch, concrete-ID assertion, auto-ID lifecycle, request-ID drive, write response-demux behavior, and residue-aligned report surfaces; reads current AXI manager residue, generated .isf/.fsm/SystemVerilog artifacts, diagnostics, mdBook, roadmap, and Knowledge Map; chooses one next exact IAL2 behavior subset or prerequisite before any behavior changes; records scope, non-goals, public syntax/report expectations, generated artifact expectations, diagnostics, validation gates, residue, rollback, docs, and VHDL deferral.`
  Verification: `Read the post-.32 response-demux schedule report, AXI ID/order evidence, rule matrix, generated write response-demux behavior note, auto-ID residue alignment note, mdBook, roadmap, and generator report residue. The common remaining ID/auto-ID/write-demux residue is same_id_ordering. Selected .34 as a readiness audit before any same-ID ordering implementation or prerequisite changes.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.33: select AXI same-ID readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.34`
  Status: `done`
  Goal: `Audit AXI same-ID ordering readiness after generated write response demux.`
  Acceptance: `The audit reads AXI same-ID ordering evidence, the rule matrix, shipped auto-ID lifecycle request-ID drive, generated write BID response-demux behavior, residue-aligned reports, IAL1/IAL0/SystemVerilog storage/rule/assertion substrate, diagnostics, mdBook, roadmap, and Knowledge Map; decides whether the first same-ID ordering step should be static/report classification, generated assertions, allocator constraints, per-ID issue-order queues/scoreboards, or a smaller IAL1/IAL0/SystemVerilog prerequisite; records exact scope, non-goals, report/public syntax expectations, generated artifact expectations, diagnostics, validation gates, residue, rollback, docs, and VHDL deferral before behavior changes.`
  Verification: `Read the AXI same-ID ordering evidence, rule matrix, .33 selector, shipped auto-ID request-ID drive behavior, generated write BID response-demux behavior, residue-aligned reports, current response-demux schedule JSON, IAL1 rule/assertion/resource substrate, focused tests, mdBook, roadmap, and Knowledge Map. Concluded no IAL1/IAL0/SystemVerilog prerequisite is needed for the first bounded same-ID step. Selected .35 to formalize generated auto-ID same-ID avoidance with pairwise active-ID assertions and machine-readable same_id_ordering report metadata before per-ID queues or read-side behavior.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.34: audit AXI same-ID readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.35`
  Status: `done`
  Goal: `Implement bounded AXI auto-ID same-ID avoidance assertions and report metadata.`
  Acceptance: `For generated auto-id-lifecycle families, the capacity/status generator emits pairwise runtime assertions proving active auto-ID transaction states do not share the same selected ID; report JSON additively emits machine-readable same_id_ordering metadata with avoid_same_id_concurrency strategy, covered families, generated assertion names, source anchors, and residue; generated auto-ID lifecycle and generated write response-demux report residue remove same_id_ordering only for the covered auto-ID write-demux subset while id_response_rule_engine remains honest for concrete-ID same-ID cases; public .ppif syntax remains unchanged; generated .isf/.fsm/SystemVerilog, focused generator and PPIF/CLI tests, check JSON/semantic JSON gates, mdBook, Knowledge Map, roadmap, task tree, and memory stay synced; per-ID issue-order queues/scoreboards, authored concrete-ID same-ID ordering, read RID demux, read-data interleaving/reassembly, bursts, queued/blocking policy, aliases, full-manager behavior, and VHDL remain residue.`
  Verification: `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus now emits generated same-ID avoidance assertions for generated auto-ID families and reports same_id_ordering metadata with avoid_same_id_concurrency strategy, covered family state, generated assertion names, source anchors, and residue. The response-demux sample reports empty auto_id_lifecycle.residue, response_demux.residue without same_id_ordering, same_id_ordering.generated_behavior true, and id_response_rule_engine.residue still preserving concrete/per-ID same-ID ordering residue. Focused generator and PPIF/CLI tests prove generated .isf/.fsm/SystemVerilog assertion reachability, report shape, and unchanged public .ppif syntax.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.35: ship AXI same-ID avoidance`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.36`
  Status: `done`
  Goal: `Select the next IAL2 feature-completeness slice after bounded auto-ID same-ID avoidance.`
  Acceptance: `The selector reads the shipped same_id_ordering report/assertion surface, current response_demux/id_response_rule_engine/unsupported residue, AXI ID/order evidence, rule matrix, mdBook, roadmap, Knowledge Map, focused tests, and generated response-demux schedule report; chooses one next exact IAL2 behavior subset or prerequisite before any behavior changes; records scope, non-goals, public syntax/report expectations, generated artifact expectations, diagnostics, validation gates, residue, rollback, docs, and VHDL deferral.`
  Verification: `Read the shipped same-ID ordering first slice, generated write response-demux behavior, auto-ID residue alignment, AXI ID/order evidence, rule matrix, mdBook, Knowledge Map, generator/parser surfaces, and the current response-demux schedule report. Selected .37 as a readiness audit for bounded read RID response demux before any read response behavior, read-data interleaving/reassembly, burst/last-beat, per-ID queue, full-manager, or VHDL changes.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.36: select AXI read response demux`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.37`
  Status: `done`
  Goal: `Audit AXI read response-demux readiness after generated same-ID avoidance.`
  Acceptance: `The audit reads shipped write response-demux behavior, same-ID avoidance, read ID-family/transaction/auto-ID lifecycle substrate, AXI read response/interleaving evidence, PPIF parser constraints, IAL1 rule-pulse/assertion/lowering support, SystemVerilog reachability, mdBook, roadmap, and Knowledge Map; decides whether a bounded read RID response-demux implementation can be selected directly, requires parser/report metadata first, needs an IAL1/IAL0/SystemVerilog prerequisite, or must defer behind read-data interleaving/reassembly or burst/last-beat ownership; records exact public syntax/report expectations, generated .isf/.fsm/HDL boundaries, diagnostics, validation gates, residue, rollback, docs, and VHDL deferral before behavior changes.`
  Verification: `Read the shipped write response-demux behavior, generated same-ID avoidance, read ID-family/transaction/auto-ID lifecycle substrate, parser and generator response_demux write-only constraints, IAL1 rule-pulse support, AXI read response/interleaving evidence, current response-demux report, mdBook, roadmap, and Knowledge Map. Selected .38 as a public contract-selection slice for bounded read response demux before parser/report metadata, generated .isf/.fsm/HDL behavior, read-data interleaving/reassembly, burst/last-beat, per-ID queue, full-manager, or VHDL changes.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.37: audit AXI read response demux`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.38`
  Status: `done`
  Goal: `Select the bounded AXI read response-demux public contract.`
  Acceptance: `The selector chooses the exact additive public syntax for a read response-demux arm or records why it must defer; decides whether the first scope is single-beat/non-burst only, whether response-event must equal top-level read-complete, whether response-event means raw accepted R-channel transfer or transaction-level last-beat completion, whether positive-width read id_families/read transactions/read auto_id_lifecycle metadata are required, whether transaction-completion generated reclassifies read completion names as generated pulse outputs only under explicit opt-in, the report key shape, diagnostics, generated artifact boundaries, validation gates, residue, rollback, docs, and VHDL deferral; no parser/generator/HDL behavior changes occur in the selector slice.`
  Verification: `Selected an additive public (response-demux (read (response-event EVENT) (response-scope single-beat) (transaction-completion generated))) arm. In the first bounded contract EVENT must equal top-level read-complete and means one accepted single-beat/non-burst read response transfer; read demux requires positive-width read id_families, read transactions, and read auto_id_lifecycle metadata; transaction completion names become generated read demux pulse outputs only under the explicit opt-in. Selected .39 for parser/report metadata and static validation first, with generated read .isf/.fsm/HDL behavior unchanged.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.38: select AXI read response demux contract`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.39`
  Status: `done`
  Goal: `Implement parser/report metadata for the bounded AXI read response-demux contract.`
  Acceptance: `The public .ppif parser accepts one optional read response-demux arm with required (response-event EVENT), (response-scope single-beat), and (transaction-completion generated) under manager-capacity-status; supports one read arm, one write arm, or both; validates response-event equality with top-level read-complete, required generated transaction completion ownership, positive-width read id_families, transactions, read auto_id_lifecycle, at least one read auto-ID transaction, collision-free generated demux/report names, and focused diagnostics for duplicate/unsupported/malformed clauses; the generator normalizes and reports structural response_demux.read metadata with generated_behavior false, response_scope single_beat, response_event_role raw_accepted_read_response, response ID input direction, generated transaction completion source, auto transactions, and residue; updates runnable sample/support accounting/focused generator and PPIF/CLI tests/check JSON/semantic JSON/docs/mdBook/Knowledge Map/memory; generated read .isf/.fsm/HDL behavior remains unchanged and shipped write demux behavior remains intact.`
  Verification: `FSM::Adapter::IAL2::PPIF now parses read, write, or mixed response-demux family arms and requires read response-event, response-scope single-beat, and transaction-completion generated. FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus normalizes/report response_demux.read metadata with generated_behavior false, response_scope single_beat, raw accepted read-response role, response ID metadata, generated completion ownership, read auto transactions, and generated_read_rid_demux residue while leaving generated read .isf/.fsm/HDL behavior unchanged. Added ppif/axi_manager_capacity_status_read_response_demux.ppif, support-accounting entry intent.ppif_axi_manager_capacity_status_read_response_demux, focused generator and PPIF/CLI coverage including mixed read/write arms, docs, mdBook, Knowledge Map, roadmap, and memory sync.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.39: ship AXI read response demux metadata`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.40`
  Status: `done`
  Goal: `Audit generated AXI read RID response-demux behavior readiness after parser/report metadata.`
  Acceptance: `The audit reads the shipped read response-demux parser/report metadata, generated write BID response-demux behavior, IAL1 rule-pulse support, read auto-ID lifecycle state, read transaction fan-in/capacity release behavior, same-ID avoidance metadata, AXI read response/interleaving evidence, SystemVerilog reachability, focused tests, mdBook, roadmap, and Knowledge Map; decides whether generated read RID demux behavior can be implemented directly, requires an IAL1/IAL0/SystemVerilog prerequisite, must first adjust read completion fan-in/auto-ID release semantics, or must defer behind read-data interleaving/reassembly or burst/last-beat ownership; records exact generated .isf/.fsm/HDL boundary, report additions, diagnostics, validation gates, rollback, residue, docs, and VHDL deferral before behavior changes.`
  Verification: `Read the shipped read response-demux parser/report metadata, generated write BID response-demux behavior, IAL1 rule-pulse support, read auto-ID lifecycle state, read transaction fan-in/capacity release behavior, same-ID avoidance metadata, AXI read response/interleaving evidence, SystemVerilog reachability, focused tests, mdBook, roadmap, and Knowledge Map. Concluded that bounded single-beat generated read RID response-demux behavior can be implemented directly with no new IAL1/IAL0/SystemVerilog prerequisite; selected .41 as the behavior leaf that generalizes response-demux helpers to read/write families and owns the generated read completion fan-in/auto-ID release shift.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.40: audit AXI read response demux behavior`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.41`
  Status: `done`
  Goal: `Implement bounded generated AXI read RID response-demux behavior.`
  Acceptance: `The generator emits single-beat read RID response-demux behavior for explicit read response-demux contracts by adding the read response ID signal as a generated input, reclassifying selected read transaction completion names as generated pulse outputs, excluding those generated completion names from authored event inputs, keeping the raw read response event as the response input, emitting one IAL1 (pulse COMPLETION) demux rule per read auto-ID transaction, emitting read active-match and unique-match assertions, preserving generated write BID demux behavior and mixed read/write contracts, driving read capacity release and auto-ID release from the generated completion pulses, reporting per-family read generated rules/completion signals/assertions and residue alignment, updating runnable sample/support accounting/focused tests/check JSON/semantic JSON/docs/mdBook/Knowledge Map/memory, passing --verify-hdl on the read sample, and keeping read-data interleaving/reassembly, bursts/RLAST, per-ID queues, queued/blocking policy, full-manager behavior, direct backend lowering, and VHDL out of scope.`
  Verification: `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus now treats response-demux behavior as family-aware: explicit read arms add RID as a generated input, selected read completion names become generated pulse outputs rather than authored inputs, read demux rules pulse those completions, read active/unique-match assertions are generated, read capacity and auto-ID release consume generated completion pulses, mixed write/read contracts preserve write BID behavior while adding read RID behavior, and reports list per-family generated rules/completion signals/assertions with response_demux.residue [read_data_interleaving, bursts]. Focused generator and PPIF/CLI tests pass, including read --verify-hdl coverage; broader gate evidence is logged below.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.41: ship AXI read response demux behavior`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.42`
  Status: `done`
  Goal: `Select the next SV-backed IAL2 feature-completeness slice after generated read response-demux behavior.`
  Acceptance: `The selector reads shipped read/write response-demux behavior, generated same-ID avoidance, auto-ID lifecycle residue, transaction/event dispatch surfaces, AXI evidence, focused tests, mdBook, roadmap, and Knowledge Map; chooses the next exact IAL2 feature-completeness slice or prerequisite before any code changes; explicitly decides whether the next owner is read-data interleaving/reassembly, burst/RLAST ownership, per-ID queues, authored concrete-ID same-ID ordering, queued/blocking policy, profile aliases, full-manager behavior, another report/static-validation prerequisite, or a smaller IAL1/IAL0/SystemVerilog substrate slice; records public syntax/report expectations, generated artifact boundaries, diagnostics, validation gates, residue, rollback, docs, Knowledge Map, and VHDL deferral; no parser/generator/HDL behavior changes occur in the selector slice.`
  Verification: `Read post-.41 read and write response-demux schedule JSON, AXI ID/order evidence, the AXI manager rule matrix, same-ID/read response-demux docs, mdBook, roadmap, and Knowledge Map. Selected .43 as a readiness audit for AXI read-data payload, burst/RLAST, and per-ID ordering/reassembly ownership after generated read response demux. No parser, generator, or HDL behavior changed.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.42: select AXI read data readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.43`
  Status: `done`
  Goal: `Audit AXI read-data payload, burst/RLAST, and per-ID ordering/reassembly readiness after generated read response demux.`
  Acceptance: `The audit reads the post-.41 read/write response-demux reports, AXI ID/order/read-data/burst evidence, AXI manager rule matrix, same-ID ordering residue, current PPIF parser/generator surfaces, IAL1/IAL0/SystemVerilog data-path and assertion substrate, mdBook, roadmap, and Knowledge Map; decides whether the next owner should be parser/report metadata only, generated behavior, a public contract selector, per-ID queue/reassembly substrate, burst/last-beat completion semantics, a static fail-closed interleaving capability, or another smaller prerequisite; records exact public syntax/report expectations, generated .isf/.fsm/HDL boundaries, diagnostics, validation gates, rollback, residue, docs, and VHDL deferral before behavior changes.`
  Verification: `Read the shipped read/write response-demux behavior and selector notes, AXI ID/order and rule-matrix evidence, the PPIF parser/generator surfaces, IAL1 width-bearing data/rule substrate, mdBook, roadmap, and Knowledge Map. Concluded no parser/generator/HDL behavior should be implemented directly next; selected .44 to define the bounded public read-data payload/status contract first, likely single-beat and layered on generated read RID demux. Burst/RLAST, different-ID reassembly, per-ID queues, full-manager behavior, direct backend lowering, and VHDL remain residue.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.43: audit AXI read data readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.44`
  Status: `done`
  Goal: `Select the bounded AXI read-data payload public contract.`
  Acceptance: `The selector reads the .43 readiness audit, shipped read/write response-demux behavior, AXI ID/order/read-data/burst evidence, current public PPIF syntax, generator report shape, IAL1/IAL0/SystemVerilog data-path substrate, mdBook, roadmap, and Knowledge Map; chooses the exact additive public syntax/report contract for the first read-data payload/status slice or records why it must defer; decides RDATA/RRESP/RLAST ownership, single-beat versus burst scope, relationship between raw read-complete and generated transaction completions, data destination binding, interleaving/static fail-closed policy, ID-family/auto-lifecycle/read-demux prerequisites, diagnostics, generated artifact boundaries, validation gates, rollback, residue, docs, and VHDL deferral; no parser/generator/HDL behavior changes occur in the selector slice.`
  Verification: `Selected an explicit optional (read-data (read ...)) public contract under manager-capacity-status for bounded single-beat RDATA/RRESP capture. The contract requires capture-scope single-beat, completion-source response-demux, data-signal width, 2-bit status-signal, interleaving single-beat-by-rid, per-read-transaction data/status outputs, and the already-shipped generated read response-demux prerequisite. It excludes RLAST, bursts, multi-beat reassembly, explicit output widths, direct backend lowering, and VHDL. Selected .45 for parser/report metadata and static validation first, with generated .isf/.fsm/HDL behavior unchanged.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.44: select AXI read data contract`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.45`
  Status: `done`
  Goal: `Implement parser/report metadata for the bounded AXI read-data payload contract.`
  Acceptance: `The public .ppif parser accepts one optional read-data clause with a read family arm under manager-capacity-status; validates capture-scope single-beat, completion-source response-demux, data-signal positive width, status-signal width 2, interleaving single-beat-by-rid, transaction data/status output bindings, unique transaction coverage against read response-demux auto transactions, and collision-free names; rejects duplicate/malformed/unsupported read-data clauses, RLAST, burst/multi-beat/reassembly fields, explicit output widths, unsupported interleaving policies, missing generated read response-demux prerequisites, and name collisions with focused diagnostics; the generator normalizes and reports structural read_data metadata with generated_behavior false and generated_read_data_capture residue; adds a runnable sample/support-accounting entry or extends the read-demux sample while proving generated .isf, .fsm, and HDL behavior remains unchanged; syncs check JSON, semantic JSON, docs, mdBook, Knowledge Map, roadmap, and memory.`
  Verification: `FSM::Adapter::IAL2::PPIF now parses the optional (read-data (read ...)) clause with single-beat capture, response-demux completion source, typed RDATA/RRESP input signal records, and per-transaction data/status output bindings. FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus normalizes and reports structural read_data metadata with generated_behavior false, exact coverage against generated read response-demux auto transactions, collision checks, and generated_read_data_capture residue. The checked-in ppif/axi_manager_capacity_status_read_data.ppif sample and support-accounting entry cover schedule JSON, check JSON, semantic JSON, and --verify-hdl while focused tests prove generated .isf/.fsm/HDL behavior remains unchanged from the read response-demux sample.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.45: ship AXI read data metadata`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.46`
  Status: `done`
  Goal: `Audit generated AXI read-data capture behavior readiness after parser/report metadata.`
  Acceptance: `The audit reads the shipped read-data parser/report metadata, checked-in read-data PPIF sample and report, generated read RID response-demux behavior, transaction-event fan-in and generated completion pulses, auto-ID lifecycle release behavior, IAL1/IAL0/SystemVerilog data-path substrate, focused tests, mdBook, roadmap, and Knowledge Map; decides whether generated single-beat RDATA/RRESP capture can be implemented directly or needs a smaller IAL1/IAL0/SystemVerilog prerequisite first; records exact generated IAL1/.fsm/HDL boundaries, data/status input/output width ownership, capture-rule semantics, report updates, diagnostics, validation gates, residue movement, rollback, docs, and VHDL deferral before behavior changes.`
  Verification: `Read the shipped read-data parser/report metadata, schedule JSON for ppif/axi_manager_capacity_status_read_data.ppif, generated read RID response-demux behavior, transaction completion fan-in, auto-ID release behavior, IAL1 width-bearing input/output and rule-assignment docs, generator ISF emission helpers, mdBook, roadmap, and Knowledge Map. Concluded generated single-beat RDATA/RRESP capture can be implemented directly with no new IAL1/IAL0/SystemVerilog prerequisite. Selected .47 to add generated data/status inputs, per-transaction outputs, guarded normal capture assignments, report artifacts, and residue alignment while keeping RLAST, bursts, multi-beat reassembly, full-manager behavior, direct backend lowering, and VHDL deferred.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.46: audit AXI read data capture`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.47`
  Status: `done`
  Goal: `Implement generated single-beat AXI read-data capture behavior.`
  Acceptance: `For explicit read_data contracts with generated read response-demux, the generator adds the declared RDATA/RRESP signals as generated IAL1 inputs with declared widths; adds per-transaction data_output/status_output names as generated IAL1 outputs with inherited data/status widths; emits one guarded IAL1 capture rule per read-data transaction using the generated demux completion signal as guard and normal data/status assignments, not pulse actions; keeps read capacity release and auto-ID release driven by generated completion pulses; reports read_data.generated_behavior true with generated input/output/rule artifacts; removes generated_read_data_capture from read_data residue while retaining rlast_completion, bursts, and multi_beat_read_data_reassembly; focused generator and PPIF/CLI tests prove generated .isf/.fsm/SystemVerilog reachability, width preservation, check JSON/semantic JSON support, --verify-hdl, docs, mdBook, Knowledge Map, memory, and VHDL deferral.`
  Verification: `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus now emits generated read-data source inputs, per-transaction data/status outputs, normal guarded capture rules, generated artifact report lists, and aligned read_data residue for explicit single-beat read-data contracts. Focused generator and PPIF/CLI tests prove .isf/.fsm/SystemVerilog reachability, width preservation, schedule JSON, and --verify-hdl coverage; broader gate evidence is logged below.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.47: ship AXI read data capture`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.48`
  Status: `done`
  Goal: `Select the next SV-backed IAL2 feature-completeness slice after generated AXI read-data capture behavior.`
  Acceptance: `The selector reads the shipped read-data capture behavior, generated read/write response-demux behavior, same-ID ordering metadata, auto-ID lifecycle residue, AXI rule matrix/evidence, focused tests, mdBook, roadmap, and Knowledge Map; chooses one next exact IAL2 behavior subset or prerequisite before any code changes; explicitly decides whether the next owner is RLAST/burst completion, multi-beat read-data reassembly, per-ID queues, authored concrete-ID same-ID ordering, queued/blocking policy, profile aliases, full-manager behavior, another report/static-validation prerequisite, or a smaller IAL1/IAL0/SystemVerilog substrate slice; records public syntax/report expectations, generated artifact boundaries, diagnostics, validation gates, residue, rollback, docs, Knowledge Map, and VHDL deferral.`
  Verification: `Read the shipped read-data capture behavior and live schedule report, generated read/write response-demux behavior, same-ID ordering metadata, auto-ID lifecycle/report residue, AXI rule matrix and ID/order evidence, focused generator and PPIF tests, mdBook, roadmap, task tree, and Knowledge Map. Selected .49 as a readiness audit for AXI burst/RLAST completion semantics before multi-beat read-data reassembly, per-ID queues, authored concrete-ID same-ID ordering, queued/blocking policy, profile aliases, full-manager behavior, direct backend lowering, or VHDL work.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.48: select AXI RLAST readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.49`
  Status: `done`
  Goal: `Audit AXI burst/RLAST completion readiness after generated single-beat read-data capture.`
  Acceptance: `The audit reads the post-read-data selector, shipped read-data capture behavior, read response-demux contract/behavior, read-data contract/metadata/behavior notes, AXI rule matrix and ID/order evidence, current live schedule report, PPIF parser/generator/tests, IAL1/IAL0/SystemVerilog rule/storage/data-path substrate, mdBook, roadmap, and Knowledge Map; decides whether the next owner should be public contract selection, parser/report metadata, generated RLAST/burst behavior, or a smaller IAL1/IAL0/SystemVerilog prerequisite; records source syntax expectations, report/residue movement, generated artifact boundaries, diagnostics, validation gates, rollback, docs, Knowledge Map, and VHDL deferral before any parser/generator/HDL behavior changes.`
  Verification: `Read the post-read-data selector, shipped read-data capture behavior, read response-demux contract/behavior, read-data contract/metadata/behavior notes, AXI rule matrix and ID/order evidence, live schedule JSON for ppif/axi_manager_capacity_status_read_data.ppif, PPIF parser/generator/tests, IAL1 rule/storage/interface substrate, mdBook, roadmap, and Knowledge Map. Concluded no new IAL1/IAL0/SystemVerilog prerequisite is evident for a bounded RLAST implementation, but direct parser/report or HDL behavior is premature because public source syntax has not selected RLAST signal ownership, burst length/beat-count metadata, beat-valid versus transaction-complete semantics, data/status capture granularity, report/residue movement, or fail-closed diagnostics. Selected .50 as the public AXI burst/RLAST completion contract selector.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.49: audit AXI RLAST readiness`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.50`
  Status: `done`
  Goal: `Select the public AXI burst/RLAST completion contract after generated single-beat read-data capture.`
  Acceptance: `The selector reads the .49 RLAST completion readiness audit, shipped read response-demux and read-data contracts/behavior, AXI rule matrix and ID/order evidence, current live schedule report, PPIF parser/generator/tests, IAL1/IAL0/SystemVerilog rule/storage/data-path substrate, mdBook, roadmap, and Knowledge Map; selects exact public source syntax and report semantics for bounded burst/RLAST completion before parser/generator/HDL behavior changes; decides whether the contract extends response-demux, extends read-data, or adds a separate bounded read-completion/burst-completion clause; selects RLAST signal spelling/direction/width, burst length or beat-count ownership, beat-valid versus transaction-complete pulse semantics, data/status capture granularity, report/residue movement, generated artifact boundaries, diagnostics, validation gates, rollback, docs, Knowledge Map, and VHDL deferral; no parser/generator/HDL behavior changes occur in the selector slice.`
  Verification: `Read the .49 RLAST completion readiness audit, shipped read response-demux and read-data contracts/behavior, AXI rule matrix and ID/order evidence, live schedule JSON for ppif/axi_manager_capacity_status_read_data.ppif, PPIF parser/generator fail-closed tests, IAL1/IAL0/SystemVerilog rule/storage/data-path substrate, mdBook, roadmap, and Knowledge Map. Selected an additive read response-demux contract using response-scope burst-last plus a one-bit last-signal. The first boundary uses RLAST as the authoritative last-beat marker, keeps transaction completion as the existing generated completion pulse, publishes no per-transaction beat-valid output, does not select burst length/beat-count/ARLEN ownership, and keeps read-data multi-beat capture/reassembly deferred. Selected .51 as parser/report metadata and static validation with generated .isf/.fsm/HDL behavior unchanged.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.50: select AXI RLAST contract`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.51`
  Status: `done`
  Goal: `Implement parser/report metadata for the bounded AXI RLAST completion contract.`
  Acceptance: `The public .ppif parser accepts response-demux read response-scope burst-last with exactly one last-signal NAME (width 1) clause, keeps single-beat read response-demux behavior and syntax unchanged, rejects last-signal on single-beat, rejects burst-last without a one-bit last-signal, rejects the current single-beat read-data contract when paired with burst-last response-demux, and preserves existing read ID-family/transactions/auto-id-lifecycle prerequisites and collision checks; the generator normalizes and reports structural response_demux.read metadata for burst_last with generated_behavior false, last-signal metadata, transaction_completion_source generated_demux_last_beat, burst_length_source rlast_only, burst_length_validation not_generated, and generated_burst_last_read_demux residue; generated .isf, .fsm, HDL, existing samples, and shipped single-beat read-data behavior remain unchanged; focused PPIF/generator tests, check JSON/semantic JSON support accounting for a new sample, docs/mdBook/Knowledge Map/roadmap/memory, and VHDL deferral stay synced.`
  Verification: `Shipped parser/report metadata and static validation for the additive read response-demux burst-last contract. The PPIF parser accepts response-scope burst-last with exactly one width-1 last-signal, rejects malformed/missing/wrong-width last-signal clauses, rejects last-signal on single-beat, and rejects read-data paired with burst-last response demux. The normalizer reports response_demux.generated_behavior false, response_demux.read.generated_behavior false, response_scope burst_last, last_signal metadata, transaction_completion_source generated_demux_last_beat, transaction_completion_semantics matched_rid_and_last_signal, beat_valid_output none, burst_length_source rlast_only, burst_length_validation not_generated, and generated_burst_last_read_demux residue. Added ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif plus support-accounting/check JSON/semantic JSON coverage. Focused generator and PPIF tests prove generated .isf/.fsm/HDL artifacts remain unchanged from the report-only baseline and single-beat read response-demux/read-data behavior remains guarded. Selected .52 as the generated burst-last/RLAST completion behavior readiness audit.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.51: ship AXI RLAST metadata`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.52`
  Status: `done`
  Goal: `Audit generated AXI burst-last/RLAST completion behavior readiness after parser/report metadata.`
  Acceptance: `The audit reads the .51 metadata slice, runnable burst-last PPIF sample, emitted schedule JSON, generated artifact comparisons, focused PPIF/generator tests, read response-demux behavior implementation, auto-ID lifecycle release behavior, same-ID ordering report behavior, read-data single-beat capture behavior and its burst-last rejection, IAL1/IAL0/SystemVerilog rule/interface/assertion substrate, mdBook, roadmap, and Knowledge Map; decides whether generated burst-last/RLAST completion behavior can be implemented directly or requires a smaller IAL1, IAL0/SystemVerilog, report, or static-validation prerequisite; records expected generated RLAST/RID inputs, generated transaction completion outputs/rules/assertions, capacity/auto-ID release semantics, same-ID/report residue movement, generated artifact boundaries, diagnostics, validation gates, rollback, docs, Knowledge Map, and VHDL deferral; no parser/generator/HDL behavior changes occur in the audit slice.`
  Verification: `Read the .51 metadata slice, checked-in burst-last PPIF sample, schedule JSON, focused generated-artifact comparison tests, generated single-beat read response-demux behavior, auto-ID lifecycle release helpers, same-ID response-demux coverage helpers, read-data capture behavior and burst-last rejection, IAL1/IAL0/SystemVerilog interface/rule/assertion helpers, mdBook, roadmap, and Knowledge Map. Concluded no new IAL1/IAL0/SystemVerilog prerequisite is required: existing generated input/output, pulse-rule, assertion, report-artifact, capacity-release, and auto-ID release plumbing can carry bounded burst-last completion. Selected .53 for direct generated burst-last/RLAST completion behavior, with read-data reassembly, beat-count/ARLEN validation, per-beat outputs, per-ID queues, direct backend lowering, and VHDL deferred.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.52: audit AXI RLAST behavior`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.53`
  Status: `done`
  Goal: `Implement generated AXI burst-last/RLAST completion behavior for explicit response-demux contracts.`
  Acceptance: `For response-demux.read response_scope burst_last, the generator emits generated response-event, RID, and RLAST inputs, reclassifies selected read transaction completion names as generated one-cycle pulse outputs, omits those generated completions from authored event inputs, emits one read response-demux pulse rule per read auto-ID transaction guarded by raw response_event, active transaction state, matching RID, and asserted RLAST, emits read response-demux active-match and unique-match assertions, drives read capacity release and read auto-ID release from those generated last-beat completion pulses, reports generated rules/completion signals/assertions with response_demux.generated_behavior true and response_demux.read.generated_behavior true, removes generated_burst_last_read_demux and response_demux residue where covered, marks read same-ID response_demux_covered true, keeps single-beat read demux behavior and read-data burst-last rejection unchanged, keeps read-data reassembly, beat-count/ARLEN validation, per-beat outputs, per-ID queues, full-manager behavior, direct backend lowering, and VHDL out of scope, updates focused tests, sample report checks, docs/mdBook/Knowledge Map/roadmap/memory, and passes --verify-hdl on the burst-last sample.`
  Verification: `Implemented generated burst-last/RLAST completion behavior. The burst-last sample now emits raw read response-event, RID, and RLAST inputs; generated read transaction completion pulse outputs; RLAST-gated read response-demux rules; active-match and unique-match assertions; auto-ID lifecycle release and read capacity release from generated last-beat completion pulses; response_demux generated artifacts with generated_behavior true; auto-ID lifecycle response_demux residue removal; and read same-ID response_demux_covered true. Single-beat read demux behavior and read-data burst-last rejection remain unchanged. Read-data reassembly, beat-count/ARLEN validation, per-beat outputs, per-ID queues, full-manager behavior, direct backend lowering, and VHDL remain deferred.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.53: ship AXI RLAST behavior`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.54`
  Status: `done`
  Goal: `Select the next exact AXI manager feature-completeness slice after generated RLAST completion behavior.`
  Acceptance: `The selector reads the shipped read/write response-demux behavior, generated read-data capture behavior, generated burst-last/RLAST completion behavior, current live schedule reports, same-ID/order residue, read-data interleaving/reassembly residue, per-ID queue residue, authored concrete-ID same-ID ordering residue, queued/blocking/profile/full-manager residue, focused tests, mdBook, roadmap, task tree, and Knowledge Map; chooses one next exact implementation/audit/contract-selection owner or records why a smaller prerequisite is required; explicitly decides whether the next owner is multi-beat read-data reassembly, per-ID response queues, authored concrete-ID same-ID ordering, queued/blocking policy, profile aliases, full-manager behavior, another report/static-validation prerequisite, direct backend lowering prerequisite, or a smaller IAL1/IAL0/SystemVerilog substrate slice; records generated artifact boundaries, diagnostics, validation gates, rollback, docs, Knowledge Map, and VHDL deferral; no parser/generator/HDL behavior changes occur in the selector slice.`
  Verification: `Read shipped write and read response-demux behavior notes, generated single-beat read-data capture behavior, generated burst-last/RLAST completion behavior, live schedule reports for write demux, read demux, read-data, and burst-last samples, same-ID and auto-ID residues, focused generator and PPIF tests, implementation guards that keep read-data single-beat-only, mdBook, roadmap, task tree, and Knowledge Map. Found that structured burst-last response-demux report fields and generated artifacts are correct, but generated report prose still says burst-last RLAST is report-only and generated burst/last-beat tracking remains outside the shell. Selected .55 as a narrow report/static-text alignment prerequisite before multi-beat read-data reassembly, per-ID queues, authored concrete-ID ordering, queued/blocking policy, profile aliases, full-manager behavior, direct backend lowering, or VHDL.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.54: select AXI RLAST report alignment`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.55`
  Status: `done`
  Goal: `Align AXI manager capacity/status schedule-report prose after generated burst-last/RLAST completion behavior.`
  Acceptance: `The implementation updates generated enforced_static_rules and unsupported_residue prose so reports no longer describe burst-last RLAST response-demux as report-only or generated burst/last-beat tracking as outside the capacity/status shell; reports instead state that explicit burst-last response-demux contracts generate matched-RID-and-RLAST completion behavior while broader burst payload assembly, ARLEN/beat-count validation, per-beat outputs, read-data interleaving/reassembly, per-ID queues, authored concrete-ID same-ID ordering, queued/blocking policy, profile aliases, full-manager behavior, direct backend lowering, and VHDL remain deferred; focused generator and PPIF/CLI tests assert the corrected report strings and absence of stale phrases; generated .isf/.fsm/HDL behavior, public syntax, support accounting, check JSON, and semantic JSON behavior remain unchanged; docs/mdBook/Knowledge Map/roadmap/memory are synced and appropriate report/docs gates pass.`
  Verification: `Updated generated schedule-report prose so enforced_static_rules now says burst-last response-demux generates matched-RID-and-RLAST last-beat completion behavior, and unsupported_residue now lists generated burst-last RLAST response-demux completion as supported while keeping broader burst payload assembly, ARLEN/beat-count validation, per-beat outputs, read-data interleaving/reassembly, per-ID queues, authored concrete-ID same-ID ordering, queued/blocking policy, profile aliases, full-manager behavior, direct backend lowering, and VHDL deferred. Added focused generator and PPIF/CLI assertions for corrected report strings and absence of stale report-only/burst-tracking prose. Generated .isf/.fsm/HDL behavior, public syntax, support accounting, check JSON, and semantic JSON behavior are unchanged. Selected .56 as the next selector for the public contract/readiness step that combines generated RLAST completion with read-data behavior.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.55: align AXI RLAST report text`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.56`
  Status: `done`
  Goal: `Select the next public AXI read-data/burst contract or readiness owner after RLAST report alignment.`
  Acceptance: `The selector reads generated single-beat read-data capture behavior, generated burst-last/RLAST completion behavior, aligned report prose, current read-data and burst-last schedule reports, read-data burst-last rejection diagnostics, same-ID/per-ID/interleaving residues, focused tests, mdBook, roadmap, task tree, and Knowledge Map; decides whether the next exact owner is a public burst read-data contract selector, a readiness audit for multi-beat read-data reassembly, a per-ID response queue prerequisite, authored concrete-ID same-ID ordering, another report/static-validation prerequisite, or a smaller IAL1/IAL0/SystemVerilog substrate slice; records generated artifact boundaries, diagnostics, validation gates, rollback, docs, Knowledge Map, and VHDL deferral; no parser/generator/HDL behavior changes occur in the selector slice.`
  Verification: `Read generated single-beat read-data capture behavior, generated burst-last/RLAST completion behavior, aligned report prose, live read-data and burst-last schedule reports, read-data burst-last rejection diagnostics, same-ID/per-ID/interleaving residues, focused tests, mdBook, roadmap, task tree, and Knowledge Map. Selected .57 as a public burst read-data contract selector because direct behavior would require unselected output shape, capture scope, beat-count/ARLEN or bounded-depth semantics, RRESP aggregation, valid/length metadata, interleaving policy, diagnostics, and report residue movement. No parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changed in this selector slice.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.56: select AXI burst read-data contract`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.57`
  Status: `done`
  Goal: `Select the public AXI burst read-data contract after generated RLAST completion and report alignment.`
  Acceptance: `The selector reads .56, shipped single-beat read-data behavior, shipped burst-last/RLAST completion behavior, current read-data and burst-last reports, read-data burst-last rejection diagnostics, AXI read-data/response/order evidence, focused tests, mdBook, roadmap, task tree, and Knowledge Map; chooses the additive public source/report contract for the first burst read-data metadata or records a smaller prerequisite first; decides capture scope beyond single-beat, completion source under last-beat response demux, data/status/valid/length output binding shape, ARLEN/beat-count or fixed bounded-depth policy, RRESP aggregation, interleaving/per-ID queue policy, diagnostics, report keys/residue movement, validation gates, rollback, docs, Knowledge Map, and VHDL deferral; no parser/generator/HDL behavior changes occur in this selector slice.`
  Verification: `Selected an additive explicit read-data (capture-scope last-beat) contract paired only with generated response_demux.read response_scope burst_last. The contract reuses response-demux last-beat completion pulses as validity strobes, keeps per-transaction data/status output binding with inherited widths, requires status-policy last-beat and interleaving last-beat-by-rid, selects no ARLEN/beat-count/fixed-depth/valid/length/per-beat/packed output, reports RRESP aggregation as none, and leaves full multi-beat reassembly, per-ID queues, ARLEN validation, per-beat outputs, and VHDL deferred. Selected .58 as parser/report metadata and static validation before generated behavior. No parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changed in this selector slice.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.57: select AXI last-beat read data`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.58`
  Status: `done`
  Goal: `Implement parser/report metadata and static validation for AXI last-beat read-data capture.`
  Acceptance: `The public .ppif parser accepts additive read-data (capture-scope last-beat) syntax with completion-source response-demux, data-signal, status-signal width 2, status-policy last-beat, interleaving last-beat-by-rid, and per-transaction data/status outputs; it requires generated read response-demux metadata with response_scope burst_last and exact auto-transaction coverage; reports read_data mode bounded_last_beat_read_data_contract with generated_behavior false, completion_validity generated_read_response_demux_last_beat_completion_pulse, status_aggregation none, burst_length_source rlast_only, no beat storage, no valid/length outputs, and explicit residue; rejects malformed/unsupported burst read-data shapes, single-beat/status-policy misuse, unsupported output/depth/count/aggregation clauses, missing prerequisites, unknown transactions, and name collisions; adds a runnable support-accounted sample or equivalent report path while generated .isf, .fsm, HDL behavior, check JSON semantics, and existing single-beat read-data behavior remain unchanged; docs, mdBook, roadmap, task tree, Knowledge Map, memory, and validation gates are synced.`
  Verification: `Shipped parser/report metadata and static validation for explicit last-beat read-data capture. The public PPIF parser now accepts capture-scope last-beat with status-policy last-beat and interleaving last-beat-by-rid, requires generated burst-last read response-demux prerequisites, reports bounded_last_beat_read_data_contract with generated_behavior false, no beat storage, no valid/length output, and explicit residue, rejects malformed/unsupported shapes, and adds ppif/axi_manager_capacity_status_read_data_last_beat.ppif with strict support accounting. Generated .isf, .fsm, HDL behavior, check JSON semantics, and existing single-beat read-data behavior remain unchanged.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.58: ship AXI last-beat read-data metadata`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.59`
  Status: `done`
  Goal: `Audit readiness for generated AXI last-beat read-data capture behavior.`
  Acceptance: `The audit reads the .58 metadata slice, generated burst-last response-demux behavior, generated single-beat read-data capture behavior, current last-beat sample reports and generated artifacts, IAL1 rule/input/output/storage substrate, IAL0/SystemVerilog lowering behavior, focused tests, support accounting, mdBook, roadmap, task tree, and Knowledge Map; decides whether generated last-beat RDATA/RRESP capture can be implemented directly or requires a smaller prerequisite first; records generated input/output/rule/report/residue boundaries, diagnostics, validation gates, rollback, docs, Knowledge Map, and VHDL deferral; no parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changes occur in this audit slice.`
  Verification: `Read the .58 metadata slice, generated burst-last response-demux behavior, generated single-beat read-data capture behavior, last-beat sample reports, generator helpers for read-data inputs/outputs/capture rules/generated artifacts, focused tests, support accounting, mdBook, roadmap, task tree, and Knowledge Map. Concluded no new IAL1, IAL0/SystemVerilog, static-validation, support-accounting, or report-schema prerequisite is required. Selected .60 to implement generated last-beat RDATA/RRESP capture behavior directly, with full multi-beat reassembly, per-beat outputs, RRESP aggregation, ARLEN/beat-count validation, per-ID queues, direct backend lowering, and VHDL deferred.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.59: audit AXI last-beat read-data capture`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.60`
  Status: `done`
  Goal: `Implement generated AXI last-beat RDATA/RRESP capture behavior.`
  Acceptance: `For explicit read-data capture_scope last-beat contracts paired with generated response_demux.read response_scope burst_last, the generator emits RDATA/RRESP source inputs, per-transaction last-beat data/status outputs with inherited widths, one normal guarded capture rule per read transaction guarded by that transaction's generated burst-last completion pulse, generated .fsm assignments, HDL reachability, and read_data generated artifact report lists; read_data.generated_behavior becomes true for last-beat contracts and generated_last_beat_read_data_capture is removed from read_data.residue; generated burst-last response-demux behavior, generated single-beat read-data behavior, parser/static validation, support accounting, check JSON source identity, semantic JSON source identity, docs, mdBook, roadmap, task tree, Knowledge Map, memory, and validation gates are synced; full multi-beat reassembly, per-beat outputs, RRESP aggregation, ARLEN/beat-count validation, per-ID queues, direct backend lowering, and VHDL remain deferred.`
  Verification: `Shipped generated last-beat RDATA/RRESP capture behavior. The last-beat sample now emits generated RDATA/RRESP inputs, per-transaction last-beat data/status outputs, normal guarded capture rules driven by generated burst-last completion pulses, generated .fsm assignments, HDL reachability, read_data.generated_behavior true, generated read_data artifact report lists, and read_data residue without generated_last_beat_read_data_capture. Generated burst-last response-demux behavior, generated single-beat read-data behavior, parser/static validation, support accounting, check JSON source identity, and semantic JSON source identity remain intact.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.60: ship AXI last-beat read-data capture`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.61`
  Status: `done`
  Goal: `Select the next exact AXI manager feature-completeness owner after generated last-beat read-data capture.`
  Acceptance: `The selector reads shipped generated single-beat and last-beat read-data capture behavior, generated burst-last response-demux behavior, current schedule reports and residue, same-ID/per-ID/interleaving residues, focused tests, support accounting, mdBook, roadmap, task tree, and Knowledge Map; decides whether the next exact owner is full multi-beat read-data reassembly, per-beat outputs, RRESP aggregation, ARLEN/beat-count validation, per-ID response queues, authored concrete-ID same-ID ordering, queued/blocking policy, profile aliases, full-manager behavior, another report/static-validation prerequisite, or a smaller IAL1/IAL0/SystemVerilog substrate slice; records generated artifact boundaries, diagnostics, validation gates, rollback, docs, Knowledge Map, and VHDL deferral; no parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changes occur in this selector slice.`
  Verification: `Read shipped generated single-beat and last-beat read-data capture behavior, generated burst-last response-demux behavior, live single-beat and last-beat reports, read_data/response_demux/same_id_ordering/unsupported residue, mdBook, roadmap, task tree, and Knowledge Map. Selected .62, public AXI burst read-data beat-count/depth contract selection, because full multi-beat reassembly, per-beat outputs, RRESP aggregation, missing/extra beat validation, and per-ID reassembly all depend on an explicit expected-count/depth contract. No parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changed.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.61: select AXI read-data beat-count contract`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.62`
  Status: `done`
  Goal: `Select the public AXI burst read-data beat-count/depth contract.`
  Acceptance: `The selector reads shipped generated single-beat and last-beat read-data capture behavior, generated burst-last response-demux behavior, read_data/response_demux/same_id_ordering residue, AXI burst/read-response evidence, parser constraints, generator report helpers, focused tests, support accounting, mdBook, roadmap, task tree, and Knowledge Map; decides whether public syntax names ARLEN, expected beat count, fixed bounded depth, or a combination; decides report keys for burst length/depth source, validation status, storage/indexing expectations, output-shape scope, status aggregation, diagnostics, generated artifact boundaries, residue movement, rollback, and validation gates; explicitly defers parser/report metadata, generated counter/storage/reassembly behavior, per-beat outputs, RRESP aggregation, per-ID queues, queued/blocking policy, profile aliases, full-manager behavior, direct backend lowering, and VHDL unless selected as follow-up owners; no parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changes occur in this selector slice.`
  Verification: `Selected an additive last-beat read-data burst-length contract using AXI ARLEN as the first beat-count source, width-8 axlen-plus-one encoding, transaction-request capture, required max-beats in range 1..256, and report-only validation. Selected .63, parser/report metadata and static validation for that contract, with generated counters, storage, validation, reassembly, per-beat outputs, RRESP aggregation, per-ID queues, direct backend lowering, and VHDL deferred. No parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changed.`
  Commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.62: select AXI read-data beat-count syntax`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.63`
  Status: `pending`
  Goal: `Implement parser/report metadata and static validation for AXI burst read-data ARLEN beat-count/depth contracts.`
  Acceptance: `The PPIF parser accepts an optional read-data read burst-length clause only for last-beat capture contracts paired with generated burst-last read response demux: source arlen, signal NAME width 8, encoding axlen-plus-one, capture request, required max-beats 1..256, and validation report-only; rejects duplicate/missing/unknown/unsupported burst-length subclauses, unsupported sources, bad widths, invalid bounds, unsupported validation modes, and misuse with single-beat read-data or non-burst-last response demux; reports additive read_data.read burst_length metadata while preserving generated last-beat RDATA/RRESP capture behavior and generated artifacts; keeps generated .isf/.fsm/HDL behavior unchanged except for any explicitly reviewed report-only sample identity; updates support accounting/check JSON/semantic JSON if a sample is added; updates docs, mdBook, roadmap, task tree, Knowledge Map, memory, and validation gates.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-FEATURE-COMPLETENESS-FRONTIER.63` | `pending` | `.62` selected ARLEN-based public burst-length metadata; implement parser/report metadata and static validation before generated counters, storage, reassembly, or validation behavior. |

## Decisions

- `2026-06-12`: Prioritize IAL2 feature completeness on the
  SystemVerilog-backed path before reopening VHDL backend or direct VHDL
  rerouting work.
- `2026-06-12`: IAL2 feature-completeness slices may require new IAL1 and
  IAL0/SV support. Those prerequisites are in scope when explicitly selected
  by a task-tree leaf and must preserve the reviewable lowering chain.
- `2026-06-12`: Selector `.1` audited the shipped IAL2 surface. Shipped:
  `FSM::IAL2::ProtocolIntent::ValidReadyChannel`, public `.ppif` single
  Valid-Ready input, multi-channel `.ppif` Valid-Ready bundles, aggregate IAL2
  report JSON, public check JSON/source identity, aggregate semantic JSON,
  generated `.isf`/`.fsm` review artifacts, and aggregate wrapper/top
  SystemVerilog HDL plus `--verify-hdl` for the tracked AW/W sample.
- `2026-06-12`: Still missing for IAL2 feature completeness: full AXI manager
  behavior, transaction IDs, outstanding read/write windows, same-ID ordering,
  different-ID interleaving, response matching, burst/last-beat tracking,
  cross-channel dependency rules, platform placement/resource mapping,
  additional `.ppif` protocol/platform objects or clauses, and `.pif`/`.ppi`
  or profile alias suffixes such as `.axi`.
- `2026-06-12`: The next exact slice is
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.2`: select the first AXI manager rule
  subset and pre-code contract from
  `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`. Alias suffixes and extra
  `.ppif` syntax are lower priority than the manager rule engine because they
  widen entrypoints without closing the main behavior gap.
- `2026-06-12`: `.2` must not implement behavior. It must select one bounded
  rule family, preserve the mandatory `IAL2 -> IAL1 -> IAL0 -> SystemVerilog`
  chain, identify any required IAL1/IAL0/SV substrate first, and keep Easy
  mode from degenerating into one-transaction-at-a-time behavior unless the
  selected user configuration explicitly has one slot.
- `2026-06-12`: Expected validation gates for a later implementation leaf
  selected by `.2` include focused PPIF/parser diagnostics, generated IAL1 and
  IAL0 review-artifact assertions, report/semantic JSON contract checks,
  focused HDL generation and `--verify-hdl` for the selected subset, mdBook
  runnable examples, Knowledge Map sync, memory-architecture check, and
  doc-path/diff hygiene. The selector itself remains docs-only.
- `2026-06-12`: Rollback boundary for this selector is documentation-only:
  revert the `.1` selector edits, Knowledge Map fact card/map regeneration,
  README, roadmap, and mdBook wording. No code, parser, test, or generated HDL
  behavior is changed by `.1`.
- `2026-06-12`: Selector `.2` chose the first post-Valid-Ready AXI manager
  rule subset: outstanding transaction capacity plus acceptance/status
  feedback. The exact source anchors are `A1.1`, `A1.2`, and `A5.1` from the
  rule-matrix/evidence notes. The subset owns explicit read/write pending
  capacity, `try`-style acceptance feedback, full/pending/slots status, and a
  bounded blocked-reason vocabulary for capacity exhaustion. It does not yet
  own ID allocation, ID validation, same-ID ordering, different-ID
  interleaving, response matching, burst/last-beat tracking, channel expansion,
  or `blocking`/`queued` policy behavior.
- `2026-06-12`: `.2` authored surface expectation: a future `.ppif`
  `(profile axi4)` manager object should require explicit read/write
  `max-pending` depths before claiming multi-slot behavior, should avoid bare
  `can_accept` collisions by emitting namespaced status outputs such as
  `axi0_read_can_accept`, and should fail closed on unsupported policies or
  ambiguous defaults instead of silently collapsing Easy mode to one
  transaction at a time.
- `2026-06-12`: `.2` generated artifact expectation: the future implementation
  must emit a reviewable IAL1 `.isf` manager-capacity shell before IAL0. The
  generated `.isf` should expose abstract read/write submit and completion
  events, generated pending counters, capacity comparators, status outputs,
  and optional capacity-only blocked-reason reporting. The generated IAL0
  `.fsm`/SystemVerilog surface should make those counters and status outputs
  explicit and must not claim full AXI channel, ID, ordering, or response
  behavior.
- `2026-06-12`: `.2` prerequisite expectation: the readiness audit must verify
  whether existing `.ppif` parsing, IAL2 report generation, IAL1 constructs,
  IAL0 emission, and SystemVerilog output can represent generated counters,
  vector/numeric status ports, capacity-only block reasons, and namespaced
  status signals without widening `.isf` with IAL2 source forms. Any missing
  substrate becomes an explicit IAL1 or IAL0/SV prerequisite leaf before the
  manager behavior leaf.
- `2026-06-12`: `.2` selected `.3` as the next leaf: an implementation
  readiness audit for the capacity/status subset. `.3` must not ship behavior;
  it must map code/test/docs/report owners and choose the safe first
  implementation boundary.
- `2026-06-12`: Readiness audit `.3` found no IAL1 or IAL0/SystemVerilog
  prerequisite blocker for the first capacity/status behavior. Existing actor
  storage, status-output, rule/update, scheduled `.fsm`, and SystemVerilog
  paths can carry generated read/write pending counters and namespaced status
  outputs.
- `2026-06-12`: The first capacity/status behavior slice is selected as an
  in-process IAL2 generator first, not public `.ppif` syntax. Public parser,
  CLI, sample, support-accounting, manifest, and source-identity work remains
  a later exact owner after the generated `.isf`/`.fsm`/SystemVerilog shell is
  proven.
- `2026-06-12`: `.4` must implement the in-process capacity/status generator
  with report schema
  `fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`, explicit
  read/write depths, `try` policy, abstract submit/complete events, namespaced
  status outputs, generated review artifacts, focused tests, mdBook sync, and
  fail-closed diagnostics for unsupported policies, IDs, ordering, response
  matching, bursts, channel expansion, and name collisions.
- `2026-06-12`: `.4` shipped
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` as the first
  in-process AXI manager capacity/status generator. The generator accepts a
  structured contract hash, emits generated `.isf` before `.fsm`, lowers
  through existing IAL1/IAL0 to SystemVerilog, reports schema
  `fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`, and keeps
  public `.ppif` syntax, IDs, ordering, response matching, bursts,
  queued/blocking policy, and VHDL as explicit residue.
- `2026-06-12`: `.5` is selected as the next leaf to choose the public
  `.ppif` capacity/status syntax and readiness boundary before parser/CLI
  code, samples, support-accounting, manifest, semantic JSON, or check JSON
  behavior changes.
- `2026-06-12`: `.5` selected the first public capacity/status object syntax:
  one `(manager-capacity-status NAME ...)` clause under
  `(protocol-platform-intent ...)`, `(profile axi4)`, and top-level
  `(source ...)`, with explicit `read-max-pending`, `write-max-pending`,
  `submit-policy try`, abstract submit/complete events, reset/clock, and
  optional namespaced status outputs. The first public parser slice must
  support exactly one manager object and fail closed on mixed Valid-Ready
  objects, multiple managers, IDs, ordering, responses, bursts,
  queued/blocking policy, aliases, and VHDL.
- `2026-06-12`: `.6` shipped the public AXI manager capacity/status `.ppif`
  parser/CLI first slice. `FSM::Adapter::IAL2::PPIF` now accepts exactly one
  selected `(manager-capacity-status ...)` object, maps it to
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`, and the tracked
  sample `ppif/axi_manager_capacity_status.ppif` works through schedule JSON,
  generated `.isf`/`.fsm` review artifacts, default HDL, `--verify-hdl`,
  check JSON, and normalized semantic JSON while preserving public `.ppif`
  source identity.
- `2026-06-12`: `.7` is selected as the next leaf: choose the next AXI manager
  behavior subset or an explicit IAL1/IAL0/SV prerequisite before any further
  behavior changes. IDs, ordering, response matching, bursts, channel
  expansion, queued/blocking policy, and full manager behavior remain residue
  until the selector narrows the next owner.
- `2026-06-12`: `.7` selected AXI manager ID-family declaration and static
  validation as the next subset after capacity/status. The subset owns
  separate read/write ID-family widths, request/response ID signal-pair
  metadata, zero-width absence semantics, static diagnostics, source anchors,
  report metadata, and explicit residue. It does not yet own ID allocation,
  per-transaction user-ID validation, ordering queues, interleaving, `BID`/`RID`
  response matching, bursts, queued/blocking policy, profile aliases, or VHDL.
- `2026-06-12`: `.8` is selected as the next leaf: readiness-audit the
  ID-family/static-validation implementation boundary and decide whether it
  should extend the existing capacity/status object, introduce a broader
  manager object, or require an IAL1/IAL0/SV prerequisite first.
- `2026-06-12`: Readiness audit `.8` selected an additive optional
  `id_families` extension to the existing `manager-capacity-status` object for
  the first implementation. No IAL1, IAL0, or SystemVerilog prerequisite is
  required because the slice is static/report metadata and should not change
  generated `.isf`, generated `.fsm`, or HDL behavior.
- `2026-06-12`: `.9` is selected as the next leaf: implement the additive
  ID-family/static-validation slice with public `(id-families ...)` syntax, a
  separate sample/support-accounting entry, report JSON `id_families`,
  fail-closed diagnostics, unchanged generated artifacts, mdBook, Knowledge
  Map, and focused tests.
- `2026-06-12`: `.9` shipped optional `(id-families ...)` metadata on the
  existing public `manager-capacity-status` object. The generator now accepts
  structured `id_families`; the PPIF parser maps read/write family clauses;
  report JSON additively emits `id_families`; generated `.isf`, generated
  `.fsm`, and HDL behavior are unchanged; check JSON and semantic JSON
  support-account the separate public sample while preserving `.ppif` source
  identity.
- `2026-06-12`: `.10` is selected as the next leaf: choose the next exact
  IAL2 feature-completeness slice or required IAL1/IAL0/SV prerequisite after
  shipped Valid-Ready, bundle, capacity/status, and ID-family metadata.
- `2026-06-12`: `.10` selected AXI manager logical read/write transaction
  envelope and static validation as the next subset. The subset owns
  machine-readable AST/structural transaction names, read/write kind,
  user-visible tags, request/completion event bindings, optional requested-ID
  policy/fit validation against declared ID families, source anchors, report
  metadata, and explicit residue. It does not yet own ID allocation algorithms,
  same-ID ordering queues, different-ID interleaving, `BID`/`RID` response
  matching, bursts, queued/blocking policy, profile aliases, or VHDL.
- `2026-06-12`: `.11` is selected as the next leaf: audit readiness for the
  transaction-envelope/static-validation implementation and decide whether it
  extends `manager-capacity-status`, introduces a broader manager object, or
  requires an IAL1/IAL0/SV prerequisite first.
- `2026-06-12`: Readiness audit `.11` selected an additive optional
  `(transactions ...)` extension under the existing `manager-capacity-status`
  object. No IAL1, IAL0, or SystemVerilog prerequisite is required for the
  first implementation because the selected slice is static/report metadata
  and transaction request/completion bindings must reference the existing
  direction-level abstract events, leaving generated `.isf`, generated
  `.fsm`, and HDL behavior unchanged.
- `2026-06-12`: `.12` is selected as the next leaf: implement the additive
  transaction-envelope/static-validation metadata slice with public
  `(transactions ...)` syntax, a separate sample/support-accounting entry,
  report JSON `transactions`, fail-closed diagnostics, unchanged generated
  artifacts, mdBook, Knowledge Map, and focused tests.
- `2026-06-12`: `.12` shipped optional `(transactions ...)` metadata on the
  existing public `manager-capacity-status` object. The generator now accepts
  structured `transactions`; the PPIF parser maps read/write transaction
  clauses; report JSON additively emits `transactions`; generated `.isf`,
  generated `.fsm`, and HDL behavior are unchanged; check JSON and semantic
  JSON support-account the separate public sample while preserving `.ppif`
  source identity.
- `2026-06-12`: `.13` is selected as the next leaf: choose the next exact
  IAL2 feature-completeness slice or required IAL1/IAL0/SV prerequisite after
  shipped Valid-Ready, bundle, capacity/status, ID-family metadata, and
  transaction-envelope metadata.
- `2026-06-12`: `.13` selected transaction event dispatch and direction
  fan-in as the next prerequisite before ID allocation, ordering, response
  matching, or other dynamic manager behavior. Without per-transaction request
  and completion event provenance, the generated manager cannot honestly know
  which logical transaction requested an ID or completed.
- `2026-06-12`: `.14` is selected as the next leaf: readiness-audit whether
  distinct per-transaction request/completion events can fan into the existing
  read/write capacity/status rule matrices through the current IAL1/IAL0/SV
  path, or whether a prerequisite is required first.
- `2026-06-12`: Readiness audit `.14` selected an additive implementation
  boundary for transaction event dispatch and direction fan-in under the
  existing `manager-capacity-status` object. No separate IAL1, IAL0, or
  SystemVerilog prerequisite is required first for the exact OR fan-in guard
  shape: the PPIF parser already accepts scalar per-transaction events, the
  generator normalizer is the narrow restriction point, and a temporary
  `.isf -> .fsm -> SystemVerilog` probe verified nested `(| ...)` fan-in in
  rule guards.
- `2026-06-12`: `.15` is selected as the next leaf: implement the additive
  dispatch/fan-in slice with unique per-transaction request/completion event
  inputs, scalar one-event compatibility, OR fan-in guards for multi-event
  groups, additive `transaction_event_dispatch` report metadata, a separate
  public `.ppif` sample/support-accounting entry, focused diagnostics, and
  unchanged ID allocation/response/ordering/burst/VHDL residue.
- `2026-06-12`: `.15` shipped AXI manager transaction event dispatch and
  direction fan-in under the existing `manager-capacity-status` object.
  Distinct transaction events now become generated IAL1 inputs, multi-event
  direction groups lower as OR fan-in guards, scalar one-event groups remain
  scalar, reports add `transaction_event_dispatch`, and the IAL1 conflict
  proof now understands the bounded OR/negated-OR guard shape used by the
  generated capacity/status rule matrix.
- `2026-06-12`: `.16` is selected as the next leaf: choose the next exact
  IAL2 feature-completeness slice after shipped transaction event provenance,
  before any ID allocation, response matching, ordering, burst, queued policy,
  alias, full manager, or VHDL behavior changes.
- `2026-06-12`: `.16` selected AXI manager ID/response rule-engine readiness
  as the next exact subset. The shipped event-dispatch slice gives stable
  transaction provenance; the next gap is deciding whether the first
  ID/response behavior can honestly extend the existing capacity/status object
  through current IAL1/IAL0/SystemVerilog substrate, or whether a narrower
  prerequisite is needed first.
- `2026-06-12`: `.17` is selected as the next leaf: readiness-audit the AXI
  manager ID/response rule-engine boundary before any ID allocation, response
  matching, ordering, burst, queued-policy, alias, full-manager, or VHDL
  behavior changes.
- `2026-06-12`: Readiness audit `.17` selected an additive concrete
  transaction ID assertion implementation boundary under the existing
  `manager-capacity-status` object. No separate IAL1, IAL0, or SystemVerilog
  prerequisite is required first for this narrow slice: IAL1 supports
  width-bearing ID inputs, equality/implication assertion expressions,
  assertion-only transactions that emit `.fsm` `+assert` carriers without
  synthetic start/done ports, and the existing SystemVerilog assertion emitter
  path can render the concrete-ID property.
- `2026-06-12`: `.18` is selected as the next leaf: implement concrete
  transaction ID request/response assertions before any auto-ID allocation,
  ID release, response demux, ordering, burst, queued-policy, alias,
  full-manager, or VHDL behavior changes.
- `2026-06-12`: `.18` shipped concrete transaction ID request/response
  assertions under the existing `manager-capacity-status` object. Concrete
  requested IDs now declare used ID-family request/response ID signals as
  generated IAL1 inputs, lower assertion-only checks to `.fsm` `+assert`
  carriers, emit verification-only SystemVerilog assertions, and report
  `id_response_rule_engine` metadata.
- `2026-06-12`: `.19` selected AXI manager auto-ID lifecycle readiness as the
  next exact subset. The next audit must resolve request-ID drive direction,
  ID busy/free state, completion release, diagnostics, report shape, and
  IAL1/IAL0/SystemVerilog substrate readiness before any auto-ID allocation or
  response demux implementation.
- `2026-06-12`: `.20` is selected as the next leaf: readiness-audit AXI
  manager auto-ID lifecycle and request-ID drive before any auto-ID
  allocation, ID release, response demux, ordering, burst, queued-policy,
  alias, full-manager, or VHDL behavior changes.
- `2026-06-12`: `.20` concluded that the current IAL1/IAL0/SystemVerilog
  substrate can carry a bounded scalar request-ID lifecycle, but auto-ID
  allocation must not be inferred directly from ID width or existing `(id
  auto)` syntax. `.21` is selected as the next leaf: choose the bounded
  auto-ID pool/request-ID drive contract before behavior changes.
- `2026-06-12`: `.21` selected explicit optional
  `(auto-id-lifecycle (write (pool ...)) (read (pool ...)))` syntax. Existing
  `(id auto)` remains structural/report-only when the clause is absent. `.22`
  is selected as the next leaf: implement parser/report metadata and static
  validation first, with generated `.isf`, `.fsm`, and HDL behavior unchanged.
- `2026-06-12`: `.22` shipped public `auto-id-lifecycle` parser/report
  metadata and static validation with generated `.isf`, `.fsm`, and HDL
  behavior unchanged. `.23` is selected as the next leaf: implement bounded
  request-ID drive behavior for explicit auto-ID lifecycle families.
- `2026-06-12`: `.23` shipped bounded request-ID drive behavior for explicit
  auto-ID lifecycle families. Generated IAL1 now declares request ID outputs,
  selected-ID/busy state, first-free allocation rules, completion release
  rules, generated priority edges, and runtime assertions; reports mark
  `auto_id_lifecycle.generated_behavior` true and leave same-ID ordering and
  response demux as residue. `.24` is selected as the next leaf: choose the
  next exact IAL2 feature-completeness slice before further behavior changes.
- `2026-06-12`: `.24` selected AXI manager generated response-demux readiness
  as the next exact subset. `.25` must audit response-channel `BID`/`RID`
  ownership, completion-event direction, generated demux completion signals,
  report shape, diagnostics, and IAL1/IAL0/SystemVerilog substrate before
  response matching, same-ID ordering, read-data interleaving/reassembly,
  burst, queued-policy, alias, full-manager, or VHDL behavior changes.
- `2026-06-12`: `.25` concluded that bounded write `BID` demux likely fits the
  current IAL1/IAL0/SystemVerilog substrate after a public contract exists,
  but existing `.ppif` `completion` names are authored inputs and must not be
  silently reinterpreted as generated demux signals. `.26` is selected as the
  next leaf: choose the bounded write response-demux public contract before
  parser/report or generated behavior changes.
- `2026-06-12`: `.26` selected explicit optional
  `(response-demux (write (response-event EVENT) (transaction-completion generated)))`
  syntax. In the first bounded contract, `EVENT` must equal top-level
  `write-complete`, transaction `completion` names become generated demux
  signals only under the opt-in clause, and read `RID` demux remains future
  work. `.27` is selected as the next leaf: implement parser/report metadata
  and static validation first, with generated `.isf`, `.fsm`, and HDL behavior
  unchanged.
- `2026-06-12`: `.27` shipped public `response-demux` parser/report metadata
  and static validation with generated `.isf`, `.fsm`, and HDL behavior
  unchanged. It selected `.28`, now completed, to audit generated write `BID`
  response-demux behavior readiness against the current IAL1/IAL0/SystemVerilog
  lowering semantics before generated demux behavior changes.
- `2026-06-12`: `.28` concluded that generated write `BID` demux should not
  be implemented directly until IAL1 has a rule-owned one-cycle pulse action
  for generated completion signals. Ordinary IAL1 rule actions are sticky
  flopped assignments, while response-demux transaction completion names must
  preserve the existing pulse-shaped completion contract. `.29` is selected as
  the next leaf: implement the minimal IAL1 rule-pulse prerequisite before the
  generated response-demux behavior slice.
- `2026-06-12`: `.29` shipped bounded IAL1 `(pulse TARGET)` rule actions for
  scalar actor outputs and scalar actor storage variables. They lower as `<1`
  delayed pulses with `rule_pulse_action` provenance and participate in
  pulse-domain compatible fan-in. `.30` is selected as the next leaf: implement
  generated AXI write `BID` response-demux behavior using those pulse actions.
- `2026-06-12`: `.30` shipped generated AXI write `BID` response-demux
  behavior through IAL1 rule-pulse completions. Explicit write
  response-demux contracts now generate the response ID input, transaction
  completion pulse outputs, guarded demux rules, active/unique match
  assertions, and `response_demux.generated_behavior: true`. `.31` is
  selected as the next leaf: choose the next exact IAL2 feature-completeness
  slice before any further behavior changes.
- `2026-06-12`: `.31` selected `.32` as the next exact slice after reading the
  post-`.30` report. `response_demux` and `id_response_rule_engine` residue
  are aligned, but `auto_id_lifecycle.residue` still lists `response_demux`
  even though generated demux pulses now drive auto-ID release. `.32` is a
  narrow report-contract cleanup before same-ID ordering, read `RID` demux,
  interleaving, burst, alias, full-manager, or VHDL work.
- `2026-06-12`: `.32` shipped the selected report-contract cleanup.
  Explicit generated write response-demux contracts now remove
  `response_demux` from `auto_id_lifecycle.residue`; non-demux lifecycle
  samples keep that residue. `.33` is selected as the next leaf: choose the
  next exact IAL2 feature-completeness slice before any further behavior
  changes.
- `2026-06-12`: `.33` selected `.34` as the next exact slice. After `.32`,
  `same_id_ordering` is the common remaining residue across
  `auto_id_lifecycle`, `id_response_rule_engine`, and `response_demux`.
  `.34` will audit same-ID ordering readiness before selecting assertions,
  allocator constraints, per-ID queues/scoreboards, or a smaller substrate
  prerequisite.
- `2026-06-12`: `.34` audited same-ID ordering readiness. The first bounded
  implementation should formalize the existing generated auto-ID unique-active
  selected-ID invariant as same-ID ordering by avoidance, using pairwise
  assertions and machine-readable `same_id_ordering` report metadata. Full
  per-ID issue-order queues, authored concrete-ID same-ID ordering, read
  response demux, read-data interleaving, bursts, queued policy, aliases,
  full-manager behavior, and VHDL remain residue.
- `2026-06-12`: `.35` shipped bounded generated auto-ID same-ID avoidance.
  Generated auto-ID families now get pairwise active selected-ID assertions,
  schedule reports add machine-readable `same_id_ordering` metadata, generated
  write demux reports no longer list covered same-ID ordering residue, and
  `.36` is selected as the next exact IAL2 feature-completeness selector.
- `2026-06-12`: `.36` selected `.37` as a readiness audit for bounded read
  `RID` response demux after generated same-ID avoidance. The audit must
  decide whether read response demux can be isolated as single-beat/non-burst
  generated completion pulses, needs parser/report metadata first, requires an
  IAL1/IAL0/SystemVerilog prerequisite, or must defer behind read-data
  interleaving/reassembly or burst ownership. Read-data interleaving, bursts,
  per-ID queues, full-manager behavior, and VHDL remain residue.
- `2026-06-12`: `.37` audited read response-demux readiness and selected
  `.38`, a public contract-selection slice, before parser/report metadata or
  generated behavior. The contract must define the bounded single-beat or
  non-burst scope, read `response-event` semantics, whether top-level
  `read-complete` is the raw accepted response event, required read
  ID-family/transaction/auto-ID lifecycle metadata, generated completion
  ownership, report shape, diagnostics, residue, rollback, and VHDL deferral.
- `2026-06-12`: `.38` selected an explicit read response-demux contract arm
  with `(response-scope single-beat)`. The first read contract treats
  top-level `read-complete` as the raw accepted single-beat read response event
  under the opt-in, requires positive-width read ID-family/read
  transaction/read auto-ID lifecycle metadata, and reclassifies read
  transaction completion names as generated demux pulse outputs only under
  explicit opt-in. `.39` will implement parser/report metadata and static
  validation before generated read behavior.
- `2026-06-12`: `.39` shipped read response-demux parser/report metadata and
  static validation. Public `.ppif` now accepts read, write, or mixed
  `response-demux` arms; the read arm requires `response-event`,
  `response-scope single-beat`, and `transaction-completion generated`; the
  report publishes structural `response_demux.read` metadata with
  `generated_behavior` false, raw accepted read-response role, `RID` metadata,
  generated completion ownership, auto read transactions, and
  `generated_read_rid_demux` residue. Generated read `.isf`, `.fsm`, and HDL
  behavior remains unchanged. `.40` is selected as a readiness audit before
  generated read `RID` response-demux behavior.
- `2026-06-12`: `.40` audited generated read `RID` response-demux behavior
  readiness after the read parser/report metadata slice. It found no new
  IAL1, IAL0, or SystemVerilog prerequisite: the shipped IAL1 `(pulse TARGET)`
  action and the existing write demux path can carry the bounded single-beat
  read demux. `.41` will implement generated read behavior by making
  response-demux helpers family-aware, reclassifying selected read transaction
  completion names as generated pulse outputs under the explicit opt-in, and
  keeping raw top-level `read-complete` as the accepted read-response input.
  Read-data interleaving/reassembly, bursts/`RLAST`, per-ID queues,
  queued/blocking policy, full-manager behavior, direct backend lowering, and
  VHDL remain residue.
- `2026-06-12`: `.41` shipped bounded generated single-beat read `RID`
  response-demux behavior. Explicit read demux arms now add `RID` as a
  generated input, treat selected read transaction completions as generated
  pulse outputs, emit read demux pulse rules and read active/unique-match
  assertions, and keep read capacity plus auto-ID release driven by generated
  completion pulses. `.42` is selected as a no-code selector for the next
  SV-backed IAL2 feature-completeness slice before any further parser,
  generator, or HDL behavior changes.
- `2026-06-12`: `.42` selected `.43` as a readiness audit for AXI read-data
  payload, burst/`RLAST`, and per-ID ordering/reassembly ownership after
  generated read response demux. The selector chose an audit instead of direct
  implementation because read-data payload capture, burst last-beat semantics,
  different-ID interleaving, and same-ID concrete/per-ID queues are
  interdependent and must not be collapsed into a broad full-manager jump.
- `2026-06-12`: `.43` audited read-data payload, burst/`RLAST`, and per-ID
  ordering/reassembly readiness after generated read response demux. It found
  that a bounded single-beat payload/status subset likely fits the existing
  IAL1/IAL0/SystemVerilog data-path substrate, but FSMGen must first select
  the public source syntax, report shape, target binding semantics, and
  interleaving/burst residue policy. `.44` is selected as that public contract
  selector before parser/report metadata or generated behavior changes.
- `2026-06-12`: `.44` selected an explicit optional
  `(read-data (read ...))` public contract under `manager-capacity-status` for
  bounded single-beat `RDATA`/`RRESP` capture. The contract requires
  `capture-scope single-beat`, `completion-source response-demux`, a positive
  `data-signal` width, 2-bit `status-signal`, `interleaving
  single-beat-by-rid`, per-read-transaction generated data/status outputs, and
  the generated read response-demux prerequisite. `.45` is selected to ship
  parser/report metadata and static validation first, with generated `.isf`,
  `.fsm`, and HDL behavior unchanged.
- `2026-06-12`: `.45` shipped read-data parser/report metadata and static
  validation for the bounded single-beat `RDATA`/`RRESP` contract. The public
  `.ppif` parser accepts one structural `read-data` read arm, report JSON
  publishes `read_data.generated_behavior: false` with source signals,
  inherited output widths, transaction-bound output names, and
  `generated_read_data_capture` residue, and generated `.isf`, `.fsm`, and HDL
  behavior remains unchanged from the read response-demux sample. `.46` is
  selected as the generated read-data capture behavior readiness audit.
- `2026-06-12`: `.46` audited generated single-beat read-data capture behavior
  readiness after the parser/report metadata slice. It found no new IAL1,
  IAL0, or SystemVerilog prerequisite: existing width-bearing IAL1
  inputs/outputs and normal guarded rule assignments can hold captured
  payload/status values under the generated read demux completion pulse. `.47`
  is selected to implement generated `RDATA`/`RRESP` capture behavior and
  report `read_data.generated_behavior: true` while keeping `RLAST`, bursts,
  multi-beat reassembly, full-manager behavior, direct backend lowering, and
  VHDL deferred.
- `2026-06-13`: `.47` shipped generated single-beat read-data capture
  behavior. Explicit `read-data` contracts now generate `RDATA`/`RRESP` inputs,
  per-transaction data/status outputs, and normal guarded capture rules under
  generated read-demux completion pulses. `.48` is selected as the next
  selector before RLAST/bursts, multi-beat reassembly, per-ID queues,
  queued/blocking policy, aliases, full-manager behavior, direct backend
  lowering, or VHDL work.
- `2026-06-13`: `.48` selected `.49` as a readiness audit for AXI
  burst/`RLAST` completion semantics after generated single-beat read-data
  capture. The next owner must decide the public last-beat/completion contract
  and any IAL1/IAL0/SystemVerilog prerequisite before multi-beat read-data
  reassembly, per-ID queues, authored concrete-ID same-ID ordering,
  queued/blocking policy, profile aliases, full-manager behavior, direct
  backend lowering, or VHDL work.
- `2026-06-13`: `.49` audited AXI burst/`RLAST` completion readiness after
  generated single-beat read-data capture. It found no evident new
  IAL1/IAL0/SystemVerilog prerequisite for a later bounded implementation, but
  selected `.50` as a public contract selector because source syntax has not
  yet selected `RLAST` signal ownership, beat-count metadata, beat-valid versus
  transaction-complete semantics, data/status capture granularity, diagnostics,
  or report/residue movement.
- `2026-06-13`: `.50` selected the first public `RLAST` completion contract
  as an additive read `response-demux` scope: `response-scope burst-last` plus
  one-bit `last-signal`. It keeps generated transaction completion as the
  last-beat pulse, publishes no generated per-transaction beat-valid output,
  uses `RLAST` rather than `ARLEN`/beat-count metadata for this boundary, and
  leaves multi-beat read-data reassembly for a later exact owner. `.51` owns
  parser/report metadata and static validation before generated behavior.
- `2026-06-13`: `.51` shipped parser/report metadata and static validation
  for the burst-last `RLAST` contract. The first implementation is report-only:
  generated `.isf`, `.fsm`, and HDL behavior remain unchanged, the report marks
  burst-last read demux `generated_behavior: false`, and
  `generated_burst_last_read_demux` remains residue. `.52` owns generated
  burst-last/`RLAST` completion behavior readiness before behavior changes.
- `2026-06-13`: `.52` audited generated burst-last/`RLAST` completion
  readiness and found no new IAL1/IAL0/SystemVerilog prerequisite. `.53` owns
  direct generated behavior: add the generated `RLAST` input, reuse generated
  `RID` matching, pulse transaction completions only on matched last beats,
  move report/residue coverage, and keep read-data reassembly plus beat-count
  validation deferred.
- `2026-06-13`: `.53` shipped generated burst-last/`RLAST` completion
  behavior. Explicit burst-last read response-demux contracts now generate the
  raw response beat input, `RID` input, one-bit `RLAST` input, last-beat
  transaction completion pulse outputs/rules/assertions, auto-ID lifecycle
  and same-ID residue movement, and HDL reachability. `.54` owns the next AXI
  manager feature-completeness selector before more behavior changes.
- `2026-06-13`: `.54` selected `.55`, a narrow report-alignment
  implementation slice. The selector found that structured burst-last
  response-demux report fields and generated artifacts are correct after `.53`,
  but generated report prose still says burst-last `RLAST` is report-only and
  generated burst/last-beat tracking remains outside the capacity/status shell.
  Larger multi-beat read-data reassembly, per-ID queues, full-manager behavior,
  direct backend lowering, and VHDL remain deferred until this report/static
  text prerequisite is resolved.
- `2026-06-13`: `.55` aligned generated report prose after burst-last
  `RLAST` behavior. Reports now state that explicit burst-last response-demux
  contracts generate matched-RID-and-RLAST last-beat completion behavior, and
  list generated burst-last `RLAST` response-demux completion as supported.
  `.56` owns the next selector before any public burst read-data, multi-beat
  reassembly, per-ID queue, or broader manager behavior changes.
- `2026-06-13`: `.56` selected `.57`, public AXI burst read-data contract
  selection. Direct behavior remains premature because the current `read-data`
  contract is single-beat-only, the burst-last sample has no `read_data`
  contract, and the public shape for burst capture scope, output binding,
  beat-count/depth, `RRESP` aggregation, interleaving, diagnostics, and report
  residue movement is not selected yet.
- `2026-06-13`: `.57` selected `.58`, parser/report metadata and static
  validation for explicit last-beat read-data capture. The selected contract
  extends `(read-data (read ...))` with `capture-scope last-beat`,
  `status-policy last-beat`, and `interleaving last-beat-by-rid`, requires
  generated burst-last read response-demux metadata, captures only last-beat
  `RDATA`/`RRESP`, and leaves full multi-beat reassembly, per-beat outputs,
  `RRESP` aggregation, `ARLEN`/beat-count validation, per-ID queues, direct
  backend lowering, and VHDL deferred.
- `2026-06-13`: `.58` shipped parser/report metadata and static validation for
  explicit last-beat read-data capture, kept generated behavior deferred, and
  selected `.59`, generated last-beat read-data capture readiness.
- `2026-06-13`: `.59` found no new IAL1/IAL0/SystemVerilog prerequisite and
  selected `.60`, direct generated last-beat `RDATA`/`RRESP` capture behavior.
- `2026-06-13`: `.60` shipped generated last-beat `RDATA`/`RRESP` capture
  behavior and removed `generated_last_beat_read_data_capture` from
  `read_data.residue`.
- `2026-06-13`: `.61` selected `.62`, public AXI burst read-data
  beat-count/depth contract selection, because full multi-beat reassembly,
  per-beat outputs, `RRESP` aggregation, missing/extra beat validation, and
  per-ID reassembly all depend on an explicit expected-count/depth contract.
- `2026-06-13`: `.62` selected `.63`, parser/report metadata and static
  validation for an ARLEN-based burst-length contract under last-beat
  read-data. The selected contract uses `source arlen`, width-8
  `axlen-plus-one` encoding, transaction-request capture, required
  `max-beats` in range `1..256`, and `validation report-only`; generated
  counters, storage, reassembly, per-beat outputs, `RRESP` aggregation,
  per-ID queues, direct backend lowering, and VHDL remain deferred.
- `2026-06-12`: User clarified the backend strategy: FSMGen is currently Perl
  5, but IAL0/IAL1/IAL2 and the mdBook must remain backend-language-neutral
  contracts for future Rust, Rust/Wasm, browser-capable JavaScript, and
  Dart/web implementations. Decision `0018` records that current Perl module
  names are reference implementation entrypoints, not the portable IAL
  definitions.

## Open Questions

- The broader full-manager object spelling remains open. `.11` selected the
  first transaction-envelope implementation as an additive static/report
  metadata extension under `manager-capacity-status`. Full ID allocation,
  ordering, response matching, bursts, queued/blocking policy, dynamic
  per-transaction behavior, broader `(axi-manager ...)` syntax, and profile
  aliases remain future exact-owner work.

## Blockers

- Not blocked.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.1` | `README.md`; `MEMORY_ARCHITECTURE.md`; `COMMIT.md`; `docs/TASK_TREE.md`; decisions `0003`, `0005`, `0006`, `0007`, `0014`-`0017`; Knowledge Map IAL2/AXI fact cards; `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md`; `docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md`; `perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `bin/fsmgen`; `t/1436-ial2-ppif-parser-cli.t`; `docs/book/src/14-feature-backlog.md`; `ROADMAP_V2.md` | Selected `.2` as the next exact pre-code owner for the first AXI manager rule subset. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.1` | `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; selector fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.2` | `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`; `docs/book/src/13a-actor-interface.md`; `docs/ISF_SPEC.md`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected outstanding-capacity and acceptance/status as the first post-Valid-Ready AXI manager subset and selected `.3` as the readiness-audit frontier. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.2` | `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; selector fact-card reverify `rg`; capacity/status fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.3` | `perl/FSM/Adapter/IAL2/PPIF.pm`; `bin/fsmgen`; `perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm`; `perl/FSM/Adapter/ISF/Parser.pm`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl/FSM/Support/RegressionCorpus.pm`; `perl/FSM/Support/LanguageSurfaceSection.pm`; `t/1232-isf-actor-storage-declarations.t`; `t/1235-isf-fifo-same-cycle-update-matrix.t`; `t/1435-axi-ial2-valid-ready-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/book/src/13a-actor-interface.md`; `docs/book/src/13k-isf-feature-support-matrix.md`; `docs/ISF_SPEC.md`; `docs/book/src/14-feature-backlog.md`; `ROADMAP_V2.md`; `README.md` | Selected an in-process generator as the first capacity/status implementation boundary and advanced the frontier to `.4`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.3` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; readiness fact-card reverify `rg`; capacity/status fact-card reverify `rg`; IAL2 priority fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.4` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1435-axi-ial2-valid-ready-generator.t t/1235-isf-fifo-same-cycle-update-matrix.t t/1232-isf-actor-storage-declarations.t t/1437-axi-ial2-manager-capacity-status-generator.t` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.4` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; capacity/status generator fact-card reverify `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; readiness fact-card reverify `rg`; IAL2 priority fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.5` | `perl/FSM/Adapter/IAL2/PPIF.pm`; `bin/fsmgen`; `perl/FSM/Support/RegressionCorpus.pm`; `perl/FSM/Support/LanguageSurfaceSection.pm`; `perl/FSM/Support/LanguageSurfaceContract.pm`; `perl/FSM/Support/CheckDiagnostics.pm`; `perl/FSM/Support/NormalizedSemanticReport.pm`; `t/1436-ial2-ppif-parser-cli.t`; `t/297-capability-manifest.t`; `t/317-language-surface-contract.t`; `t/301-check-json-supported-corpus.t`; `t/303-normalized-semantic-json-supported-corpus.t`; PPIF docs and samples | Selected public capacity/status PPIF syntax and advanced the frontier to `.6`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.5` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; PPIF syntax fact-card reverify `rg`; generator fact-card reverify `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.6` | `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.6` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; PPIF first-slice fact-card reverify `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; PPIF syntax fact-card reverify `rg`; generator fact-card reverify `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.7` | `KNOWLEDGE_MAP.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`; `docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md`; `docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md`; `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected ID-family declaration/static validation and advanced the frontier to `.8` readiness audit. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.7` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; ID-family fact-card reverify `rg`; IAL2 next-slice fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.8` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/Support/RegressionCorpus.pm`; `perl/FSM/Support/LanguageSurfaceSection.pm`; `perl/FSM/Support/CheckDiagnostics.pm`; `bin/fsmgen`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `t/297-capability-manifest.t`; `t/301-check-json-supported-corpus.t`; `t/303-normalized-semantic-json-supported-corpus.t`; `docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected additive ID-family implementation boundary and advanced the frontier to `.9`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.8` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; ID-family readiness fact-card reverify `rg`; IAL2 next-slice fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.9` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.9` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; ID-family first-slice fact-card reverify `prove`; backend-neutral fact-card reverify `rg`; next-slice/readiness/subset fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.10` | `KNOWLEDGE_MAP.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `t/1436-ial2-ppif-parser-cli.t`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected AXI manager logical transaction-envelope/static validation with a machine-readable AST/structural contract and advanced the frontier to `.11` readiness audit. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.10` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; transaction-envelope fact-card reverify `rg`; next-slice fact-card reverify `rg`; stale-frontier wording search `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.11` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `ppif/axi_manager_capacity_status_id_family.ppif`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected additive transaction-envelope implementation boundary and advanced the frontier to `.12`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.11` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; transaction-envelope readiness fact-card reverify `rg`; next-slice fact-card reverify `rg`; stale-frontier wording search `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.12` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.12` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; transaction-envelope first-slice fact-card reverify `prove`; next-slice/readiness/selection fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.13` | `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected transaction event dispatch and direction fan-in as the next prerequisite and advanced the frontier to `.14` readiness audit. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.13` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; transaction-event-dispatch fact-card reverify `rg`; next-slice fact-card reverify `rg`; stale-frontier wording search `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.14` | `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md`; `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/Adapter/ISF/Parser.pm`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl/FSM/ExpressionNamer.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected an additive dispatch/fan-in implementation boundary and advanced the frontier to `.15`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.14` | Temporary runtime probe with an in-memory `.isf` rule guard `(& (| req0 req1) (! (| done0 done1)) (== pending_q 0))` through `FSM::Adapter::ISF`, `FSM::Scheduler::ISF`, `FSM::Pipeline::SourceFrontend`, and `FSM::HDL::FlattenedDT` | Passed; `.fsm` retained the nested OR fan-in guard and SystemVerilog emitted factored `req0 | req1`, `done0 | done1`, and combined enable wires. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.14` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; transaction-event-dispatch-readiness fact-card reverify `rg`; next-slice fact-card reverify `rg`; transaction-event-dispatch-selection fact-card reverify `rg`; priority fact-card reverify `rg`; stale-frontier wording search `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.15` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl/FSM/Support/RegressionCorpus.pm`; `perl/FSM/Support/LanguageSurfaceSection.pm`; `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Shipped additive transaction event dispatch/fan-in, report metadata, public sample/support accounting, focused diagnostics, and IAL1 bounded OR/negated-OR conflict proof support; advanced the frontier to `.16`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.15` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.15` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; first-slice fact-card reverify `rg`; next-slice fact-card reverify `rg`; readiness fact-card reverify `rg`; selection fact-card reverify `rg`; stale-frontier wording search `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.16` | `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/ISF_SPEC.md`; `docs/book/src/13a-actor-interface.md`; `docs/book/src/13k-isf-feature-support-matrix.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected AXI manager ID/response rule-engine readiness as the next exact subset and advanced the frontier to `.17`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.16` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; ID/response selection fact-card reverify `rg`; next-slice fact-card reverify `rg`; stale-current-frontier wording search `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.17` | `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `docs/book/src/13k-isf-feature-support-matrix.md`; `t/1410-isf-assert-carrier.t`; `t/1411-isf-assert-emit.t`; temporary `.isf -> .fsm` concrete-ID assertion probe; temporary assertion-only transaction probe; temporary `FSMGenFull -> GeneratedModuleInfoBuilder -> GeneratedModuleEmitter` SystemVerilog assertion probe | Selected additive concrete transaction ID request/response assertions as the first ID/response implementation boundary and advanced the frontier to `.18`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.17` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; concrete-ID readiness fact-card reverify `rg`; next-slice fact-card reverify `rg`; stale-current-frontier wording search `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.18` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Support/LanguageSurfaceSection.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md`; `docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Shipped concrete transaction ID request/response assertions with generated ID inputs, `.fsm` `+assert` carriers, SystemVerilog assertion backend coverage, report metadata, diagnostics, docs, and advanced the frontier to `.19`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.18` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.18` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-frontier wording search `rg`; `git_message_brief.txt` size check | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.19` | `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected AXI manager auto-ID lifecycle readiness and advanced the frontier to `.20`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.19` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.20` | `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/Adapter/ISF/Parser.pm`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl/FSM/Backend/GeneratedModuleEmitter.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected bounded auto-ID pool/request-ID drive contract selection as the prerequisite before any auto-ID allocation behavior change and advanced the frontier to `.21`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.20` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search; auto-ID readiness fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.21` | `docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`; `ppif/axi_manager_capacity_status_transaction_envelope.ppif`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md` | Selected explicit optional auto-id-lifecycle syntax with bounded pools and advanced the frontier to `.22`, parser/report metadata and static validation. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.21` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search; auto-ID pool contract fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.22` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/Support/RegressionCorpus.pm`; `ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md` | Shipped public auto-id-lifecycle parser/report metadata, static validation, runnable sample, support accounting, and docs; advanced the frontier to `.23`, bounded request-ID drive behavior. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.22` | `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.23` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial2-axi-manager-auto-id-request-id-drive-first-slice.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Shipped bounded request-ID drive behavior for explicit auto-id-lifecycle families, generated selected-ID/busy state and runtime assertions, removed allocation/release from lifecycle residue, documented the public contract, and advanced the frontier to `.24`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.23` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif`; `prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-frontier wording search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.24` | `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial2-axi-manager-response-demux-selection.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Selected AXI manager generated response-demux readiness as the next exact subset and advanced the frontier to `.25` before response matching, same-ID ordering, read-data interleaving/reassembly, burst, queued-policy, alias, full-manager, or VHDL behavior changes. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.24` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.25` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial2-axi-manager-response-demux-readiness-audit.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Selected bounded write response-demux public contract selection as the next exact prerequisite because existing transaction completion names are authored inputs and must not be silently reinterpreted as generated demux signals. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.25` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.26` | `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial2-axi-manager-write-response-demux-contract-selection.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Selected explicit write-only response-demux syntax, response-event equality with top-level write-complete, generated transaction completion ownership under opt-in, and `.27` parser/report metadata implementation before generated demux behavior changes. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.26` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.27` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/Support/RegressionCorpus.pm`; `perl/FSM/Support/LanguageSurfaceSection.pm`; `ppif/axi_manager_capacity_status_response_demux.ppif`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial2-axi-manager-write-response-demux-metadata-first-slice.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Shipped public response-demux parser/report metadata, static validation, runnable sample, support accounting, focused diagnostics, and unchanged generated .isf/.fsm behavior; advanced the frontier to `.28`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.27` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.27` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_response_demux.ppif`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.28` | `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial2-axi-manager-write-response-demux-behavior-readiness-audit.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Audited generated write BID demux behavior readiness, found the missing IAL1 rule-pulse prerequisite, selected `.29`, and kept generated behavior unchanged. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.28` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.29` | `perl/FSM/Adapter/ISF/Parser.pm`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `t/1181-isf-rule-action-boundary.t`; `t/1168-isf-rule-guard-factoring.t`; `t/1207-isf-assignment-provenance-inventory.t`; `t/1208-isf-compatible-fanin-classification.t`; `docs/ISF_SPEC.md`; `docs/book/src/13g-rules.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial1-rule-pulse-action.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Shipped bounded IAL1 `(pulse TARGET)` rule actions as `<1` pulse-domain assignments with `rule_pulse_action` provenance, documented the public contract, and advanced the frontier to `.30`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.29` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1181-isf-rule-action-boundary.t t/1168-isf-rule-guard-factoring.t t/1171-isf-rule-trigger-fanin.t t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t`; `prove -Iperl t/1209-isf-static-conflict-detection.t t/1214-isf-rejected-conflict-diagnostics.t t/1222-isf-rule-expression-conflict-report.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1376-isf-book-example-lowering-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.30` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Support/LanguageSurfaceSection.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `ppif/axi_manager_capacity_status_response_demux.ppif`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial2-axi-manager-write-response-demux-behavior-first-slice.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Shipped generated write BID response-demux behavior with generated response ID input, generated completion pulse outputs, guarded IAL1 pulse rules, active/unique match assertions, report metadata, and updated residue; advanced the frontier to `.31`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.30` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_response_demux.ppif`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.31` | `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/book/src/14-feature-backlog.md`; `ROADMAP_V2.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `ppif/axi_manager_capacity_status_response_demux.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif`; `docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md` | Selected `.32`, auto-ID lifecycle report-residue alignment after generated write BID response-demux behavior. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.31` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.32` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `ppif/axi_manager_capacity_status_response_demux.ppif`; `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial2-axi-manager-auto-id-residue-alignment-first-slice.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Shipped auto-ID lifecycle report-residue alignment after generated write BID response-demux behavior and advanced the frontier to `.33`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.32` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_response_demux.ppif`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.33` | `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/book/src/14-feature-backlog.md`; `ROADMAP_V2.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Selected `.34`, same-ID ordering readiness after generated write response-demux behavior and report-residue alignment. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.33` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.34` | `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md`; `docs/book/src/13g-rules.md`; `docs/book/src/14-feature-backlog.md`; `ROADMAP_V2.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif`; `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Selected `.35`, bounded auto-ID same-ID avoidance assertions and report metadata before per-ID queues or read-side behavior. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.34` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.35` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `ppif/axi_manager_capacity_status_response_demux.ppif`; `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial2-axi-manager-same-id-ordering-first-slice.md`; `README.md`; `ROADMAP_V2.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Shipped generated auto-ID same-ID avoidance assertions, same_id_ordering report metadata, and residue alignment for the generated write demux sample; advanced the frontier to `.36`. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.35` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_response_demux.ppif`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier and stale-residue searches | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.36` | `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `docs/knowledge/ial2-axi-manager-same-id-ordering-first-slice.md`; `ppif/axi_manager_capacity_status_response_demux.ppif`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Selected `.37`, read response-demux readiness after generated same-ID avoidance. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.36` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search; read response-demux selector fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.37` | `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/knowledge/ial1-rule-pulse-action.md`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1436-ial2-ppif-parser-cli.t`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `ppif/axi_manager_capacity_status_response_demux.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Selected `.38`, bounded read response-demux public contract selection before parser/report metadata or behavior changes. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.37` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; read response-demux readiness fact-card reverify `rg`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.38` | `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `MEMORY.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` | Selected `.39`, parser/report metadata and static validation for the explicit single-beat read response-demux arm. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.38` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; read response-demux contract fact-card reverify `rg`; stale-current-frontier search | Passed; stale `.38` matches are historical advancement notes only. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.39` | `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Support/RegressionCorpus.pm`; `perl/FSM/Support/LanguageSurfaceSection.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `ppif/axi_manager_capacity_status_read_response_demux.ppif`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `MEMORY.md` | Shipped read response-demux parser/report metadata and static validation; selected `.40`, generated read RID response-demux behavior readiness audit. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.39` | `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_response_demux.ppif`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; read response-demux fact-card reverify; stale-current-frontier search | Passed; mixed read/write response-demux arm regressions cover the public parser and generator, and stale `.39` frontier matches are historical advancement notes only. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.40` | `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/book/src/13g-rules.md`; `docs/book/src/14-feature-backlog.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `ppif/axi_manager_capacity_status_read_response_demux.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `MEMORY.md`; Knowledge Map cards | Selected `.41`, bounded generated single-beat read RID response-demux behavior. No new IAL1/IAL0/SystemVerilog prerequisite is required; the implementation leaf owns family-aware demux helpers, generated read completion pulse outputs/rules/assertions, and read capacity/auto-ID release on generated completion pulses. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.40` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; new read response-demux behavior readiness fact-card reverify `rg`; next-slice fact-card reverify `rg`; metadata fact-card reverify `rg`; contract-selection fact-card reverify `rg`; stale-current-frontier search | Passed; stale `.40` matches are historical advancement notes or `.40` owner references, not active-frontier claims. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.41` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `MEMORY.md`; `docs/knowledge/ial2-axi-manager-read-response-demux-behavior-first-slice.md`; `docs/knowledge/ial2-axi-manager-read-response-demux-behavior-readiness-audit.md`; `docs/knowledge/ial2-axi-manager-read-response-demux-metadata-first-slice.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `KNOWLEDGE_MAP.md` | Shipped bounded generated single-beat read RID response-demux behavior; selected `.42`, the next-slice selector after generated read demux. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.41` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_response_demux.ppif`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; behavior first-slice fact-card reverify `rg`; next-slice fact-card reverify `rg`; stale-current-frontier search | Passed; stale `.41` matches are historical owner references or completed-slice notes, not active-frontier claims. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.42` | `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; `docs/knowledge/ial2-axi-manager-post-read-demux-next-slice-selection.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `docs/knowledge/ial2-axi-manager-read-response-demux-behavior-first-slice.md`; `KNOWLEDGE_MAP.md` | Selected `.43`, a readiness audit for read-data payload, burst/RLAST, and per-ID ordering/reassembly ownership after generated read response demux. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.42` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; post-read-demux selector fact-card reverify `rg`; next-slice fact-card reverify `rg`; stale-current-frontier search | Passed; no parser/generator/HDL behavior changed in the selector slice. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.43` | `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/book/src/13a-actor-interface.md`; `docs/book/src/13g-rules.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `ppif/axi_manager_capacity_status_read_response_demux.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.44`, the bounded AXI read-data payload public contract selector, before parser/report metadata or generated behavior changes. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.43` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; read-data readiness fact-card reverify `rg`; next-slice fact-card reverify `rg`; stale-current-frontier search | Passed; no parser/generator/HDL behavior changed in the readiness audit slice. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.44` | `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.45`, parser/report metadata and static validation for the bounded single-beat read-data payload/status contract, with generated behavior unchanged. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.44` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; read-data contract fact-card reverify `rg`; next-slice fact-card reverify `rg`; stale-current-frontier search | Passed; no parser/generator/HDL behavior changed in the selector slice. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.45` | `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Support/RegressionCorpus.pm`; `ppif/axi_manager_capacity_status_read_data.ppif`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `MEMORY.md`; `docs/knowledge/ial2-axi-manager-read-data-metadata-first-slice.md`; `docs/knowledge/ial2-feature-completeness-next-slice.md`; `KNOWLEDGE_MAP.md` | Shipped read-data parser/report metadata and static validation, checked-in runnable sample/support-accounting entry, proved generated .isf/.fsm/HDL behavior remains unchanged from read response-demux, and selected `.46`, generated read-data capture behavior readiness audit. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.45` | `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_data.ppif`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.46` | `docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/book/src/13g-rules.md`; `docs/ISF_SPEC.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.47`, generated single-beat AXI read-data capture behavior. No new IAL1/IAL0/SystemVerilog prerequisite is required; the implementation leaf owns generated RDATA/RRESP inputs, per-transaction outputs, normal guarded capture assignments, report artifacts, and residue alignment. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.46` | `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Passed; stale `.46` active-frontier search returned no matches. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.47` | `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md`; `ppif/axi_manager_capacity_status_read_data.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Shipped generated single-beat AXI read-data capture behavior. Explicit read-data contracts now emit generated `RDATA`/`RRESP` inputs, per-transaction output registers, normal guarded capture rules, report generated input/output/rule artifacts, and narrowed `read_data.residue`; selected `.48`, the next SV-backed IAL2 feature-completeness selector. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.47` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_data.ppif`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale-current-frontier search | Focused syntax, generator, PPIF parser/CLI, generated `.isf`, generated `.fsm`, SystemVerilog reachability, `--verify-hdl`, docs, Knowledge Map, memory, and diff hygiene gates passed. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.48` | `README.md`; `MEMORY_ARCHITECTURE.md`; `MEMORY.md`; `COMMIT.md`; `docs/TASK_TREE.md`; decisions `0003`, `0005`, `0006`, `0007`, `0014`-`0018`; `KNOWLEDGE_MAP.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/book/src/14-feature-backlog.md`; Knowledge Map cards | Selected `.49`, AXI burst/`RLAST` completion readiness after generated single-beat read-data capture. No parser, generator, HDL, sample, support-accounting, or test behavior changed in this selector slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.48` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale `.48` active-frontier search | Passed; no stale active `.48` frontier remains. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.49` | `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_POST_READ_DATA_NEXT_SLICE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.50`, public AXI burst/`RLAST` completion contract selection, before parser/report metadata or generated behavior changes. No parser, generator, HDL, sample, support-accounting, or test behavior changed in this readiness audit slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.50` | `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.51`, parser/report metadata and static validation for `response-scope burst-last` plus one-bit `last-signal`, before generated `RLAST` completion behavior. No parser, generator, HDL, sample, support-accounting, or test behavior changed in this selector slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.51` | `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md`; `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Support/RegressionCorpus.pm`; `docs/REGRESSION_CORPUS.md`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Shipped parser/report metadata and static validation for `response-scope burst-last` plus width-1 `last-signal`, with generated `.isf`, `.fsm`, and HDL behavior unchanged and generated `RLAST` completion behavior deferred to readiness audit `.52`. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.51` | `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `prove -Iperl t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.51` frontier search | Passed. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.52` | `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.53`, direct generated burst-last/`RLAST` completion behavior. No parser, generator, HDL, sample, support-accounting, or test behavior changed in this audit slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.52` | `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.52` frontier search | Passed. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.53` | `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md`; `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Shipped generated burst-last/`RLAST` completion behavior and selected `.54`, the next exact AXI manager feature-completeness selector. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.53` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `prove -Iperl t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.53` frontier search | Passed. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.54` | `docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.55`, narrow AXI `RLAST` report/static-text alignment before larger read-data reassembly or manager behavior work. No parser, generator, HDL, sample, support-accounting, or test behavior changed in this selector slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.54` | `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.54` frontier search | Passed; no parser/generator/HDL behavior changed in the selector slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.55` | `docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Shipped AXI `RLAST` report/static-text alignment and selected `.56`, the next public AXI read-data/burst owner selector. Generated `.isf`, `.fsm`, HDL, public syntax, support accounting, check JSON, and semantic JSON behavior remain unchanged. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.55` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `prove -Iperl t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.55` frontier search; stale generated-report prose search | Passed. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.56` | `docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `ppif/axi_manager_capacity_status_read_data.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.57`, public AXI burst read-data contract selection, before parser/report metadata, generated behavior, per-ID queues, or broader manager work. No parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changed in this selector slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.56` | `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.56` frontier search | Passed; no parser/generator/HDL behavior changed in the selector slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.57` | `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `ppif/axi_manager_capacity_status_read_data.ppif`; live schedule reports; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.58`, parser/report metadata and static validation for explicit last-beat read-data capture. No parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changed in this selector slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.57` | `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.57` frontier search | Passed; no parser/generator/HDL behavior changed in the selector slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.58` | `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md`; `ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl/FSM/Support/RegressionCorpus.pm`; `docs/REGRESSION_CORPUS.md`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Shipped parser/report metadata and static validation for explicit last-beat read-data capture. The public PPIF parser accepts `capture-scope last-beat`, `status-policy last-beat`, and `interleaving last-beat-by-rid` only with generated burst-last read response-demux, reports `bounded_last_beat_read_data_contract` with generated behavior false and explicit residue, adds a support-accounted sample, and keeps generated .isf/.fsm/HDL behavior plus single-beat read-data behavior unchanged; selected `.59`, generated last-beat read-data capture readiness audit. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.58` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen-ial2-58-last-beat.sv ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.58` frontier search | Passed. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.59` | `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Audited generated last-beat read-data capture readiness. Existing read-data input/output/capture-rule/report helpers and generated burst-last response-demux completion pulses are sufficient for a direct generated behavior slice; selected `.60`, generated last-beat `RDATA`/`RRESP` capture behavior, with full multi-beat reassembly, per-beat outputs, `RRESP` aggregation, `ARLEN`/beat-count validation, per-ID queues, direct backend lowering, and VHDL deferred. No parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changed in this audit slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.59` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.59` frontier search | Passed; no parser/generator/HDL behavior changed in the audit slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.60` | `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md`; `ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `t/1437-axi-ial2-manager-capacity-status-generator.t`; `t/1436-ial2-ppif-parser-cli.t`; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Shipped generated last-beat `RDATA`/`RRESP` capture behavior. The last-beat sample now emits generated data/status inputs, per-transaction last-beat data/status outputs, normal guarded capture rules driven by generated burst-last completion pulses, generated `.fsm` assignments, HDL reachability, read_data generated artifact reports, and read_data residue without `generated_last_beat_read_data_capture`; selected `.61`, the next AXI manager feature-completeness selector. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.60` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `jq '{read_data: .read_data, response_scope: .response_demux.read.response_scope}' /tmp/fsmgen-ial2-60-last-beat-report.json`; `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen-ial2-60-last-beat.sv ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.60` frontier search | Passed; report inspection confirmed `read_data.generated_behavior: true`, generated `RDATA`/`RRESP` inputs, generated per-transaction last-beat data/status outputs, generated capture rules, `response_scope: burst_last`, and residue without `generated_last_beat_read_data_capture`. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.61` | `docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md`; `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md`; `ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `ppif/axi_manager_capacity_status_read_data.ppif`; live schedule reports; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.62`, public AXI burst read-data beat-count/depth contract selection, before full multi-beat reassembly, per-beat outputs, `RRESP` aggregation, missing/extra beat validation, per-ID queues, full-manager behavior, direct backend lowering, or VHDL work. No parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changed in this selector slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.61` | `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `jq` report-residue inspections for `/tmp/fsmgen-ial2-61-last-beat-report.json` and `/tmp/fsmgen-ial2-61-single-beat-report.json`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.61` frontier search | Passed; live reports confirmed generated last-beat capture with `burst_length_source: rlast_only`, no beat storage, no length/valid output, read-data residue `[multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation, arlen_or_beat_count_validation]`, response-demux residue `[read_data_interleaving, bursts]`, and same-ID residue `[concrete_id_same_id_ordering, per_id_issue_order_queues, read_data_interleaving, bursts]`. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.62` | `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md`; `docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`; `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md`; `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `ppif/axi_manager_capacity_status_read_data.ppif`; live schedule reports; `README.md`; `ROADMAP_V2.md`; `docs/TASK_TREE.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/book/src/14-feature-backlog.md`; `MEMORY.md`; Knowledge Map cards | Selected `.63`, parser/report metadata and static validation for an additive last-beat read-data `burst-length` clause using AXI `ARLEN`, width-8 `axlen-plus-one` encoding, transaction-request capture, required `max-beats`, and report-only validation. No parser, generator, HDL, sample, support-accounting, check JSON, semantic JSON, or validation behavior changed in this selector slice. |
| `2026-06-13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.62` | `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`; `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif`; `jq` report-residue inspections for `/tmp/fsmgen-ial2-62-last-beat-report.json` and `/tmp/fsmgen-ial2-62-single-beat-report.json`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; stale active `.62` frontier search | Passed; live reports remain behavior-identical with last-beat `burst_length_source: rlast_only`, `burst_length_validation: not_generated`, `beat_storage: none`, read-data residue `[multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation, arlen_or_beat_count_validation]`, response-demux residue `[read_data_interleaving, bursts]`, and same-ID residue `[concrete_id_same_id_ordering, per_id_issue_order_queues, read_data_interleaving, bursts]`. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.1` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.1: select next IAL2 slice` | Audited shipped IAL2 surface and moved the frontier to first AXI manager rule-subset selection. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.2` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.2: select AXI manager capacity slice` | Selected the first post-Valid-Ready AXI manager subset and advanced the frontier to `.3` readiness audit. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.3` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.3: audit AXI manager capacity readiness` | Audited implementation readiness and advanced the frontier to `.4`, the in-process generator slice. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.4` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.4: ship AXI manager capacity generator` | Shipped the in-process capacity/status generator, focused tests, docs, mdBook sync, and advanced the frontier to `.5`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.5` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.5: select AXI capacity PPIF syntax` | Selected the public capacity/status `.ppif` syntax/readiness boundary and advanced the frontier to `.6`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.6` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.6: ship AXI capacity PPIF parser` | Shipped the public capacity/status `.ppif` parser/CLI sample, support-accounting entry, source-identity checks, docs, mdBook sync, and advanced the frontier to `.7`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.7` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.7: select AXI ID family slice` | Selected the ID-family/static-validation subset and advanced the frontier to `.8`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.8` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.8: audit AXI ID family readiness` | Selected the additive implementation boundary and advanced the frontier to `.9`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.9` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.9: ship AXI ID family metadata` | Shipped optional `(id-families ...)` metadata for the public capacity/status object and advanced the frontier to `.10`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.10` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.10: select AXI transaction envelope slice` | Selected logical read/write transaction-envelope/static validation and advanced the frontier to `.11`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.11` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.11: audit AXI transaction envelope readiness` | Selected the additive implementation boundary and advanced the frontier to `.12`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.12: ship AXI transaction metadata` | Shipped optional `(transactions ...)` metadata for the public capacity/status object and advanced the frontier to `.13`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.13` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.13: select AXI transaction event dispatch` | Selected transaction event dispatch and direction fan-in and advanced the frontier to `.14`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.14` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.14: audit AXI transaction dispatch readiness` | Selected the additive implementation boundary and advanced the frontier to `.15`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.15` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.15: ship AXI transaction event dispatch` | Shipped additive transaction event dispatch/fan-in and advanced the frontier to `.16`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.16` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.16: select AXI ID response readiness` | Selected AXI manager ID/response rule-engine readiness and advanced the frontier to `.17`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.17` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.17: audit AXI ID response readiness` | Selected additive concrete transaction ID assertions and advanced the frontier to `.18`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.18` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.18: ship AXI concrete ID assertions` | Shipped concrete transaction ID request/response assertions and advanced the frontier to `.19`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.19` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.19: select AXI auto-ID lifecycle` | Selected auto-ID lifecycle/request-ID drive readiness and advanced the frontier to `.20`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.20` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.20: audit AXI auto-ID readiness` | Selected bounded auto-ID pool/request-ID drive contract selection and advanced the frontier to `.21`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.21` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.21: select AXI auto-ID pool contract` | Selected explicit auto-id-lifecycle bounded-pool syntax and advanced the frontier to `.22`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.22` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.22: ship AXI auto-ID lifecycle metadata` | Shipped public auto-id-lifecycle parser/report metadata and advanced the frontier to `.23`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.23` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.23: ship AXI auto-ID request drive` | Shipped bounded request-ID drive behavior for explicit auto-id-lifecycle families and advanced the frontier to `.24`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.24` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.24: select AXI response demux readiness` | Selected generated response-demux readiness and advanced the frontier to `.25`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.25` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.25: audit AXI response demux readiness` | Selected bounded write response-demux public contract selection and advanced the frontier to `.26`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.26` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.26: select AXI write response demux contract` | Selected explicit write response-demux syntax and advanced the frontier to `.27`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.27` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.27: ship AXI response demux metadata` | Shipped public response-demux parser/report metadata and advanced the frontier to `.28`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.28` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.28: audit AXI response demux behavior` | Selected the minimal IAL1 rule-pulse prerequisite and advanced the frontier to `.29`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.29` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.29: ship IAL1 rule pulse action` | Shipped bounded IAL1 rule-owned pulse actions and advanced the frontier to `.30`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.30` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.30: ship AXI response demux behavior` | Shipped generated AXI write BID response-demux behavior and advanced the frontier to `.31`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.31` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.31: select AXI residue alignment` | Selected auto-ID lifecycle report-residue alignment and advanced the frontier to `.32`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.32` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.32: align AXI auto-ID residue` | Shipped auto-ID lifecycle report-residue alignment and advanced the frontier to `.33`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.33` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.33: select AXI same-ID readiness` | Selected same-ID ordering readiness and advanced the frontier to `.34`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.34` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.34: audit AXI same-ID readiness` | Selected bounded auto-ID same-ID avoidance assertions/report metadata and advanced the frontier to `.35`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.35` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.35: ship AXI same-ID avoidance` | Shipped generated auto-ID same-ID avoidance assertions/report metadata and advanced the frontier to `.36`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.36` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.36: select AXI read response demux` | Selected read response-demux readiness and advanced the frontier to `.37`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.37` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.37: audit AXI read response demux` | Selected bounded read response-demux public contract selection and advanced the frontier to `.38`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.38` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.38: select AXI read response demux contract` | Selected explicit `response-scope single-beat` read response-demux syntax and advanced the frontier to `.39`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.39` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.39: ship AXI read response demux metadata` | Shipped read response-demux parser/report metadata and advanced the frontier to `.40`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.40` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.40: audit AXI read response demux behavior` | Selected bounded generated read RID response-demux behavior and advanced the frontier to `.41`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.41` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.41: ship AXI read response demux behavior` | Shipped bounded generated read RID response-demux behavior and advanced the frontier to `.42`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.42` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.42: select AXI read data readiness` | Selected read-data payload, burst/RLAST, and per-ID readiness and advanced the frontier to `.43`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.43` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.43: audit AXI read data readiness` | Selected bounded AXI read-data payload public contract selection and advanced the frontier to `.44`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.44` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.44: select AXI read data contract` | Selected parser/report metadata and static validation for bounded single-beat read-data payload/status and advanced the frontier to `.45`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.45` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.45: ship AXI read data metadata` | Shipped read-data parser/report metadata and static validation and advanced the frontier to `.46`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.46` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.46: audit AXI read data capture` | Audited generated read-data capture readiness and advanced the frontier to `.47`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.47` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.47: ship AXI read data capture` | Shipped generated single-beat `RDATA`/`RRESP` capture behavior and advanced the frontier to `.48`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.48` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.48: select AXI RLAST readiness` | Selected burst/`RLAST` completion readiness and advanced the frontier to `.49`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.49` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.49: audit AXI RLAST readiness` | Audited burst/`RLAST` readiness and advanced the frontier to `.50`, public contract selection. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.50` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.50: select AXI RLAST contract` | Selected additive `response-scope burst-last` plus `last-signal` syntax and advanced the frontier to `.51`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.51` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.51: ship AXI RLAST metadata` | Shipped parser/report metadata and static validation for burst-last `RLAST` response-demux and advanced the frontier to `.52`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.52` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.52: audit AXI RLAST behavior` | Audited generated burst-last/`RLAST` completion readiness and advanced the frontier to `.53`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.53` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.53: ship AXI RLAST behavior` | Shipped generated burst-last/`RLAST` completion behavior and advanced the frontier to `.54`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.54` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.54: select AXI RLAST report alignment` | Selected narrow report/static-text alignment after generated `RLAST` behavior and advanced the frontier to `.55`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.55` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.55: align AXI RLAST report text` | Aligned generated report prose after generated `RLAST` behavior and advanced the frontier to `.56`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.56` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.56: select AXI burst read-data contract` | Selected public AXI burst read-data contract selection and advanced the frontier to `.57`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.57` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.57: select AXI last-beat read data` | Selected explicit last-beat read-data parser/report metadata and advanced the frontier to `.58`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.58` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.58: ship AXI last-beat read-data metadata` | Shipped parser/report metadata and static validation for explicit last-beat read-data capture and advanced the frontier to `.59`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.59` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.59: audit AXI last-beat read-data capture` | Audited generated last-beat read-data capture readiness and advanced the frontier to `.60`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.60` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.60: ship AXI last-beat read-data capture` | Shipped generated last-beat `RDATA`/`RRESP` capture behavior and advanced the frontier to `.61`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.61` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.61: select AXI read-data beat-count contract` | Selected public AXI burst read-data beat-count/depth contract selection and advanced the frontier to `.62`. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.62` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.62: select AXI read-data beat-count syntax` | Selected ARLEN-based burst-length parser/report metadata and static validation and advanced the frontier to `.63`. |

## Changelog

- `2026-06-12`: Created active IAL2 feature-completeness frontier.
- `2026-06-12`: Completed `.1` selector and advanced frontier to `.2`, the
  first AXI manager rule-subset selection/pre-code contract.
- `2026-06-12`: Completed `.2` selector, chose AXI manager
  outstanding-capacity and acceptance/status as the first post-Valid-Ready
  manager subset, and advanced the frontier to `.3` readiness audit before
  implementation changes.
- `2026-06-12`: Completed `.3` readiness audit, selected an in-process
  capacity/status generator as the first behavior-bearing implementation
  boundary, and advanced the frontier to `.4`.
- `2026-06-12`: Completed `.4` in-process generator slice and advanced the
  frontier to `.5`, public `.ppif` capacity/status syntax/readiness
  selection.
- `2026-06-12`: Completed `.5` public `.ppif` syntax/readiness selector and
  advanced the frontier to `.6`, the parser/CLI first implementation slice.
- `2026-06-12`: Completed `.6` public `.ppif` capacity/status parser/CLI
  implementation and advanced the frontier to `.7`, the next AXI manager
  behavior-subset selector.
- `2026-06-12`: Completed `.7` next-subset selector, chose AXI ID-family
  declaration/static validation, and advanced the frontier to `.8` readiness
  audit.
- `2026-06-12`: Completed `.8` readiness audit, selected an additive
  capacity/status ID-family implementation boundary, and advanced the frontier
  to `.9`.
- `2026-06-12`: Completed `.9` implementation, shipped optional
  `(id-families ...)` public metadata for the capacity/status object, and
  advanced the frontier to `.10`, the next IAL2 feature-completeness selector.
- `2026-06-12`: Completed `.10` selector, chose AXI manager logical
  read/write transaction-envelope/static validation, and advanced the frontier
  to `.11` readiness audit before implementation changes.
- `2026-06-12`: Completed `.11` readiness audit, selected an additive
  capacity/status transaction-envelope implementation boundary, and advanced
  the frontier to `.12`.
- `2026-06-12`: Completed `.12` implementation, shipped optional
  `(transactions ...)` public metadata for the capacity/status object, and
  advanced the frontier to `.13`, the next IAL2 feature-completeness selector.
- `2026-06-12`: Completed `.13` selector, chose AXI manager transaction event
  dispatch and direction fan-in, and advanced the frontier to `.14` readiness
  audit before implementation changes.
- `2026-06-12`: Completed `.14` readiness audit, selected an additive
  transaction event dispatch/direction fan-in implementation boundary with no
  separate IAL1/IAL0/SystemVerilog prerequisite first, and advanced the
  frontier to `.15`.
- `2026-06-12`: Completed `.15` implementation, shipped transaction event
  dispatch/direction fan-in for the public capacity/status object, added
  bounded IAL1 OR/negated-OR guard conflict proof support, and advanced the
  frontier to `.16`, the next IAL2 feature-completeness selector.
- `2026-06-12`: Completed `.16` selector, chose AXI manager ID/response
  rule-engine readiness as the next exact subset, and advanced the frontier to
  `.17` readiness audit before behavior changes.
- `2026-06-12`: Completed `.17` readiness audit, selected additive concrete
  transaction ID assertions as the first ID/response implementation boundary,
  and advanced the frontier to `.18`.
- `2026-06-12`: Completed `.18` implementation, shipped concrete transaction
  ID request/response assertions for the public capacity/status object, and
  advanced the frontier to `.19`, the next IAL2 feature-completeness selector.
- `2026-06-12`: Completed `.19` selector, chose AXI manager auto-ID lifecycle
  readiness, and advanced the frontier to `.20` readiness audit before
  implementation changes.
- `2026-06-12`: Completed `.20` readiness audit, concluded that auto-ID
  allocation needs a bounded public pool/request-ID drive contract first, and
  advanced the frontier to `.21` contract selection before behavior changes.
- `2026-06-12`: Completed `.21` contract selector, chose explicit
  `(auto-id-lifecycle ...)` bounded-pool syntax, and advanced the frontier to
  `.22` parser/report metadata implementation before generated request-ID
  drive behavior changes.
- `2026-06-12`: Completed `.22` implementation, shipped public
  `auto-id-lifecycle` parser/report metadata and static validation without
  generated `.isf`/`.fsm`/HDL behavior changes, and advanced the frontier to
  `.23`, bounded request-ID drive behavior.
- `2026-06-12`: Completed `.23` implementation, shipped bounded auto-ID
  request-ID drive behavior for explicit lifecycle families, and advanced the
  frontier to `.24`, the next IAL2 feature-completeness selector.
- `2026-06-12`: Completed `.24` selector, chose AXI manager generated
  response-demux readiness as the next exact subset, and advanced the frontier
  to `.25` readiness audit before response matching, ordering,
  interleaving/reassembly, burst, queued-policy, alias, full-manager, or VHDL
  behavior changes.
- `2026-06-12`: Completed `.25` readiness audit, selected bounded write
  response-demux public contract selection as the next exact prerequisite, and
  advanced the frontier to `.26` before parser/report or generated behavior
  changes.
- `2026-06-12`: Completed `.26` contract selector, chose explicit write-only
  `response-demux` syntax, and advanced the frontier to `.27` parser/report
  metadata implementation before generated demux behavior changes.
- `2026-06-12`: Completed `.27` implementation, shipped public
  `response-demux` parser/report metadata and static validation without
  generated `.isf`/`.fsm`/HDL behavior changes, and advanced the frontier to
  `.28`, generated write response-demux behavior readiness.
- `2026-06-12`: Completed `.28` readiness audit, selected a minimal IAL1
  rule-owned one-cycle pulse action as the prerequisite for generated
  response-demux completion outputs, and advanced the frontier to `.29`.
- `2026-06-12`: Completed `.29` implementation, shipped bounded IAL1
  `(pulse TARGET)` rule actions through `<1` pulse-domain lowering, and
  advanced the frontier to `.30`, generated AXI write `BID` response-demux
  behavior.
- `2026-06-12`: Completed `.30` implementation, shipped generated AXI write
  `BID` response-demux behavior through IAL1 rule-pulse completions, and
  advanced the frontier to `.31`, the next IAL2 feature-completeness selector.
- `2026-06-12`: Completed `.31` selector, chose auto-ID lifecycle
  report-residue alignment after generated write `BID` response demux, and
  advanced the frontier to `.32`.
- `2026-06-12`: Completed `.32` implementation, aligned
  `auto_id_lifecycle.residue` for generated write `BID` response demux, and
  advanced the frontier to `.33`, the next IAL2 feature-completeness selector.
- `2026-06-12`: Completed `.33` selector, chose AXI same-ID ordering
  readiness as the next exact slice, and advanced the frontier to `.34`.
- `2026-06-12`: Completed `.34` readiness audit, selected bounded auto-ID
  same-ID avoidance assertions/report metadata, and advanced the frontier to
  `.35`.
- `2026-06-12`: Completed `.35` implementation, shipped generated auto-ID
  same-ID avoidance assertions/report metadata, and advanced the frontier to
  `.36`, the next IAL2 feature-completeness selector.
- `2026-06-12`: Completed `.36` selector, chose read response-demux readiness
  after generated auto-ID same-ID avoidance, and advanced the frontier to
  `.37`.
- `2026-06-12`: Completed `.37` readiness audit, selected bounded read
  response-demux public contract selection before parser/report metadata or
  generated behavior, and advanced the frontier to `.38`.
- `2026-06-12`: Completed `.38` contract selector, chose explicit
  `(response-scope single-beat)` read response-demux syntax, and advanced the
  frontier to `.39`, parser/report metadata and static validation before
  generated read behavior.
- `2026-06-12`: Completed `.39` implementation, shipped read response-demux
  parser/report metadata and static validation without generated read behavior,
  and advanced the frontier to `.40`, generated read `RID` response-demux
  behavior readiness audit.
- `2026-06-12`: Completed `.40` readiness audit, concluded bounded generated
  single-beat read `RID` response-demux behavior can be implemented directly,
  and advanced the frontier to `.41`, the generated read behavior
  implementation slice.
- `2026-06-12`: Completed `.41` implementation, shipped bounded generated
  single-beat read `RID` response-demux behavior, and advanced the frontier to
  `.42`, the selector for the next SV-backed IAL2 feature-completeness slice.
- `2026-06-12`: Completed `.42` selector, chose read-data payload,
  burst/`RLAST`, and per-ID readiness after generated read demux, and advanced
  the frontier to `.43`, the readiness audit.
- `2026-06-12`: Completed `.43` readiness audit, concluded the public
  read-data payload/status contract must be selected before parser/report or
  generated behavior changes, and advanced the frontier to `.44`.
- `2026-06-12`: Completed `.44` selector, chose explicit bounded
  `(read-data (read ...))` syntax for single-beat `RDATA`/`RRESP` capture, and
  advanced the frontier to `.45`, parser/report metadata and static validation
  before generated data-capture behavior.
- `2026-06-12`: Completed `.45` implementation, shipped read-data
  parser/report metadata and static validation with generated behavior still
  unchanged, and advanced the frontier to `.46`, generated read-data capture
  behavior readiness audit.
- `2026-06-12`: Completed `.46` readiness audit, selected direct generated
  single-beat read-data capture behavior with no new IAL1/IAL0/SystemVerilog
  prerequisite, and advanced the frontier to `.47`.
- `2026-06-13`: Completed `.47` implementation, shipped generated
  single-beat read-data capture behavior, and advanced the frontier to `.48`,
  the selector for the next SV-backed IAL2 feature-completeness slice.
- `2026-06-13`: Completed `.48` selector, chose AXI burst/`RLAST` completion
  readiness as the next exact prerequisite after generated single-beat
  read-data capture, and advanced the frontier to `.49`.
- `2026-06-13`: Completed `.49` readiness audit, selected public AXI
  burst/`RLAST` completion contract selection before parser/report metadata or
  generated behavior changes, and advanced the frontier to `.50`.
- `2026-06-13`: Completed `.50` selector, chose additive read
  `response-demux` syntax for `response-scope burst-last` with one-bit
  `last-signal`, and advanced the frontier to `.51`, parser/report metadata
  and static validation.
- `2026-06-13`: Completed `.51` implementation, shipped report-only
  burst-last `RLAST` response-demux metadata and static validation, and
  advanced the frontier to `.52`, generated burst-last/`RLAST` completion
  behavior readiness.
- `2026-06-13`: Completed `.52` readiness audit, selected direct generated
  burst-last/`RLAST` completion behavior, and advanced the frontier to `.53`.
- `2026-06-13`: Completed `.53` implementation, shipped generated
  burst-last/`RLAST` completion behavior, and advanced the frontier to `.54`,
  the selector for the next AXI manager feature-completeness slice.
- `2026-06-13`: Completed `.54` selector, selected AXI `RLAST`
  report/static-text alignment, and advanced the frontier to `.55`.
- `2026-06-13`: Completed `.55` implementation, aligned generated AXI
  `RLAST` report prose with shipped behavior, and advanced the frontier to
  `.56`, the next public read-data/burst owner selector.
- `2026-06-13`: Completed `.56` selector, selected public AXI burst read-data
  contract selection, and advanced the frontier to `.57`.
- `2026-06-13`: Completed `.57` selector, selected explicit last-beat
  read-data parser/report metadata, and advanced the frontier to `.58`.
- `2026-06-13`: Completed `.58` implementation, shipped parser/report
  metadata and static validation for explicit last-beat read-data capture, and
  advanced the frontier to `.59`, generated last-beat read-data capture
  readiness.
- `2026-06-13`: Completed `.59` readiness audit, selected direct generated
  last-beat read-data capture behavior, and advanced the frontier to `.60`.
- `2026-06-13`: Completed `.60` implementation, shipped generated last-beat
  `RDATA`/`RRESP` capture behavior, and advanced the frontier to `.61`, the
  next AXI manager feature-completeness selector.
- `2026-06-13`: Completed `.61` selector, selected public AXI burst read-data
  beat-count/depth contract selection, and advanced the frontier to `.62`.
- `2026-06-13`: Completed `.62` selector, selected ARLEN-based burst-length
  parser/report metadata and static validation, and advanced the frontier to
  `.63`.
