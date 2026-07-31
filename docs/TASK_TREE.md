# Repo-Local Task Tree Workflow

This document defines the repo-local task-tree workflow used by FSMGen.
It is intentionally portable: another project can copy this file, the
`docs/tasks/TEMPLATE.md` template, and the commit-subject rule, then replace
the roadmap lane names and live-doc file names with local equivalents.

For a step-by-step setup guide that can be reused by another project, read
[docs/TASK_TREE_README.md](docs/TASK_TREE_README.md).

## Purpose

Use a task tree when a top-level task is too broad to finish safely as one
signoff-level slice, or when a task is expected to discover subtasks and
sub-subtasks over time.

The goal is not to create a second roadmap. The roadmap states the high-level
workstream direction. A task tree owns the recursive breakdown, current
frontier, acceptance criteria, blockers, decisions, validation, and completion
evidence for one top-level task.

## Mandatory Task-Tree Gate For Code Changes

No code, test, source, generated-artifact, or config change may begin without
task-tree ownership already in place.

Before implementation starts:

- Attach the work to an existing active task-tree leaf, or create the smallest
  honest `docs/tasks/*.md` tree or leaf from
  [docs/tasks/TEMPLATE.md](docs/tasks/TEMPLATE.md).
- Record enough acceptance criteria and verification scope that the slice can
  be reviewed and recovered after a crash.
- If the work is too small for a multi-leaf breakdown, create a one-leaf tree
  or attach it to a clearly matching existing leaf before changing code.
- Do not treat proposed backlog text as implementation permission. Activate
  or select the owning leaf first.

Documentation-only workflow repairs may update these docs directly, but any
future behavior-bearing implementation still has to pass this task-tree gate
first.

## Active Task Trees

Only rows marked `active` are PNT-eligible. Completed and deferred tree
chronology is query-first through the bounded archive described below.

