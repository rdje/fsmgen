# IAL1-VERIFICATION-CODE-GENERATION-FRONTIER: IAL1 Verification Code Generation Frontier

## Metadata

- Tree ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER`
- Status: `active`
- Roadmap lane: `Verification code generation / IAL1`
- Created: `2026-06-16`
- Last updated: `2026-06-16`
- Owner: repo-local workflow

## Goal

Create a first-class FSMGen verification-code generation lane whose default
source boundary is IAL1 (`.isf`) and whose future output targets can include
SystemVerilog/UVM agents, monitors, scoreboards, protocol checkers, coverage,
reusable verification IP, and VHDL-oriented verification artifacts.

## Non-Goals

- Do not mix non-synthesizable verification target code into the current
  synthesizable RTL/HDL feature-completeness lane.
- Do not implement direct IAL2-to-verification generation before an audit
  proves that it is needed and defines how it composes with the IAL2 -> IAL1
  -> IAL0 lowering doctrine.
- Do not assume the existing IAL1 verification primitives are sufficient for
  SV/UVM or VHDL verification output. Any needed IAL1 verification-specific
  source features must be selected, task-tree owned, documented, and tested.
- Do not claim UVM, VHDL verification, PSL, formal, simulation, or reusable
  VIP support before one exact output contract and validation gate ships.
- Do not bypass reviewable generated artifacts, reports, source identity,
  support accounting, diagnostics, mdBook, and Knowledge Map synchronization.

## Acceptance Criteria

- The verification-code generation idea is task-tree owned outside the IAL2
  synthesizable RTL/HDL lane.
- The first executable leaf audits IAL1 as the source contract and identifies
  any missing IAL1 verification-specific features before output generation.
- SV/UVM and VHDL verification output targets are selected through separate
  contract leaves before implementation.
- IAL2-to-verification is treated as an explicit open question and cannot be
  implemented until an audit selects a safe route.
- Public docs, roadmap, mdBook, task-tree index, Memory, and Knowledge Map
  make the lane discoverable.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER`
  Status: `active`
  Goal: `Build an IAL1-first verification-code generation lane for SV/UVM, VHDL-oriented verification artifacts, and future reusable verification IP.`
  Children: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1`
  Status: `done`
  Goal: `Create the first-class IAL1 verification-code generation task tree and route the deferred verification-code note into durable layers.`
  Acceptance: `The new task tree, task index, README, roadmap, mdBook, Memory, and Knowledge Map identify verification-code generation as an IAL1-first lane, record SV/UVM and VHDL verification targets as future exact owners, and preserve IAL2-to-verification as an audit question rather than an implementation permission.`
  Verification: `passed: Knowledge Map regeneration/check, mdBook build, docs path audit, memory architecture check, positive ownership scans, and diff hygiene`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1: create verification frontier`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2`
  Status: `done`
  Goal: `Audit the IAL1 verification-generation source contract and missing IAL1 verification-specific features.`
  Acceptance: `The audit reads ISF/IAL1 verification constructs, generated .fsm assertion carriers, schedule JSON, normalized semantic JSON, support accounting, current SystemVerilog assertion lowering, VHDL scaffold boundaries, Accellera UVM references, mdBook verification chapters, and downstream integration docs; it decides whether existing IAL1 assert/assume/cover/monitor/property primitives are sufficient for first verification output, or selects exact IAL1 verification-specific feature prerequisites such as verification roles, observed interfaces, transactions/events, scoreboarding hooks, coverage intent, UVM component metadata, or VHDL/PSL-friendly property metadata.`
  Verification: `passed: Knowledge Map regeneration/check, mdBook build, docs path audit, memory architecture check, positive ownership scans, and diff hygiene`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2: audit IAL1 verification source`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3`
  Status: `done`
  Goal: `Select the first IAL1 verification observation/source-feature contract before output generation.`
  Acceptance: `Because .2 found missing IAL1 surface area for first-class verification-code generation, this selector chooses one exact source/report feature family, expected to cover passive observation roles and source identity for future monitors/checkers; records diagnostics, examples, generated .fsm or report artifact boundary, support-accounting shape, mdBook coverage, validation gates, and deferrals before implementation. UVM, VHDL, scoreboard, coverage, reusable VIP, direct IAL2 routing, and public CLI/artifact behavior remain behind their later selector leaves.`
  Verification: `passed: Knowledge Map regeneration/check, mdBook build, docs path audit, memory architecture check, positive ownership scans, and diff hygiene`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3: select observation metadata`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`
  Status: `done`
  Goal: `Select the first SV/UVM verification output contract.`
  Acceptance: `The selector chooses one bounded SV/UVM output target such as a monitor, checker, scoreboard shell, agent skeleton, coverage collector, or reusable VIP package; records source prerequisites, generated artifact names, CLI/report surfaces, UVM version/reference assumptions, simulation/formal boundaries, validation gates, and explicit non-goals before code generation.`
  Verification: `Selected a bounded passive UVM monitor skeleton package derived only from shipped verification_observations[] report entries. The selected future artifact family is uvm/<actor>_observation_uvm_pkg.sv with package <actor>_observation_uvm_pkg and inert <observation>_snapshot / <observation>_monitor class skeletons. The selector read the .2 source-readiness audit, .3 observation selection, ISF-VERIFICATION-OBSERVATION-METADATA.1 implementation record, downstream schedule-report contract, local UVM 1.2 monitor/agent/analysis-port sources, README, ROADMAP_V2, mdBook, task index, Memory, and Knowledge Map. It records that .7 must select public CLI, artifact layout, report/manifest shape, support accounting, and validation gates before any SV/UVM files are emitted.`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4: select passive UVM monitor skeleton`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5`
  Status: `pending`
  Goal: `Select the first VHDL-oriented verification output contract.`
  Acceptance: `The selector audits VHDL assertion/testbench/PSL feasibility against the current VHDL scaffold and validation environment; chooses one bounded VHDL-oriented verification artifact or records why VHDL verification generation remains deferred behind a smaller prerequisite.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6`
  Status: `pending`
  Goal: `Audit whether IAL2 should feed verification generation directly or only through IAL1.`
  Acceptance: `The audit reads current .ppif/IAL2 report semantics, IAL2 -> IAL1 review artifacts, IAL1 verification-source findings, protocol-specific verification needs, and downstream integration docs; it decides whether IAL2 verification generation needs a direct route, an IAL2-to-IAL1 verification annotation handoff, or no separate route for the first implementation.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`
  Status: `pending`
  Goal: `Select the public CLI, artifact, report, and support-accounting contract for verification output generation.`
  Acceptance: `The selector records command-line entry points, output directory layout, generated artifact review surfaces, check JSON/semantic JSON behavior, support-accounting entries, diagnostics, mdBook examples, and regression gates before any implementation emits verification code.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` | `done` | Audit completed; existing IAL1 checks/properties are enough for inline SV assertion projection but not enough for first-class SV/UVM or VHDL-oriented verification-code generation. |
| 2 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` | `done` | Selected actor-level passive observation metadata as the first IAL1 verification-specific source feature. |
| 3 | `ISF-VERIFICATION-OBSERVATION-METADATA.1` | `done` | Shipped the selected report-only `observe` metadata contract through parser/report/public-contract coverage. |
| 4 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` | `done` | Selected a passive UVM monitor skeleton package as the first bounded SV/UVM output target. |
| 5 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7` | `pending` | Select public CLI, artifact layout, report/manifest, support-accounting, and validation gates before any SV/UVM files are emitted. |

