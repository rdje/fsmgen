# IAL2-FEATURE-COMPLETENESS-FRONTIER: IAL2 Feature Completeness Frontier

## Metadata

- Tree ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER`
- Status: `active`
- Roadmap lane: `IAL2 / SV-backed feature completeness`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
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
  Children: `IAL2-FEATURE-COMPLETENESS-FRONTIER.1, IAL2-FEATURE-COMPLETENESS-FRONTIER.2, IAL2-FEATURE-COMPLETENESS-FRONTIER.3, IAL2-FEATURE-COMPLETENESS-FRONTIER.4, IAL2-FEATURE-COMPLETENESS-FRONTIER.5, IAL2-FEATURE-COMPLETENESS-FRONTIER.6, IAL2-FEATURE-COMPLETENESS-FRONTIER.7, IAL2-FEATURE-COMPLETENESS-FRONTIER.8, IAL2-FEATURE-COMPLETENESS-FRONTIER.9, IAL2-FEATURE-COMPLETENESS-FRONTIER.10, IAL2-FEATURE-COMPLETENESS-FRONTIER.11, IAL2-FEATURE-COMPLETENESS-FRONTIER.12, IAL2-FEATURE-COMPLETENESS-FRONTIER.13, IAL2-FEATURE-COMPLETENESS-FRONTIER.14, IAL2-FEATURE-COMPLETENESS-FRONTIER.15, IAL2-FEATURE-COMPLETENESS-FRONTIER.16, IAL2-FEATURE-COMPLETENESS-FRONTIER.17, IAL2-FEATURE-COMPLETENESS-FRONTIER.18, IAL2-FEATURE-COMPLETENESS-FRONTIER.19, IAL2-FEATURE-COMPLETENESS-FRONTIER.20, IAL2-FEATURE-COMPLETENESS-FRONTIER.21`

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
  Status: `pending`
  Goal: `Select the bounded AXI auto-ID pool and request-ID drive contract.`
  Acceptance: `The selector reads the .20 readiness audit, shipped id_families, transactions, transaction_event_dispatch, and concrete-ID assertion surfaces; AXI rule/evidence notes; public .ppif syntax; report schema; IAL1 output/storage/rule/assertion substrate; mdBook; roadmap; and prior residue. It chooses the exact bounded public contract for auto-ID pools and request-ID drive, including whether existing (id auto) becomes behavior-bearing only with an explicit bounded pool or a new additive opt-in clause is required; records request-ID output direction, response-ID input direction, pool validation, selected-ID and busy/free storage, completion release boundary, no-ID-available behavior, report key/shape, diagnostics, generated .isf/.fsm/HDL impacts, validation gates, rollback, residue, and the next implementation owner before behavior changes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-FEATURE-COMPLETENESS-FRONTIER.21` | `pending` | `.20` concluded auto-ID lifecycle needs a bounded public pool/request-ID drive contract before any request-ID output, allocation, release, or response-demux behavior changes. |

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
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.21` | `pending` | `pending` |

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
