# ISF-REMAINING-BROAD-FRONTIER: Remaining Broad ISF Frontier

## Metadata

- Tree ID: `ISF-REMAINING-BROAD-FRONTIER`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-06-05`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Own the broad ISF/R14 backlog items named in the 2026-06-05 remaining-work
inventory that are not already the active frontier of a narrower ISF tree.

## Non-Goals

- Do not supersede existing active ISF trees for their current frontier leaves.
- Do not implement ISF behavior before the exact leaf is selected and placed in
  the current frontier.
- Do not widen downstream-visible syntax, diagnostics, report keys, generated
  artifacts, or public contracts without activating a concrete leaf.

## Acceptance Criteria

- Each broad ISF backlog item has a leaf-level owner.
- When selected, the tree activates one executable leaf at a time.
- ISF public sync rules in `docs/TASK_TREE.md` apply to every activated leaf.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REMAINING-BROAD-FRONTIER`
  Status: `active`
  Goal: `Track broad remaining ISF/R14 backlog directions.`
  Children: `ISF-REMAINING-BROAD-FRONTIER.1`,
    `ISF-REMAINING-BROAD-FRONTIER.2`,
    `ISF-REMAINING-BROAD-FRONTIER.3`,
    `ISF-REMAINING-BROAD-FRONTIER.4`,
    `ISF-REMAINING-BROAD-FRONTIER.5`,
    `ISF-REMAINING-BROAD-FRONTIER.6`,
    `ISF-REMAINING-BROAD-FRONTIER.7`,
    `ISF-REMAINING-BROAD-FRONTIER.8`,
    `ISF-REMAINING-BROAD-FRONTIER.9`,
    `ISF-REMAINING-BROAD-FRONTIER.10`,
    `ISF-REMAINING-BROAD-FRONTIER.11`,
    `ISF-REMAINING-BROAD-FRONTIER.12`

