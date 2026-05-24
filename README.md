# FSMGen
This file is the **single entry point** for the project.
Use it first for objective, navigation, and where to find code/docs quickly.

## Session safety invariant
- The commit workflow in `COMMIT.md` is mandatory and non-negotiable.
- Before any code, test, source, generated-artifact, or config change, the work
  must already have task-tree ownership in `docs/TASK_TREE.md` and
  `docs/tasks/*.md`.
- After every completed task, slice, lane, or task-scoped activity, run that workflow before starting or switching to the next one.
- Do not ask the user whether to run it after completion; run it automatically.
- Do not batch several finished tasks into one later cleanup commit.
- Run git index-mutating steps in that workflow sequentially; never overlap `git add`, `git rm`, `git mv`, or `git commit`.
- The reason is operational, not stylistic: task-scoped commits are the project's crash-recovery mechanism for session loss, app crashes, and machine crashes.
- If a task is complete but not committed, that task is not safely finished yet.

## Documentation path invariant
- Paths in live docs and the mdBook must be relative to the repository root.
- Do not record machine-local absolute paths such as user home directories in
  tracked documentation.
- If a note references an external workspace, describe it without linking to a
  local filesystem path.

## Documentation synchronization invariant
- The mdBook is a required user-facing artifact for every future slice that
  changes behavior, syntax, diagnostics, workflow, public contracts, or any
  other user-visible FSMGen behavior.
- Keep the mdBook, live specs, roadmap/task-tree status, and public contract
  docs synchronized in the same slice as the code change.
