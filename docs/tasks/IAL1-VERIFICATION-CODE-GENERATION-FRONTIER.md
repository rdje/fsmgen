# IAL1-VERIFICATION-CODE-GENERATION-FRONTIER: IAL1 Verification Code Generation Frontier

## Metadata

- Tree ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER`
- Status: `done`
- Roadmap lane: `Verification code generation / IAL1`
- Created: `2026-06-16`
- Last updated: `2026-06-26`
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
  Status: `done`
  Goal: `Build an IAL1-first verification-code generation lane for SV/UVM, VHDL-oriented verification artifacts, and future reusable verification IP.`
  Children: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10, IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11`

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
  Status: `done`
  Goal: `Select the first VHDL-oriented verification output contract.`
  Acceptance: `The selector audits VHDL assertion/testbench/PSL feasibility against the current VHDL scaffold and validation environment; chooses one bounded VHDL-oriented verification artifact or records why VHDL verification generation remains deferred behind a smaller prerequisite.`
  Verification: `Complete: no VHDL-oriented verification artifact was selected. The selector audited the current VHDL scaffold, VHDL validation contract, VHDL backend shape, structural VHDL emitter, direct VHDL scaffold coverage, CLI/capability surfaces, local tool availability, and a smoke VHDL emission of the passive-observation ISF fixture; it recorded that VHDL verification generation remains deferred behind .9, the VHDL verification validation-substrate selector.`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5: select VHDL verification prerequisite`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6`
  Status: `done`
  Goal: `Audit whether IAL2 should feed verification generation directly or only through IAL1.`
  Acceptance: `The audit reads current .ppif/IAL2 report semantics, IAL2 -> IAL1 review artifacts, IAL1 verification-source findings, protocol-specific verification needs, and downstream integration docs; it decides whether IAL2 verification generation needs a direct route, an IAL2-to-IAL1 verification annotation handoff, or no separate route for the first implementation.`
  Verification: `Complete: selected no direct .ppif verification-output route for the current lane. Future protocol-specific verification facts should first lower or annotate generated IAL1 .isf review artifacts and reuse the IAL1 verification-output path unless a later exact owner proves a direct route is required.`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6: audit direct IAL2 verification route`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`
  Status: `done`
  Goal: `Select the public CLI, artifact, report, and support-accounting contract for verification output generation.`
  Acceptance: `The selector records command-line entry points, output directory layout, generated artifact review surfaces, check JSON/semantic JSON behavior, support-accounting entries, diagnostics, mdBook examples, and regression gates before any implementation emits verification code.`
  Verification: `Selected the first public verification-output surface: ./bin/fsmgen --emit-verification-output uvm-passive-monitor --verification-outdir DIR source.isf. The selected first implementation accepts .isf only, requires shipped passive verification_observations[], emits DIR/uvm/<actor>_observation_uvm_pkg.sv plus DIR/verification-output-manifest.json, adds a verification_outputs capability-manifest section, adds support-accounting entry feature.isf_verification_observation_uvm_passive_monitor_skeleton, keeps schedule/check/semantic JSON unchanged for the first implementation, rejects incompatible HDL/report options, and explicitly does not claim UVM compile support.`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7: select verification output surface`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8`
  Status: `done`
  Goal: `Implement the selected public verification-output surface for the passive UVM monitor skeleton.`
  Acceptance: `The CLI accepts --emit-verification-output uvm-passive-monitor --verification-outdir DIR for .isf sources with passive verification_observations[], emits the selected UVM package skeleton and verification-output manifest, rejects unsupported sources/options before creating artifacts, advertises the target in capability manifest metadata, adds the selected support-accounting entry, documents the user-facing flow in the mdBook, and proves the artifact shape plus deferred-behavior absence without claiming UVM compile support.`
  Verification: `passed: syntax checks for changed CLI/modules/tests; focused prove cluster t/1464, t/248, t/297; explicit verification-output/check-json/semantic-json/capability-manifest smokes; Knowledge Map regeneration; mdBook/doctrine closeout gates. Guarded broad corpus reruns t/296, t/301, and t/303 were attempted and stopped by the RAM guard on existing dynamic PPIF cases before this new verification-output fixture.`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8: implement UVM passive monitor output`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9`
  Status: `done`
  Goal: `Select the first VHDL verification validation substrate before any VHDL-oriented verification artifact.`
  Acceptance: `The selector audits GHDL, PSL-aware analysis, VHDL package/testbench syntax checking, text-shape-only artifact gates, support-accounting identity, capability-manifest/report boundaries, and mdBook expectations; it chooses the first honest validation substrate or records why VHDL verification output must remain deferred.`
  Verification: `Complete: selected artifact-shape and inert-behavior validation with explicit manifest non-claims for VHDL compile, syntax, PSL, simulation, formal, and analyzer support. GHDL/NVC/vcom are unavailable locally; Verilator/Yosys remain SystemVerilog-only.`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9: select VHDL validation substrate`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10`
  Status: `done`
  Goal: `Select the first VHDL-oriented verification artifact under the shape-only validation substrate.`
  Acceptance: `The selector chooses a bounded inert VHDL verification artifact family, such as a package shell, testbench shell, PSL sidecar placeholder, or no artifact yet; records CLI target, canonical manifest/capability id, artifact layout, validation non-claims, support-accounting shape, mdBook expectations, and implementation owner before any generator code changes.`
  Verification: `Complete: selected an inert VHDL observation metadata package skeleton with CLI target vhdl-observation-package, canonical id vhdl_observation_package_skeleton, artifact path vhdl/<actor>_observation_vhdl_pkg.vhd, explicit no-compile/no-PSL validation claims, and support-accounting entry feature.isf_verification_observation_vhdl_package_skeleton.`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10: select VHDL observation package`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11`
  Status: `done`
  Goal: `Implement the selected VHDL observation package verification-output target.`
  Acceptance: `The CLI accepts --emit-verification-output vhdl-observation-package --verification-outdir DIR for .isf sources with passive verification_observations[], emits the selected inert VHDL package skeleton and manifest, rejects unsupported sources/options before artifact writes, advertises the target in capability manifest metadata, adds the selected support-accounting entry, documents the user-facing flow in the mdBook, and proves artifact shape plus deferred-behavior absence without claiming VHDL compile, syntax, PSL, simulator, analyzer, scoreboard, coverage, reusable VIP, or direct IAL2 support.`
  Verification: `passed: syntax checks for changed CLI/modules/tests; focused prove cluster t/1465, t/1464, t/248, and t/297; explicit VHDL verification-output CLI smoke; capability-manifest/support-accounting checks; Knowledge Map regeneration; mdBook/doctrine closeout gates. The shipped artifact remains shape-only and inert with no VHDL compile, syntax, PSL, simulator, analyzer, scoreboard, coverage, reusable VIP, or direct IAL2 support claim.`
  Commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11: implement VHDL observation package`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` | `done` | Audit completed; existing IAL1 checks/properties are enough for inline SV assertion projection but not enough for first-class SV/UVM or VHDL-oriented verification-code generation. |