| Tree | Status | Roadmap lane | Current frontier | File |
| --- | --- | --- | --- | --- |
| `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION` | `active` | `infra/continuity / project-wide live-document lifecycle` | `.14` publishes the detailed external review packet and response template; `.15` owns common JSONL self-bounds/hard semantics, `.16` owns the utility/retirement audit, and `.8` remains the next family migration | [docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md](docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md) |
| `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE` | `active` | `Verification code generation / intent architecture` | `.3` ships bounded VIAL semantics; `.5` the review-routed bridge; `.7.3` the private deterministic plan; `.8` selects public tooling; decision `0043` and completed `.9` select static plain-SV lowering, inactive-edge scheduling, declared-probe adapters, closed trace/results, and exact Verilator 5.046 known-value qualification; completed `.10.1` ships public capabilities/check/canonical normal-terse formatting through one defensive source-only CLI/API, and clean commit `50a0d7d39` activates `.10.2` for planning/artifacts before backend/runtime children; decision `0034` keeps VIAL non-synthesis-bounded | [docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md](docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md) |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER` | `active` | `IAL2 / SV-backed feature completeness` | completed `.844` selected HIAL/VIAL `.1`; child `.1` selected architecture under decision `0032`, and child `.2` now selects proposed bounded VIAL parser/SemanticIR implementation `.3` under decision `0033` | [docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md) |

## Proposed Task Trees

Proposed trees record accepted backlog direction, but they are not
PNT-eligible until explicitly activated or until the roadmap selects that lane.

| Tree | Status | Roadmap lane | Proposed first leaf | File |
| --- | --- | --- | --- | --- |
| `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW` | `proposed` | `infra/continuity / project-document lifecycle` | `.2` complete: decision 0025 now makes `CHANGES.md` per-slice and `DEVELOPMENT_NOTES.md` conditional while leaving both status files untouched; proposed `.1` retains the later four-file lifecycle review | [docs/tasks/PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.md](docs/tasks/PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.md) |
| `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC` | `proposed` | `test integrity / generated HDL expression simplification` | `.1` is pending after the current dirty VIAL slice: classify and repair six stale unary-expression oracles exposed as 24/613 default plus 24/614 strict t261 failures | [docs/tasks/SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC.md](docs/tasks/SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC.md) |
| `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT` | `proposed` | `test integrity / IAL2 PPIF support accounting` | `.1` is pending after the current dirty VIAL slice: t296 conflates in-memory generated entry modules with public CLI aggregate tops across PPIF sources | [docs/tasks/SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.md](docs/tasks/SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.md) |
| `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC` | `proposed` | `test integrity / capability-manifest discovery` | `.1` is pending after the current dirty VIAL slice: t370 proves the HEAD discovery list omits live verification-output guidance and JSON-safety keys; repair stays separate from bridge behavior | [docs/tasks/CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.md](docs/tasks/CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.md) |
| `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` | `proposed` | `IAL2 horizon exploration / authoring ergonomics` | remains proposed behind the selected source-facing HIR boundary; `.1` must not assume direct IAL emission before HIR selection | [docs/tasks/IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.md](docs/tasks/IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.md) |
| `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` | `proposed` | `infra/continuity` | `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.1` select the corrected macOS availability formula (guard counts reclaimable inactive/purgeable as available); needs director approval to change the safety guard | [docs/tasks/AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.md](docs/tasks/AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.md) |
| `FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY` | `proposed` | `performance/scalability / end-to-end design capacity` | `.841` selects the narrower source-facing HIR boundary first; `.1` still owns measurable big/really-big workload, correctness-oracle, resource-profile, budget, graceful-failure, and regression-gate selection before any capacity claim | [docs/tasks/FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.md](docs/tasks/FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.md) |
| `SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON` | `proposed` | `Embedding And Public APIs / AI integration` | `SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.1` select the smallest safe beyond-read-only MCP capability (write/generation tool, sampling, elicitation, roots, or service transport) and its trust/opt-in boundary before any implementation | [docs/tasks/SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.md](docs/tasks/SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.md) |
| `IAL2-T1436-PREEXISTING-FAILURES` | `proposed` | `infra / test + HDL-quality hygiene` | Discovered while verifying `.4`: 5 pre-existing `t/1436` failures, proven unrelated to the AW-driver change (commit `21bdd0947` touched neither the failing code nor tests). (1) stale APB cardinality diagnostic regex (`t/1436` ~:3686 vs the extended message at `PPIF.pm:459`/`:245`) — trivial test fix; (2) `WIDTHTRUNC` verilator lint in generated `axi0_capacity_status` SV (`!` on a 3-bit concat in the equality-to-zero lowering, `AxiManagerCapacityStatus.pm`) — real generator fix. Needs director prioritization | [docs/tasks/IAL2-T1436-PREEXISTING-FAILURES.md](docs/tasks/IAL2-T1436-PREEXISTING-FAILURES.md) |
| `IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON` | `proposed` | `IAL2 / architecture horizon / transaction layer + role composition` | Director thinking-aloud future North Star (explicitly **no pivot**, decision `0020`): grow the IAL2 protocol layer into a layered protocol-agnostic transactor — a `write`/`read` (single or burst) transaction interface upward, primitive per-(protocol,role) bus-adapter role blocks (AXI manager/subordinate, AHB requester/subordinate, APB requester/completer), composed into higher-order IAL2 entities that present the interface up the stack and let sibling sub-blocks interact through it (bridges/converters). Seed: the AHB requester `local-command`/`local-status` is an embryonic transaction port; the AXI AW driver (`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.4`) is the first bus-side primitive. Not PNT-eligible until director-activated | [docs/tasks/IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON.md](docs/tasks/IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON.md) |
| `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE` | `proposed` | `roadmap/documentation alignment / IAL2 mdBook` | `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.1` audit the IAL2 mdBook coherence + AXI coverage gap (AXI ships 142 `.ppif` sources but `16a` documents ~4%; the one-language/per-protocol-profile/optional-alias/layered-lowering model per decisions 0014/0015/0016 is under-conveyed) and select the bounded backfill plan; documentation-only, director-activated | [docs/tasks/IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.md](docs/tasks/IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.md) |

## Completed Task Trees

Completed, deferred, and superseded cross-tree rows are exact, query-first
history rather than an append-only live table. The task files remain directly
addressable under `docs/tasks/`; the former 540-row index is sealed at the
exact version object declared here:

- Completed-history manifest: `doctrine/task_tree/index_archives.jsonl`

```bash
# Locate a current task file by stable tree ID, including legacy task formats.
rg -l 'TREE-ID' docs/tasks/*.md

# Inspect the exact former cross-tree row or the whole sealed index.
git show 44b5f159789ba1c31b487c6b047097bb27a9770d:docs/TASK_TREE.md | rg 'TREE-ID'
git show 44b5f159789ba1c31b487c6b047097bb27a9770d:docs/TASK_TREE.md
```

The task-tree integrity doctrine retrieves and digest-checks that snapshot,
proves all 540 archived rows have unique terminal IDs and safe task-file links,
and keeps PNT selection confined to the live active table above.

## R14 ISF Objective Coverage

All currently documented ongoing or unresolved R14 ISF objective families have
task-tree ownership. Already-shipped base objectives such as parsing `.isf`
actors, lowering through `LoweringIR`, emitting scheduled `.fsm`, schedule JSON
emission, and HDL handoff remain recorded by the completed task nodes and git
history unless a future task reopens them.

| ISF objective family | Owning tree |
| --- | --- |
| Same-cycle output conflicts, fan-in, and fail-closed drive policy | `ISF-CONFLICTS` |
| Generated-child top instantiation, spawn parameter binding, and generated blocking `do` activations | `ISF-COMPOSITION`, `ISF-TRANSACTION-ACTIVATION` |
| Resource arbitration and priority enforcement | `ISF-RESOURCE-PRIORITY` |
| Shareable resource kind catalog and public resource registry | `ISF-RESOURCE-CATALOG` |
| Expression-valued rule assignments and rule action widening | `ISF-RULE-ACTIONS` |
| Transaction stage lowering and temporal contract lowering | `ISF-STAGES-CONTRACTS` |
| Temporal-contract actor-constant window counts | `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS` |
| Temporal-contract actor-scalar-parameter window counts | `ISF-CONTRACT-ACTOR-PARAM-WINDOWS` |
| Temporal-contract qualified package scalar-constant window counts | `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS` |
| Temporal-contract generated child same-transaction scalar parameter window counts | `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS` |
| Temporal-contract direct transaction same-transaction scalar parameter window counts | `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS` |
| Activation-site override diagnostics for generated child temporal contract-window parameters | `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS` |
| Same-value activation-site overrides for generated child temporal contract-window parameters | `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE` |
| Activation-site override gates for generated child static timing parameters | `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES` |
| Transaction latency actor-constant min/max bounds | `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS` |
| Transaction latency actor-scalar-parameter min/max bounds | `ISF-LATENCY-ACTOR-PARAM-BOUNDS` |
| Transaction latency qualified package scalar-constant min/max bounds | `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS` |
| Actor top-level interface actor-constant widths | `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS` |
| Actor top-level interface actor-scalar-parameter widths | `ISF-INTERFACE-ACTOR-PARAM-WIDTHS` |
| Actor-owned scalar storage actor-constant widths | `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS` |
| Actor-owned scalar storage actor-scalar-parameter widths | `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS` |
| Actor-owned bank storage actor-constant widths | `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS` |
| Actor-owned bank storage actor-scalar-parameter widths | `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS` |
| Actor-owned bank storage actor-constant depths | `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS` |
| Actor-owned bank storage actor-scalar-parameter depths | `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS` |
| Transaction-local port actor-scalar-parameter widths | `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS` |
| Actor-level and await-local watchdog actor-scalar-parameter limits | `ISF-WATCHDOG-ACTOR-PARAM-LIMITS` |
| Actor-level and await-local watchdog qualified package scalar-constant limits | `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS` |
| Transaction repeat actor-scalar-parameter counts | `ISF-REPEAT-ACTOR-PARAM-COUNTS` |
| Transaction repeat qualified package scalar-constant counts | `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS` |
| Transaction repeat same-transaction scalar-parameter counts | `ISF-REPEAT-TRANSACTION-PARAM-COUNTS` |
| Temporal-contract monitor storage schedule-report roles | `ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS` |
| Temporal-contract SystemVerilog assertion projection | `ISF-TEMPORAL-CONTRACT-ASSERTIONS` |
| Actor-level phase/stage schedule-report metadata | `ISF-ACTOR-PHASE-STAGE-REPORTS` |
| Actor-level parameter default schedule-report metadata | `ISF-ACTOR-PARAM-REPORTS` |
| Data-operation width inference for shift/extract/assemble families | `ISF-DATA-WIDTHS` |
| Operation-local `shift_left` width evidence | `ISF-SHIFT-LEFT-EXPLICIT-WIDTH` |
| Single-missing-field `extract` width inference | `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE` |
| Single-missing-part `assemble` width inference | `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE` |
| Schedule-report storage classes and schedule JSON stabilization | `ISF-SCHEDULE-REPORTS` |
| Realistic protocol fixtures, strict-mode checks, and end-to-end coverage | `ISF-FIXTURES` |
| Burst-reader realistic fixture promotion | `ISF-BURST-FIXTURE-PROMOTION` |
| UART transmit realistic fixture promotion | `ISF-UART-FIXTURE-PROMOTION` |
| Phase metadata realistic fixture promotion | `ISF-PHASE-FIXTURE-PROMOTION` |
| Switch dispatch realistic fixture promotion | `ISF-SWITCH-FIXTURE-PROMOTION` |
| Conditional `when` realistic fixture promotion | `ISF-WHEN-FIXTURE-PROMOTION` |
| Generated-composition fixture strict/outdir/HDL promotion | `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION` |
| Rule/resource arbitration realistic fixture promotion | `ISF-RULE-RESOURCE-FIXTURE-PROMOTION` |
| Stage/contract realistic fixture promotion | `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION` |
| FIFO controller realistic fixture promotion | `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION` |
| FIFO datapath bank-access realistic fixture promotion | `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION` |
| FIFO reusable-library realistic fixture promotion | `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION` |
| I2C-like realistic fixture promotion | `ISF-I2C-FIXTURE-PROMOTION` |
| Reusable ISF libraries/imports for generic actors and transactions | `ISF-LIBRARIES` |
| Reusable-library clock/reset name remapping inside the single-clock-domain ISF model | `ISF-LIBRARY-SYSTEM-BINDINGS` |
| Reusable-library use-site package scalar constant overrides | `ISF-LIBRARY-USE-PACKAGE-CONSTANTS` |
| Default actor timing conventions for omitted legacy single-clock actor clock/reset/watchdog clauses | `ISF-TIMING-CONVENTIONS` |
| Actor-constant watchdog limits | `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS` |
| Multi-clock, asynchronous, and interacting clock-domain semantics | `ISF-CLOCK-DOMAINS` |
| Multi-clock/CDC fixture matrix hardening | `ISF-CDC-FIXTURE-MATRIX` |
| ISF enum/type/aggregate parity with existing `.fsm` semantic machinery | `ISF-TYPE-AGGREGATE-PARITY` |
| Actor-owned scalar storage source vocabulary | `ISF-STORAGE-VAR-SURFACE`, `ISF-STORAGE-VAR-ALIASES` |
| Transaction ports, activation bindings, and actor top-level pin access | `ISF-PORT-BINDING` |
| Generated-child rule-trigger output bindings | `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS` |
| Expression-valued activation input bindings | `ISF-ACTIVATION-BIND-EXPRESSIONS` |
| Remaining repeat-body child activation widening: `await_any` after generated `do`, new spawn after `do` before drain, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics | `ISF-REPEAT-BODY-CHILD-ACTIVATION` |
| Actor Transfer Level (`ATL`) actor-network orchestration: top-level actor-as-network structure, actor/transaction triggers, event sync, actor-to-actor and pin-to-actor data movement, concurrent actor groups, and network-level scheduling/reporting | `ISF-ACTOR-NETWORK-ORCHESTRATION`, `ISF-ATL-MULTI-EVENT-WAIT` |
| Scalar setter syntax shared by rules and transactions | `ISF-SETTER-SYNTAX` |
| Task-like transaction activation semantics and parameter overrides | `ISF-TRANSACTION-ACTIVATION` |
| Remaining rule-trigger and direct-activation parameter overrides | `ISF-ACTIVATION-PARAM-OVERRIDES` |
| Actor constants as activation parameter override values | `ISF-PARAM-OVERRIDE-CONSTANTS` |
| Removed `(assign ...)` diagnostic truth synchronization | `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC` |
| ISF spec focused-test index synchronization | `ISF-SPEC-TEST-INDEX-SYNC` |
| Self-contained downstream ISF integration handoff | `ISF-DOWNSTREAM-INTEGRATION-SPEC` |
| ISF feature-backlog truth synchronization | `ISF-BACKLOG-TRUTH-SYNC` |
| Resource arbitration and storage-role backlog truth synchronization | `ISF-RESOURCE-BACKLOG-TRUTH-SYNC` |
| ISF feature-backlog status-label truth synchronization after closed task trees | `ISF-FEATURE-BACKLOG-STATUS-SYNC` |
| Generated-name stability policy for schedule reports and generated artifacts | `ISF-GENERATED-NAME-POLICY` |
| Schedule-report schema version metadata | `ISF-SCHEDULE-REPORT-SCHEMA-VERSION` |
| Schedule-report additive/deprecation evolution policy | `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY` |
| Schedule-report assignment provenance and multi-file child summary boundary | `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY` |
| Schedule-report golden fixture matrix | `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX` |
| Schedule-report full-schema stability flag | `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE` |
| Legacy handshake metadata and removed transaction `assign` compatibility | `ISF-COMPATIBILITY` |
| Transaction-local unconditional waits and dynamic loops | `ISF-CONTROL-FLOW`, `ISF-WAIT-ZERO` |
| Actor constants as repeat counter width evidence | `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS` |
| Static zero-count repeat policy | `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY` |
| Non-literal transaction wait counts | `ISF-DYNAMIC-WAIT` |
| Parameter-backed static transaction wait counts | `ISF-PARAM-WAIT-COUNTS` |
| Consecutive runtime wait pending-sample zero-link carrying | `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE` |
| Stage zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-STAGE-SAMPLE` |
| Contract arm zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE` |
| Loop decision zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE` |
| Completion zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE` |
| Independent setter zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE` |
| Independent shift zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE` |
| Independent assemble zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE` |
| Independent extract zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE` |
| Independent bank-load zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE` |
| Independent bank-store zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE` |
| Dynamic divisor safety for runtime expression surfaces | `ISF-DYNAMIC-DIVISOR-SAFETY` |
| Actor-constant zero divisor safety for runtime expression surfaces | `ISF-DYNAMIC-DIVISOR-CONSTANTS` |
| Actor-parameter-zero divisor safety for runtime expression surfaces | `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO` |
| Runtime dynamic-wait counter storage schedule-report roles | `ISF-DYNAMIC-WAIT-STORAGE-REPORTS` |
| Generated activation handoff storage schedule-report roles | `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS` |
| Generated activation start/done handoff storage schedule-report roles | `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS` |
| Transaction-local port storage schedule-report roles | `ISF-TRANSACTION-PORT-STORAGE-REPORTS` |
| Transaction-port binding endpoint-kind schedule-report metadata | `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS` |
| Rule-trigger source and payload-source storage schedule-report roles | `ISF-RULE-TRIGGER-STORAGE-REPORTS` |
| ISF spec, mdBook, public interface contract, and manifest synchronization | `ISF-PUBLIC-CONTRACT` |
| Public ISF live-document manifest discovery for mdBook chapters | `ISF-LIVE-BOOK-DOCUMENT-PATHS` |
| Repeat-body shipped-subset documentation truth synchronization | `ISF-REPEAT-BODY-DOC-TRUTH-SYNC` |
| Book-facing ISF shipped feature matrix | `ISF-MDBOOK-FEATURE-MATRIX` |
| Standalone enum/aggregate rule-guard backlog truth synchronization | `ISF-RULE-GUARD-DOC-TRUTH-SYNC` |
| Loop-body shipped-clause documentation truth synchronization | `ISF-LOOP-BODY-DOC-TRUTH-SYNC` |
| ISF shipped feature matrix coverage synchronization | `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC` |
| Transaction port/binding feature matrix coverage | `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC` |
| Schedule-report metadata feature matrix coverage | `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC` |
| Downstream issue-bundle feature matrix coverage | `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC` |
| `.isf` CLI example feature matrix coverage | `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC` |
| Broad feature-backlog owner coverage synchronization | `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC` |

## Book-Facing Feature Backlog Owner Coverage

The mdBook feature backlog is the user-facing review surface for broad future
work. A category listed here with `future task tree required` is deliberately
not an implementation permission slip: before code, tests, source artifacts,
generated artifacts, or public behavior change for that category, the work
must be attached to an active task tree with executable leaves and acceptance
criteria.

| mdBook backlog category | Current tracking stance |
| --- | --- |
| `Language Ergonomics` | `completed DYNAMIC-DIVISOR-SAFETY-FRONTIER tree for direct runtime literal-zero divisor rejection; completed INFERENCE-FIRST-SCALAR-AUTHORING tree for symbolic scalar type widths; future task tree required for broader language ergonomics behavior outside those trees` |
| `Aggregate Types And Data` | `completed COMPOSITION-TYPE-BACKLOG-EXHAUSTION tree for broader aggregate/type exhaustion; completed RICHER-AGGREGATE-OPERATORS tree for semantic parameter/generic aggregate operator widening; completed AGGREGATE-AUTOGROWTH-FROM-USAGE tree for bounded automatic aggregate growth; completed BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING tree for exact-contract Verilog-family structured-lowering audit; completed R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT tree for the shipped bounded portable-type frontier decision` |
| `Composition` | `completed COMPOSITION-TYPE-BACKLOG-EXHAUSTION tree for generated-child, reusable-module, top-boundary, shared-datapath, VHDL generic-map, and generalized composition backlog exhaustion; completed R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT tree for the declared top-port/connect-by-name convention frontier; covered by completed composition task trees for shipped surfaces; VHDL backend-dependent follow-up work was routed through completed BACKEND-API-VALIDATION-FRONTIER leaves or left behind future exact owners` |
| `Intent Scheduling Format` | `covered by the R14 ISF objective coverage table above for shipped surfaces and by completed ISF-REMAINING-BROAD-FRONTIER for broad remaining deferred ISF behavior; ISF extraction remains deferred until a stable family is identified by an exact owner` |
| `Verification Code Generation` | `completed IAL1-VERIFICATION-CODE-GENERATION-FRONTIER owns the first-class verification-generation lane; .3 selected actor-level passive observation metadata, ISF-VERIFICATION-OBSERVATION-METADATA.1 shipped it, .4 selected a passive UVM monitor skeleton package, .7 selected the public CLI/artifact/report/support-accounting surface, .8 shipped the inert UVM output mode, .5 deferred VHDL artifact selection behind validation-substrate selection, .9 selected shape-only inert-artifact validation, .10 selected an inert VHDL observation package, .11 shipped it, and .6 selected no direct .ppif verification-output route for the current lane` |
| `Backends And Validation` | `completed BACKEND-API-VALIDATION-FRONTIER tree owns the exhausted active VHDL/backend-validation/API frontier through .132; future behavior-bearing backend work still requires a new exact active owner leaf` |
| `Embedding And Public APIs` | `completed BACKEND-API-VALIDATION-FRONTIER tree owns the exhausted normalized-export/public-API frontier through .132; future public API/export work still requires a new exact active owner leaf` |
| `Architecture` | `completed ARCHITECTURE-DEBT-FRONTIER tree through .3; direct-backend StructuralRTLIR internal declaration nets shipped, ISF parser/lowerer extraction remains deferred until a stable family has a future exact owner, and broad extraction/refactor work remains gated by exact leaves` |

## ISF Task-Tree Rule

All ISF work under `R14` is task-tree-managed by default.

Before implementing any ISF task, slice, or PNT-selected activity, apply the
mandatory task-tree gate above and then:

- Attach it to an existing active ISF task tree, or create a new
  `docs/tasks/*.md` tree from [docs/tasks/TEMPLATE.md](docs/tasks/TEMPLATE.md).
- Slice the work into executable leaf nodes before changing scheduler,
  parser, emitter, contract, fixture, or book content.
- Put only executable leaf nodes in the tree's current frontier.
- Implement one frontier leaf at a time.
- For every ISF feature leaf, inspect the reusable synchronization checklist in
  [docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md](docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md)
  and record the selected public sync scope in the owning task file, live
  recovery docs, or commit body.
- For every downstream-visible ISF behavior, syntax, diagnostics, report,
  public-facade, generated-artifact, fixture, or deferral change, keep
  [docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
  synchronized in the same slice. This handoff document is part of the public
  sync set, not optional secondary documentation.
- Update the owning task file when the leaf status, blocker, decision,
  validation evidence, or completion evidence changes.
- Run the full [COMMIT.md](COMMIT.md) workflow after each completed leaf before
  selecting another ISF leaf.

Small ISF documentation-only or diagnostics-only changes still need a tree
entry. If the change is genuinely small, the tree can contain one leaf, but the
task must still be visible in the task-tree ledger before implementation.

## Directory Layout

```text
docs/TASK_TREE.md
docs/tasks/
  TEMPLATE.md
  <TREE>.md
```

`docs/TASK_TREE.md` is the workflow and active-tree index.
Each top-level task owns one file in `docs/tasks/`.
`docs/tasks/TEMPLATE.md` is copied when creating a new top-level tree.
Long-running trees may optionally use a bounded segment manifest and
content-addressed sealed Markdown segments; existing one-file trees remain
valid without them.

## Definitions

- Task tree: the recursive decomposition of one top-level task.
- Node: one item in that tree.
- Container node: a node with children. It is not directly executable.
- Leaf node: a node with no children. It is the only unit PNT may implement.
- Current frontier: the ordered set of leaf nodes that are eligible to be
  picked next.
- Slice: one completed leaf task plus its tests, docs, live-doc updates, and
  commit workflow.
- Evidence: the validation output, changed-doc summary, and git commit subject
  that prove a leaf was completed.
- Long-running-tree containment: a live root keeps metadata and the
  nonterminal ancestor/frontier; content-addressed sealed segments copy exact
  completed subtrees, while compact terminals reconstruct them from an exact
  version object.

## ID Rules

Each task tree has a stable top-level ID.

```text
<TREE>
<TREE>.1
<TREE>.1.1
<TREE>.1.1.1
```

Rules:

- `<TREE>` uses uppercase letters, digits, and hyphens.
- Child IDs append dot-separated positive integers.
- IDs are permanent once published.
- Never renumber closed nodes.
- If a new ordering is needed, add new IDs and mark old nodes `superseded` or
  `deferred` with a reason.
- A commit that completes a task-tree leaf must identify the leaf ID in the
  commit subject or in the first body line.

## Status Vocabulary

Use only these statuses.

| Status | Meaning |
| --- | --- |
| `proposed` | Captured but not yet accepted into the active tree. |
| `active` | The top-level tree is open, or a container has unfinished children. |
| `pending` | Ready to be selected once it reaches the current frontier. |
| `in_progress` | Currently being implemented in the worktree. |
| `blocked` | Cannot proceed without a named blocker and unblock condition. |
| `done` | Completed, validated, documented, and committed. |
| `deferred` | Deliberately postponed with an explicit consequence. |
| `superseded` | Replaced by another node, with the replacement ID named. |

## Required Task File Sections

Every top-level task file must contain:

- Metadata: tree ID, status, roadmap lane, created date, last updated date.
- Goal: the user-visible or project-visible outcome.
- Non-goals: what this tree deliberately does not try to solve.
- Acceptance criteria: concrete conditions that close the top-level task.
- Task tree: all known nodes, with status and short result intent. **This node
  graph is the authoritative, live record**: by default it is the in-file node
  list; when a `Segment manifest` is declared, it is the checked union of the
  live list and manifest-addressed sealed segments. Each leaf's `Status` is its
  live state and its `Verification`/`Commit` fields hold its evidence and
  completion commit.
- Decisions: accepted technical decisions and their rationale.
- Open questions: unresolved questions that do not block the whole tree yet.
- Blockers: blockers with unblock conditions.

An optional `Segment manifest` metadata field points to
`docs/tasks/segments/<TREE>/manifest.jsonl`. The live file still contains the
root and all nonterminal ancestors; ordinary trees require no manifest.

The following four sections are **optional historical convenience views**, not
required to be maintained per-slice (decision
[0019](decisions/0019-task-tree-in-file-secondary-views-are-historical.md)); the
live sources are the node list above, this `docs/TASK_TREE.md`, and
`git log --grep=<TREE-ID>`. When present they may lag; treat them as historical
and do not rely on them for the current frontier:

- Current frontier: an optional ordered snapshot; the live frontier is the node
  list's eligible (`active`/`pending`, unblocked) leaves.
- Verification log: an optional snapshot of `Verification` fields already in the
  node list.
- Commit log: an optional snapshot of `Commit` fields already in the node list
  and in git.
- Changelog: an optional dated snapshot; git is the audit trail.

## Node Rules

Every node must be one of these two shapes.

Container node:

```text
- ID: <TREE>.<n>
  Status: active
  Goal: ...
  Children: <TREE>.<n>.1, <TREE>.<n>.2
```

Leaf node:

```text
- ID: <TREE>.<n>
  Status: pending
  Goal: ...
  Acceptance: ...
  Verification: pending
  Commit: pending
```

For a long-running tree only, decision
[0042](decisions/0042-task-trees-seal-completed-subtrees-with-exact-provenance.md)
permits finite JSONL manifests over content-addressed, exact-source terminal
subtree segments, or a compact live `version_object` node whose complete
terminal subtree is retrieved and proved by revision, digest, goal, count,
closure, verification, and commit evidence. The full schema and examples live
in [docs/TASK_TREE_README.md](docs/TASK_TREE_README.md); ordinary trees remain
in one file.

A node with children must not be marked `done` until every child is `done`,
`deferred`, or `superseded`, and every non-`done` child has a recorded reason.

The registered `TASK-TREE-INTEGRITY` doctrine mechanically checks these live
and optional sealed/version-object rules for every tree indexed as `active`:

```bash
scripts/check_task_tree_integrity.pl
```

It deliberately does not parse or enforce the optional historical views below.

## Current Frontier Rules

The frontier is the set of **eligible live leaf nodes in the `## Task Tree`
node list** — leaves whose `Status` is `active` or `pending` and that are not
blocked. Sealed segments and compact terminals are terminal by construction.
The node list is authoritative; the optional `## Current Frontier` table is a
historical snapshot only (decision
[0019](decisions/0019-task-tree-in-file-secondary-views-are-historical.md)).

Rules:

- The frontier contains only leaf nodes; a container never appears in it.
- A blocked node is not eligible until unblocked.
- When a leaf is split, mark it `active` and add children; the first executable
  child or children become the eligible frontier.
- When a leaf completes, mark it `done` and the next eligible leaf or leaves
  become the frontier.
- If the optional `## Current Frontier` table is present, it may lag the node
  list; when it disagrees, the node list wins.

## PNT Selection Rules

When PNT is asked to continue and at least one active task tree exists:

1. Read `docs/TASK_TREE.md`.
2. Read the active task file named in the `Active Task Trees` table.
3. Pick the first eligible live leaf from that file's `## Task Tree` node list — the
   earliest `active`/`pending`, unblocked leaf (decision
   [0019](decisions/0019-task-tree-in-file-secondary-views-are-historical.md)).
   The optional `## Current Frontier` table is historical and may lag; do not
   select from it.
4. Implement only that leaf.
5. If the leaf is too broad, split it before implementation and commit the
   tree update as the leaf's honest outcome.
6. Run the required validation for the leaf.
7. Update the task file, live docs, and roadmap if status changed.
8. Run the full commit workflow before selecting another leaf.

If several active trees exist, choose the first active tree in the table unless
the user names another tree or the roadmap status names a different immediate
lane.

## Splitting Rules

Split a node when any of these are true:

- It cannot be completed to signoff quality in one slice.
- It mixes design, implementation, diagnostics, tests, and docs in ways that
  can be reviewed independently.
- It hides an unresolved policy choice behind implementation wording.
- It would require touching unrelated ownership areas in one commit.
- It discovers a lower-level dependency that should be solved first.

Do not split merely to create vague placeholders. Every child must have a
clear goal and a way to verify completion.

## Completion Rules

A leaf is complete only when all of the following are true:

- Implementation or documentation work for that leaf is finished.
- Focused checks passed, and broader checks ran when warranted.
- The owning task file records the result, validation, and commit subject.
- `docs/TASK_TREE.md` and the owning task node carry live state; accepted
  cross-cutting decisions go under `docs/decisions/`; bounded `MEMORY.md`
  carries only the resume pointer; the mdBook is synchronized when user-facing
  behavior or claims change; git carries history.
- The commit workflow in `COMMIT.md` has completed.
- `git_message_brief.txt` has been cleared after commit.

Commit hashes are intentionally not required inside the same task-file update:
the final hash cannot be known until after the commit exists. The stable
join key is the leaf ID in the commit subject or first body line. Later status
refreshes may backfill hashes if useful.

## Blocker Rules

A blocked node must record:

- the exact blocker,
- why it blocks the node,
- the unblock condition,
- and the next task that should run instead, if any.

Do not leave a node as `blocked` only because it is large or unclear. Large or
unclear work should be split until a real blocker is visible.

## Relationship To Live Docs

The task tree is the detailed execution ledger.

- `ROADMAP_V2.md` carries high-level roadmap intent, not a duplicate live
  frontier.
- `docs/TASK_TREE.md` plus each owning node list carry live work state.
- `MEMORY.md` is the bounded overwrite-only recovery/handoff pointer.
- `docs/decisions/` carries durable accepted rationale and cross-cutting facts.
- Git is the chronological audit trail.
- The mdBook is the user-facing product/language documentation.
- `CHANGES.md` is the concise per-slice technical changelog.
- `DEVELOPMENT_NOTES.md` is conditional: update it only for durable engineering
  rationale, constraints, or working decisions that lack a better canonical
  home.
- `ROADMAP_STATUS.md` and `LIVE_ACHIEVEMENT_STATUS.md` remain frozen legacy
  records pending `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`; do not append
  to or treat them as live sources. See decision
  [0025](decisions/0025-project-document-interim-lifecycle.md).

Do not duplicate the task tree or git history into another hand-maintained
status narrative.

## Copying This Workflow To Another Project

The detailed project-adoption checklist lives in
[docs/TASK_TREE_README.md](docs/TASK_TREE_README.md).

To reuse this approach elsewhere:

1. Copy `docs/TASK_TREE_README.md`.
2. Copy `docs/TASK_TREE.md`.
3. Copy `docs/tasks/TEMPLATE.md`.
4. Add `docs/tasks/` to the project documentation index.
5. Add a commit-workflow rule requiring completed task-tree leaf commits to
   identify the leaf ID.
6. Add the task-tree file to the session bootstrap or fast ramp-up order.
7. Create one top-level task file per broad task.
8. Keep the roadmap high-level and the task files detailed.

The only project-specific parts are roadmap lane names, live-doc filenames,
validation commands, and commit-message conventions.