- For downstream-visible `.isf` changes, also keep
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` synchronized with the codebase,
  live specs, mdBook, public contract, manifest metadata, tests, and explicit
  deferrals. That file is the single SPECFORGE-style integration handoff.
- Do not treat a user-visible implementation slice as complete until the book
  describes the shipped behavior accurately enough for review without reading
  the codebase.

## Project objective
FSMGen compiles Lisp-like `.fsm` state machine specifications into synthesizable HDL, and now accepts `.isf` intent-scheduling sources that lower into explicit scheduled `.fsm` before HDL generation.
Current primary target is SystemVerilog, with Verilog conversion support and explicit VHDL not-implemented signaling.
The project objective is robust, traceable FSM-to-HDL generation with clear assignment semantics, optimization via AST factorization, and behavior-preserving refactoring toward a modular architecture.

## Fast ramp-up order
1. `README.md` (this file): project objective + navigation.
2. `COMMIT.md`: mandatory commit workflow and safety invariant for crash recovery.
3. `SESSION_BOOTSTRAP.md`: default first task for a new engineering session.
4. `ROADMAP_STATUS.md`: canonical live roadmap/workstream status.
5. `docs/TASK_TREE_README.md`: setup guide for adopting this task-tree tracking workflow in another project.
6. `docs/TASK_TREE.md`: repo-local task-tree workflow, active tree index, and PNT frontier rules.
7. `ROADMAP_V2.md`: detailed post-`R0`..`R7` roadmap intent and sequencing.
8. `docs/book/src/SUMMARY.md`: progressive mdBook table of contents.
9. `docs/USER_GUIDE.md`: broad live reference during the book split.
10. `docs/COMPOSITION_SCOPE.md`: concrete `R6` composition scope and acceptance boundary.
11. `docs/COMPOSITION_LEGACY_MAPPING.md`: historical `fx/bin/fsmgen` composition behavior mapped onto the active `R6` plan.
12. `docs/EXTENSION_MODEL.md`: active `R7` typed extension boundary replacing legacy `.plg` / `PPlugin` as architecture direction.
13. `docs/SPECFORGE_FEEDBACK_RESPONSE.md`: FSMGen's tracked response and alignment plan for SPECFORGE adapter feedback.
14. `docs/INTENT_SCHEDULING_BRAINSTORM.md`: living brainstorm log for an intent-scheduling layer above explicit cycle-authored `.fsm`.
15. `docs/ISF_ATL_DESIGN_PROPOSAL.md`: live design proposal for ISF Actor Transfer Level actor-network orchestration.
16. `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`: single self-contained downstream `.isf` integration handoff.
17. `docs/DOWNSTREAM_ISSUE_REPORTING.md`: strict downstream issue-reporting protocol for local FSMGen reproduction.
18. `docs/ISF_SPEC.md`: active R14 `.isf` Intent Scheduling Format specification.
19. `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`: live downstream-consumer API contract for ISF parser/scheduler surfaces.
20. `docs/ISF_LIBRARY_CATALOG.md`: live catalog of shipped reusable ISF library definitions.
21. `docs/BIN_FSMGEN_IMPORT_TREE.md`: live `bin/fsmgen` import-tree and runtime-spine architecture snapshot.
22. `docs/REGRESSION_CORPUS.md`: human-readable regression/support-accounting corpus companion.
23. `docs/INTENT_CAPTURE_AXI_CASE_STUDY.md`: AXI intent-capture case-study notes for future high-level synthesis work.
24. `docs/FEATURE_BACKLOG.md`: pointer to the canonical mdBook feature backlog for deferred/not-fully-shipped user-visible work.
25. `CHANGES.md`: chronological technical changes.
26. `DEVELOPMENT_NOTES.md`: design rationale and decisions.
27. `MEMORY.md`: continuity/handoff state.
28. `LIVE_ACHIEVEMENT_STATUS.md`: latest completed roadmap-aligned slice.
29. `WARP.md`: repository-specific agent/development guidance.
30. `.agents/workflows/commit.md`: automation-oriented commit workflow description.

## Documentation index (all `.md` files in this repo)
- `README.md` — single entry point and navigation hub.
- `SESSION_BOOTSTRAP.md` — canonical first-task file for a new engineering session.
- `ROADMAP_STATUS.md` — canonical live roadmap/workstream status board.
- `ROADMAP_V2.md` — detailed post-`R0`..`R7` roadmap intent and sequencing.
- `docs/book/` — mdBook source for the progressive FSMGen book.
- `docs/BOOK_PLAN.md` — migration plan from the monolithic guide into the mdBook.
- `docs/USER_GUIDE.md` — broad live reference and command usage during the split.
- `docs/TASK_TREE_README.md` — setup guide for adopting the task-tree tracking workflow in another project.
- `docs/TASK_TREE.md` — repo-local task-tree workflow, active tree index, and PNT frontier rules.
- `docs/tasks/TEMPLATE.md` — reusable template for one top-level task tree.
- `docs/tasks/INFERENCE-FIRST-SCALAR-AUTHORING.md` — completed language-ergonomics task tree for the first inference-first scalar authoring slice.
- `docs/tasks/COMPOSITION-WIRING-LISPISH.md` — completed `R11` task tree for canonical Lisp-ish `?wiring` list forms.
- `docs/tasks/FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.md` — completed roadmap-maintenance task tree for broad feature-backlog owner coverage synchronization.
- `docs/tasks/ISF-CONFLICT-RESOLUTION.md` — completed `R14` task tree for ISF same-cycle conflict semantics.
- `docs/tasks/ISF-TRANSACTION-OVER-RULE-PRIORITY.md` — completed `R14` task tree for covered transaction-over-rule same-target priority.
- `docs/tasks/ISF-COMPOSITION-INSTANTIATION.md` — completed `R14` task tree for generated child instantiation and spawn parameter binding.
- `docs/tasks/ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.md` — completed `R14` task tree for bounded round-robin resource arbitration.
- `docs/tasks/ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.md` — completed `R14` task tree for output-bundle priority resource enforcement.
- `docs/tasks/ISF-STORAGE-PORT-RESOURCE-PRIORITY.md` — completed `R14` task tree for storage-port priority resource enforcement.
- `docs/tasks/ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.md` — completed `R14` task tree for storage-port member documentation truth sync.
- `docs/tasks/ISF-RESOURCE-PRIORITY.md` — completed `R14` task tree for resource arbitration and priority enforcement.
- `docs/tasks/ISF-RESOURCE-CATALOG.md` — completed `R14` task tree for the shareable resource kind registry.
- `docs/tasks/ISF-RULE-ACTIONS.md` — completed `R14` task tree for expression-valued rule assignments.
- `docs/tasks/ISF-STAGES-CONTRACTS.md` — completed `R14` task tree for transaction stages and temporal contracts.
- `docs/tasks/ISF-DATA-WIDTHS.md` — completed `R14` task tree for data-operation width inference.
- `docs/tasks/ISF-ASSEMBLE-STATIC-PART-WIDTHS.md` — completed `R14` task tree for optional `assemble` part-width evidence.
- `docs/tasks/ISF-DATA-OP-STATIC-WIDTH-SOURCES.md` — completed `R14` task tree for actor-local static value sources in data-operation width evidence.
- `docs/tasks/ISF-SHIFT-LEFT-EXPLICIT-WIDTH.md` — completed `R14` task tree for optional `shift_left` width evidence.
- `docs/tasks/ISF-SCHEDULE-REPORTS.md` — completed `R14` task tree for schedule-report storage classes and schema stabilization.
- `docs/tasks/ISF-FIXTURE-COVERAGE.md` — completed `R14` task tree for realistic fixtures and strict-mode coverage.
- `docs/tasks/ISF-BURST-FIXTURE-PROMOTION.md` — completed `R14` task tree for burst-reader fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-UART-FIXTURE-PROMOTION.md` — completed `R14` task tree for UART-like fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-PHASE-FIXTURE-PROMOTION.md` — completed `R14` task tree for phase fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-SWITCH-FIXTURE-PROMOTION.md` — completed `R14` task tree for switch fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-WHEN-FIXTURE-PROMOTION.md` — completed `R14` task tree for `when` fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.md` — completed `R14` task tree for generated-composition fixture strict/outdir/HDL promotion.
- `docs/tasks/ISF-RULE-RESOURCE-FIXTURE-PROMOTION.md` — completed `R14` task tree for rule/resource arbitration fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.md` — completed `R14` task tree for stage/contract fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.md` — completed `R14` task tree for FIFO controller fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.md` — completed `R14` task tree for FIFO datapath bank-access fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md` — completed `R14` task tree for FIFO reusable-library fixture schedule/strict/outdir/HDL promotion.
- `docs/tasks/ISF-I2C-FIXTURE-PROMOTION.md` — completed `R14` task tree for I2C-like fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-COMPATIBILITY-SURFACE.md` — completed `R14` task tree for legacy handshake and removed assign compatibility policy.
- `docs/tasks/ISF-PORT-BINDING.md` — completed `R14` task tree for transaction ports and actor pin access.
- `docs/tasks/ISF-CONTROL-FLOW.md` — completed `R14` task tree for transaction-local waits and dynamic loops.
- `docs/tasks/ISF-WAIT-ZERO.md` — completed `R14` task tree for zero-count transaction wait semantics.
- `docs/tasks/ISF-DYNAMIC-WAIT.md` — completed `R14` task tree for non-literal transaction wait counts.
- `docs/tasks/ISF-PARAM-WAIT-COUNTS.md` — completed `R14` task tree for actor-parameter-backed static transaction wait counts.
- `docs/tasks/ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.md` — completed `R14` task tree for completion zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.md` — completed `R14` task tree for independent setter zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.md` — completed `R14` task tree for explicit independent update zero-bypass coverage.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.md` — completed `R14` task tree for independent shift zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE.md` — completed `R14` task tree for independent assemble zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.md` — completed `R14` task tree for independent extract zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.md` — completed `R14` task tree for independent bank-load zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.md` — completed `R14` task tree for independent bank-store zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.md` — completed `R14` task tree for carrying pending samples across consecutive runtime wait zero-count links.
- `docs/tasks/ISF-DYNAMIC-WAIT-STAGE-SAMPLE.md` — completed `R14` task tree for stage zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.md` — completed `R14` task tree for contract arm zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.md` — completed `R14` task tree for loop decision zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.md` — completed `R14` task tree for dynamic waits after bank load/store predecessors.
- `docs/tasks/ISF-DYNAMIC-WAIT-SYNC-SAMPLE.md` — completed `R14` task tree for await_all/await_any zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.md` — completed `R14` task tree for spawn zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-PHASE-SAMPLE.md` — completed `R14` task tree for transaction phase zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-SPAWN-IN-REPEAT.md` — completed `R14` task tree for static child spawn inside repeat bodies.
- `docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md` — completed `R14` task tree for repeat-body spawn parameter overrides.
- `docs/tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md` — completed `R14` task tree for repeat-body child activation widening.
- `docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md` — completed `R14` task tree for static ISF Actor Transfer Level actor-network orchestration.
- `docs/tasks/ISF-CONTRACT-ACTOR-PARAM-WINDOWS.md` — completed `R14` task tree for actor-parameter-backed temporal contract windows.
- `docs/tasks/ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.md` — completed `R14` task tree for positive actor constants in transaction latency bounds.
- `docs/tasks/ISF-LATENCY-ACTOR-PARAM-BOUNDS.md` — completed `R14` task tree for actor-parameter-backed transaction latency bounds.
- `docs/tasks/ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor interface port widths.
- `docs/tasks/ISF-INTERFACE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor interface port widths.
- `docs/tasks/ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned scalar storage widths.
- `docs/tasks/ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned scalar storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned bank storage depths.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed transaction-local port widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned bank storage depths.
- `docs/tasks/ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.md` — completed `R14` task tree for positive actor constants in watchdog limits.
- `docs/tasks/ISF-WATCHDOG-ACTOR-PARAM-LIMITS.md` — completed `R14` task tree for actor-parameter-backed watchdog limits.
- `docs/tasks/ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor constants as repeat counter width evidence.
- `docs/tasks/ISF-REPEAT-ACTOR-PARAM-COUNTS.md` — completed `R14` task tree for actor-parameter-backed repeat counts.
- `docs/tasks/ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.md` — completed `R14` task tree for a bounded static zero-count repeat policy.
- `docs/tasks/ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.md` — completed `R14` task tree for runtime scalar repeat zero-count skip policy.
- `docs/tasks/ISF-REPEAT-COUNT-SOURCE-BOUNDARY.md` — completed `R14` task tree for the accepted repeat count source boundary.
- `docs/tasks/ISF-BACKLOG-OWNER-TRUTH-SYNC.md` — completed `R14` task tree for mdBook backlog task-tree owner truth synchronization.
- `docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.md` — completed `R14` task tree for targeted transaction-parameter repeat count diagnostics.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.md` — completed `R14` task tree for dynamic-divisor drive-expression coverage hardening.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-CONTROL-BANK-COVERAGE.md` — completed `R14` task tree for dynamic-divisor control and bank expression coverage hardening.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.md` — completed `R14` task tree for actor-parameter-zero dynamic-divisor safety.
- `docs/tasks/ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for synchronizing stale next-PNT roadmap wording.
- `docs/tasks/CI-FEATURE-BACKLOG-STATUS-AUDIT.md` — completed project-operations task tree for repairing a stale feature-backlog status audit expectation.
- `docs/tasks/ISF-ATL-FRONTIER-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for synchronizing stale closed ATL frontier wording.
- `docs/tasks/ISF-ATL-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing stale ATL backlog prose.
- `docs/tasks/ISF-ATL-COMPACT-INSTANCE-ALIAS.md` — completed `R14` task tree for the compact ATL static instance alias.
- `docs/tasks/ISF-ATL-COMPACT-GROUP-ALIAS.md` — completed `R14` task tree for the compact ATL concurrent group alias.
- `docs/tasks/ISF-ATL-MULTI-EVENT-WAIT.md` — completed `R14` task tree for bounded ATL transaction-body multi-event waits.
- `docs/tasks/ISF-ATL-PIN-MIXED-ROUTE-SETS.md` — completed `R14` task tree for bounded generated-child ATL top-level pin mixed scalar/vector route sets.
- `docs/tasks/ISF-ATL-PIN-VECTOR-MULTI-ROUTE.md` — completed `R14` task tree for bounded generated-child ATL top-level pin exact-width vector multi-route sets.
- `docs/tasks/ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.md` — completed `R14` task tree for bounded generated-child ATL top-level pin exact-width vector routes.
- `docs/tasks/ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.md` — completed `R14` task tree for bounded generated-child ATL actor-to-actor exact-width vector routes.
- `docs/tasks/ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.md` — completed `R14` task tree for shared ATL route-drive formal/actual-argument boundary hardening.
- `docs/tasks/ISF-ATL-PIN-EGRESS-MULTI-ROUTE.md` — completed `R14` task tree for bounded generated-child ATL resolved-child pin-egress multi-route scalar movement.
- `docs/tasks/ISF-ATL-PIN-INGRESS-MULTI-ROUTE.md` — completed `R14` task tree for bounded generated-child ATL top-level pin-ingress multi-route scalar movement.
- `docs/tasks/ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.md` — completed `R14` task tree for bounded generated-child ATL multi-route scalar data movement.
- `docs/tasks/ROADMAP-R14-FRONTIER-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for removing stale R14 frontier text after ATL multi-route closure.
- `docs/tasks/ISF-ATL-DOC-STATUS-TRUTH-SYNC.md` — completed `R14` task tree for ATL book/proposal/status truth synchronization after tree closure.
- `docs/tasks/ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.md` — completed `R14` task tree for SPECFORGE-reported ISF stage/contract conformance bugs.
- `docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md` — completed `R14` task tree for expression-valued activation input bindings.
- `docs/tasks/ISF-SETTER-SYNTAX.md` — completed `R14` task tree for scalar setter syntax shared by rules and transactions.
- `docs/tasks/ISF-TRANSACTION-ACTIVATION.md` — completed `R14` task tree for task-like transaction activation and parameter overrides.
- `docs/tasks/ISF-ACTIVATION-PARAM-OVERRIDES.md` — completed `R14` task tree for remaining rule-trigger and direct-activation parameter overrides.
- `docs/tasks/ISF-LIBRARY-SYSTEM-BINDINGS.md` — completed `R14` task tree for reusable-library clock/reset name remapping.
- `docs/tasks/ISF-STORAGE-VAR-ALIASES.md` — completed `R14` task tree for actor-owned scalar storage variable aliases.
- `docs/tasks/ISF-STORAGE-VAR-SURFACE.md` — completed `R14` task tree for the narrowed actor-owned scalar storage source vocabulary.
- `docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md` — completed `R14` task tree for ISF spec, book, manifest, and contract synchronization.
- `docs/tasks/ISF-CLOCK-DOMAINS.md` — completed `R14` task tree for multi-clock and CDC semantics.
- `docs/tasks/ISF-TIMING-CONVENTIONS.md` — completed `R14` task tree for default actor timing conventions.
- `docs/tasks/ISF-DOWNSTREAM-INTEGRATION-SPEC.md` — completed `R14` task tree for the self-contained `.isf` downstream integration handoff.
- `docs/tasks/ISF-LIVE-BOOK-DOCUMENT-PATHS.md` — completed `R14` task tree for advertising complete ISF mdBook live-document paths through the public contract.
- `docs/tasks/ISF-REPEAT-BODY-DOC-TRUTH-SYNC.md` — completed `R14` task tree for repeat-body shipped-subset documentation truth synchronization.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX.md` — completed `R14` task tree for the book-facing ISF shipped feature matrix.
- `docs/tasks/ISF-RULE-GUARD-DOC-TRUTH-SYNC.md` — completed `R14` task tree for standalone enum/aggregate rule-guard backlog truth synchronization.
- `docs/tasks/ISF-LOOP-BODY-DOC-TRUTH-SYNC.md` — completed `R14` task tree for loop-body shipped-clause documentation truth synchronization.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.md` — completed `R14` task tree for shipped stage/contract coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.md` — completed `R14` task tree for transaction port/binding coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.md` — completed `R14` task tree for report metadata coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.md` — completed `R14` task tree for downstream issue-bundle coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.md` — completed `R14` task tree for `.isf` CLI example coverage in the ISF book feature matrix.
- `docs/tasks/ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.md` — completed `R14` task tree for exactly-one-missing-part `assemble` width inference.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-CONSTANTS.md` — completed `R14` task tree for actor-constant zero divisor rejection in shipped ISF runtime expression contexts.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-SAFETY.md` — completed `R14` task tree for literal-zero divisor rejection in shipped ISF runtime expression contexts.
- `docs/tasks/ISF-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing stale ISF feature-backlog status text.
- `docs/tasks/ISF-RESOURCE-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing resource arbitration and storage-role backlog status text.
- `docs/tasks/ISF-FEATURE-BACKLOG-STATUS-SYNC.md` — completed `R14` task tree for synchronizing stale ISF feature-backlog status labels after closed task trees.
- `docs/tasks/ISF-GENERATED-NAME-POLICY.md` — completed `R14` task tree for generated-name stability policy in schedule reports and generated artifacts.
- `docs/tasks/ISF-SCHEDULE-REPORT-SCHEMA-VERSION.md` — completed `R14` task tree for report-level schedule JSON schema-version metadata.
- `docs/tasks/ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.md` — completed `R14` task tree for schedule-report additive/deprecation evolution policy.
- `docs/tasks/ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.md` — completed `R14` task tree for schedule-report assignment provenance and multi-file child summary boundary.
- `docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md` — completed `R14` task tree for the executable schedule-report golden fixture matrix.
- `docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md` — completed `R14` task tree for freezing schedule JSON schema version 1.
- `docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md` — completed `R14` task tree for actor constants in activation parameter overrides.
- `docs/tasks/ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing removed `(assign ...)` diagnostic truth.
- `docs/tasks/ISF-SPEC-TEST-INDEX-SYNC.md` — completed `R14` task tree for keeping the ISF spec focused-test index synchronized.
- `docs/tasks/DOWNSTREAM-ISSUE-REPRO-FLOW.md` — completed `R14` task tree for downstream reproducible issue-reporting flow.
- `docs/tasks/ISF-ACTOR-PHASE-STAGE-REPORTS.md` — completed `R14` task tree for actor-level phase/stage schedule-report metadata.
- `docs/tasks/ISF-ACTOR-PARAM-REPORTS.md` — completed `R14` task tree for actor-level parameter default schedule-report metadata.
- `docs/tasks/ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.md` — completed `R14` task tree for exactly-one-missing-field `extract` width inference.
- `docs/tasks/ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.md` — completed `R14` task tree for positive actor constants in bounded eventual temporal-contract windows.
- `docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md` — completed `R14` task tree for temporal-contract monitor storage schedule-report roles.
- `docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md` — completed `R14` task tree for temporal-contract SystemVerilog assertion projection.
- `docs/tasks/ISF-CDC-FIXTURE-MATRIX.md` — completed `R14` task tree for dual acknowledged-event CDC fixture hardening.
- `docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md` — completed `R14` task tree for ISF enum/type/aggregate parity with existing `.fsm` semantic machinery.
- `docs/tasks/ISF-DYNAMIC-WAIT-STORAGE-REPORTS.md` — completed `R14` task tree for runtime dynamic-wait counter storage schedule-report roles.
- `docs/tasks/ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.md` — completed `R14` task tree for generated activation handoff storage schedule-report roles.
- `docs/tasks/ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.md` — completed `R14` task tree for generated activation start/done handoff storage schedule-report roles.
- `docs/tasks/ISF-TRANSACTION-PORT-STORAGE-REPORTS.md` — completed `R14` task tree for transaction-local port storage schedule-report roles.
- `docs/tasks/ISF-RULE-TRIGGER-STORAGE-REPORTS.md` — completed `R14` task tree for rule-trigger source and payload-source storage schedule-report roles.
- `docs/tasks/FSMGEN-IR-AUDIT.md` — completed architecture task tree for current IR inventory, canonical/private boundary classification, repo-local IR policy, and consolidation follow-up selection.
- `docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md` — completed architecture follow-up that guarded the current direct-root `structural_rtl_ir` projection before future convergence work.
- `docs/tasks/IR-EXPRESSION-AST-OWNERSHIP.md` — completed architecture follow-up for expression representation ownership and conversion boundaries.
- `docs/tasks/EXPR-NAMER-TRACKED-COPY-CLEANUP.md` — completed architecture follow-up that removed the tracked `ExpressionNamer.pm.new` duplicate.
- `docs/tasks/EXPR-AST-UTILS-OWNER-CONSOLIDATION.md` — completed architecture follow-up that collapsed duplicate `FSM::AST::Utils` ownership.
- `docs/tasks/EXPR-NAMER-LEGACY-PARSE-BOUNDARY.md` — completed architecture follow-up for guarding `ExpressionNamer` legacy hash/string parse boundaries.
- `docs/tasks/GLOBAL-AST-MANAGER-BOUNDARY.md` — completed architecture follow-up for resolving legacy `GlobalASTManager` ownership.
- `docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md` — completed architecture follow-up that inventoried private ISF `LoweringIR` subfamilies and deferred helper-owner extraction.
- `docs/tasks/MODULE-INFO-PROJECTION-GUARD.md` — completed architecture follow-up that audited `module_info` mirrors and closed without extra guard work.
- `docs/tasks/ROADMAP-ACTIVE-LANE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for repairing stale live-roadmap active-lane/frontier claims.
- `docs/tasks/R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for composition parser token and top-symbol diagnostics.
- `docs/tasks/R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for composition endpoint-shape diagnostics.
- `docs/tasks/R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for C1 passthrough exposure diagnostics.
- `docs/tasks/R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for missing explicit composition wiring diagnostics.
- `docs/tasks/R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for unsupported composition backend target diagnostics.
- `docs/tasks/R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for composition ports shape-gate diagnostics.
- `docs/tasks/R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for duplicate composition declaration diagnostics.
- `docs/tasks/R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for unsupported composition child-kind and legacy ports-mapping diagnostics.
- `docs/tasks/R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for malformed composition child-entry structure.
- `docs/tasks/R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for malformed external RTL child source count and payload shape.
- `docs/tasks/R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for malformed generated-child source count and payload shape.
- `docs/tasks/R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported standalone DTC explicit-system auto-wiring corpus coverage.
- `docs/tasks/R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for wrong-kind generated-child source realization.
- `docs/tasks/R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported standalone DT explicit-system corpus coverage.
- `docs/tasks/R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported implicit composition system-port auto-wiring corpus coverage.
- `docs/tasks/R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported direct implicit system defaults corpus coverage.
- `docs/tasks/R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported custom system clock corpus coverage.
- `docs/tasks/R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported compound update variant corpus coverage.
- `docs/tasks/R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported nested and compound guard corpus coverage.
- `docs/tasks/R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported arithmetic and XOR operator corpus coverage.
- `docs/tasks/R12-RESET-STATE-ALIAS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported reset-state alias corpus coverage.
- `docs/tasks/R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.md` — completed `R9` task tree for strict-mode rejection of the legacy `<=+` assignment alias.
- `docs/tasks/R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported RHS expression variant corpus coverage.
- `docs/tasks/R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported computed comparison selector corpus coverage.
- `docs/tasks/R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported symbolic/default test-selector corpus coverage.
- `docs/tasks/R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported plain test-signal corpus coverage.
- `docs/tasks/R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported standalone DT guard corpus coverage.
- `docs/tasks/R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported relational test-branch selector corpus coverage.
- `docs/tasks/R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported computed test-selector corpus coverage.
- `docs/tasks/R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported relational-operator corpus coverage.
- `docs/tasks/R12-GUARD-SHORTHAND-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported guard-shorthand corpus coverage.
- `docs/tasks/R12-STATE-DTE-GUARD-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported state-DT header guard corpus coverage.
- `docs/tasks/R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported update-shorthand variant corpus coverage.
- `docs/tasks/R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained duplicate default test-selector expected-failure corpus coverage.
- `docs/tasks/R12-TOP-LEVEL-FORM-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained unsupported top-level form expected-failure corpus coverage.
- `docs/tasks/R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained delayed-pulse LHS target expected-failure corpus coverage.
- `docs/tasks/R12-PLUS-FSM-BODY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed legacy `+fsm` root-body expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-TOKEN-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained symbol-definition token expected-failure corpus coverage.
- `docs/tasks/R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained aggregate parameter-expression expected-failure corpus coverage.
- `docs/tasks/R12-PARAM-DEPENDENCY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained parameter dependency expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-VALUE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained symbol-definition value expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-ENTRY-MALFORMED-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed symbol-definition entry expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained empty symbol-definition section expected-failure corpus coverage.
- `docs/tasks/R12-INIT-DIRECTIVE-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained `:=` init-directive shape expected-failure corpus coverage.
- `docs/tasks/R12-CONDITION-EXPRESSION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained condition-expression expected-failure corpus coverage.
- `docs/tasks/R12-RHS-EXPRESSION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained RHS expression expected-failure corpus coverage.
- `docs/tasks/R12-FSM-ROOT-BODY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained structured `?fsm` root-body expected-failure corpus coverage.
- `docs/tasks/R12-STATE-BODY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained state/DT body expected-failure corpus coverage.
- `docs/tasks/R12-UPDATE-SHORTHAND-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained update-shorthand expected-failure corpus coverage.
- `docs/tasks/R12-INLINE-MODIFIER-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained inline compound modifier expected-failure corpus coverage.
- `docs/tasks/R12-TEST-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained test-signal/test-selector expected-failure corpus coverage.
- `docs/tasks/R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained authored operator/directive expected-failure corpus coverage.
- `docs/tasks/R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained assignment-boundary expected-failure corpus coverage.
- `docs/tasks/R12-NAME-REFERENCE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained source-name, state/DT-name, and transition-target expected-failure corpus coverage.
- `docs/tasks/R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained language-contract expected-failure corpus coverage.
- `docs/tasks/R12-MALFORMED-FORM-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed-form expected-failure corpus coverage.
- `docs/tasks/R12-SYSTEM-SECTION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed `+system` expected-failure corpus coverage.
- `docs/tasks/R8-PARTIAL-LHS-PULSE-BOUNDARY.md` — completed `R8` task tree for the delayed-pulse partial-LHS fail-closed boundary.
- `docs/tasks/R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.md` — completed `R8` task tree for preferred `<=-` partial-LHS dual-output coverage and the remaining pulse/vector decision split.
- `docs/BIN_FSMGEN_IMPORT_TREE.md` — live `bin/fsmgen` import-tree and runtime-spine architecture snapshot.
- `docs/IR_POLICY.md` — repo-local policy for adding, extending, exposing, or retiring IR and IR-like compiler surfaces.
- `docs/COMPOSITION_SCOPE.md` — concrete composition scope and acceptance boundary for the active architecture.
- `docs/COMPOSITION_LEGACY_MAPPING.md` — historical legacy-composition behavior mapped onto the active architecture.
- `docs/EXTENSION_MODEL.md` — typed extension boundary for the active `R7` replacement path.
- `docs/SPECFORGE_FEEDBACK_RESPONSE.md` — tracked FSMGen response to SPECFORGE adapter/tool-integration feedback.
- `docs/DOWNSTREAM_ISSUE_REPORTING.md` — strict downstream issue-reporting protocol for locally reproducible FSMGen bug reports.
- `docs/INTENT_SCHEDULING_BRAINSTORM.md` — living brainstorm log for inferring/scheduling cycles from a hardware-native intent layer above explicit `.fsm`.
- `docs/ISF_ATL_DESIGN_PROPOSAL.md` — live design proposal for ISF Actor Transfer Level actor-network orchestration.
- `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` — single self-contained downstream `.isf` integration handoff that must stay synchronized with the live spec, book, public contract, manifest metadata, tests, and code.
- `docs/ISF_SPEC.md` — active R14 `.isf` Intent Scheduling Format specification.
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` — live downstream-consumer API contract for ISF parser/scheduler surfaces.
- `docs/ISF_LIBRARY_CATALOG.md` — live catalog of shipped reusable ISF library definitions.
- `docs/REGRESSION_CORPUS.md` — human-readable companion to the machine-checked support and regression catalog.
- `docs/INTENT_CAPTURE_AXI_CASE_STUDY.md` — AXI intent-capture case-study notes for future high-level synthesis work.
- `docs/FEATURE_BACKLOG.md` — repo-level pointer to the canonical mdBook backlog for deferred/not-fully-shipped user-visible features.
- `docs/VHDL_SCOPE.md` — scoped VHDL backend plan preserved for future horizon H5 reference.
- `CHANGES.md` — persistent technical change history.
- `DEVELOPMENT_NOTES.md` — architecture notes and engineering rationale.
- `MEMORY.md` — live continuity context and recovery notes.
- `LIVE_ACHIEVEMENT_STATUS.md` — latest completed roadmap-aligned slice for fast recovery.
- `COMMIT.md` — canonical commit workflow specification.
- `WARP.md` — project guidance for Warp/agent workflows.
- `.agents/workflows/commit.md` — agent workflow definition for commit operations.
- `.github/workflows/README.md` — active hosted CI and GitHub Pages workflow overview.