## Decisions

- `2026-06-16`: Promote verification-code generation from the deferred
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.80` note into a first-class active task
  tree. The selected default stance is IAL1-first: verification generation
  should start from the `.isf`/IAL1 scheduling-intent layer unless a later
  audit proves a direct IAL2 route is needed. SV/UVM and VHDL verification
  output targets require separate contract-selection leaves.
- `2026-06-16`: Record the likely need for IAL1 verification-specific source
  features as an explicit audit question. Existing IAL1 assert/assume/cover,
  temporal property, trigger-anchor, and monitor surfaces are evidence, not a
  blanket proof that agents, scoreboards, coverage, reusable VIP, or VHDL/PSL
  artifacts have enough source semantics.
- `2026-06-16`: Complete the `.2` source-readiness audit. The shipped IAL1
  verification primitives are sufficient for inline SV assertion/property
  projection through the `.fsm` `+assert` carrier, but not sufficient for
  first-class SV/UVM or VHDL-oriented verification-code generation. Select
  `.3`, an IAL1 verification observation/source-feature selector, before
  choosing output artifacts.
- `2026-06-16`: Complete selector `.3`. The selected first source feature is
  actor-level passive observation metadata spelled
  `(observe NAME (role passive_monitor) (signals SIG...))`, projected only to
  additive schedule JSON `verification_observations[]`. Implementation is
  owned by active tree `ISF-VERIFICATION-OBSERVATION-METADATA`, leaf `.1`.
- `2026-06-16`: `ISF-VERIFICATION-OBSERVATION-METADATA.1` ships the selected
  observation metadata source prerequisite. The parser/report/public-contract
  surface is report-only and does not generate SV/UVM, VHDL, scoreboard,
  coverage, reusable VIP, `.fsm`, or HDL behavior. This unblocks `.4`, the
  first SV/UVM output contract selector.
- `2026-06-16`: `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.2` records selector
  input for `.4`: SPECFORGE's grounded transaction phase membership should
  not be lowered by fabricating drive values or transaction-body order. Future
  checked transaction phase-group metadata belongs in `.isf`; `.val`, if ever
  selected, is a verification artifact/layer and not a replacement for `.isf`.
- `2026-06-26`: Complete selector `.4`. The first SV/UVM output target is a
  passive UVM monitor skeleton package derived only from shipped
  `verification_observations[]` metadata. The selected skeleton may declare
  inert UVM 1.2 snapshot item and monitor classes, but it must not sample a
  DUT interface, publish transactions, infer events, build an agent, generate
  a scoreboard, generate coverage, or emit reusable VIP behavior. `.7` is the
  next prerequisite because public CLI, artifact layout, report/manifest shape,
  support-accounting identity, and validation gates must be selected before any
  implementation emits SV/UVM files.

## Open Questions

- What transaction/event object model should follow after
  `ISF-VERIFICATION-OBSERVATION-METADATA.1` ships passive observation
  metadata?
- What checked transaction phase-group metadata shape should carry grounded
  membership/phase/role facts without implying drive values, body order, or
  generated verification output?
- Should protocol-specific IAL2 facts become verification annotations on the
  generated IAL1 artifact, or should a future direct IAL2 verification route
  exist at all?
- Which public CLI/artifact/report/support-accounting surface should emit the
  selected passive UVM monitor skeleton package?

## Blockers

- None for `.7`; `.4` selected the passive UVM monitor skeleton package as the
  first SV/UVM output target. SV/UVM output code generation still requires `.7`
  to select public CLI, artifact layout, report/manifest, support-accounting,
  and validation gates before implementation.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `rg -n 'IAL1-VERIFICATION-CODE-GENERATION-FRONTIER|IAL1 verification-specific|SV/UVM|VHDL-oriented verification|Direct IAL2-to-verification|Verification Code Generation' docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial1-verification-code-generation-frontier.md docs/knowledge/ial2-axi-manager-post-rresp-aggregation-next-slice.md MEMORY.md`; Knowledge Map generated-index spot check; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed`; verification-code generation is now task-tree owned as an IAL1-first lane, with IAL1 verification-specific features, SV/UVM targets, VHDL verification targets, IAL2 routing, and public artifact/report/support-accounting contracts captured as executable future leaves |
