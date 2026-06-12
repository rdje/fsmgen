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
  Children: `IAL2-FEATURE-COMPLETENESS-FRONTIER.1, IAL2-FEATURE-COMPLETENESS-FRONTIER.2, IAL2-FEATURE-COMPLETENESS-FRONTIER.3`

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
  Commit: `pending`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.3`
  Status: `pending`
  Goal: `Audit readiness for the AXI manager capacity/status implementation slice.`
  Acceptance: `The audit reads the PPIF parser/generator, IAL2 Valid-Ready generator, IAL1 parser/lowerer/report emitters, IAL0/HDL emission surfaces, public contract metadata, and focused tests; decides whether the selected capacity/status subset can be implemented by existing IAL1 constructs or needs new IAL1/IAL0/SV prerequisites first; records exact implementation boundary, tests, report schema, mdBook updates, blockers, residue, and rollback before behavior changes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-FEATURE-COMPLETENESS-FRONTIER.3` | `pending` | `.2` selected outstanding-capacity and acceptance/status as the first post-Valid-Ready AXI manager rule subset; the next safe step is a readiness audit before implementation changes. |

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

## Open Questions

- `IAL2-FEATURE-COMPLETENESS-FRONTIER.3` must decide whether the first
  capacity/status implementation can be a public `.ppif` object immediately or
  whether an in-process generator/readiness slice must come first.
- `.3` must decide whether capacity-only blocked-reason reporting should be
  an HDL output, report-only metadata, or both for the first behavior-bearing
  slice.
- `.3` must decide whether abstract completion events are sufficient for the
  first manager-capacity shell, or whether the implementation must first own a
  narrower read-only or write-only capacity path.

## Blockers

- Not blocked.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.1` | `README.md`; `MEMORY_ARCHITECTURE.md`; `COMMIT.md`; `docs/TASK_TREE.md`; decisions `0003`, `0005`, `0006`, `0007`, `0014`-`0017`; Knowledge Map IAL2/AXI fact cards; `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`; `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; `docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md`; `docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md`; `perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm`; `perl/FSM/Adapter/IAL2/PPIF.pm`; `bin/fsmgen`; `t/1436-ial2-ppif-parser-cli.t`; `docs/book/src/14-feature-backlog.md`; `ROADMAP_V2.md` | Selected `.2` as the next exact pre-code owner for the first AXI manager rule subset. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.1` | `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; selector fact-card reverify `rg` | Passed. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.2` | `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`; `docs/book/src/13a-actor-interface.md`; `docs/ISF_SPEC.md`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `docs/book/src/14-feature-backlog.md`; `README.md`; `ROADMAP_V2.md` | Selected outstanding-capacity and acceptance/status as the first post-Valid-Ready AXI manager subset and selected `.3` as the readiness-audit frontier. |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.2` | `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; selector fact-card reverify `rg`; capacity/status fact-card reverify `rg` | Passed. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.1` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.1: select next IAL2 slice` | Audited shipped IAL2 surface and moved the frontier to first AXI manager rule-subset selection. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.2` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.2: select AXI manager capacity slice` | Selected the first post-Valid-Ready AXI manager subset and advanced the frontier to `.3` readiness audit. |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.3` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created active IAL2 feature-completeness frontier.
- `2026-06-12`: Completed `.1` selector and advanced frontier to `.2`, the
  first AXI manager rule-subset selection/pre-code contract.
- `2026-06-12`: Completed `.2` selector, chose AXI manager
  outstanding-capacity and acceptance/status as the first post-Valid-Ready
  manager subset, and advanced the frontier to `.3` readiness audit before
  implementation changes.