## Project file and directory map
### Core entrypoints and pipeline
- `bin/fsmgen` — main CLI entrypoint.
- `bin/fsmgen-issue-bundle` — downstream issue-bundle helper that captures
  reproducible FSMGen command artifacts for local triage.
- `perl/FSM/Adapter/ISF.pm` — `.isf` parser facade for intent-scheduling sources.
- `perl/FSM/Scheduler/ISF.pm` — `.isf` lowering facade that emits scheduled `.fsm` and schedule JSON reports.
- `perl/FSM/Scheduler/ISF/LoweringIR.pm` — typed lowering IR builder for `.isf` actors, transactions, drives, control flow, and spawned children.
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm` — scheduled `.fsm` emitter for `.isf` lowering results.
- `perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm` — generated `?top` emitter for ISF spawned-child parent/child handoff.
- `perl/FSM/Scheduler/ISF/Emitter/JSON.pm` — machine-readable schedule-report emitter for `.isf` lowering results.
- `perl/FSM/Pipeline/HDLGenerator.pm` — thin public generation facade around source/direct/composition orchestrators.
- `perl/FSM/Composition/Net.pm` — typed internal net plan for multi-child composition wiring.
- `perl/FSM/Composition/Parser.pm` — first typed composition parser/IR boundary.
- `perl/FSM/Composition/Plan.pm` — typed realized top-planning object for active composition work.
- `perl/FSM/Composition/RTLInterfaceLoader.pm` — sidecar external-RTL interface loader for the shipped `C3` composition lane.
- `perl/FSM/Extension/Loader.pm` — explicit typed extension-module loader for the active `R7` replacement seam.
- `perl/FSM/Extension/Registry.pm` — typed extension registry for the active `R7` replacement seam.
- `perl/FSM/Extension/Context.pm` — typed hook context object passed to active extensions.
- `perl/FSM/Support/CapabilityManifest.pm` — machine-readable capability manifest builder for downstream tool integration.
- `perl/FSM/Support/CapabilityManifestContract.pm` — bounded top-level capability-manifest shell contract advertised through the manifest itself.
- `perl/FSM/Support/DiagnosticsContract.pm` — bounded manifest-facing contract for the `diagnostics` section's public top-level and stable-code entry families.
- `perl/FSM/Support/EmbeddingContract.pm` — bounded manifest-facing contract for the `embedding` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/BackendValidationContract.pm` — bounded manifest-facing contract for the `backend_validation` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/DocumentationContract.pm` — bounded manifest-facing contract for the `documentation` section's public path-list keys.
- `perl/FSM/Support/LanguageSurfaceContract.pm` — bounded manifest-facing contract for the `language_surface` section's public top-level and first nested key lists.
- `perl/FSM/Support/ProducerContract.pm` — bounded manifest-facing contract for the `producer` section's public identity/build metadata keys.
- `perl/FSM/Support/SemanticExportsContract.pm` — bounded manifest-facing contract for the `semantic_exports` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/CheckDiagnostics.pm` — bounded `--check --json` report builder and stable-code classifier.
- `perl/FSM/Support/CheckDiagnosticsContract.pm` — bounded `--check --json` key-presence contract advertised through the capability manifest.
- `perl/FSM/Support/CheckFailureDiagnosticContract.pm` — shared bounded nested-object contract for failure `diagnostic` payloads in public check JSON and normalized semantic JSON.
- `perl/FSM/Support/CheckResultContract.pm` — bounded nested-object contract for successful public check JSON `result` payloads.
- `perl/FSM/Support/CompositionReportContract.pm` — bounded sanitized composition provenance/report contract for semantic JSON.
- `perl/FSM/Support/NormalizedSemanticCompositionContract.pm` — bounded nested-object contract for the `semantic.composition` summary in successful public normalized semantic JSON composition sources.
- `perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm` — bounded nested-object contract for the `semantic.explicit_system_contract` summary in successful public normalized semantic JSON when that authored explicit contract is preserved.
- `perl/FSM/Support/NormalizedSemanticForwardIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.lowered_rtl_ir` summary in successful public normalized semantic JSON, including its composition-only extension keys.
- `perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.structural_rtl_ir` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.intent_hir` summary in successful public normalized semantic JSON, including its composition-only extension keys.
- `perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm` — bounded nested-object contract for the `semantic.signal_analysis` summary in successful public normalized semantic JSON, including the shared core signal-entry keys.
- `perl/FSM/Support/NormalizedSemanticSystemContract.pm` — bounded nested-object contract for the `semantic.system_contract` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticSymbolContract.pm` — bounded nested-object contract for the optional `semantic.symbol_contract` summary in successful public normalized semantic JSON symbol-rich sources.
- `perl/FSM/Support/NormalizedSemanticModuleContract.pm` — bounded nested-object contract for the `semantic.module` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticPayloadContract.pm` — bounded nested-object contract for successful public normalized semantic JSON `semantic` payloads.
- `perl/FSM/Support/DiagnosticCodes.pm` — stable diagnostic-code registry consumed by support accounting and the capability manifest.
- `perl/FSM/Support/DiagnosticCodeRegistryContract.pm` — bounded stable-code registry contract advertised through the capability manifest.
- `perl/FSM/Support/DebugRuntimeContract.pm` — bounded in-process debug save/restore/scoped runtime contract advertised through `embedding.debug_runtime`.
- `perl/FSM/Support/ExtensionContract.pm` — bounded typed-extension/context contract advertised to embedders through the capability manifest.
- `perl/FSM/Support/HDLGeneratorFacadeContract.pm` — bounded public in-process `HDLGenerator` constructor/generation facade contract advertised through `embedding.hdl_generator_facade`.
- `perl/FSM/Support/ISFPublicInterfaceContract.pm` — bounded public ISF parser/scheduler facade and schedule-report contract advertised through `embedding.isf_public_interface`.
- `perl/FSM/Support/ISFResourceCatalog.pm` — shared ISF resource-kind registry consumed by the parser and public contract, including current arbiters, shareable resource kinds, shipped/backlog status, and meaning text.
- `perl/FSM/Support/HDLGeneratorModuleInfoContract.pm` — bounded nested-object contract for `HDLGenerator` `module_info` identity plus direct/composition scalar summary subsurfaces.
- `perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `composition_plan` branch plus its sanitized composition-summary fallback surfaces.
- `perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `composition_spec` branch plus its sanitized composition-summary fallback surfaces.
- `perl/FSM/Support/HDLGeneratorFSMModuleContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `fsm_module` CoreAST branch plus its semantic-summary fallback surfaces.
- `perl/FSM/Support/HDLGeneratorRawASTContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `raw_ast` parser/debug branch plus its semantic-summary fallback surface.
- `perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `resolved_package_imports` package-spec map plus its stable package-import summary surface.
- `perl/FSM/Support/HDLGeneratorStatisticsContract.pm` — bounded nested-object contract for `HDLGenerator` `statistics` direct/composition scalar summary subsurfaces.
- `perl/FSM/Support/HDLGeneratorSourceInfoContract.pm` — bounded nested-object contract for `HDLGenerator` `source_info` identity and package-import summary subsurfaces.
- `perl/FSM/Support/HDLGeneratorResultContract.pm` — bounded top-level result contract plus delegated nested `source_info`/`module_info`/`statistics` owners, delegated shell-only `composition_plan`/`composition_spec`/`fsm_module`/`raw_ast`/`resolved_package_imports` owners, advertised stable subsurfaces for `source_info`/`module_info`/`statistics` rather than whole-hash promises, an explicitly raw `composition_report` compatibility branch, and reused semantic-layer shell contracts rather than separate whole-hash promises for in-process `HDLGenerator` embedders.
- `perl/FSM/Support/SerializablePlanReportContract.pm` — bounded `embedding.serializable_plan_reports` contract that advertises JSON-safe plan/report surfaces and raw `HDLGenerator` shell replacement guidance for embedders.
- `perl/FSM/Support/SerializableCompositionPlanSnapshot.pm` — JSON-safe bounded composition-plan snapshot builder/contract for embedders that need plan summaries without traversing raw `FSM::Composition::Plan` objects.
- `perl/FSM/Support/SerializableGenerationResultSnapshot.pm` — JSON-safe bounded `HDLGenerator` result snapshot builder/contract for embedders that need result summaries without exporting raw compatibility-shell objects.
- `perl/FSM/Support/SerializableDiagnosticSummary.pm` — JSON-safe bounded diagnostic summary builder/contract for stable diagnostic code/count inspection across public reports.
- `perl/FSM/Support/HDLExternalValidation.pm` — optional Verilator/Yosys validation lane for generated SystemVerilog.
- `perl/FSM/Support/HDLExternalValidationContract.pm` — bounded external validation contract advertised through the capability manifest.
- `perl/FSM/Support/NormalizedSemanticReport.pm` — bounded normalized semantic JSON report builder for downstream tool integration.
- `perl/FSM/Support/NormalizedSemanticReportContract.pm` — bounded normalized semantic JSON key-presence contract advertised through the capability manifest.
- `perl/FSM/Support/ReportGeneratedOutputContract.pm` — shared bounded nested-object contract for public `generated_output` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/ReportCommandContract.pm` — shared bounded nested-object contract for public `command` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/ReportProducerContract.pm` — shared bounded nested-object contract for public `producer` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/ReportSourceContract.pm` — shared bounded nested-object contract for public `source` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/SupportAccountingMatchContract.pm` — shared bounded nested-object contract for public support-accounting match payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/SupportAccountingContract.pm` — bounded support-accounting section contract advertised through the capability manifest.
- `perl/FSM/Support/RegressionCorpus.pm` — production support-accounting catalog owner consumed by the manifest and regression tests.
- `perl/FSM/SourceClassifier.pm` — top-level source-kind classification for FSM vs composition inputs.
- `perl/FSM/Adapter/FSMGenFull.pm` — FSM adapter/parsing entry.
- `perl/FSM/HDL/FlattenedDT.pm` — Flattened decision-tree facade.
- `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm` — live direct SystemVerilog post-flattening assembly owner.
- `perl/FSM/Package/IntegerLiteralSupport.pm` — shared `.fsm` integer-literal interpreter and target-HDL normalizer for decimal, based, prefixed, and intent-level sized spellings such as `5'23`, `8'-10`, and `20'x1`.
- `perl/FSM/Synthesis/EnableGraph.pm` — enable synthesis/helper ownership.

