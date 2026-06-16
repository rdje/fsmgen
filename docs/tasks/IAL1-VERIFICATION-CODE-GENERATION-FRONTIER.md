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
  Status: `pending`
  Goal: `Audit the IAL1 verification-generation source contract and missing IAL1 verification-specific features.`
  Acceptance: `The audit reads ISF/IAL1 verification constructs, generated .fsm assertion carriers, schedule JSON, normalized semantic JSON, support accounting, current SystemVerilog assertion lowering, VHDL scaffold boundaries, Accellera UVM references, mdBook verification chapters, and downstream integration docs; it decides whether existing IAL1 assert/assume/cover/monitor/property primitives are sufficient for first verification output, or selects exact IAL1 verification-specific feature prerequisites such as verification roles, observed interfaces, transactions/events, scoreboarding hooks, coverage intent, UVM component metadata, or VHDL/PSL-friendly property metadata.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3`
  Status: `pending`
  Goal: `Select any required IAL1 verification-specific source features before output generation.`
  Acceptance: `If .2 finds missing IAL1 surface area, this selector chooses one exact source/report feature family, diagnostics, examples, generated .fsm or report artifact boundary, support-accounting shape, mdBook coverage, validation gates, and deferrals before implementation. If .2 finds no prerequisite, this leaf records the close-out and advances to output-target selection.`
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
| 1 | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` | `pending` | The lane is now task-tree owned; the next safe step is an audit of IAL1 verification-source sufficiency and any missing IAL1 verification-specific feature prerequisites before choosing SV/UVM, VHDL, or IAL2 routing behavior. |

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

## Open Questions

- Which IAL1 verification-specific feature family, if any, must ship before
  verification output generation?
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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1` | `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.1: create verification frontier` | Created the active IAL1-first verification-code generation frontier and selected `.2`, the IAL1 verification-source/prerequisite audit. |

## Changelog

- `2026-06-16`: Created active IAL1 verification-code generation frontier and
  selected `.2`, IAL1 verification-source and prerequisite audit, as the next
  executable leaf.