- ID: `ISF-REMAINING-BROAD-FRONTIER.1`
  Status: `done`
  Goal: `Select the next executable broad ISF leaf from active evidence and backlog text.`
  Acceptance: `Activated this broad R14 tree after the previous active ISF frontier exhausted; selected the stage/wait/loop category and split its first exact executable leaf as ISF-REMAINING-BROAD-FRONTIER.7.1.`
  Verification: `Selection only: read docs/TASK_TREE.md, this task file, dynamic-wait backlog text, existing dynamic-wait task files, loop-control docs/tests, and LoweringIR loop_exit_when linking. No code/source behavior changed.`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.2`
  Status: `done`
  Goal: `Broaden ATL actor-network orchestration beyond the shipped bounded v0 contract.`
  Children: `ISF-REMAINING-BROAD-FRONTIER.2.1`
  Acceptance: `One exact ATL expansion is selected, implemented or deferred, synchronized, and covered.`
  Verification: `Selected and implemented rule-level qualified actor-transaction trigger parent handoffs in .2.1 while preserving generated-top, payload, repeated-trigger, and local rule-trigger boundaries.`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.2.1`
  Status: `done`
  Goal: `Support rule-level qualified actor-transaction triggers: a rule action (trigger INSTANCE.TRANSACTION) should pulse the same ATL parent handoff output used by transaction-body triggers and report actor_network.transaction_triggers[] metadata with context rule_action, without widening generated ATL tops, payloads, bindings, nested trigger contexts, repeated-trigger semantics, or rule-trigger fan-in for local transactions.`
  Acceptance: `A rule whose guard fires and whose action is (trigger worker.process) for a declared static actor instance lowers to a guarded rule DT that pulses worker_process_start for one cycle, exposes that output port, and records bounded actor_network.transaction_triggers[] metadata. Existing transaction-body trigger behavior, local rule (trigger transaction) behavior, and fail-closed boundaries for unknown instances, malformed targets, bindings/payloads, generated-top wiring, nested contexts, and repeated/fan-in semantics stay intact. Focused tests, docs/spec/public surfaces, mdBook, and ATL gates pass.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1171-isf-rule-trigger-fanin.t t/1172-isf-rule-trigger-fanin-schedule-report.t t/1182-isf-rule-trigger-target-boundary.t`; `prove -Iperl t/1376-isf-book-example-lowering-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.3`
  Status: `done`
  Goal: `Explore and, if selected, specify IAL2 protocol/platform intent.`
  Acceptance: `IAL2 is either kept as horizon exploration or one executable design slice is selected.`
  Verification: `Read README.md remaining-work note, docs/tasks/R14-ASPECT-COVERAGE-AUDIT.md Gap 2, docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md .6, docs/ISF_SPEC.md intent abstraction layers, docs/ISF_ATL_DESIGN_PROPOSAL.md ATL/IAL1 boundary, docs/book/src/13-intent-scheduling.md, and docs/book/src/14-feature-backlog.md IAL2 exploration. Existing sources already agree that IAL2 remains non-R14 horizon exploration unless a future source model introduces real protocol/platform semantics above explicit ISF actor/network syntax; no executable implementation slice is selected.`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.4`
  Status: `done`
  Goal: `Broaden ISF enum, type, and aggregate parity.`
  Acceptance: `One exact enum/type/aggregate parity surface is selected, implemented or deferred, synchronized, and covered.`
  Verification: `Read docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md terminal .49 closure, its open questions/decisions, docs/book/src/13j-type-enum-aggregate.md, docs/book/src/14-feature-backlog.md ISF enum/type/aggregate section, docs/ISF_SPEC.md remaining aggregate boundary, docs/ISF_PUBLIC_INTERFACE_CONTRACT.md parity notes, and completed Composition/type owner trees. Existing sources already agree that remaining enum target/operator-position behavior, subaggregate operands/updates, additional aggregate carriers, broader field/slice/update lowering, and shape inference are future semantic-contract families requiring new exact task-tree ownership; no adjacent executable ISF parser/lowering slice is selected here.`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.5`
  Status: `done`
  Goal: `Broaden resource kinds and arbiter policies.`
  Acceptance: `One exact resource kind or arbiter policy is selected, implemented or deferred, synchronized, and covered.`
  Verification: `Read the shipped resource-priority and round-robin task trees, ISF resource specs/contracts/book backlog, and FSM::Support::ISFResourceCatalog. Existing sources already agree that priority and bounded round_robin are exhausted for rule_slot, output_bundle, transaction_start, and storage_port rule users, while interface_bundle, named_drive, child_instance, generated-child resources, actor-network resource users, weighted/token/multi-capacity arbiters, route mux/storage, storage locks, memory-port protocols, and lifetime ownership require future exact ownership contracts; no adjacent executable parser/lowering slice is selected here.`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.6`
  Status: `pending`
  Goal: `Broaden priority-resolution cases.`
  Acceptance: `One exact same-cycle or same-target priority case is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.7`
  Status: `done`
  Goal: `Broaden transaction stages, waits, and dynamic loop combinations.`
  Children: `ISF-REMAINING-BROAD-FRONTIER.7.1`

- ID: `ISF-REMAINING-BROAD-FRONTIER.7.1`
  Status: `done`
  Goal: `Support runtime waits immediately after loop-control decision states: (exit-when ...) / (continue-when ...) false edges must split a following runtime (wait ...) while true edges keep their exit/continue target.`
  Acceptance: `A while/until loop body with (exit-when COND) or (continue-when COND) followed by runtime (wait COUNT) lowers with the false edge sampling/entering/bypassing the generated dynamic wait, while the true edge still exits or continues. Focused tests cover exit-when and continue-when, docs/spec/public surfaces are synchronized, and ISF gates pass.`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1389-isf-loop-early-exit.t t/1393-isf-loop-continue.t`; `prove -Iperl t/1376-isf-book-example-lowering-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.8`
  Status: `pending`
  Goal: `Broaden transaction ports, pin access, report, and output surfaces.`
  Acceptance: `One exact port/report/output surface is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.9`
  Status: `pending`
  Goal: `Broaden temporal/property forms beyond the shipped formal/simulable subsets.`
  Acceptance: `One exact temporal/property form is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.10`
  Status: `pending`
  Goal: `Broaden schedule-report storage classes and fixture/library coverage.`
  Acceptance: `One exact report class, fixture promotion, or reusable-library surface is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.11`
  Status: `pending`
  Goal: `Broaden CDC semantics, including cross-domain spawn and payload movement.`
  Acceptance: `One exact CDC activation/payload/reset/remap surface is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.12`
  Status: `pending`
  Goal: `Confirm whether the full-width inference terminal remains closed or a new decidable subcase exists.`
  Acceptance: `A decidable width-inference subcase is selected for implementation or the existing fail-closed terminal is reaffirmed.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REMAINING-BROAD-FRONTIER.1` | `done` | Broad R14 frontier selected after the previous active ISF tree closed. |