| 2 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` | `done` | Selected actor-level passive observation metadata as the first IAL1 verification-specific source feature. |
| 3 | `ISF-VERIFICATION-OBSERVATION-METADATA.1` | `done` | Shipped the selected report-only `observe` metadata contract through parser/report/public-contract coverage. |
| 4 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` | `done` | Selected a passive UVM monitor skeleton package as the first bounded SV/UVM output target. |
| 5 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7` | `done` | Selected public CLI, artifact layout, report/manifest, support-accounting, diagnostics, and validation gates for the passive UVM monitor skeleton. |
| 6 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8` | `done` | Shipped the selected `.isf` verification-output command and inert UVM package skeleton before any broader verification output. |
| 7 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5` | `done` | Audited VHDL assertion/testbench/PSL feasibility and deferred VHDL verification artifact selection behind a smaller validation-substrate prerequisite. |
| 8 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9` | `done` | Selected artifact-shape and inert-behavior validation with explicit no-compile/no-PSL manifest claims for future inert VHDL verification skeletons. |
| 9 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10` | `done` | Selected an inert VHDL observation metadata package skeleton as the first VHDL-oriented verification artifact. |
| 10 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11` | `done` | Shipped the selected `vhdl-observation-package` verification-output target before any broader VHDL verification output. |
| 11 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6` | `done` | Selected no direct `.ppif` verification-output route for the current lane; future protocol verification facts must route through reviewable generated IAL1 unless a later exact owner proves otherwise. |

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
- `2026-06-26`: Complete selector `.7`. The first public verification-output
  surface is `--emit-verification-output uvm-passive-monitor
  --verification-outdir DIR source.isf`. It writes
  `DIR/uvm/<actor>_observation_uvm_pkg.sv` and
  `DIR/verification-output-manifest.json`, accepts `.isf` sources with shipped
  passive `verification_observations[]` only, keeps schedule/check/semantic
  JSON unchanged for the first implementation, adds a future
  `verification_outputs` capability-manifest section and
  `feature.isf_verification_observation_uvm_passive_monitor_skeleton`
  support-accounting entry, and does not claim UVM compile support. `.8` owns
  implementation.
- `2026-06-26`: Complete implementation `.8`. The CLI now accepts the selected
  `--emit-verification-output uvm-passive-monitor --verification-outdir DIR`
  mode for `.isf` sources with passive `verification_observations[]`, emits
  `DIR/uvm/<actor>_observation_uvm_pkg.sv` plus
  `DIR/verification-output-manifest.json`, rejects unsupported sources and
  incompatible report/HDL options before artifact writes, advertises
  `uvm_passive_monitor_skeleton` through the capability manifest, adds support
  entry `feature.isf_verification_observation_uvm_passive_monitor_skeleton`,
  keeps schedule/check/semantic JSON unchanged for the first implementation,
  and does not claim UVM compile support. The next frontier leaf is `.5`, the
  VHDL-oriented verification output contract selector.
- `2026-06-26`: Complete selector `.5`. No VHDL-oriented verification artifact
  is selected yet. The current VHDL path is a synthesizable scaffold, the
  external validation contract is SystemVerilog-only, GHDL is unavailable in
  the selector environment, and VHDL package/record/array/GHDL validation
  scope remains deferred. `.9` is selected as the smaller prerequisite to
  choose a VHDL verification validation substrate before any VHDL assertion,
  PSL, testbench, package, or monitor-like artifact is implemented.
- `2026-06-26`: Complete selector `.9`. The first VHDL verification validation
  substrate is artifact-shape and inert-behavior checking with explicit
  manifest non-claims for VHDL compile, syntax, PSL, simulation, formal, and
  analyzer support. GHDL/NVC/vcom are unavailable in the selector environment,
  so real VHDL syntax or PSL validation remains a future owner. `.10` selected
  the inert VHDL observation package under this substrate.
- `2026-06-26`: Complete selector `.10`. The first selected VHDL-oriented
  verification artifact is an inert VHDL observation metadata package skeleton
  emitted by target `vhdl-observation-package`, canonical id
  `vhdl_observation_package_skeleton`, under
  `vhdl/<actor>_observation_vhdl_pkg.vhd`. It remains shape-only and inert,
  with explicit no-compile/no-PSL validation claims. `.11` owns
  implementation.
- `2026-06-26`: Complete `.11`. The selected VHDL observation package target
  now ships as `--emit-verification-output vhdl-observation-package
  --verification-outdir DIR source.isf`, writing
  `vhdl/<actor>_observation_vhdl_pkg.vhd` plus
  `verification-output-manifest.json` for `.isf` sources with passive
  `verification_observations[]`. The artifact is still shape-only and inert,
  with no VHDL compile, syntax, PSL, simulator, analyzer, scoreboard,
  coverage, reusable VIP, or direct IAL2 support claim. `.6` followed as the
  direct IAL2 route audit.
- `2026-06-26`: Complete `.6`. Direct `.ppif` verification-output generation
  is not selected for the current lane. Future protocol-specific verification
  facts should be made reviewable by generated IAL1 `.isf` annotations before
  artifact generation; a direct IAL2 route requires a later exact owner that
  proves generated IAL1 cannot preserve the needed semantics.

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
- After the inert passive UVM monitor skeleton ships, what transaction/event
  source contract should allow real DUT sampling and transaction publication?
- After the inert VHDL observation package ships, which VHDL/PSL/tool
  validation owner should be selected before any behavioral VHDL verification
  artifact?

## Blockers

- None. VHDL compile, syntax, PSL, simulation,
  formal, and analyzer support remain blocked behind future real-tool
  validation owners.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `rg -n 'IAL1-VERIFICATION-CODE-GENERATION-FRONTIER|IAL1 verification-specific|SV/UVM|VHDL-oriented verification|Direct IAL2-to-verification|Verification Code Generation' docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial1-verification-code-generation-frontier.md docs/knowledge/ial2-axi-manager-post-rresp-aggregation-next-slice.md MEMORY.md`; Knowledge Map generated-index spot check; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed`; verification-code generation is now task-tree owned as an IAL1-first lane, with IAL1 verification-specific features, SV/UVM targets, VHDL verification targets, IAL2 routing, and public artifact/report/support-accounting contracts captured as executable future leaves |
