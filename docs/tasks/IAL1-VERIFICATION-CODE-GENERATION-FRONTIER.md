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
  Status: `pending`
  Goal: `Select the first IAL1 verification observation/source-feature contract before output generation.`
  Acceptance: `Because .2 found missing IAL1 surface area for first-class verification-code generation, this selector chooses one exact source/report feature family, expected to cover passive observation roles and source identity for future monitors/checkers; records diagnostics, examples, generated .fsm or report artifact boundary, support-accounting shape, mdBook coverage, validation gates, and deferrals before implementation. UVM, VHDL, scoreboard, coverage, reusable VIP, direct IAL2 routing, and public CLI/artifact behavior remain behind their later selector leaves.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`
  Status: `pending`
  Goal: `Select the first SV/UVM verification output contract.`
  Acceptance: `The selector chooses one bounded SV/UVM output target such as a monitor, checker, scoreboard shell, agent skeleton, coverage collector, or reusable VIP package; records source prerequisites, generated artifact names, CLI/report surfaces, UVM version/reference assumptions, simulation/formal boundaries, validation gates, and explicit non-goals before code generation.`
  Verification: `pending`
  Commit: `pending`

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
| 2 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` | `pending` | Select the first IAL1 verification-specific observation/source-feature contract before any output generator is chosen. |

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

## Open Questions

- What exact IAL1 passive observation/source-identity contract should `.3`
  select before verification output generation?
- Should protocol-specific IAL2 facts become verification annotations on the
  generated IAL1 artifact, or should a future direct IAL2 verification route
  exist at all?
- Which output family should be first: SV/UVM monitor/checker, scoreboard,
  coverage, reusable VIP, or a smaller VHDL-oriented verification artifact?

## Blockers

- None for the `.2` audit. Implementation remains blocked until the audit and
  relevant contract-selection leaves complete.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `rg -n 'IAL1-VERIFICATION-CODE-GENERATION-FRONTIER|IAL1 verification-specific|SV/UVM|VHDL-oriented verification|Direct IAL2-to-verification|Verification Code Generation' docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial1-verification-code-generation-frontier.md docs/knowledge/ial2-axi-manager-post-rresp-aggregation-next-slice.md MEMORY.md`; Knowledge Map generated-index spot check; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed`; verification-code generation is now task-tree owned as an IAL1-first lane, with IAL1 verification-specific features, SV/UVM targets, VHDL verification targets, IAL2 routing, and public artifact/report/support-accounting contracts captured as executable future leaves |
| `2026-06-16` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` | Audit/read: `docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md`; `docs/ISF_SPEC.md`; `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`; `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`; `docs/book/src/13d-control-flow.md`; `docs/book/src/13h-lowering-reference.md`; `docs/book/src/13k-isf-feature-support-matrix.md`; `docs/book/src/14-feature-backlog.md`; `docs/tasks/ISF-ASSERT.md`; `docs/tasks/ISF-ASSERT-CONCURRENT.md`; `docs/tasks/ISF-COVER-ASSUME.md`; `docs/tasks/ISF-PROPERTY-IMPLICATION.md`; `docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md`; `docs/tasks/ISF-PROPERTY-WINDOW-RANGE.md`; `docs/tasks/ISF-TRIGGER-ANCHOR.md`; `docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md`; `docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md`; `docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md`; `docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf`; `docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf`; `.cache/local-references/accellera/uvm/uvm-1.2`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`; `perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm`; `perl/FSM/Backend/GeneratedModuleEmitter.pm`; `pdftotext`/`rg` UVM reference scans; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed`; existing IAL1 verification checks/properties are sufficient for inline SV assertion projection but insufficient for first-class verification-code generation, so `.3` is selected to define an IAL1 verification observation/source-feature contract |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1: create verification frontier` | Created the active IAL1-first verification-code generation frontier and selected `.2`, the IAL1 verification-source/prerequisite audit. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2: audit IAL1 verification source` | Completed the IAL1 source-readiness audit and selected `.3`, an IAL1 verification observation/source-feature contract selector. |

## Changelog

- `2026-06-16`: Created active IAL1 verification-code generation frontier and
  selected `.2`, IAL1 verification-source and prerequisite audit, as the next
  executable leaf.
