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
    `ISF-REMAINING-BROAD-FRONTIER.9.1`,
    `ISF-REMAINING-BROAD-FRONTIER.10`,
    `ISF-REMAINING-BROAD-FRONTIER.11`,
    `ISF-REMAINING-BROAD-FRONTIER.11.1`,
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
  Status: `done`
  Goal: `Broaden priority-resolution cases.`
  Acceptance: `One exact same-cycle or same-target priority case is selected, implemented or deferred, synchronized, and covered.`
  Verification: `Read docs/tasks/ISF-CONFLICT-RESOLUTION.md, docs/tasks/ISF-TRANSACTION-OVER-RULE-PRIORITY.md, docs/tasks/ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.md, docs/tasks/ISF-RESOURCE-PRIORITY.md, docs/tasks/ISF-RULE-ACTIONS.md, docs/book/src/14-feature-backlog.md, docs/ISF_SPEC.md, docs/ISF_PUBLIC_INTERFACE_CONTRACT.md, docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md, t/1219-isf-rule-transaction-priority.t, and priority/conflict references in LoweringIR. Existing sources already agree that rule/rule same-target data priority and covered rule-over-transaction plus transaction-over-rule same-target data priority are shipped; unordered rule/transaction conflicts, mixed timing conflicts, priority cycles, transaction/transaction priority, and drive/rule arbitration policy remain deferred or fail-closed until future exact policy owners define their semantics. No adjacent executable parser/lowering slice is selected here.`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check`
  Commit: `this slice`

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
  Status: `done`
  Goal: `Broaden transaction ports, pin access, report, and output surfaces.`
  Acceptance: `One exact port/report/output surface is selected, implemented or deferred, synchronized, and covered.`
  Verification: `Read the ISF schedule-report additive-key knowledge card, docs/tasks/ISF-PORT-BINDING.md, docs/tasks/ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.md, docs/tasks/ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.md, docs/tasks/ISF-TRANSACTION-PORT-BINDING-*.md, docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md, docs/tasks/ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.md, docs/book/src/14-feature-backlog.md, docs/ISF_SPEC.md, docs/ISF_PUBLIC_INTERFACE_CONTRACT.md, docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md, t/1371-isf-transaction-port-activation-override-width-gate.t, and relevant LoweringIR diagnostics. Existing sources already agree that transaction port declarations/bindings, actor-pin conflict coverage, expression-valued input bindings, generated-child rule-trigger output bindings, current-timing snapshot/live assertions, endpoint/timing/authored-mode report metadata, and transaction-port width default-preserving override gates are shipped. Direct/local rule-trigger output bindings, behavior-changing snapshot/live conversion, per-activation transaction port-width specialization, arbitrary richer report fields, and broader static conflict proofs require future exact owners; no adjacent executable parser/lowering/report slice is selected here. Also repaired stale completed task metadata for ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.9`
  Status: `done`
  Goal: `Broaden temporal/property forms beyond the shipped formal/simulable subsets.`
  Children: `ISF-REMAINING-BROAD-FRONTIER.9.1`
  Acceptance: `Selected value-returning (past SIG [N]) inside assertion/property expressions as the exact executable temporal/property leaf.`
  Verification: `Selection audit/read: docs/knowledge/isf-property-grammar-location.md, docs/knowledge/isf-sampled-value-predicates.md, docs/knowledge/isf-bounded-window-min.md, docs/knowledge/isf-verification-book-map.md, docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md, docs/tasks/ISF-PROPERTY-IMPLICATION.md, docs/tasks/ISF-PROPERTY-WINDOW-RANGE.md, docs/tasks/ISF-ASSERT-CONCURRENT.md, docs/tasks/ISF-TRIGGER-ANCHOR.md, docs/book/src/14-feature-backlog.md, perl/FSM/Adapter/FSMGenFull/Parser.pm, perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm, perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm, perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm, and t/1417-isf-property-sampled-value.t. Existing evidence shows (past SIG [N]) was explicitly deferred behind expression-level property composition, while parser/rendering/signal-retention hooks can support a bounded property-only value function without widening synthesizable expression positions.`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.9.1`
  Status: `done`
  Goal: `Support value-returning (past SIG [N]) inside assert/assume/cover property expressions only, rendering to $past(SIG) or $past(SIG, N) while preserving fail-closed behavior in synthesizable expression positions.`
  Acceptance: `A check such as (assert (== data (past data))) renders condition_sv as data == $past(data); (past data 2) renders $past(data, 2); signals referenced only through past are kept alive as input ports; malformed arity, non-signal operands, and nonpositive/nonliteral depths fail closed; (past ...) remains unsupported in ordinary synthesizable expressions such as when guards. Focused tests, public docs/book, knowledge map, and required gates pass.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`; `prove -Iperl t/1417-isf-property-sampled-value.t t/1412-isf-property-implication.t t/1418-isf-property-window-range.t t/1411-isf-assert-emit.t`; `prove -Iperl t/1376-isf-book-example-lowering-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `./bin/ci-regression isf --no-book` (294 files / 2126 tests); `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.10`
  Status: `done`
  Goal: `Broaden schedule-report storage classes and fixture/library coverage.`
  Acceptance: `One exact report class, fixture promotion, or reusable-library surface is selected, implemented or deferred, synchronized, and covered.`
  Verification: `Read docs/knowledge/isf-schedule-report-additive-keys.md, docs/tasks/ISF-SCHEDULE-REPORT-STORAGE-ROLES.md, docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md, docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md, docs/tasks/ISF-FIXTURE-COVERAGE.md, docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md, docs/tasks/ISF-LIBRARY-SYSTEM-BINDINGS.md, docs/book/src/14-feature-backlog.md, docs/book/src/13k-isf-feature-support-matrix.md, docs/ISF_SPEC.md, docs/ISF_PUBLIC_INTERFACE_CONTRACT.md, docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md, checked-in isf fixtures, and fixture/schedule-report tests. Existing sources already agree that schema-version-1 additive keys, full schema freeze, golden matrix coverage, bounded storage roles, realistic fixture promotions, ATL fixture promotions, and fixed FIFO reusable-library fixture coverage are shipped. Remaining rich storage-class optimization, additional resource/debug storage roles, new realistic protocol fixtures, nested/parameter-driven reusable-library behavior, standalone library transaction/drive exports, and broader fixture promotions need future exact semantic or fixture owners; no adjacent executable report/fixture/library slice is selected here.`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.11`
  Status: `done`
  Goal: `Broaden CDC semantics, including cross-domain spawn and payload movement.`
  Children: `ISF-REMAINING-BROAD-FRONTIER.11.1`
  Acceptance: `Selected .11.1, a downstream/public contract sync for already-shipped nested blocking cross-domain (do) activation contexts through explicit activation crossings, before changing any contract text.`
  Verification: `Selection audit/read: docs/tasks/ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.md, docs/tasks/ISF-NESTED-CROSS-DOMAIN-ACTIVATION.md, t/1387-isf-cross-domain-activation-handshake-lowering.t, docs/book/src/13a-actor-interface.md, docs/book/src/13d-control-flow.md, docs/book/src/13k-isf-feature-support-matrix.md, docs/book/src/14-feature-backlog.md, docs/ISF_PUBLIC_INTERFACE_CONTRACT.md, and docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md. Existing evidence shows the mdBook and test-backed task tree describe shipped nested blocking cross-domain (do) contexts, while downstream/public contract passages still carry older top-level-only/nested-fail-closed wording; this is a contract-sync repair, not new CDC behavior.`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.11.1`
  Status: `done`
  Goal: `Synchronize downstream/public CDC contract text for shipped nested blocking cross-domain (do) activation contexts.`
  Acceptance: `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md and docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md describe the same shipped activation-crossing support boundary as the mdBook and t/1387: transaction top level, top-level repeat, top-level when/switch/while/until bodies, top-level when/switch branch-contained repeats, supported nested when chains, and repeats under those chains. They must still defer uncovered activation, declared-but-unused or mis-placed crossings, cross-domain spawn, payload CDC, auto-crossing, nested switch, repeat-contained branch, nested while/until, and unsupported deeper placements. No code behavior changes.`
  Verification: `Updated docs/ISF_PUBLIC_INTERFACE_CONTRACT.md test-backed activation-crossing paragraph and docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md activation-crossing rules/repeat-body boundary wording; drift scan found no remaining top-level-only or all-nested-fail-closed activation crossing claims across the mdBook/contract/spec surfaces.`
  Commit: `this slice`

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
| 8 | `ISF-REMAINING-BROAD-FRONTIER.6` | `done` | Remaining priority-resolution widening deferred to future exact conflict-policy owners. |
| 9 | `ISF-REMAINING-BROAD-FRONTIER.8` | `done` | Remaining port/report/output widening deferred to future exact binding/report-contract owners. |
| 10 | `ISF-REMAINING-BROAD-FRONTIER.9` | `done` | Selected value-returning `(past SIG [N])` as the exact temporal/property form after auditing shipped property grammar, sampled-value predicates, window ranges, verification docs, and parser/render/signal-retention hooks. |
| 11 | `ISF-REMAINING-BROAD-FRONTIER.9.1` | `done` | Property-only `(past SIG [N])` now renders to `$past`, keeps operand signals alive, stays simulable, and fails closed outside check-property expressions. |
| 12 | `ISF-REMAINING-BROAD-FRONTIER.10` | `done` | Remaining schedule-report storage, fixture, and reusable-library widening deferred to future exact report/fixture/library owners. |
| 13 | `ISF-REMAINING-BROAD-FRONTIER.11` | `done` | Selected `.11.1`, a downstream/public contract sync for already-shipped nested blocking cross-domain `(do)` activation contexts. |
| 14 | `ISF-REMAINING-BROAD-FRONTIER.11.1` | `done` | Downstream/public contract wording now matches the mdBook and `t/1387` shipped nested activation boundary. |
| 15 | `ISF-REMAINING-BROAD-FRONTIER.12` | `pending` | Next broad item: confirm whether the full-width inference terminal remains closed or a new decidable subcase exists. |

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
- `2026-06-05`: Closed `.6` without code: shipped priority resolution already
  covers rule/rule same-target data conflicts plus covered
  rule-over-transaction and transaction-over-rule same-target data conflicts. Remaining
  transaction/transaction, drive/rule, unordered, mixed-timing, and broader
  conflict-policy cases need future exact semantic owners before
  behavior-bearing implementation can be selected.
- `2026-06-05`: Closed `.8` without behavior changes: shipped port/report
  surfaces already cover transaction port declarations/bindings, actor-pin
  conflict coverage, generated-child rule-trigger output bindings, expression
  input bindings, current-timing assertions, and bounded binding report
  metadata. Remaining direct/local rule-trigger output bindings, timing
  conversion, per-activation port-width specialization, richer report fields,
  and broader conflict proofs need future exact owners.
- `2026-06-05`: Closed `.9` selection without behavior changes: the next exact
  temporal/property leaf is value-returning `(past SIG [N])` inside
  `assert`/`assume`/`cover` property expressions only. Existing shipped forms
  cover boolean sampled-value predicates and formal-only `next`/`within`
  windows; `$past` needs a property-expression value hook plus signal-retention
  coverage, but should remain fail-closed in ordinary synthesizable expression
  positions.
- `2026-06-05`: Closed `.9.1`: check-property expressions now accept
  value-returning `(past SIG [N])` for signal/bit/slice/aggregate leaves and
  optional positive literal depth, rendering to `$past(SIG)` or `$past(SIG, N)`.
  The hook is active only from `assert`/`assume`/`cover`; ordinary
  synthesizable expression positions still fail closed.
- `2026-06-05`: Closed `.10` without behavior changes: the shipped
  schedule-report and fixture/library surfaces already cover additive report
  evolution, schema-version-1 freeze, golden-matrix coverage, bounded storage
  roles, realistic fixture promotions, ATL fixture promotions, and the fixed
  FIFO reusable-library fixture. Remaining rich storage/debug roles, new
  realistic protocols, and broader reusable-library semantics need future
  exact owners before behavior-bearing implementation can be selected.
- `2026-06-05`: Closed `.11` selection without behavior changes: the next exact
  CDC leaf is `.11.1`, a downstream/public contract sync for shipped nested
  blocking cross-domain `(do child)` activation contexts through explicit
  activation crossings. The mdBook and `t/1387` already describe support beyond
  the top-level case, while `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` and
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` still contain older
  nested-fail-closed wording that needs alignment without widening behavior.