| `2026-06-16` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` | Audit/read: `docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md`; `docs/ISF_SPEC.md`; `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`; `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`; `docs/book/src/13d-control-flow.md`; `docs/book/src/13h-lowering-reference.md`; `docs/book/src/13k-isf-feature-support-matrix.md`; `docs/book/src/14-feature-backlog.md`; `docs/tasks/ISF-ASSERT.md`; `docs/tasks/ISF-ASSERT-CONCURRENT.md`; `docs/tasks/ISF-COVER-ASSUME.md`; `docs/tasks/ISF-PROPERTY-IMPLICATION.md`; `docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md`; `docs/tasks/ISF-PROPERTY-WINDOW-RANGE.md`; `docs/tasks/ISF-TRIGGER-ANCHOR.md`; `docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md`; `docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md`; `docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md`; `docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf`; `docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf`; `.cache/local-references/accellera/uvm/uvm-1.2`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`; `perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm`; `perl/FSM/Backend/GeneratedModuleEmitter.pm`; `pdftotext`/`rg` UVM reference scans; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed`; existing IAL1 verification checks/properties are sufficient for inline SV assertion projection but insufficient for first-class verification-code generation, so `.3` is selected to define an IAL1 verification observation/source-feature contract |
| `2026-06-16` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` | Selection/read: `docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md`; `docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md`; `docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md`; `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`; `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`; `docs/book/src/13k-isf-feature-support-matrix.md`; `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl/FSM/Adapter/ISF/Parser.pm`; `t/1179-isf-phase-stage-boundary.t`; `t/1252-isf-actor-phase-stage-report.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed`; selected actor-level passive `observe` metadata and created `ISF-VERIFICATION-OBSERVATION-METADATA.1` as the implementation owner before SV/UVM output selection |
| `2026-06-16` | `ISF-VERIFICATION-OBSERVATION-METADATA.1` | See [docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md](ISF-VERIFICATION-OBSERVATION-METADATA.md) | `passed`; implementation prerequisite for `.4` shipped |
| `2026-06-26` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` | `docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md`; `.2` source-readiness audit; `.3` observation selector; `ISF-VERIFICATION-OBSERVATION-METADATA.1`; `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`; local UVM 1.2 `uvm_monitor`, `uvm_agent`, and `uvm_analysis_port` sources; README, ROADMAP_V2, mdBook, task index, Memory, and Knowledge Map; docs/doctrine closeout gates | `passed`; selected a passive UVM monitor skeleton package as the first SV/UVM output target and routed public CLI/artifact/report/support-accounting selection to `.7` before implementation. No parser, generator, CLI, artifact, support-accounting, schedule/check/semantic JSON, test, HDL/runtime, UVM output, VHDL output, direct IAL2 route, scoreboard, coverage, reusable VIP, or backend behavior changed. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1: create verification frontier` | Created the active IAL1-first verification-code generation frontier and selected `.2`, the IAL1 verification-source/prerequisite audit. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2: audit IAL1 verification source` | Completed the IAL1 source-readiness audit and selected `.3`, an IAL1 verification observation/source-feature contract selector. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3: select observation metadata` | Selected the first IAL1 verification-specific source feature and created `ISF-VERIFICATION-OBSERVATION-METADATA.1`. |
| `ISF-VERIFICATION-OBSERVATION-METADATA.1` | `ISF-VERIFICATION-OBSERVATION-METADATA.1: ship observation metadata` | Observation metadata implementation owner; unblocks `.4`. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4: select passive UVM monitor skeleton` | Selected the first SV/UVM output target and routed public artifact/CLI contract selection to `.7`. |

## Changelog

- `2026-06-16`: Created active IAL1 verification-code generation frontier and
  selected `.2`, IAL1 verification-source and prerequisite audit, as the next
  executable leaf.
- `2026-06-16`: Completed `.3`, selecting actor-level passive observation
  metadata and creating the active implementation owner tree
  `ISF-VERIFICATION-OBSERVATION-METADATA`.
- `2026-06-16`: `ISF-VERIFICATION-OBSERVATION-METADATA.1` shipped the
  report-only observation metadata source prerequisite; `.4` is the next
  executable selector.
- `2026-06-26`: Completed `.4`, selecting a passive UVM monitor skeleton
  package as the first SV/UVM output target and routing public CLI/artifact/
  report/support-accounting selection to `.7`.