| 2 | `ISF-REMAINING-BROAD-FRONTIER.7.1` | `done` | Loop-control false fallthrough edges now split following runtime waits while preserving true exit/continue targets. |
| 3 | `ISF-REMAINING-BROAD-FRONTIER.2` | `done` | ATL expansion category selected and the exact rule-level qualified trigger leaf closed. |
| 4 | `ISF-REMAINING-BROAD-FRONTIER.2.1` | `done` | Rule-level qualified `(trigger INSTANCE.TRANSACTION)` now pulses parent handoff output and reports rule-action metadata. |
| 5 | `ISF-REMAINING-BROAD-FRONTIER.3` | `done` | IAL2 remains non-R14 horizon exploration; no executable ISF slice selected. |
| 6 | `ISF-REMAINING-BROAD-FRONTIER.4` | `done` | Remaining enum/type/aggregate work deferred to future exact semantic-contract owners. |
| 7 | `ISF-REMAINING-BROAD-FRONTIER.5` | `done` | Remaining resource/arbiter widening deferred to future exact resource-ownership contracts. |
| 8 | `ISF-REMAINING-BROAD-FRONTIER.6` | `pending` | Next broad item: select one exact priority-resolution case, or defer with evidence. |

## Decisions

- `2026-06-05`: Keep this tree proposed while the user-selected active focus is
  Composition/type. Immediate active ISF frontier leaves remain owned by their
  existing narrower task trees.
- `2026-06-05`: Activated after the active ISF frontier exhausted and selected the
  stage/wait/loop category first. Evidence: existing dynamic-wait zero-bypass owners are
  done, but `loop_exit_when` states created by `(exit-when ...)` / `(continue-when ...)`
  are linked before the generic dynamic-wait predecessor splitter in `LoweringIR`, making
  a following runtime wait a small exact executable gap.
- `2026-06-05`: Selected ATL rule-level qualified actor-transaction triggers as the next
  exact broad-ATL leaf. Evidence: transaction-body qualified triggers and local rule
  triggers are already shipped, while the ATL public contract explicitly reserves
  rule-level qualified triggers as future behavior; the implementation crosses parser
  normalization, rule-DT lowering, report metadata, and generated-top exclusion, so it
  needs its own exact leaf before code changes.
- `2026-06-05`: Closed `.2.1`: one top-level rule action
  `(trigger actor.transaction)` now normalizes to an ATL parent handoff pulse with
  `context: "rule_action"` metadata; generated ATL tops, payloads/bindings,
  repeated rule-action triggers, nested contexts, and local rule-trigger fan-in stay
  outside the slice.
- `2026-06-05`: Closed `.3` without code: IAL2 remains horizon exploration and
  non-R14 until a source model introduces protocol/platform semantics above
  explicit `.isf` actor/network syntax. Current docs and prior audits already
  agree on that boundary, so no executable design slice is selected.
- `2026-06-05`: Closed `.4` without code: the completed
  `ISF-TYPE-AGGREGATE-PARITY` tree already exhausted adjacent ISF parity
  widening and documented the remaining enum/aggregate work as future
  semantic-contract families. No exact executable parser/lowering slice is
  selected in this broad tree.