| `2026-06-16` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` | Audit/read: `docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md`; `docs/ISF_SPEC.md`; `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`; `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`; `docs/book/src/13d-control-flow.md`; `docs/book/src/13h-lowering-reference.md`; `docs/book/src/13k-isf-feature-support-matrix.md`; `docs/book/src/14-feature-backlog.md`; `docs/tasks/ISF-ASSERT.md`; `docs/tasks/ISF-ASSERT-CONCURRENT.md`; `docs/tasks/ISF-COVER-ASSUME.md`; `docs/tasks/ISF-PROPERTY-IMPLICATION.md`; `docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md`; `docs/tasks/ISF-PROPERTY-WINDOW-RANGE.md`; `docs/tasks/ISF-TRIGGER-ANCHOR.md`; `docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md`; `docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md`; `docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md`; `docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf`; `docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf`; `.cache/local-references/accellera/uvm/uvm-1.2`; `perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`; `perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm`; `perl/FSM/Backend/GeneratedModuleEmitter.pm`; `pdftotext`/`rg` UVM reference scans; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed`; existing IAL1 verification checks/properties are sufficient for inline SV assertion projection but insufficient for first-class verification-code generation, so `.3` is selected to define an IAL1 verification observation/source-feature contract |
| `2026-06-16` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` | Selection/read: `docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md`; `docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md`; `docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md`; `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`; `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`; `docs/book/src/13k-isf-feature-support-matrix.md`; `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl/FSM/Adapter/ISF/Parser.pm`; `t/1179-isf-phase-stage-boundary.t`; `t/1252-isf-actor-phase-stage-report.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed`; selected actor-level passive `observe` metadata and created `ISF-VERIFICATION-OBSERVATION-METADATA.1` as the implementation owner before SV/UVM output selection |
| `2026-06-16` | `ISF-VERIFICATION-OBSERVATION-METADATA.1` | See [docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md](ISF-VERIFICATION-OBSERVATION-METADATA.md) | `passed`; implementation prerequisite for `.4` shipped |
| `2026-06-26` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` | `docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md`; `.2` source-readiness audit; `.3` observation selector; `ISF-VERIFICATION-OBSERVATION-METADATA.1`; `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`; local UVM 1.2 `uvm_monitor`, `uvm_agent`, and `uvm_analysis_port` sources; README, ROADMAP_V2, mdBook, task index, Memory, and Knowledge Map; docs/doctrine closeout gates | `passed`; selected a passive UVM monitor skeleton package as the first SV/UVM output target and routed public CLI/artifact/report/support-accounting selection to `.7` before implementation. No parser, generator, CLI, artifact, support-accounting, schedule/check/semantic JSON, test, HDL/runtime, UVM output, VHDL output, direct IAL2 route, scoreboard, coverage, reusable VIP, or backend behavior changed. |
| `2026-06-26` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7` | `docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md`; `.4` passive UVM monitor skeleton selector; shipped `verification_observations[]` fixture and tests; CLI/outdir/report/support-accounting/capability-manifest code and contract patterns; generated HDL artifact placement policy; local tool availability for Verilator/Yosys/Icarus without a selected UVM-aware compile gate; README, ROADMAP_V2, mdBook, public/downstream contracts, task index, Memory, and Knowledge Map; docs/doctrine closeout gates | `passed`; selected the public verification-output command, artifact layout, manifest shape, support-accounting entry, capability-manifest section, diagnostics, and validation boundary for `.8`. No parser, generator, CLI, artifact, support-accounting, schedule/check/semantic JSON, HDL/runtime, UVM output, VHDL output, direct IAL2 route, scoreboard, coverage, reusable VIP, or backend behavior changed. |
| `2026-06-26` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8` | `perl -Iperl -c bin/fsmgen`; syntax checks for `perl/FSM/VerificationOutput/UVM/PassiveMonitorSkeleton.pm`, `perl/FSM/Support/VerificationOutputsContract.pm`, `perl/FSM/Support/VerificationOutputsSection.pm`, `perl/FSM/Support/CapabilityManifest.pm`, `perl/FSM/Support/CapabilityManifestContract.pm`, `perl/FSM/Support/LanguageSurfaceSection.pm`, `perl/FSM/Support/RegressionCorpus.pm`, `t/1464-isf-verification-output-uvm-passive-monitor.t`, `t/248-regression-corpus-accounting.t`, `t/297-capability-manifest.t`; `prove -Iperl t/1464-isf-verification-output-uvm-passive-monitor.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t`; `./bin/fsmgen --quiet --strict --check --json isf/verification_observation_metadata.isf`; `./bin/fsmgen --quiet --strict --emit-semantic-json isf/verification_observation_metadata.isf`; `./bin/fsmgen --quiet --emit-verification-output uvm-passive-monitor --verification-outdir /tmp/fsmgen-uvm-smoke isf/verification_observation_metadata.isf`; `./bin/fsmgen --capability-manifest`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_docs_relative_paths.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; `scripts/check_doctrines.sh`; guarded broad attempts `scripts/run_with_ram_guard.sh -- prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`, then `t/301` and `t/303` separately | `passed` for focused syntax/CLI/manifest/support-accounting/report checks and docs/doctrine closeout gates; guarded broad corpus attempts stopped at the 4096 MiB descendant RSS cutoff on existing dynamic PPIF cases before completion; `.8` shipped the explicit inert UVM passive-monitor skeleton output without widening schedule/check/semantic JSON or claiming UVM compile support |
| `2026-06-26` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5` | Read/audit `docs/VHDL_SCOPE.md`, `docs/knowledge/direct-vhdl-scaffold.md`, `docs/knowledge/vhdl-deferred-until-sv-ial-complete.md`, `perl/FSM/Support/HDLExternalValidationContract.pm`, `perl/FSM/Support/HDLExternalValidation.pm`, `perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm`, `perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm`, `t/1420-vhdl-direct-backend-scaffold.t`, current CLI help, current capability manifest, and public docs; checked local `ghdl`/`verilator`/`yosys` availability; `./bin/fsmgen --quiet --language vhdl --output /tmp/fsmgen-vhdl-selector-smoke.vhd isf/verification_observation_metadata.isf`; scanned the emitted VHDL for assertion/PSL/testbench/UVM/monitor constructs; `prove -Iperl t/1420-vhdl-direct-backend-scaffold.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_docs_relative_paths.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; `scripts/check_doctrines.sh` | `passed`; selected no VHDL verification artifact. The emitted VHDL is synthesizable entity/architecture scaffold only, the validation contract remains SystemVerilog-only, `ghdl` was unavailable, and `.9` later selected the VHDL verification validation substrate before any VHDL artifact implementation |
| `2026-06-26` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9` | Read/audit `docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md`, `docs/VHDL_SCOPE.md`, `docs/knowledge/direct-vhdl-scaffold.md`, `docs/knowledge/vhdl-deferred-until-sv-ial-complete.md`, `perl/FSM/Support/HDLExternalValidationContract.pm`, `perl/FSM/Support/VerificationOutputsContract.pm`, `perl/FSM/VerificationOutput/UVM/PassiveMonitorSkeleton.pm`, `t/1464-isf-verification-output-uvm-passive-monitor.t`, current capability manifest, README, ROADMAP_V2, and mdBook VHDL/GHDL backlog text; checked local `ghdl`/`nvc`/`vcom`/`verilator`/`yosys` availability; targeted capability-manifest probe for VHDL validation deferral and absence of VHDL verification targets; `prove -Iperl t/313-hdl-external-validation-contract.t t/297-capability-manifest.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_docs_relative_paths.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; `scripts/check_doctrines.sh` | `passed`; selected artifact-shape and inert-behavior validation. The substrate makes no VHDL compile, syntax, PSL, simulation, formal, or analyzer claim, and `.10` later selected the inert VHDL observation package under it |
| `2026-06-26` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10` | Read/audit `.5` VHDL output selector, `.9` validation-substrate selector, public verification-output selector `.7`, UVM skeleton selector `.4`, current `bin/fsmgen` verification-output branch, `perl/FSM/Support/VerificationOutputsContract.pm`, `perl/FSM/Support/VerificationOutputsSection.pm`, `perl/FSM/Support/RegressionCorpus.pm`, `t/1464-isf-verification-output-uvm-passive-monitor.t`, README, ROADMAP_V2, mdBook, ISF public/downstream contracts, task index, Memory, and Knowledge Map; targeted capability-manifest probe proving `vhdl-observation-package` remains pending implementation; `prove -Iperl t/1464-isf-verification-output-uvm-passive-monitor.t t/297-capability-manifest.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_docs_relative_paths.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; `scripts/check_doctrines.sh` | `passed`; selected inert VHDL observation metadata package. `.11` owns implementation of `--emit-verification-output vhdl-observation-package --verification-outdir DIR source.isf` without VHDL compile, syntax, PSL, simulator, analyzer, scoreboard, coverage, reusable VIP, or direct IAL2 support claims |
| `2026-06-26` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11` | `perl -Iperl -c bin/fsmgen`; syntax checks for `perl/FSM/VerificationOutput/VHDL/ObservationPackageSkeleton.pm`, `perl/FSM/Support/VerificationOutputsContract.pm`, `perl/FSM/Support/VerificationOutputsSection.pm`, `perl/FSM/Support/RegressionCorpus.pm`, and `t/1465-isf-verification-output-vhdl-observation-package.t`; `prove -Iperl t/1465-isf-verification-output-vhdl-observation-package.t t/1464-isf-verification-output-uvm-passive-monitor.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t`; `./bin/fsmgen --quiet --emit-verification-output vhdl-observation-package --verification-outdir /tmp/fsmgen-vhdl-observation-smoke-ial1-11 isf/verification_observation_metadata.isf`; `./bin/fsmgen --capability-manifest`; emitted VHDL package and manifest token inspections; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_docs_relative_paths.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; `scripts/check_doctrines.sh` | `passed`; shipped the explicit inert VHDL observation package output, support-accounting entry, capability-manifest target, focused tests, and public docs without claiming VHDL compile, syntax, PSL, simulator, analyzer, scoreboard, coverage, reusable VIP, or direct IAL2 support |
| `2026-06-26` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6` | Read/audit `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, `docs/book/src/13h-lowering-reference.md`, `docs/book/src/14-feature-backlog.md`, `docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md`, `docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md`, `docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md`, `docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md`, `perl/FSM/Support/LanguageSurfaceSection.pm`, `perl/FSM/Adapter/IAL2/PPIF.pm`, `bin/fsmgen`, and `t/297-capability-manifest.t`; checked that `.ppif` lowers through generated `.isf` before `.fsm`, that `--emit-verification-output` rejects non-`.isf` before PPIF lowering, and that `.ppif` does not advertise verification-output CLI modes; `prove -Iperl t/297-capability-manifest.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_docs_relative_paths.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; `scripts/check_doctrines.sh` | `passed`; selected no direct IAL2-to-verification route for the current lane and requires future protocol verification facts to route through reviewable generated IAL1 unless a later exact owner proves otherwise |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1: create verification frontier` | Created the active IAL1-first verification-code generation frontier and selected `.2`, the IAL1 verification-source/prerequisite audit. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2: audit IAL1 verification source` | Completed the IAL1 source-readiness audit and selected `.3`, an IAL1 verification observation/source-feature contract selector. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3: select observation metadata` | Selected the first IAL1 verification-specific source feature and created `ISF-VERIFICATION-OBSERVATION-METADATA.1`. |
| `ISF-VERIFICATION-OBSERVATION-METADATA.1` | `ISF-VERIFICATION-OBSERVATION-METADATA.1: ship observation metadata` | Observation metadata implementation owner; unblocks `.4`. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4: select passive UVM monitor skeleton` | Selected the first SV/UVM output target and routed public artifact/CLI contract selection to `.7`. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7: select verification output surface` | Selected the public CLI/artifact/report/support-accounting contract and routed implementation to `.8`. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8: implement UVM passive monitor output` | Implemented the explicit verification-output CLI, inert UVM package/manifest writer, capability-manifest target, support-accounting entry, focused tests, and public docs. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5: select VHDL verification prerequisite` | Selected no VHDL verification artifact; routed the next step to `.9`, the VHDL verification validation-substrate selector. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9: select VHDL validation substrate` | Selected shape-only inert-artifact validation with explicit no-compile/no-PSL manifest claims and routed artifact selection to `.10`. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10: select VHDL observation package` | Selected the inert VHDL observation metadata package target and routed implementation to `.11`. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11: implement VHDL observation package` | Implemented the explicit VHDL verification-output CLI target, inert VHDL package/manifest writer, capability-manifest target, support-accounting entry, focused tests, and public docs. |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6: audit direct IAL2 verification route` | Selected no direct `.ppif` verification-output route for the current lane; future protocol verification facts should route through generated IAL1 review artifacts first. |

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
- `2026-06-26`: Completed `.7`, selecting
  `--emit-verification-output uvm-passive-monitor --verification-outdir DIR`
  plus the artifact manifest/support-accounting/capability-manifest contract
  for `.8`, the first implementation leaf.
- `2026-06-26`: Completed `.8`, shipping the explicit
  `--emit-verification-output uvm-passive-monitor --verification-outdir DIR`
  mode for passive-observation `.isf` sources and moving the next frontier to
  `.5`, the VHDL-oriented verification output selector.
- `2026-06-26`: Completed `.5`, selecting no VHDL verification artifact and
  routing the next exact prerequisite to `.9`, the VHDL verification
  validation-substrate selector.
- `2026-06-26`: Completed `.9`, selecting shape-only inert-artifact validation
  for future VHDL verification skeletons and routing the next exact selector to
  `.10`, first VHDL artifact selection.
- `2026-06-26`: Completed `.10`, selecting the inert VHDL observation metadata
  package and routing implementation to `.11`.
- `2026-06-26`: Completed `.11`, shipping
  `--emit-verification-output vhdl-observation-package --verification-outdir
  DIR` for passive-observation `.isf` sources before the direct IAL2
  verification-route audit completed in `.6`.
- `2026-06-26`: Completed `.6`, selecting no direct `.ppif`
  verification-output route for the current lane and completing this frontier.
