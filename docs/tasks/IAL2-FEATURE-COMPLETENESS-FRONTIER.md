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
  Children: `IAL2-FEATURE-COMPLETENESS-FRONTIER.1, IAL2-FEATURE-COMPLETENESS-FRONTIER.2, IAL2-FEATURE-COMPLETENESS-FRONTIER.3, IAL2-FEATURE-COMPLETENESS-FRONTIER.4, IAL2-FEATURE-COMPLETENESS-FRONTIER.5, IAL2-FEATURE-COMPLETENESS-FRONTIER.6, IAL2-FEATURE-COMPLETENESS-FRONTIER.7, IAL2-FEATURE-COMPLETENESS-FRONTIER.8`

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
  Status: `pending`
  Goal: `Audit readiness for the AXI manager ID-family/static-validation implementation slice.`
  Acceptance: `The audit reads the shipped capacity/status generator, PPIF parser, public sample, support-accounting corpus, report/check/semantic JSON surfaces, IAL1/IAL0/SystemVerilog paths, identifier/name-collision helpers, mdBook, and focused tests; decides whether the selected ID-family subset should be implemented as an additive capacity/status extension, a new manager object, or a prerequisite IAL1/IAL0/SV substrate slice; records exact implementation boundary, public syntax, report schema/versioning, diagnostics, validation gates, docs, residue, and rollback before behavior changes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-FEATURE-COMPLETENESS-FRONTIER.8` | `pending` | `.7` selected ID-family declaration and static validation; the next safe step is a readiness audit before parser/generator behavior changes. |

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

## Open Questions

- The exact implementation boundary for ID-family/static-validation remains
  open until `.8`: additive capacity/status extension, broader manager object,
  or prerequisite IAL1/IAL0/SV substrate.

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
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.8` | `pending` | `pending` |

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