### Input, tests, and support
- `fsm/` — sample/input `.fsm` files.
- `t/` — regression and behavior tests.
- `docs/` — user and technical docs.
- `generated/` — generated parser/output artifacts.
- `grammars/` — grammar definitions.
- `rust/Makefile` — makefile used for rust-side build/management tasks.

## Quick start
```bash
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen --output /tmp/trial_0.sv fsm/trial_0.fsm
./bin/fsmgen --debug=3 fsm/lte_dif_pmaster.fsm
./bin/fsmgen --verify-hdl --output /tmp/lte_dif_pmaster.sv fsm/lte_dif_pmaster.fsm
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --emit-schedule-json isf/i2c_master.isf
```

## Documentation quick preview
```bash
mdbook build docs/book
cd docs/book && mdbook serve
```
- The mdBook is the progressive learning surface.
- `docs/USER_GUIDE.md` remains the broad live reference while that split is still in progress.
- GitHub Pages publishes the same mdBook from `docs/book` through the active
  workflow in `.github/workflows/pages.yml` when the repository's Pages source
  is set to GitHub Actions.

## Local CI / pre-push regression
```bash
./bin/ci-regression quick
./bin/ci-regression smoke
./bin/ci-regression isf
./bin/ci-regression
./bin/ci-regression --list
```
- `bin/ci-regression` is the repo-owned local regression entrypoint.
- The script resolves the repository root itself, so you can invoke it without depending on your current working directory.
- It supports explicit turnaround tiers:
  - `quick`: curated smoke set across direct `.fsm`, composition
    classification, one composition child path, ISF parse/schedule, and the
    ISF public contract.
  - `smoke`: alias for `quick`, provided for the fast basic-functionality
    check described by the tier.
  - `isf`: all ISF-focused tests in the current 109x, 11xx, 12xx, and 13xx
    numbered bands.
  - `full`: the complete Perl regression suite with `prove -I perl t`.