- `2026-06-05`: Closed `.11.1` without behavior changes: downstream/public CDC
  contract text now names the shipped nested blocking `(do child)` activation
  contexts already documented in the mdBook and covered by `t/1387`, while
  preserving fail-closed boundaries for cross-domain `spawn`, payload CDC,
  auto-crossing, nested `switch`/`while`/`until`, repeat-contained branch
  prerequisites, and unsupported deeper placements.

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
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.6` | Priority/conflict audit/read: `docs/tasks/ISF-CONFLICT-RESOLUTION.md`, `docs/tasks/ISF-TRANSACTION-OVER-RULE-PRIORITY.md`, `docs/tasks/ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.md`, `docs/tasks/ISF-RESOURCE-PRIORITY.md`, `docs/tasks/ISF-RULE-ACTIONS.md`, `docs/book/src/14-feature-backlog.md`, `docs/ISF_SPEC.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, `t/1219-isf-rule-transaction-priority.t`, and priority/conflict references in `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.8` | Port/report/output audit/read: `docs/knowledge/isf-schedule-report-additive-keys.md`, `docs/tasks/ISF-PORT-BINDING.md`, `docs/tasks/ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.md`, `docs/tasks/ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.md`, `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.md`, `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.md`, `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.md`, `docs/tasks/ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.md`, `docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md`, `docs/tasks/ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.md`, `docs/book/src/14-feature-backlog.md`, `docs/ISF_SPEC.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, `t/1371-isf-transaction-port-activation-override-width-gate.t`, and related `LoweringIR` diagnostics; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.9` | Selection audit/read: `docs/knowledge/isf-property-grammar-location.md`, `docs/knowledge/isf-sampled-value-predicates.md`, `docs/knowledge/isf-bounded-window-min.md`, `docs/knowledge/isf-verification-book-map.md`, `docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md`, `docs/tasks/ISF-PROPERTY-IMPLICATION.md`, `docs/tasks/ISF-PROPERTY-WINDOW-RANGE.md`, `docs/tasks/ISF-ASSERT-CONCURRENT.md`, `docs/tasks/ISF-TRIGGER-ANCHOR.md`, `docs/book/src/14-feature-backlog.md`, `perl/FSM/Adapter/FSMGenFull/Parser.pm`, `perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`, `perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm`, `perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`, and `t/1417-isf-property-sampled-value.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.9.1` | `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`; `prove -Iperl t/1417-isf-property-sampled-value.t t/1412-isf-property-implication.t t/1418-isf-property-window-range.t t/1411-isf-assert-emit.t`; `prove -Iperl t/1376-isf-book-example-lowering-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `./bin/ci-regression isf --no-book` (294 files / 2126 tests); `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `git diff --check` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.10` | Schedule-report/fixture/library audit/read: `docs/knowledge/isf-schedule-report-additive-keys.md`, `docs/tasks/ISF-SCHEDULE-REPORT-STORAGE-ROLES.md`, `docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md`, `docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md`, `docs/tasks/ISF-FIXTURE-COVERAGE.md`, `docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md`, `docs/tasks/ISF-LIBRARY-SYSTEM-BINDINGS.md`, `docs/book/src/14-feature-backlog.md`, `docs/book/src/13k-isf-feature-support-matrix.md`, `docs/ISF_SPEC.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, checked-in `isf/` fixtures, and fixture/schedule-report tests; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.11` | CDC selection audit/read: `docs/tasks/ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.md`, `docs/tasks/ISF-NESTED-CROSS-DOMAIN-ACTIVATION.md`, `t/1387-isf-cross-domain-activation-handshake-lowering.t`, `docs/book/src/13a-actor-interface.md`, `docs/book/src/13d-control-flow.md`, `docs/book/src/13k-isf-feature-support-matrix.md`, `docs/book/src/14-feature-backlog.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, and `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.11.1` | Contract sync + drift scan: `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, `docs/book/src/13a-actor-interface.md`, `docs/book/src/13d-control-flow.md`, `docs/book/src/13k-isf-feature-support-matrix.md`, `docs/book/src/14-feature-backlog.md`; `prove -Iperl t/1387-isf-cross-domain-activation-handshake-lowering.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REMAINING-BROAD-FRONTIER.1` | `ISF-REMAINING-BROAD-FRONTIER.1: select loop-control dynamic waits` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.2` | `ISF-REMAINING-BROAD-FRONTIER.2: select ATL rule triggers` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.2.1` | `ISF-REMAINING-BROAD-FRONTIER.2.1: ship ATL rule triggers` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.3` | `ISF-REMAINING-BROAD-FRONTIER.3: keep IAL2 horizon` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.4` | `ISF-REMAINING-BROAD-FRONTIER.4: defer parity contracts` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.5` | `ISF-REMAINING-BROAD-FRONTIER.5: defer resource widening` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.6` | `ISF-REMAINING-BROAD-FRONTIER.6: defer priority widening` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.8` | `ISF-REMAINING-BROAD-FRONTIER.8: defer port surfaces` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.9` | `ISF-REMAINING-BROAD-FRONTIER.9: select past property value` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.9.1` | `ISF-REMAINING-BROAD-FRONTIER.9.1: ship past property value` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.10` | `ISF-REMAINING-BROAD-FRONTIER.10: defer report and fixture widening` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.11` | `ISF-REMAINING-BROAD-FRONTIER.11: select CDC contract sync` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.11.1` | `ISF-REMAINING-BROAD-FRONTIER.11.1: sync CDC contract boundary` | this slice |
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
- `2026-06-05`: `.6` deferred remaining priority-resolution widening to
  future exact conflict-policy owners; next frontier is port/report/output
  surface selection.
- `2026-06-05`: `.8` deferred remaining port/report/output widening to
  future exact binding/report-contract owners and repaired stale completed
  task metadata for `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE`;
  next frontier is temporal/property form selection.
- `2026-06-05`: `.9` selected `.9.1`, value-returning `(past SIG [N])` for
  assertion/property expressions only, before parser/test/source changes.
- `2026-06-05`: `.9.1` shipped value-returning `(past SIG [N])` inside
  assertion/property expressions only, synced mdBook/spec/knowledge, and moved
  the frontier to schedule-report storage/fixture/library selection.
- `2026-06-05`: `.10` deferred remaining schedule-report storage,
  fixture-promotion, and reusable-library widening to future exact owners;
  next frontier is CDC semantics.
- `2026-06-05`: `.11` selected `.11.1`, a downstream/public contract-sync
  repair for already-shipped nested blocking cross-domain activation contexts,
  before changing contract text.
- `2026-06-05`: `.11.1` synced downstream/public CDC contract wording with the
  shipped nested blocking activation boundary and moved the frontier to
  full-width inference terminal review.