- `2026-06-05`: Closed `.5` without code: the shipped resource-arbitration
  surface already covers `priority` and bounded `round_robin` for
  `rule_slot`, `output_bundle`, `transaction_start`, and `storage_port` rule
  users. The remaining resource kinds and arbiter policies need new exact
  ownership contracts for protocol/drive/child/resource lifetime semantics
  before behavior-bearing implementation can be selected.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.1` | Selection audit/read: `docs/TASK_TREE.md`, this task file, dynamic-wait backlog text, existing dynamic-wait task files, loop-control docs/tests, and `LoweringIR.pm` loop-control linking | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.7.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1389-isf-loop-early-exit.t t/1393-isf-loop-continue.t`; `prove -Iperl t/1376-isf-book-example-lowering-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `./bin/ci-regression isf --no-book` (294 files / 2125 tests); `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.2` | Selection audit/read: `docs/book/src/14-feature-backlog.md` ATL section, `docs/ISF_ATL_DESIGN_PROPOSAL.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, `docs/ISF_SPEC.md`, `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, `docs/book/src/13k-isf-feature-support-matrix.md`, `t/1322-isf-actor-network-static.t`, and rule-trigger validation/lowering paths in `perl/FSM/Scheduler/ISF/LoweringIR.pm` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.2.1` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1171-isf-rule-trigger-fanin.t t/1172-isf-rule-trigger-fanin-schedule-report.t t/1182-isf-rule-trigger-target-boundary.t`; `prove -Iperl t/1376-isf-book-example-lowering-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `./bin/ci-regression isf --no-book` (294 files / 2126 tests); `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.3` | IAL2 horizon audit/read: `README.md`, `docs/tasks/R14-ASPECT-COVERAGE-AUDIT.md`, `docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md`, `docs/ISF_SPEC.md`, `docs/ISF_ATL_DESIGN_PROPOSAL.md`, `docs/book/src/13-intent-scheduling.md`, and `docs/book/src/14-feature-backlog.md`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.4` | Enum/type/aggregate audit/read: `docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md`, `docs/book/src/13j-type-enum-aggregate.md`, `docs/book/src/14-feature-backlog.md`, `docs/ISF_SPEC.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, and completed Composition/type owner trees; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.5` | Resource/arbiter audit/read: `docs/tasks/ISF-RESOURCE-CATALOG.md`, `docs/tasks/ISF-RESOURCE-PRIORITY.md`, priority and round-robin resource-kind implementation trees, `docs/ISF_SPEC.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, `docs/book/src/14-feature-backlog.md`, and `perl/FSM/Support/ISFResourceCatalog.pm`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REMAINING-BROAD-FRONTIER.1` | `ISF-REMAINING-BROAD-FRONTIER.1: select loop-control dynamic waits` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.2` | `ISF-REMAINING-BROAD-FRONTIER.2: select ATL rule triggers` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.2.1` | `ISF-REMAINING-BROAD-FRONTIER.2.1: ship ATL rule triggers` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.3` | `ISF-REMAINING-BROAD-FRONTIER.3: keep IAL2 horizon` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.4` | `ISF-REMAINING-BROAD-FRONTIER.4: defer parity contracts` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.5` | `pending` | `pending` |
| `ISF-REMAINING-BROAD-FRONTIER.7.1` | `ISF-REMAINING-BROAD-FRONTIER.7.1: split loop-control dynamic waits` | this slice |

## Changelog

- `2026-06-05`: Created proposed broad ISF frontier owner tree.
- `2026-06-05`: `.1` activated the tree and selected `.7.1`, a loop-control
  dynamic-wait predecessor leaf for `(exit-when ...)` / `(continue-when ...)` followed by
  runtime `(wait ...)`.
- `2026-06-05`: `.7.1` shipped false-edge dynamic-wait splitting after
  `(exit-when ...)` / `(continue-when ...)` while preserving the true exit or
  continue target; next frontier is broad ATL leaf selection.
- `2026-06-05`: `.2` selected `.2.1`, a rule-level qualified
  `(trigger INSTANCE.TRANSACTION)` ATL parent-handoff leaf, before any ATL code
  changes.
- `2026-06-05`: `.2.1` shipped rule-level qualified ATL transaction triggers.
- `2026-06-05`: `.3` reaffirmed IAL2 as horizon exploration with no executable
  R14 implementation slice selected.
- `2026-06-05`: `.4` deferred remaining enum/type/aggregate parity to future
  exact semantic-contract owners.
- `2026-06-05`: `.5` deferred remaining resource-kind and arbiter-policy
  widening to future exact resource ownership and lifetime-contract owners;
  next frontier is priority-resolution case selection.