- With no mode argument it runs `full`, preserving the historical pre-push
  gate behavior.
- It also builds the mdBook with `mdbook build docs/book` by default, so the
  user-facing book stays under the same local quality gate; use `--no-book`
  only for a deliberately code-only local turnaround check.
- When `verilator` and `yosys` are installed, the external SystemVerilog validation smoke runs too; otherwise that test is skipped.
- GitHub Actions is active again under [.github/workflows/](.github/workflows/).
  The hosted regression workflow calls `./bin/ci-regression`, so the local and
  GitHub quality gates use the same repo-owned entrypoint.
- Hosted CI uses a minimal Perl setup. Ordinary runtime paths should not rely
  on undeclared local CPAN modules, and CLI report modes tested for clean
  stderr must remain compatible with the hosted Perl version.

## CLI quick reference
```bash
./bin/fsmgen [options] <fsm_file_or_isf_file>
```
- `-o, --output <file>`: explicit output path.
- `--outdir <dir>`: write every scheduled `.fsm` file produced from a multi-file `.isf` lowering.
- `-l, --language <systemverilog|sv|verilog|v|vhdl>`: target language.
- `-d, --debug[=N]`: numeric debug compatibility level (`0..4`; bare `--debug` implies `4`).
- `--trace-verbosity <none|low|medium|high|debug>`: named trace verbosity.
- `--trace-log[=FILE]`: trace output file (default `trace.log`).
- `--trace-emojis` / `--notrace-emojis`: emoji marker toggle.
- `--extension-module <Module::Name>`: load an explicit typed extension module from `@INC` (may be repeated).
- `--extension-config <file>`: load typed extension modules from an explicit config file (may be repeated).
- `--capability-manifest`: print the versioned JSON FSMGen capability manifest and exit.
- `--check --json`: run the full pipeline as a check, emit JSON diagnostics, and do not write HDL.
- `--emit-semantic-json`: run the full pipeline, emit bounded normalized semantic JSON, and do not write HDL.
- `--emit-schedule-json`: for `.isf` input, emit the scheduler's JSON report and exit before HDL generation.
- `--verify-hdl`: after writing generated SystemVerilog, run Verilator lint and ABC-free Yosys structural synthesis.
- `-q, --quiet`: suppress informational output.

Inputs ending in `.isf` are parsed by the intent scheduler, lowered to one or
more explicit `.fsm` sources, and then fed through the normal `.fsm` pipeline
unless `--emit-schedule-json` is requested.
For `.isf` inputs, `--check --json` and `--check-json` emit structured
`success: false` JSON for parser, lowering, report-building, and downstream
semantic check failures instead of leaving stdout empty.

The bounded machine-readable surfaces are backed by support accounting:
`--check --json` is corpus-covered across supported, strict-supported, and
expected-failure entries, while `--emit-semantic-json` is corpus-covered across
current supported, strict-supported, and expected-failure entries.
Those two public JSON/report surfaces now also share one bounded nested-object
owner for their `support_accounting` match payloads:
[perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`producer` object owner for FSMGen identity plus the report builder owner:
[perl/FSM/Support/ReportProducerContract.pm](perl/FSM/Support/ReportProducerContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`source` object owner for the caller-facing input string and resolved source
path:
[perl/FSM/Support/ReportSourceContract.pm](perl/FSM/Support/ReportSourceContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`command` object owner for invocation metadata such as `mode`, `json`,
`strict_mode`, and `target_language`:
[perl/FSM/Support/ReportCommandContract.pm](perl/FSM/Support/ReportCommandContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`generated_output` object owner for whether the report invocation emitted HDL
artifacts:
[perl/FSM/Support/ReportGeneratedOutputContract.pm](perl/FSM/Support/ReportGeneratedOutputContract.pm).
Successful public check JSON reports now also have one bounded nested `result`
object owner for module identity plus basic summary counts:
[perl/FSM/Support/CheckResultContract.pm](perl/FSM/Support/CheckResultContract.pm).
Failed public check JSON reports now also have one bounded nested `diagnostic`
object owner for the core stable diagnostic fields, matched-only corpus keys,
optional extracted artifact paths, and nested support-accounting metadata:
[perl/FSM/Support/CheckFailureDiagnosticContract.pm](perl/FSM/Support/CheckFailureDiagnosticContract.pm).
Failed public normalized semantic JSON reports now explicitly reuse that same
bounded nested `diagnostic` owner too.
Successful public normalized semantic JSON reports now also have one bounded
nested `semantic` object owner for module/system metadata, signal analysis,
and the forward-IR projection:
[perl/FSM/Support/NormalizedSemanticPayloadContract.pm](perl/FSM/Support/NormalizedSemanticPayloadContract.pm).
The nested `semantic.system_contract` summary inside that payload now also has
its own bounded owner for the explicit clock/reset contract keys emitted today:
[perl/FSM/Support/NormalizedSemanticSystemContract.pm](perl/FSM/Support/NormalizedSemanticSystemContract.pm).
The nested `semantic.explicit_system_contract` summary inside that payload now
also has its own bounded owner when the authored explicit contract is
preserved:
[perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm](perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm).
The nested `semantic.signal_analysis` summary inside that payload now also has
its own bounded owner for the current sanitized signal families plus the shared
core signal-entry keys emitted across direct and composition roots:
[perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm](perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm).
The nested `semantic.forward_ir` summary inside that payload now also has its
own bounded owner for the current sanitized forward semantic projections:
[perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](perl/FSM/Support/NormalizedSemanticForwardIRContract.pm).
The nested `semantic.forward_ir.lowered_rtl_ir` summary inside that branch now
also has its own bounded owner for the current lowered-RTL shell plus the
current composition-only extension keys:
[perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm).
The nested `semantic.forward_ir.structural_rtl_ir` summary inside that branch
now also has its own bounded owner for the current structural-RTL shell:
[perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm).
The nested `semantic.forward_ir.intent_hir` summary inside that branch now
also has its own bounded owner for the current intent-hir shell plus the
current composition-only extension keys:
[perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm).
The optional `semantic.symbol_contract` summary inside that payload now also
has its own bounded owner for symbol-rich sources:
[perl/FSM/Support/NormalizedSemanticSymbolContract.pm](perl/FSM/Support/NormalizedSemanticSymbolContract.pm).
The nested `semantic.module` summary inside that payload now also has its own
bounded owner for the core module keys plus the current optional metric-key
family:
[perl/FSM/Support/NormalizedSemanticModuleContract.pm](perl/FSM/Support/NormalizedSemanticModuleContract.pm).
The nested `semantic.composition` summary inside that payload now also has its
own bounded owner for composition sources:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm).
The manifest-facing stable diagnostic-code registry now has its own explicit
bounded contract owner in
[perl/FSM/Support/DiagnosticCodeRegistryContract.pm](perl/FSM/Support/DiagnosticCodeRegistryContract.pm),
so downstream tools can discover the public diagnostics sibling keys and stable
entry keys without treating the whole diagnostics tree as frozen.
The capability manifest shell now has that same explicit split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
builds the JSON, while
[perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm)
owns the bounded top-level and first nested section key lists advertised under
`manifest_contract`.
That shell contract now explicitly includes the first nested
`support_accounting` key list too, so machine consumers do not have to
special-case the corpus-backed section while discovering the current bounded
manifest shape.
The manifest's `support_accounting` section now also advertises that same
bounded owner through `support_accounting.section_contract`, while keeping the
existing inline support-accounting payload and catalog metadata in place for
compatibility.
The manifest's `embedding` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current in-process embedding surfaces, while
[perl/FSM/Support/EmbeddingContract.pm](perl/FSM/Support/EmbeddingContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`embedding.section_contract` without flattening the whole embedding tree into
one accidental API.
The current embedding children include
`embedding.debug_runtime`, owned by
[perl/FSM/Support/DebugRuntimeContract.pm](perl/FSM/Support/DebugRuntimeContract.pm),
and `embedding.hdl_generator_facade`, owned by
[perl/FSM/Support/HDLGeneratorFacadeContract.pm](perl/FSM/Support/HDLGeneratorFacadeContract.pm),
and `embedding.isf_public_interface`, owned by
[perl/FSM/Support/ISFPublicInterfaceContract.pm](perl/FSM/Support/ISFPublicInterfaceContract.pm),
so callers can discover the shipped in-process runtime/facade boundaries from
the manifest instead of inferring them from Perl implementation files.
The manifest's `diagnostics` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current registry/check surfaces, while
[perl/FSM/Support/DiagnosticsContract.pm](perl/FSM/Support/DiagnosticsContract.pm)
owns the bounded top-level, scalar-string, and stable-code entry families
advertised through `diagnostics.section_contract` without flattening the whole
diagnostics tree into one accidental API.
The manifest's `producer` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current FSMGen identity/build metadata, while
[perl/FSM/Support/ProducerContract.pm](perl/FSM/Support/ProducerContract.pm)
owns the bounded top-level, scalar-string, and boolean field families
advertised through `producer.section_contract`. That keeps tool/build identity
discoverable without pretending this is already a package-manager release API.
The manifest's `semantic_exports` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current bounded semantic interchange surfaces, while
[perl/FSM/Support/SemanticExportsContract.pm](perl/FSM/Support/SemanticExportsContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`semantic_exports.section_contract`. That keeps `normalized_semantic_json`
discoverable without pretending every future semantic export format is already
frozen.
The manifest's `backend_validation` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current backend validation surfaces, while
[perl/FSM/Support/BackendValidationContract.pm](perl/FSM/Support/BackendValidationContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`backend_validation.section_contract`. That keeps
`systemverilog_external` discoverable without pretending every future backend
validation lane is already frozen.
The manifest's `language_surface` section now follows the same pattern:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the authored-surface summary, while
[perl/FSM/Support/LanguageSurfaceContract.pm](perl/FSM/Support/LanguageSurfaceContract.pm)
owns the bounded top-level and first nested section-key lists advertised
through `language_surface.surface_contract` without pretending the whole
authored language is frozen.
The manifest's `documentation` section now has the same split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current doc pointers, while
[perl/FSM/Support/DocumentationContract.pm](perl/FSM/Support/DocumentationContract.pm)
owns the bounded top-level and path-list contract advertised through
`documentation.section_contract` without freezing the exact file lists forever.

## Assignment semantics (quick reference)
- `A <- expr`: synchronous/flopped assignment where `A` names the flop output/Q value.
- `A <= expr`: synchronous/flopped variant where `A` names the D-input/next-value side.
- `A = expr`: combinational assignment.
- Safety rule: combinational `=` cannot create direct/indirect RHS feedback to same LHS.
- Safety rule: D-input-named `<=` / `<=-` cannot read the same LHS name from the RHS or guard; use `<-` for ordinary register feedback. In default mode, legacy `<=+` is accepted as an alias for `<=-`; strict mode rejects `<=+` and points to preferred `<=-`.

## README maintenance policy
- Keep `README.md` as the canonical onboarding hub.
- Update it when any of the following changes materially:
  - project objective/scope,
  - document set or purpose,
  - key file paths / architecture entrypoints,
  - onboarding workflow.
- It does **not** need to be updated on every commit—only when meaningful for onboarding accuracy.

## Fresh session shortcut
For a new engineering session, the preferred one-line instruction is:

```text
Read SESSION_BOOTSTRAP.md and start from there.
```

That startup ritual must still honor the session safety invariant above:
`COMMIT.md` is mandatory, and every completed task, slice, or lane must be committed before the next one starts.
