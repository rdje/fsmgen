# FSMGen
This file is the **single entry point** for the project.
Use it first for objective, navigation, and where to find code/docs quickly.

## Memory & continuity (read this to resume in any harness)
- **`MEMORY_ARCHITECTURE.md`** (repo root) is the durable-agent-memory standard for
  this repo — MANDATORY reading, and mechanically enforced. It defines four layers
  by lifecycle and how a fresh agent (any model, any harness) resumes deterministically:
  - **A — resume pointer**: `MEMORY.md` (bounded, overwrite-only — current state + the single next action).
  - **B — work memory**: task-trees under `docs/tasks/` (index: `docs/TASK_TREE.md`).
  - **C — decision records**: durable cross-cutting facts under `docs/decisions/` (index: `docs/decisions/INDEX.md`).
  - **D — audit trail**: `git log` (commit subjects carry the work-unit id).
- Resume order: this `README.md` → `MEMORY_ARCHITECTURE.md` → `MEMORY.md` → the active
  task-tree's frontier row → only the relevant `docs/decisions/` records.
- **Route every durable thing to a layer and commit before the turn ends** — nothing
  important may live only in the conversation. Before committing run
  `scripts/check_doctrines.sh` (git hooks and CI run it too; a non-compliant
  change cannot merge). The doctrine driver includes the doctrine-bootstrap,
  memory architecture, Knowledge Map, and docs path gates. The tool-neutral bootstrap files
  (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`,
  `GEMINI.md`, `.windsurfrules`) are pointers back here plus the doctrine and
  toolbox docs.
- **`DOCTRINE_ENFORCEMENT.md`** (repo root) is the portable doctrine-check
  architecture as applied to FSMGEN, and **`TOOLBOX.md`** is the issue
  pinpointing catalog. Use the toolbox commands first when diagnosing failures,
  trace questions, report drift, support-accounting gaps, docs drift, or
  continuity/gate issues.

## Session safety invariant
- The commit workflow in `COMMIT.md` is mandatory and non-negotiable.
- Doctrine enforcement in `DOCTRINE_ENFORCEMENT.md` and the diagnostic toolbox
  in `TOOLBOX.md` are mandatory workflow surfaces; the registered gate is
  `scripts/check_doctrines.sh`.
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
- Keep the codebase, mdBook, live specs, roadmap/task-tree status, downstream
  handoff/integration docs, public contract docs, capability-manifest metadata,
  support-accounting catalog entries, tests, and explicit deferrals
  synchronized in the same slice as any downstream-visible change. These
  surfaces must convey the same facts from their different viewpoints for any
  downstream consumer; drift is a project bug.
- For downstream-visible `.isf` or `.ppif` changes, also keep
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`,
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  `docs/book/src/13i-downstream-integration.md`,
  `docs/book/src/11-extensions-and-embedding.md`, the manifest
  `language_surface.file_surfaces` boundary, and the support-accounting
  catalog synchronized with the codebase, live specs, mdBook, public contract,
  tests, and explicit deferrals. Those files are downstream-consumer
  integration handoffs, not project-specific private notes.
- Do not treat a user-visible implementation slice as complete until the book
  describes the shipped behavior accurately enough for review without reading
  the codebase.

## Project objective

FSMGen compiles Lisp-like `.fsm` state-machine specifications into synthesizable
HDL. The objective is robust, traceable FSM-to-HDL generation with clear
assignment semantics, optimization via AST factorization, and behavior-preserving
refactoring toward a modular architecture.

Above `.fsm`, FSMGen accepts higher-level *intent* sources that lower into
explicit scheduled `.fsm` before HDL generation, so every layer stays reviewable.

### Intent abstraction layers

| Layer | Public sources | Owns |
| --- | --- | --- |
| **IAL2** | `.ppif` generic container, plus protocol profile aliases (`.axi`, `.apb`, `.ahb`) | Protocol/platform intent: bus roles, transaction envelopes, ID/ordering rules, response routing. |
| **IAL1** | `.isf` Intent Scheduling Format | Scheduling intent: actors, transactions, drive blocks, control flow, rules/priorities, verification intent. |
| **IAL0** | `.fsm` | Explicit cycle-authored state machines — the HDL-facing base layer. |

Lowering is strictly layered:

```text
IAL2 (.ppif / .axi / .apb / .ahb) -> IAL1 (.isf) -> IAL0 (.fsm) -> HDL
```

Direct IAL2-to-IAL0 lowering is forbidden; IAL2 must emit or preserve reviewable
IAL1 first ([0014](docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md)).
Protocol suffixes are vocabulary/profile aliases over the same IAL2 layer, not
separate layers and not a lowering shortcut
([0015](docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md),
[0016](docs/decisions/0016-ppif-is-first-public-ial2-container.md)).

### Backend-language neutrality

FSMGen is currently implemented in Perl 5, but IAL0, IAL1, IAL2, their public
file formats, reports, diagnostics, examples, and the mdBook are
**backend-language-neutral contracts**. The Perl implementation is the current
reference/oracle, not the definition of the layers
([0018](docs/decisions/0018-ial-contracts-are-backend-language-neutral.md)).

Future Rust, Rust/Wasm, browser JavaScript, and Dart/web implementations target
those same observable contracts, with parity expected for features, diagnostics,
semantic introspection, examples, fixtures, and tests. The mdBook is the
language-independent blueprint for building a conforming variant — see
[Implementation Blueprint](docs/book/src/15-implementation-blueprint.md).

For SystemVerilog-to-Verilog portability the default stance remains FSMGen-owned
generation/lowering rather than a mandatory external converter; tools such as
`sv2v` are audit candidates only.

### Semantic introspection and MCP

Deep semantic introspection is a first-class feature: a stable
semantic-introspection API first, with MCP as an adapter over that API.
`bin/fsmgen-mcp` ships a **read-only** local JSON-RPC stdio adapter; write,
generation, sampling, and elicitation surfaces are not enabled. The shipped
profile, its protocol boundaries, and its compatibility matrix are documented in
[Extensions and Embedding](docs/book/src/11-extensions-and-embedding.md).

### Where current state lives — do not look for it here

This file is a **bounded discovery entry point**. It carries objective, layer
model, layout, standard commands, invariants, and navigation. It deliberately
does **not** narrate what each work unit shipped
([0021](docs/decisions/0021-readme-is-a-bounded-discovery-entrypoint.md),
extending [0007](docs/decisions/0007-memory-architecture-supersedes-blob-narration.md)).

Route your question to the layer that owns the answer — each is current by
construction and mechanically checked, which prose narration was not:

| Question | Canonical source |
| --- | --- |
| Where are we now? What is next? | `MEMORY.md` (layer A, bounded resume pointer) |
| What is being built, with what status/frontier/evidence? | `docs/TASK_TREE.md` → the owning tree in `docs/tasks/` (layer B) |
| Why is it this way? What was decided and why? | `docs/decisions/INDEX.md` (layer C) |
| What changed, when, by which work unit? | `git log --grep=<UNIT-ID>` (layer D) |
| What does the shipped behavior do, with examples? | the mdBook, `docs/book/` |
| Is this sample supported/accounted for? | `docs/REGRESSION_CORPUS.md` + `prove -Iperl t/248-regression-corpus-accounting.t` |
| Is fact X already established? | `KNOWLEDGE_MAP.md` → the fact card under `docs/knowledge/` |
| How do I diagnose a failure? | `TOOLBOX.md` |
| Which rules are mechanically enforced? | `DOCTRINE_ENFORCEMENT.md` → `scripts/check_doctrines.sh --list` |

Active workstream direction stays high-level in `ROADMAP_V2.md`; per-leaf
execution detail belongs to the task-trees, never to this file.

## Fast ramp-up order
1. `README.md` (this file): project objective + navigation.
2. `COMMIT.md`: mandatory commit workflow and safety invariant for crash recovery; pair it with `DOCTRINE_ENFORCEMENT.md` and `TOOLBOX.md` for the mechanical rule gate and diagnostic commands.
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
16. `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`: single self-contained downstream `.isf` integration handoff plus `.ppif`/IAL2-to-IAL1 lowering-stack boundary.
17. `docs/DOWNSTREAM_ISSUE_REPORTING.md`: strict downstream issue-reporting protocol for local FSMGen reproduction.
18. `docs/ISF_SPEC.md`: active R14 `.isf` Intent Scheduling Format specification.
19. `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`: live downstream-consumer API contract for ISF parser/scheduler surfaces.
20. `docs/ISF_LIBRARY_CATALOG.md`: live catalog of shipped reusable ISF library definitions.
21. `docs/BIN_FSMGEN_IMPORT_TREE.md`: live `bin/fsmgen` import-tree and runtime-spine architecture snapshot.
22. `docs/REGRESSION_CORPUS.md`: human-readable regression/support-accounting corpus companion.
23. `docs/INTENT_CAPTURE_AXI_CASE_STUDY.md`: AXI intent-capture case-study notes for future high-level synthesis work.
24. `docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md`: first non-code IAL2 protocol/platform intent evaluation and go/no-go criteria.
25. `docs/AXI_VALID_READY_INTENT_PROBE.md`: first AXI Valid-Ready source-anchor evidence inventory for future IAL2 design/probe work.
26. `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`: captured AXI manager user-facing API direction for future IAL2 work.
27. `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`: first AXI ID/order/concurrency source-anchor evidence inventory for future IAL2 manager rule-engine work.
28. `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`: first AXI manager source-to-rule responsibility matrix for future IAL2 work.

That is the ramp-up. Everything past this point is reference, not reading
order — pull it on demand:

- **Per-slice selector / readiness-audit / behavior records** (the `docs/AXI_IAL2_*`,
  `docs/IAL1_*`, and similar per-work-unit documents) are listed in the
  documentation index below and owned by their task-tree leaf. They are written
  to be read when you touch that leaf, not in sequence — do not treat them as
  ramp-up steps.
- For what a given work unit did and why, use `git log --grep=<UNIT-ID>` and the
  owning tree under `docs/tasks/`, per
  [0021](docs/decisions/0021-readme-is-a-bounded-discovery-entrypoint.md).

## Documentation index (all `.md` files in this repo)
- `README.md` — single entry point and navigation hub.
- `DOCTRINE_ENFORCEMENT.md` — root doctrine-enforcement architecture and check registry.
- `TOOLBOX.md` — root FSMGEN diagnostic toolbox and gate-command catalog.
- `SESSION_BOOTSTRAP.md` — canonical first-task file for a new engineering session.
- `ROADMAP_STATUS.md` — canonical live roadmap/workstream status board.
- `ROADMAP_V2.md` — detailed post-`R0`..`R7` roadmap intent and sequencing.
- `docs/book/` — mdBook source for the progressive FSMGen book.
- `docs/BOOK_PLAN.md` — migration plan from the monolithic guide into the mdBook.
- `docs/USER_GUIDE.md` — broad live reference and command usage during the split.
- `docs/TASK_TREE_README.md` — setup guide for adopting the task-tree tracking workflow in another project.
- `docs/TASK_TREE.md` — repo-local task-tree workflow, active tree index, and PNT frontier rules.
- `docs/tasks/TEMPLATE.md` — reusable template for one top-level task tree.
- `docs/tasks/GENERATED-HDL-ARTIFACT-PLACEMENT.md` — completed artifact-hygiene task tree for routing implicit generated HDL into git-ignored hidden artifact directories while preserving explicit output paths.
- `docs/tasks/RHS-LOGIC-SIMPLIFICATION-FRONTIER.md` — completed generated-HDL quality tree for AST-level boolean and width-proven vector/multi-bit RHS logic-equivalence simplification before HDL emission.
- `docs/tasks/DOCTRINE-ENFORCEMENT-ADOPTION.md` — completed adoption tree for the portable doctrine-enforcement architecture, FSMGEN-specific issue-pinpointing toolbox catalog, doctrine driver, bootstrap self-check, docs path wrapper, pre-commit wiring, and hosted CI wiring.
- `docs/tasks/AGENT-RUNTIME-RAM-GUARD.md` — agent-runtime safety tree for guarded heavyweight local commands that could otherwise exhaust host RAM.
- `docs/tasks/PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.md` — completed roadmap-maintenance task tree that routed the 2026-06-05 remaining-work inventory to existing active owners or new broad owner trees.
- `docs/tasks/COMPOSITION-TYPE-BACKLOG-EXHAUSTION.md` — completed Composition/type backlog tree; shipped aggregate parameter/generic equality/inequality, closed the remaining Composition/type leaves behind exact prerequisites, and routed VHDL-dependent work through the completed backend/API frontier.
- `docs/tasks/ISF-REMAINING-BROAD-FRONTIER.md` — proposed broad `R14` ISF frontier owner tree for deferred ISF backlog directions not already owned by narrower active trees.
- `docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md` — completed current backend-language portability contract tree.
- `docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md` — completed IAL1-first verification-code generation tree.
- `docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` — proposed, inactive architecture tree naming current synthesizable IAL0/1/2 as HIAL and auditing a peer pure-verification VIAL with a typed bridge, native SV/UVM and VHDL verification lowerings, and separate event-capable compiled Verilator versus full-language/UVM validation profiles; the current parent selection keeps this architecture proposed while the adjacent exact-three AHB alias ships next.
- `docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md` — completed implementation owner for the selected IAL1 passive observation source feature.
- `docs/tasks/ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.md` — completed downstream-response task tree answering SPECFORGE's 2026-06-16 transaction phase-membership/value/order request; records that no runtime code change was needed, `.isf` remains SPECFORGE's synthesizable target, future checked transaction phase-group metadata belongs in an owned ISF slice, and `.val` is not a replacement for `.isf`.
- `docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.md` — completed downstream-response task tree for SPECFORGE's 2026-06-22 declarative field-structured storage request; records that FSMGen accepts the direction as future ISF work, existing runtime field operations are not static field-map declarations, and implementation selection moves to `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1`.
- `docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md` — completed ISF storage-metadata frontier.
- `docs/ISF_FIELD_STRUCTURED_STORAGE_FRONTIER_CLOSEOUT.md` — closeout for `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.5`; records that scalar storage fields are shipped/support-accounted and that broader field behavior/layout/semantic-payload directions require future exact task-tree leaves.
- `docs/ISF_FIELD_STRUCTURED_STORAGE_NEXT_RESIDUAL_SELECTION.md` — selector for `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.3`; records that the next bounded residual is a support-accounted scalar storage-field fixture and explicitly defers broader field behavior/layout/semantic-payload work.
- `docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md` — audit for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2`; records that existing IAL1 checks/properties are sufficient for inline SV assertion projection but not enough for first-class generated verification artifacts, and selects `.3`.
- `docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3`; chooses the metadata-only actor-level `observe` source contract and routes implementation to `ISF-VERIFICATION-OBSERVATION-METADATA.1`.
- `docs/IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`; chooses a passive UVM monitor skeleton package as the first SV/UVM output target and routes public CLI/artifact/report/support-accounting selection to `.7`.
- `docs/IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`; chose `--emit-verification-output uvm-passive-monitor --verification-outdir DIR`, the UVM package artifact layout, manifest shape, support-accounting entry, capability-manifest surface, diagnostics, and validation boundary implemented by `.8`.
- `docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5`; records that no VHDL verification artifact is selected yet and routes the prerequisite to `.9`, VHDL verification validation-substrate selection.
- `docs/IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9`; chooses shape-only inert-artifact validation with explicit no-compile/no-PSL manifest claims and routes first VHDL artifact selection to `.10`.
- `docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md` — selector for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10`; chose `vhdl-observation-package`, an inert VHDL observation metadata package target implemented by `.11`.
- `docs/IAL1_DIRECT_IAL2_VERIFICATION_ROUTE_AUDIT.md` — audit for `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6`; selected no direct `.ppif` verification-output route for the current lane and requires future protocol verification facts to route through reviewable generated IAL1 unless a later exact owner proves otherwise.
- `docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md` — completed immediate semantic-introspection/MCP task tree.
- `docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md` — completed backend/API frontier owner tree for VHDL, external validation, ABC, structured generation, embedding API, and normalized export backlog through `.132`.
- `docs/tasks/ARCHITECTURE-DEBT-FRONTIER.md` — completed architecture-debt frontier owner tree; direct-backend structural internal declaration nets shipped, and ISF parser/lowerer extraction remains deferred behind future exact ownership.
- `docs/tasks/ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES.md` — completed `R14` task tree that added runnable `lisp` book examples (in `13d`) for the shipped loop-contained spawn + `(await_all done)` and multi-pending `(await_any done)` + drain features (`t/1376` count 36 → 38); all repeat-body-activation frontier shapes now have copy-pasteable book examples.
- `docs/tasks/ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING.md` — completed `R14` task tree (scheduler-frontier #6) that lifted the multi-pending `(await_any done)` + later `(await_all done)` deferral for loop-contained / deeper-nested repeats, locked by `t/1384`; **completes the repeat-body-activation nesting frontier** (cross-domain `do` is excluded — net-new CDC lowering).
- `docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.md` — completed `R14` task tree (scheduler-frontier #5) that enabled the basic `(spawn ...)` + same-body `(await_all done)`/single-pending `(await_any done)` subset inside a loop-contained or deeper-nested repeat (lowering + composition parity with the top-level repeat-body spawn); gate relaxation + drain-requirement rule + multi-pending-await_any deferral, locked by `t/1383`. Undrained/multi-pending spawn and cross-domain stay deferred; the full-HDL composition-wiring limitation is pre-existing (top-level too).
- `docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #4) that enabled a same-domain generated `(do child (params ...))` at deeper branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`) to lower + instantiate its child; a 3-part lowering change (collector recursion, param threading, validator relaxation) locked by `t/1382` with verified `.fsm`↔`_top` ordinal agreement, cross-domain and spawn deferred.
- `docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #3) that enabled a plain local `(do child)` at deeper branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`) to lower; a clean validator relaxation locked by `t/1381` (deeper-nested generated-do and spawn stay deferred).
- `docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #2) that enabled a same-domain generated `(do child (params ...))` inside a `(repeat ...)` directly in one `(while ...)`/`(until ...)` body to lower and instantiate its child in the `_top`; threaded the generated-child activation through the loop-body path + added loop-body discovery to the collector, locked by `t/1380` (cross-domain do and spawn stay deferred).
- `docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #1) that enabled a plain local `(do child)` inside a `(repeat ...)` directly contained in one `(while ...)`/`(until ...)` body to lower; a validator-only gate relaxation locked by `t/1379` (spawn, generated-do, and deeper nesting stay deferred).
- `docs/tasks/ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.md` — completed `R14` task tree answering SPECFORGE's 2026-05-29 clarity request on the actor-local `(types)`↔`(enums)` relationship; documents that an enum name is not an auto type alias (co-declare `(type NAME (bits k))`), replies in `docs/SPECFORGE_FEEDBACK_RESPONSE.md`, and locks the rule with `t/1378`.
- `docs/tasks/R14-ASPECT-COVERAGE-AUDIT.md` — completed `R14` roadmap-maintenance task tree confirming every ISF backlog aspect is task-tree owned; registered `ISF-FULL-WIDTH-INFERENCE` (Proposed) and recorded IAL2 as a non-R14 horizon exploration.
- `docs/tasks/ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.md` — active `R14` task tree (CDC lane) enabling a blocking cross-domain `(do)`/`(spawn)` through a new `(crossings (activation child (from SRC)(to DEST)))` kind that routes the activation start/done through two acknowledged-event CDC children; validator-acceptance and CDC routing ship together (a validator-only relaxation would emit an unsynchronized cross-clock handoff).
- `docs/tasks/ISF-FULL-WIDTH-INFERENCE.md` — completed `R14` task tree: activated, probed, and found no decidable multi-unknown extract/assemble width-inference sub-case beyond the shipped single-missing inference (2+-unknown is underdetermined → correctly fail-closed); recorded the fail-closed terminal and locked it with `t/1385`.
- `docs/tasks/BOOK-COOKBOOK-COMPOSITION-RUNNABLE.md` — completed `R14` task tree that upgraded cookbook composition recipes 3/4/5 from `text` schematics to verified inline-runnable `lisp` examples (C1/C2/C3 patterns proven by `t/101`); `t/1377` now gates 14 standalone `.fsm` fixtures.
- `docs/tasks/BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.md` — completed `R14` task tree that extended the example-correctness build gate from the ISF surface to the non-ISF `.fsm` (IAL0) book chapters; demoted 19 multi-file/schematic blocks to `text` and added `t/1377-book-fsm-example-generation-audit.t` (11 standalone `.fsm` fixtures gated).
- `docs/tasks/CI-CORPUS-SYSTEM-INCOMPLETE-SECTION-FIX.md` — completed CI-maintenance task tree that fixed the stale `t/corpus/system_incomplete_section.fsm` fixture.
- `docs/tasks/ISF-G8-HEADING-DENSITY.md` — completed `R14` task tree that added 4 sub-headings to the Pipeline section of 13-intent-scheduling.md.
- `docs/tasks/ISF-G4-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree that appended a dated status snapshot to 14-feature-backlog.md.
- `docs/tasks/ISF-G2-LOW-DENSITY-EXAMPLES.md` — completed `R14` task tree that added constants_demo (13a), bank_demo + dataop_demo (13e) examples.
- `docs/tasks/ISF-G5-13-INTENT-EXAMPLES.md` — completed `R14` task tree that added blinker + handshake_intent examples to 13-intent-scheduling.md.
- `docs/tasks/ISF-G6-13J-EXAMPLES.md` — completed `R14` task tree that added 3 complete actor examples (type_alias_demo, enum_demo, aggregate_storage_demo) to 13j.
- `docs/tasks/ISF-G7-13D-ACCEPT-PATH-EXAMPLES.md` — completed `R14` task tree that added 4 complete accept-path control-flow actor examples (when/switch+default/while/until) to 13d.
- `docs/tasks/ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.md` — completed `R14` task tree that propagated the recent diagnostic surface (cross-domain, sub-axis, loop-contained, deeper-nested, `t/1372-1376`) to `ISF_PUBLIC_INTERFACE_CONTRACT.md` and `SPECFORGE_FEEDBACK_RESPONSE.md`.
- `docs/tasks/ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.md` — completed `R14` task tree that added `t/1376-isf-book-example-lowering-audit.t`. The test extracts every `lisp`-tagged book block and verifies it parses + lowers; failures block the test suite. 20 fixtures currently lower cleanly.
- `docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-G3.md` — completed `R14` task tree that added 4 representative examples for the remaining `remains deferred` template families and adopted the `lisp` vs `text` block-tag convention (`lisp` for accept-path fixtures only).
- `docs/tasks/ISF-COOKBOOK-WALKTHROUGHS.md` — completed `R14` task tree that added clause-by-clause walkthroughs to cookbook ISF recipes 9-13.
- `docs/tasks/ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.md` — completed `R14` task tree that fixed 14 broken ISF examples identified in the example-correctness audit addendum. Re-audit reports 20 complete fixtures lower cleanly, 0 failures.
- `docs/tasks/ISF-COOKBOOK-RECIPES-G1.md` — completed `R14` task tree that addressed audit gap G1 by adding five ISF recipes to cookbook chapter 12 (basic actor, spawn, parameterized blocking do, rule trigger, repeat-body generated do).
- `docs/tasks/ISF-MDBOOK-COVERAGE-AUDIT.md` — completed `R14` doc-only task tree that published `docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md` identifying eight gap categories (G1-G8) and a prioritized slice queue for closing the coverage gap between the codebase and the mdBook.
- `docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.md` — completed `R14` task tree that added user-facing `.fsm` source examples to book chapters 13b (five examples) and 13d (two examples) for the seven targeted diagnostics shipped this session (cross-domain repeat-body do, four activation-override sub-axes, loop-contained, deeper-nested).
- `docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.md` — completed `R14` task tree that extended the targeted-diagnostic synchronization for the loop-contained and deeper-nested slices to book chapters `13b-transactions.md`, `13d-control-flow.md`, `13h-lowering-reference.md`, and `13k-isf-feature-support-matrix.md`.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.md` — completed bootstrap architecture-maintenance task tree consolidating the import-tree note refresh for the four R14 diagnostic-precision slices; recorded `LoweringIR.pm` line count moved from `11144` to `11309`; topology unchanged.
- `docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that shipped a targeted `deeper-nested repeat-body <do|spawn> remains deferred` diagnostic for deeper-when and when-inside-switch cases at the two repeat-body subset entry points; broader deeper-nested implementation remains a future leaf; regression `t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t`.
- `docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that shipped a targeted `loop-contained repeat-body <do|spawn> remains deferred` diagnostic when a `(repeat ...)` with `do` or `spawn` body clauses is nested inside `(while ...)` or `(until ...)`; broader loop-contained implementation remains a future leaf; regression `t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t`.
- `docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that split the aggregated static-timing override gate into four sub-axis-specific gates (repeat-count, wait-count, latency-bound, watchdog-limit) each with its own targeted diagnostic; regression `t/1373-isf-timing-param-sub-axis-diagnostic.t`.
- `docs/tasks/ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that shipped a targeted cross-domain repeat-body `do` diagnostic; broader cross-domain `do` implementation remains a separate future leaf of this tree; regression `t/1372-isf-cross-domain-repeat-body-do-diagnostic.t`.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.md` — completed `R14` task tree that extended the activation-site parameter override-specialized default-preserving gate to transaction port widths (`(ports (input/output NAME (width PARAM)))`); regression `t/1371-isf-transaction-port-activation-override-width-gate.t`.
- `docs/tasks/ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.md` — completed `R14` task tree that extended the activation-site parameter override-specialized default-preserving gate from timing parameters (wait, repeat, latency, watchdog, contract) to data-operation width parameters (`shift_left`, `shift_right`, `assemble`, `extract`); regression `t/1370-isf-data-op-activation-override-width-gate.t`.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the same-domain generated `(do worker (params ...) (bind ...) (domain core))` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets, completing the BEFORE-POST-DO-AWAITANY missing-drain matrix across the five generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the bound generated `(do worker (params ...) (bind ...))` before post-do multi-pending `(await_any done)` without final drain shape on the when-body subset (switch already existed).
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the static-parameter generated `(do worker (params ...))` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the plain generated-child `(do worker)` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-LOCALDO-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the local `(do child)` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the static-parameter generated `(do worker (params ...))` prior-`await_any` plus spawn-after-do without final drain shape on the switch-branch subset, completing the SPAWN-AFTER-DO without-drain matrix across the five generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the plain generated-child `(do worker)` prior-`await_any` plus spawn-after-do without final drain shape on the switch-branch subset.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the bound generated `(do child (params ...) (bind ...))` prior-`await_any` plus second post-spawn `await_any` shape on both branch-contained subsets, completing the SECOND-AWAITANY missing-drain matrix across the five generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the static-parameter generated `(do child (params ...))` prior-`await_any` plus second post-spawn `await_any` shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the plain generated-child `(do child)` prior-`await_any` plus second post-spawn `await_any` shape on the switch-branch subset.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the same-domain generated `do` prior-`await_any` plus second post-spawn `await_any` shape.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-DOMAIN-SECOND-AWAITANY-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after the R14 same-domain generated-do prior-`await_any` plus second post-spawn `await_any` repeat-body slice.
- `docs/tasks/ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for prior-observation second post-spawn `await_any` mdBook and `t/1307` audit wording across the local-do plus four generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained same-domain generated `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-BOUND-SECOND-AWAITANY-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after the R14 static-parameter and bound generated-do prior-`await_any` plus second post-spawn `await_any` repeat-body slices.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained bound generated `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained static-parameter generated `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after the R14 generated-child second-`await_any` slice.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained plain generated-child `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-REPEAT-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after recent R14 repeat-body child-activation slices.
- `docs/tasks/ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained local `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained same-domain generated `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained bound generated `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained static-parameter generated `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.md` — completed `R14` documentation/audit truth-sync task tree for prior-`await_any` spawn-after-do repeat wording.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained plain generated-child `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained local `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained same-domain generated `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained bound generated `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained static-parameter generated `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained local `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained plain generated-child `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained same-domain generated `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained bound generated `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained static-parameter generated `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained plain generated-child `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained local `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.md` — completed `R14` task tree for same-domain generated `do` before post-do multi-pending `await_any` in branch-contained nested repeats.
- `docs/tasks/ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for mdBook static-zero repeat child-activation wording.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after static-zero repeat pruning.
- `docs/tasks/ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.md` — completed `R14` task tree for bounded static-zero repeat specialized child-activation artifact pruning.
- `docs/tasks/ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.md` — completed `R14` task tree for bounded static-zero repeat child-activation artifact pruning.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note.
- `docs/tasks/ISF-STATIC-ZERO-REPEAT-NOOP.md` — completed `R14` task tree for bounded static zero-count repeat no-op lowering.
- `docs/tasks/ROADMAP-R14-REPEAT-ZERO-STATUS-TRUTH-SYNC.md` — completed `R14` roadmap maintenance task tree for repeat zero status truth sync.
- `docs/tasks/NO-RESET-SCHEDULED-FSM-HDL.md` — completed `R14` task tree for reset-free scheduled `.fsm` HDL support.
- `docs/tasks/ISF-CDC-NO-RESET-FIXTURE.md` — completed `R14` task tree for no-reset acknowledged-event CDC fixture coverage.
- `docs/tasks/ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for data-operation width backlog wording.
- `docs/tasks/ISF-SCHEDULE-REPORT-STORAGE-ROLES.md` — completed `R14` task tree for additive schedule-report storage-role metadata.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.md` — completed `R14` task tree for same-transaction-parameter-zero runtime divisor safety.
- `docs/tasks/ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for static timing fail-closed checklist wording.
- `docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.md` — completed `R14` task tree for generated child static timing parameter activation override gates.
- `docs/tasks/ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in top-level await-local watchdog limits.
- `docs/tasks/ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in latency bounds.
- `docs/tasks/ISF-WAIT-TRANSACTION-PARAM-COUNTS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in wait counts.
- `docs/tasks/R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the top-boundary convention/connect-by-name frontier.
- `docs/tasks/R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the portable synthesizable-type frontier.
- `docs/tasks/R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the reusable standalone-DT/module-library frontier.
- `docs/tasks/R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the shared-datapath contract frontier.
- `docs/tasks/R11-PARAMETER-GENERIC-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the semantic parameter/generic frontier.
- `docs/tasks/R11-RTLIF-INTERFACE-SOURCE-DIRECTION.md` — completed `R11` task tree for deciding the `.rtlif` interface-source direction.
- `docs/tasks/R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the next composition-contract frontier.
- `docs/tasks/R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.md` — completed `R10` task tree for auditing the diagnostic/provenance exit frontier.
- `docs/tasks/R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.md` — completed `R10` task tree for cleaning D-input self-dependency diagnostic implementation leakage.
- `docs/tasks/R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.md` — completed `R10` task tree for cleaning direct self-dependency diagnostic stack leakage.
- `docs/tasks/R10-CLI-QUIET-BANNER-CLEANUP.md` — completed `R10` task tree for aligning quiet CLI banner behavior with diagnostics.
- `docs/tasks/R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.md` — completed `R10` task tree for auditing and cleaning up the next source-provenance and diagnostic frontier.
- `docs/tasks/R9-STRICT-MODE-FRONTIER-AUDIT.md` — completed `R9` task tree for auditing the strict-mode support-tier frontier.
- `docs/tasks/R8-LANGUAGE-CONTRACT-EXIT-AUDIT.md` — completed `R8` task tree for auditing the language-contract exit criteria.
- `docs/tasks/RICHER-AGGREGATE-OPERATORS.md` — completed aggregate-types task tree for richer aggregate operator widening.
- `docs/tasks/R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.md` — completed `R8` task tree for resolving the next parser-accepted language-surface gray zone.
- `docs/tasks/BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.md` — completed aggregate-types task tree for backend-owned structured aggregate lowering audit.
- `docs/tasks/AGGREGATE-AUTOGROWTH-FROM-USAGE.md` — completed aggregate-types task tree for bounded automatic aggregate growth from usage.
- `docs/tasks/DYNAMIC-DIVISOR-SAFETY-FRONTIER.md` — completed language-ergonomics task tree for direct runtime literal-zero divisor rejection.
- `docs/tasks/INFERENCE-FIRST-SCALAR-AUTHORING.md` — completed language-ergonomics task tree for the first inference-first scalar authoring slice.
- `docs/tasks/COMPOSITION-WIRING-LISPISH.md` — completed `R11` task tree for canonical Lisp-ish `?wiring` list forms.
- `docs/tasks/R8-STRICT-SUPPORT-TIER-CUTS.md` — completed `R8` task tree for the latest strict-mode support-tier cut.
- `docs/tasks/FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.md` — completed roadmap-maintenance task tree for broad feature-backlog owner coverage synchronization.
- `docs/tasks/TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for synchronizing stale completed task-tree commit evidence.
- `docs/tasks/TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for synchronizing stale `this commit` completed task-tree evidence.
- `docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNTS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in repeat counts.
- `docs/tasks/ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.md` — completed `R14` roadmap-maintenance task tree for detailed active-lane roadmap status truth sync.
- `docs/tasks/ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.md` — completed `R14` task tree for generated blocking `do` binding timing regression coverage.
- `docs/tasks/ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for binding timing history truth sync.
- `docs/tasks/ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for rule-trigger output-binding history truth sync.
- `docs/tasks/ISF-DIRECT-ON-PARAM-DIAGNOSTIC.md` — completed `R14` task tree for direct `(on ... (params ...))` diagnostic hardening.
- `docs/tasks/ISF-CONFLICT-RESOLUTION.md` — completed `R14` task tree for ISF same-cycle conflict semantics.
- `docs/tasks/ISF-TRANSACTION-OVER-RULE-PRIORITY.md` — completed `R14` task tree for covered transaction-over-rule same-target priority.
- `docs/tasks/ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for stale transaction-over-rule priority mdBook wording.
- `docs/tasks/ISF-COMPOSITION-INSTANTIATION.md` — completed `R14` task tree for generated child instantiation and spawn parameter binding.
- `docs/tasks/ISF-STORAGE-PORT-ROUND-ROBIN.md` — completed `R14` task tree for bounded storage-port round-robin resource arbitration.
- `docs/tasks/ISF-OUTPUT-BUNDLE-ROUND-ROBIN.md` — completed `R14` task tree for bounded output-bundle round-robin resource arbitration.
- `docs/tasks/ISF-TRANSACTION-START-ROUND-ROBIN.md` — completed `R14` task tree for bounded transaction-start round-robin resource arbitration.
- `docs/tasks/ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.md` — completed `R14` task tree for bounded round-robin resource arbitration.
- `docs/tasks/ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.md` — completed `R14` task tree for output-bundle priority resource enforcement.
- `docs/tasks/ISF-STORAGE-PORT-RESOURCE-PRIORITY.md` — completed `R14` task tree for storage-port priority resource enforcement.
- `docs/tasks/ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.md` — completed `R14` task tree for storage-port member documentation truth sync.
- `docs/tasks/ISF-RESOURCE-PRIORITY.md` — completed `R14` task tree for resource arbitration and priority enforcement.
- `docs/tasks/ISF-RESOURCE-CATALOG.md` — completed `R14` task tree for the shareable resource kind registry.
- `docs/tasks/ISF-RULE-ACTIONS.md` — completed `R14` task tree for expression-valued rule assignments.
- `docs/tasks/ISF-STAGES-CONTRACTS.md` — completed `R14` task tree for transaction stages and temporal contracts.
- `docs/tasks/ISF-DATA-WIDTHS.md` — completed `R14` task tree for data-operation width inference.
- `docs/tasks/ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in data-operation width evidence.
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
- `docs/tasks/ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.md` — completed `R14` task tree for generated-child rule-trigger output bindings.
- `docs/tasks/ISF-CONTROL-FLOW.md` — completed `R14` task tree for transaction-local waits and dynamic loops.
- `docs/tasks/ISF-WAIT-ZERO.md` — completed `R14` task tree for zero-count transaction wait semantics.
- `docs/tasks/ISF-DYNAMIC-WAIT.md` — completed `R14` task tree for non-literal transaction wait counts.
- `docs/tasks/ISF-PARAM-WAIT-COUNTS.md` — completed `R14` task tree for actor-parameter-backed static transaction wait counts.
- `docs/tasks/ISF-WAIT-PACKAGE-CONSTANT-COUNTS.md` — completed `R14` task tree for qualified package scalar constants in static transaction wait counts.
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
- `docs/tasks/ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.md` — completed `R14` task tree for qualified package scalar constants in temporal contract windows.
- `docs/tasks/ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.md` — completed `R14` task tree for generated child same-transaction scalar parameter defaults in temporal contract windows.
- `docs/tasks/ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.md` — completed `R14` task tree for direct transaction same-transaction scalar parameter defaults in temporal contract windows.
- `docs/tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.md` — completed `R14` task tree for activation-site override diagnostics on generated child temporal contract-window parameters.
- `docs/tasks/ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for activation override diagnostic coverage synchronization.
- `docs/tasks/ROADMAP-R14-LATEST-SLICE-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for latest R14 slice roadmap truth synchronization.
- `docs/tasks/ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for historical transaction-port binding recovery-note truth synchronization.
- `docs/tasks/ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.md` — completed `R14` task tree for duplicate generated rule-trigger output actor-target diagnostics.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for transaction-port binding report non-claim wording.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.md` — completed `R14` task tree for duplicate output-binding actor-target diagnostics.
- `docs/tasks/ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.md` — completed `R14` task tree for direct/local rule-trigger output-binding diagnostic hardening.
- `docs/tasks/ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for authored binding timing metadata wording.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.md` — completed `R14` task tree for authored transaction-port binding timing request report metadata.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.md` — completed `R14` task tree for bounded transaction-port binding timing report metadata.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.md` — completed `R14` task tree for explicit transaction input-binding timing syntax.
- `docs/tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.md` — completed `R14` task tree for same-value activation-site overrides on generated child temporal contract-window parameters.
- `docs/tasks/ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.md` — completed `R14` task tree for positive actor constants in transaction latency bounds.
- `docs/tasks/ISF-LATENCY-ACTOR-PARAM-BOUNDS.md` — completed `R14` task tree for actor-parameter-backed transaction latency bounds.
- `docs/tasks/ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.md` — completed `R14` task tree for qualified package scalar constants in transaction latency bounds.
- `docs/tasks/ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor interface port widths.
- `docs/tasks/ISF-INTERFACE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor interface port widths.
- `docs/tasks/ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in actor interface port widths.
- `docs/tasks/ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in actor-owned scalar storage widths.
- `docs/tasks/ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned scalar storage widths.
- `docs/tasks/ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned scalar storage widths.
- `docs/tasks/ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned bank storage depths.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.md` — completed `R14` task tree for transaction-port binding endpoint-kind schedule-report metadata.
- `docs/tasks/ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for stale mdBook transaction-port package-constant width wording.
- `docs/tasks/ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in explicit data-operation width evidence.
- `docs/tasks/ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.md` — completed `R14` task tree for qualified package scalar constants in actor-owned bank storage depths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned bank storage depths.
- `docs/tasks/ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.md` — completed `R14` task tree for positive actor constants in watchdog limits.
- `docs/tasks/ISF-WATCHDOG-ACTOR-PARAM-LIMITS.md` — completed `R14` task tree for actor-parameter-backed watchdog limits.
- `docs/tasks/ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.md` — completed `R14` task tree for qualified package scalar constants in watchdog limits.
- `docs/tasks/ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor constants as repeat counter width evidence.
- `docs/tasks/ISF-REPEAT-ACTOR-PARAM-COUNTS.md` — completed `R14` task tree for actor-parameter-backed repeat counts.
- `docs/tasks/ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.md` — completed `R14` task tree for qualified package scalar constants in static transaction repeat counts.
- `docs/tasks/ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.md` — completed `R14` task tree for a bounded static zero-count repeat policy.
- `docs/tasks/ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.md` — completed `R14` task tree for runtime scalar repeat zero-count skip policy.
- `docs/tasks/ISF-REPEAT-COUNT-SOURCE-BOUNDARY.md` — completed `R14` task tree for the accepted repeat count source boundary.
- `docs/tasks/ISF-BACKLOG-OWNER-TRUTH-SYNC.md` — completed `R14` task tree for mdBook backlog task-tree owner truth synchronization.
- `docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.md` — completed `R14` task tree for targeted transaction-parameter repeat count diagnostics.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.md` — completed `R14` task tree for dynamic-divisor drive-expression coverage hardening.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-CONTROL-BANK-COVERAGE.md` — completed `R14` task tree for dynamic-divisor control and bank expression coverage hardening.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.md` — completed `R14` task tree for actor-parameter-zero dynamic-divisor safety.
- `docs/tasks/ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for synchronizing stale next-PNT roadmap wording.
- `docs/tasks/CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.md` — completed project-operations task tree for repairing the hosted strict wiring and direct LHS diagnostic regression.
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
- `docs/tasks/ISF-ACTIVATION-PARAM-ACTOR-PARAMS.md` — completed `R14` task tree for actor-local scalar parameter defaults as generated activation parameter override values.
- `docs/tasks/ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for activation parameter value-domain prose.
- `docs/tasks/ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.md` — completed `R14` task tree for actor static values in reusable-library use-site parameter overrides.
- `docs/tasks/ISF-LIBRARY-USE-PACKAGE-CONSTANTS.md` — completed `R14` task tree for package scalar constants in reusable-library use-site parameter overrides.
- `docs/tasks/ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.md` — completed `R14` task tree for actor constants in actor parameter defaults.
- `docs/tasks/ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.md` — completed `R14` task tree for ordered actor-parameter-backed actor parameter defaults.
- `docs/tasks/ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.md` — completed `R14` task tree for actor-static generated-child transaction parameter defaults.
- `docs/tasks/ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.md` — completed `R14` task tree for earlier-scalar generated-child transaction parameter dependency defaults.
- `docs/tasks/ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.md` — completed `R14` task tree for package scalar constants in generated-child transaction parameter defaults.
- `docs/tasks/ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.md` — completed `R14` task tree for package scalar constants in generated activation parameter overrides.
- `docs/tasks/ROADMAP-CURRENT-ACTIVE-LANE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for synchronizing stale current-active-lane roadmap wording.
- `docs/tasks/ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.md` — completed `R14` task tree for package scalar constants in actor parameter defaults.
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
- `docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md` — proposed critical architecture task tree for source-facing FSMGEN HIR as the shared high-level frontend target above IAL2 and IAL1.
- `docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md` — completed architecture follow-up that guarded the current direct-root `structural_rtl_ir` projection before future convergence work.
- `docs/tasks/IR-EXPRESSION-AST-OWNERSHIP.md` — completed architecture follow-up for expression representation ownership and conversion boundaries.
- `docs/tasks/EXPR-NAMER-TRACKED-COPY-CLEANUP.md` — completed architecture follow-up that removed the tracked `ExpressionNamer.pm.new` duplicate.
- `docs/tasks/EXPR-AST-UTILS-OWNER-CONSOLIDATION.md` — completed architecture follow-up that collapsed duplicate `FSM::AST::Utils` ownership.
- `docs/tasks/EXPR-NAMER-LEGACY-PARSE-BOUNDARY.md` — completed architecture follow-up for guarding `ExpressionNamer` legacy hash/string parse boundaries.
- `docs/tasks/GLOBAL-AST-MANAGER-BOUNDARY.md` — completed architecture follow-up for resolving legacy `GlobalASTManager` ownership.
- `docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md` — completed architecture follow-up that inventoried private ISF `LoweringIR` subfamilies and deferred helper-owner extraction.
- `docs/tasks/MODULE-INFO-PROJECTION-GUARD.md` — completed architecture follow-up that audited `module_info` mirrors and closed without extra guard work.
- `docs/tasks/ROADMAP-ACTIVE-LANE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for repairing stale live-roadmap active-lane/frontier claims.
- `docs/tasks/ROADMAP-ACTIVE-LANE-LATEST-SLICE-SYNC.md` — completed roadmap-maintenance task tree for synchronizing the lower live-roadmap latest-slice summary.
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
- `docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md` — selected first-class semantic-introspection API and MCP adapter boundary, records the shipped read-only adapter, and names the current client-compatibility limits.
- `docs/INTENT_CAPTURE_AXI_CASE_STUDY.md` — AXI intent-capture case-study notes for future high-level synthesis work.
- `docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md` — first non-code IAL2 protocol/platform intent evaluation and go/no-go criteria.
- `docs/IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md` — reusable end-to-end workflow for adding future IAL2 protocol support from evidence through contract, implementation, validation, docs, Knowledge Map, task tree, and commit closeout.
- `docs/AXI_VALID_READY_INTENT_PROBE.md` — first bounded AXI Valid-Ready source-anchor evidence inventory for future IAL2 design/probe work.
- `docs/AXI_MANAGER_USER_API_BRAINSTORM.md` — captured AXI manager user-facing API direction for future IAL2 work.
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md` — first bounded AXI ID/order/concurrency source-anchor evidence inventory for future IAL2 manager rule-engine work.
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md` — first bounded AXI manager source-to-rule responsibility matrix for future IAL2 work.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md` — selected the first post-Valid-Ready AXI manager subset: outstanding-capacity plus acceptance/status feedback.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT.md` — readiness audit for the selected AXI manager capacity/status subset and first in-process generator boundary.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md` — first in-process AXI manager capacity/status generator slice and report surface.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md` — selected public `.ppif` syntax/readiness boundary for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md` — first public `.ppif` parser/CLI slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md` — selected the next AXI manager subset: ID-family declaration and static validation.
- `docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md` — readiness audit for the additive ID-family/static-validation implementation boundary.
- `docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md` — shipped additive `.ppif` ID-family metadata slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md` — selected the next AXI manager subset: logical read/write transaction envelope and static validation.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md` — readiness audit for the additive transaction-envelope/static-validation implementation boundary.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md` — shipped additive `.ppif` transaction-envelope metadata slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md` — selected the next prerequisite: transaction event dispatch and direction fan-in.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md` — readiness audit for additive per-transaction event dispatch and direction fan-in.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md` — shipped additive `.ppif` transaction event dispatch/fan-in slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md` — selected the next AXI manager subset: ID/response rule-engine readiness.
- `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md` — readiness audit for additive concrete transaction ID request/response assertions.
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md` — shipped additive concrete transaction ID request/response assertions for the public AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md` — selected AXI manager auto-ID lifecycle/request-ID drive readiness as the next subset.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md` — readiness audit selecting bounded auto-ID pool/request-ID drive contract selection before implementation.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md` — selected explicit optional `auto-id-lifecycle` bounded-pool syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md` — shipped additive `.ppif` auto-ID lifecycle parser/report metadata for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md` — shipped bounded auto-ID request-ID drive behavior for explicit lifecycle families.
- `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md` — selected AXI manager generated response-demux readiness after bounded auto-ID request-ID drive.
- `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md` — readiness audit selecting bounded write response-demux public contract before implementation.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected explicit write-only `response-demux` public syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md` — shipped write-only `response-demux` parser/report metadata for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md` — readiness audit selecting the IAL1 rule-pulse prerequisite before generated write `BID` demux behavior.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md` — shipped generated write `BID` response-demux behavior for explicit `response-demux` contracts.
- `docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md` — selected report-residue alignment after generated write `BID` demux before larger ordering/read-response work.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md` — shipped auto-ID lifecycle report-residue alignment after generated write `BID` demux.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md` — selected same-ID ordering readiness after generated write `BID` demux and residue alignment.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md` — readiness audit selecting bounded auto-ID same-ID avoidance assertions/report metadata before per-ID queues.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md` — shipped bounded generated auto-ID same-ID avoidance assertions/report metadata.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md` — selected read `RID` response-demux readiness after generated auto-ID same-ID avoidance.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — readiness audit selecting a bounded read response-demux public contract before parser/report or behavior changes.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected explicit `response-scope single-beat` read response-demux syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md` — shipped read response-demux parser/report metadata and static validation without generated read behavior.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md` — readiness audit selecting bounded generated single-beat read `RID` response-demux behavior before implementation.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md` — shipped bounded generated single-beat read `RID` response-demux behavior for explicit read response-demux contracts.
- `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data payload, burst/`RLAST`, and per-ID ordering/reassembly readiness as the next AXI manager IAL2 audit after generated read demux.
- `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md` — readiness audit selecting bounded public read-data payload/status contract selection before parser/report or generated behavior changes.
- `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md` — selected bounded single-beat `read-data` syntax for `RDATA`/`RRESP` capture before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md` — shipped structural `read_data` parser/report metadata and static validation without generated capture behavior.
- `docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md` — readiness audit selecting generated single-beat `RDATA`/`RRESP` capture behavior with no new IAL1/IAL0/SystemVerilog prerequisite.
- `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md` — shipped generated single-beat `RDATA`/`RRESP` capture behavior for explicit `read-data` contracts.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md` — readiness audit selecting public AXI burst/`RLAST` completion contract selection before parser/report metadata or generated behavior changes.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md` — selected additive read `response-demux` `response-scope burst-last` plus one-bit `last-signal` syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for `response-scope burst-last` with generated `RLAST` behavior deferred.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md` — readiness audit selecting direct generated burst-last/`RLAST` completion behavior.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md` — shipped generated burst-last/`RLAST` completion behavior.
- `docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md` — selected AXI `RLAST` report/static-text alignment before larger read-data reassembly or manager behavior.
- `docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md` — shipped generated AXI `RLAST` schedule-report prose alignment.
- `docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md` — selected public AXI burst read-data contract selection after generated `RLAST` completion/report alignment.
- `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md` — selected explicit last-beat `RDATA`/`RRESP` capture as the first bounded burst read-data contract.
- `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for explicit last-beat `RDATA`/`RRESP` capture with generated behavior deferred.
- `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md` — readiness audit selecting direct generated last-beat `RDATA`/`RRESP` capture behavior.
- `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md` — shipped generated last-beat `RDATA`/`RRESP` capture behavior.
- `docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected public AXI burst read-data beat-count/depth contract selection after generated last-beat capture.
- `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md` — selected ARLEN-based `burst-length` syntax and report contract before parser/report metadata.
- `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for ARLEN-based `burst-length` contracts.
- `docs/AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md` — selected generated ARLEN burst-length capture readiness audit after report-only metadata.
- `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md` — audited generated raw-ARLEN capture readiness and selected direct behavior.
- `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md` — shipped generated raw-ARLEN capture behavior for opt-in last-beat read-data `burst-length` contracts.
- `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md` — audited beat-count/RLAST validation readiness and selected public runtime-validation contract selection before behavior.
- `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md` — selected `(validation runtime-assertion)` / `runtime_assertion` as the public beat-count/RLAST validation contract before behavior.
- `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md` — shipped generated beat-count/RLAST runtime validation for `(validation runtime-assertion)` burst-length contracts.
- `docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md` — selected public multi-beat read-data reassembly/output contract selection after generated beat-count/RLAST validation.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md` — selected per-beat output-bank public contract for multi-beat read-data reassembly/output.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for the public multi-beat read-data output-bank contract.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md` — audited generated output-bank behavior readiness and selected direct scalar-lane behavior.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md` — shipped generated multi-beat read-data output-bank behavior for the public multi-beat sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md` — selected public scalar `RRESP` aggregation contract selection after generated multi-beat read-data output-bank behavior.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md` — selected additive scalar `RRESP` aggregation syntax and report contract before parser/report metadata.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for the selected scalar `RRESP` aggregation contract.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md` — audited generated scalar `RRESP` aggregation readiness and selected direct generated behavior.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md` — shipped generated scalar `RRESP` aggregation outputs/init/update behavior.
- `docs/AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md` — selected per-ID read-data interleaving and queue readiness after scalar `RRESP` aggregation.
- `docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md` — audited read-data interleaving/queue readiness and selected report/static residue alignment for the covered generated auto-ID multi-beat-by-RID subset.
- `docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md` — aligned read-data interleaving residue for the covered generated auto-ID multi-beat-by-RID subset.
- `docs/AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION.md` — selected AXI burst payload/output readiness audit after read-data interleaving residue alignment.
- `docs/AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT.md` — audited bounded burst payload/output readiness and selected report/static `bursts` residue alignment.
- `docs/AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md` — aligned broad `bursts` residue for the covered generated auto-ID multi-beat output-bank subset.
- `docs/AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md` — selected AXI concrete-ID same-ID ordering readiness after bounded burst residue alignment.
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md` — audited concrete-ID same-ID ordering readiness and selected fail-closed static validation for unsupported authored same-ID reuse.
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md` — shipped fail-closed static validation for unsupported same-family concrete-ID reuse.
- `docs/AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md` — selected per-ID issue-order queue readiness after concrete-ID static validation.
- `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md` — audited per-ID issue-order queue readiness and selected same-ID reuse policy contract selection.
- `docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md` — selected explicit same-ID reuse reject policy syntax before parser/report metadata.
- `docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md` — shipped parser/report metadata and static validation for explicit same-ID reuse reject policy.
- `docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md` — selected same-ID issue-order queue policy contract selection after explicit reject policy.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md` — selected the public AXI same-ID `issue-order-queue` policy contract and the follow-up behavior-readiness audit.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md` — audited same-ID `issue-order-queue` behavior readiness and selected metadata-first support.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md` — shipped metadata-first parser/report support for selected-not-generated `issue-order-queue`.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md` — audited admitted enqueue readiness and selected admitted request pulses before queue state.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md` — shipped admitted request pulse generation for selected same-ID `issue-order-queue` families while accepted same-ID reuse remains deferred.
- `docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md` — selected same-ID issue-order queue state and queue-head demux readiness after admitted request pulses.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md` — audited same-ID queue-state and queue-head response-demux readiness.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md` — selected compact one-hot transaction slots for future same-ID issue-order queues.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected the concrete same-ID queue-head response-demux public/report contract.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md` — shipped selected-not-generated concrete same-ID queue-head response-demux metadata and static validation.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md` — audited generated same-ID queue state plus queue-head behavior readiness and selected the first generated behavior slice selector.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md` — selected read burst-last, one duplicate concrete-ID group, two-transaction depth-2 generated queue state plus queue-head demux as the first behavior implementation boundary.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md` — shipped bounded generated read burst-last depth-2 concrete same-ID queue state plus queue-head response demux for the public same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped bounded generated write depth-2 concrete same-ID queue state plus queue-head `BID` response demux for the public write same-ID sample.
- `docs/AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md` — selected bounded read `single-beat` concrete same-ID queue-head response demux as the next behavior slice.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped bounded generated read single-beat depth-2 concrete same-ID queue state plus queue-head `RID` response demux without `RLAST`.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md` — selected queue-head read-data consumption readiness after generated read single-beat same-ID queue-head behavior.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited queue-head read-data readiness and selected generated single-beat queue-head read-data capture.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md` — shipped generated single-beat queue-head `RDATA`/`RRESP` capture for the bounded read single-beat concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected generated last-beat queue-head `RDATA`/`RRESP` capture for the bounded read burst-last concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated last-beat queue-head `RDATA`/`RRESP` capture for the bounded read burst-last concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected generated raw-`ARLEN` burst-length capture for the bounded queue-head last-beat read-data shape.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped report-only raw-`ARLEN` burst-length capture for the bounded queue-head last-beat read-data sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected generated queue-head beat-count/RLAST runtime validation for the bounded queue-head last-beat read-data shape.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated queue-head beat-count/RLAST runtime validation for the bounded queue-head last-beat read-data sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected generated queue-head multi-beat read-data output-bank behavior for the bounded read burst-last concrete same-ID queue-head demux shape.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated queue-head multi-beat read-data output-bank behavior for the bounded read burst-last concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected multiple independent read burst-last depth-2 concrete same-ID queue-head response-demux group readiness after generated queue-head multi-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple depth-2 read burst-last queue-head response-demux groups and selected the narrow implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated multiple read burst-last depth-2 concrete same-ID queue-head response-demux groups.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data-over-multiple-generated-queue-groups readiness after generated multi-group queue-head demux.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated multi-group queue-head multi-beat read-data output-bank behavior.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected last-beat-only read-data over multiple generated queue-head groups as the next audit owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md` — audited scalar last-beat read-data over multiple generated queue-head groups and selected the narrow implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated multi-group queue-head scalar last-beat read-data capture.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected generated report-only raw-`ARLEN` capture for multi-group queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` capture for multi-group queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected runtime-validation multi-group queue-head scalar last-beat readiness audit.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime-validation multi-group queue-head scalar last-beat readiness and selected the implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime-validation multi-group queue-head scalar last-beat read-data and records the `.137` support-report residue alignment.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected report/static residue cleanup after generated runtime-validation multi-group queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_SUPPORT_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md` — selected write-family multi-group queue-head response-demux readiness audit after support-residue cleanup.
- `docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited generated write-family multi-group queue-head response-demux readiness and selected the implementation owner.
- `docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated write-family multi-group queue-head response-demux behavior.
- `docs/AXI_IAL2_MANAGER_POST_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected read single-beat multi-group queue-head response-demux readiness audit after generated write-family multi-group queue-head response-demux.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited generated read single-beat multi-group queue-head response-demux readiness and selected the implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated read single-beat multi-group queue-head response-demux behavior and its semantic-introspection support-accounting surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data over read single-beat multi-group queue-head readiness audit after generated read single-beat multi-group response-demux.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited generated read-data over read single-beat multi-group queue-head readiness and selected the implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated read-data over read single-beat multi-group queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected deeper concrete same-ID queue-head readiness audit after generated read-data over read single-beat multi-group queue-head response-demux.
- `docs/AXI_IAL2_MANAGER_DEEPER_QUEUE_HEAD_GROUPS_READINESS_AUDIT.md` — audited generated concrete same-ID queue-head groups deeper than two slots and selected generated read single-beat depth-3 response-demux through generalized shared queue-state helpers.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated read single-beat depth-3 queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected focused PPIF support-detail expectation alignment before the next depth-3 behavior expansion.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited scalar read-data over generated read single-beat depth-3 queue-head response-demux readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated scalar read-data over read single-beat depth-3 queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected read burst-last depth-3 queue-head response-demux readiness audit after generated read single-beat depth-3 queue-head read-data.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited generated read burst-last depth-3 queue-head response-demux readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated read burst-last depth-3 queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data over read burst-last depth-3 queue-head response-demux readiness audit after generated read burst-last depth-3 queue-head response-demux.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited scalar read-data over generated read burst-last depth-3 queue-head response-demux readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated scalar last-beat read-data over read burst-last depth-3 queue-head response-demux and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` burst-length readiness audit after generated read burst-last depth-3 queue-head read-data.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length over generated read burst-last depth-3 queue-head read-data readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over read burst-last depth-3 queue-head read-data and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected runtime-validation readiness after generated read burst-last depth-3 queue-head report-only raw-`ARLEN` burst-length behavior.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime-validation readiness over generated read burst-last depth-3 queue-head raw-`ARLEN` burst-length and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over read burst-last depth-3 queue-head raw-`ARLEN` burst-length and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected multi-beat output-bank readiness after generated read burst-last depth-3 queue-head runtime-validation behavior.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md` — audited generated multi-beat output-bank readiness over read burst-last depth-3 queue-head runtime validation and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated multi-beat read-data output-bank behavior over read burst-last depth-3 queue-head runtime validation and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected write depth-3 queue-head response-demux readiness after generated read burst-last depth-3 queue-head multi-beat read-data.
- `docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited generated write depth-3 queue-head response-demux readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated write depth-3 queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected multiple/mixed depth-3 queue-head response-demux readiness after generated write depth-3 queue-head response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple/mixed depth-3 queue-head response-demux readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated multiple/mixed depth-3 queue-head response-demux behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data over multiple/mixed depth-3 queue-head groups as the next readiness audit after generated multiple/mixed depth-3 response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited read-data over multiple/mixed depth-3 queue-head groups and selected read single-beat scalar implementation.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated multiple/mixed depth-3 read single-beat queue-head scalar read-data behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected burst-last scalar last-beat read-data over multiple/mixed depth-3 queue-head groups as the next readiness audit.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md` — audited multiple/mixed depth-3 queue-head burst-last last-beat read-data readiness and selected the bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated multiple/mixed depth-3 read burst-last queue-head scalar last-beat read-data behavior and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` burst-length readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over multiple/mixed depth-3 queue-head scalar last-beat read-data and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected runtime beat-count/`RLAST` validation readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime beat-count/`RLAST` validation readiness over multiple/mixed depth-3 queue-head scalar last-beat read-data and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head scalar last-beat read-data and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected report/static support-residue cleanup after generated runtime beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md` — cleaned stale support/residue wording for generated runtime beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md` — selected multi-beat output-bank readiness over multiple/mixed depth-3 runtime-validation queue-head groups.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md` — audited generated multi-beat output-bank readiness over multiple/mixed depth-3 runtime-validation queue-head groups and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated multi-beat output-bank behavior over multiple/mixed depth-3 runtime-validation queue-head groups and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected same-family mixed auto-ID lifecycle plus concrete same-ID queue-head response-demux readiness after generated multiple/mixed depth-3 multi-beat output banks.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited same-family mixed auto-ID lifecycle plus concrete same-ID queue-head response-demux readiness and selected the direct bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped same-family mixed auto-ID lifecycle plus concrete same-ID queue-head response-demux behavior for bounded response-demux-only read single-beat, read burst-last, and write shapes.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected mixed read-data consumption readiness after same-family mixed auto-ID plus concrete queue-head response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited mixed scalar read-data readiness over same-family mixed auto-ID plus concrete queue-head response-demux and selected the direct bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped bounded scalar read-data over same-family mixed auto-ID plus concrete queue-head response-demux for read single-beat and read burst-last shapes.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected mixed report-only raw-`ARLEN` burst-length readiness after bounded mixed scalar read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md` — audited mixed report-only raw-`ARLEN` burst-length readiness and selected the direct support/publication owner.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped support-accounted mixed report-only raw-`ARLEN` burst-length capture and records the historical pre-`.202` runtime boundary.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited mixed runtime beat-count/`RLAST` validation readiness and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped support-accounted mixed runtime beat-count/`RLAST` validation and its semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected support/static and public-contract residue cleanup after mixed runtime validation shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md` — cleaned stale support/static and public-contract wording after mixed runtime validation shipped.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_CLEANUP_NEXT_SLICE_SELECTION.md` — selected mixed multi-beat output-bank readiness audit after mixed runtime support cleanup.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md` — audited mixed multi-beat output-bank readiness after mixed runtime validation and selected the direct bounded implementation owner.
- `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated mixed multi-beat output-bank behavior over the selected same-family mixed auto-ID plus depth-2 concrete same-ID queue-head runtime-validation shape and its support-accounted semantic-introspection surface.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected group-local simultaneous enqueue widening readiness after generated mixed multi-beat output-bank behavior.
- `docs/AXI_IAL2_MANAGER_GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT.md` — audited group-local same-ID enqueue readiness and selected counted admission/capacity prerequisite audit.
- `docs/AXI_IAL2_MANAGER_COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT.md` — audited counted same-ID request admission/capacity placement and selected the bounded counted capacity substrate implementation.
- `docs/AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR.md` — shipped counted same-ID selected-request capacity/status substrate for generated multi-group queue-head families while preserving family-wide request onehot behavior.
- `docs/AXI_IAL2_MANAGER_POST_COUNTED_CAPACITY_NEXT_SLICE_SELECTION.md` — selected admitted-request guard alignment readiness before group-local same-ID enqueue behavior.
- `docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_READINESS_AUDIT.md` — audited counted admitted-request guard alignment and selected bounded group-local request assertion implementation.
- `docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md` — shipped counted admitted-request guard alignment and group-local request assertions for generated multi-group queue-head families.
- `docs/AXI_IAL2_MANAGER_POST_COUNTED_GROUP_LOCAL_ENQUEUE_NEXT_SLICE_SELECTION.md` — selected dynamic same-ID issue-order queue readiness after counted group-local enqueue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md` — audited dynamic/user transaction-ID readiness and selected public contract selection before generalized per-ID queues.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION.md` — selected transaction-local `(id dynamic)` contract and dynamic-ID metadata readiness audit.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_READINESS_AUDIT.md` — audited metadata-first `(id dynamic)` parser/report readiness and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md` — shipped metadata-first `(id dynamic)` parser/report behavior and support-accounted dynamic-ID metadata sample.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION.md` — selected generated dynamic transaction-ID capture and response matching readiness after metadata-only `(id dynamic)` support.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md` — audited generated dynamic ID capture/matching readiness and selected bounded dynamic write `BID` contract selection.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md` — selected existing `response-demux.write` plus one dynamic write transaction as the direct generated dynamic write ID capture/matching contract.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md` — shipped bounded dynamic write transaction-ID capture and `BID` response matching for one explicit `response-demux.write` dynamic write transaction.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_ID_NEXT_SLICE_SELECTION.md` — selected dynamic read transaction-ID capture and `RID` response matching readiness after generated dynamic write ID behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md` — audited generated dynamic read transaction-ID capture and `RID` matching readiness and selected bounded single-beat contract selection.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md` — selected existing `response-demux.read` plus one dynamic read transaction as the direct generated bounded single-beat dynamic read ID capture and `RID` matching contract.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md` — shipped bounded single-beat dynamic read transaction-ID capture and `RID` response matching for one explicit `response-demux.read` dynamic read transaction.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION.md` — selected dynamic read burst-last/`RLAST` transaction-ID capture and response matching readiness after generated dynamic read ID behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_READINESS_AUDIT.md` — audited dynamic read burst-last/`RLAST` transaction-ID capture readiness and selected public contract selection before behavior changes.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md` — selected existing `response-demux.read` burst-last syntax plus one dynamic read transaction as the direct generated dynamic read `RID`/`RLAST` matching contract.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md` — shipped bounded dynamic read burst-last/`RLAST` transaction-ID capture and `RID`/`RLAST` response matching for one explicit `response-demux.read` dynamic read transaction.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_NEXT_SLICE_SELECTION.md` — selected dynamic read-data routing readiness after generated dynamic read burst-last/`RLAST` response-demux behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_READINESS_AUDIT.md` — audited dynamic read-data routing readiness and selected direct bounded scalar single-beat plus last-beat implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md` — shipped bounded scalar dynamic read-data capture over generated single-active dynamic read response-demux for scalar single-beat and scalar last-beat shapes.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected AXI manager focused-suite cost cleanup before further dynamic behavior expansion.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_FOCUSED_SUITE_CLEANUP.md` — added bounded focused validation for the shipped dynamic transaction-ID family before dynamic burst-length readiness work.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only dynamic raw-`ARLEN` burst-length readiness over generated dynamic last-beat read-data and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only dynamic raw-`ARLEN` burst-length capture over generated single-active dynamic read last-beat read-data.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited dynamic runtime beat-count/`RLAST` validation readiness over generated dynamic last-beat read-data and selected the direct implementation owner.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated dynamic runtime beat-count/`RLAST` validation over generated single-active dynamic read last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected generated dynamic multi-beat output-bank readiness after dynamic runtime validation shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md` — audited dynamic multi-beat output-bank readiness and selected direct bounded implementation over generated dynamic runtime validation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md` — shipped generated dynamic multi-beat read-data output-bank behavior over generated dynamic runtime validation.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected multiple/mixed dynamic response-demux readiness audit after generated dynamic multi-beat output banks shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple/mixed dynamic response-demux readiness and selected public contract selection for bounded multiple dynamic write demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple dynamic write response-demux with onehot0 dynamic write requests and pairwise unique active dynamic IDs.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple dynamic write response-demux for all-dynamic write families with onehot0 dynamic write requests and pairwise unique active dynamic IDs.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected multiple dynamic read response-demux readiness audit after bounded multiple dynamic write response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple dynamic read response-demux readiness and selected public contract selection for bounded multiple dynamic read demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple dynamic read single-beat response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple dynamic read single-beat response-demux for all-dynamic read families with onehot0 dynamic read requests and pairwise unique active dynamic IDs.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected readiness audit for multiple dynamic read burst-last/`RLAST` response-demux after bounded multiple dynamic read single-beat response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple dynamic read burst-last/`RLAST` response-demux readiness and selected public contract selection before behavior changes.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple dynamic read burst-last/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple dynamic read burst-last/`RLAST` response-demux with raw `RID` beat assertions and final `RID && RLAST` completion pulses.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data readiness audit after generated multiple dynamic read burst-last/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_READINESS_AUDIT.md` — audited read-data readiness over generated multiple dynamic read response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded scalar read-data over generated multiple dynamic read response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md` — shipped generated bounded scalar read-data over generated multiple dynamic read response-demux with public single-beat and last-beat samples.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected readiness audit for burst-length/runtime validation over generated multiple dynamic read response-demux after scalar multiple dynamic read-data shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_READINESS_AUDIT.md` — audited burst-length/runtime validation readiness over generated multiple dynamic read response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_CONTRACT_SELECTION.md` — selected a split public contract: report-only multiple dynamic raw-`ARLEN` capture first, then runtime beat-count/`RLAST` validation.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over generated multiple dynamic read response-demux and scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over generated multiple dynamic read response-demux and scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected generated multiple dynamic multi-beat output-bank readiness audit after multiple dynamic runtime validation shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md` — audited generated multiple dynamic multi-beat output-bank readiness and selected public contract selection before behavior changes.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_CONTRACT_SELECTION.md` — selected direct generated implementation of bounded multiple dynamic multi-beat output-bank behavior and reserved the explicit `dynamic_read_data_multi_transaction_multi_beat` public sample stem.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md` — shipped generated bounded multiple dynamic multi-beat output-bank behavior over generated multiple dynamic runtime validation.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static response-demux readiness after generated bounded multiple dynamic multi-beat output banks shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited mixed dynamic/static response-demux readiness and selected public contract selection for bounded mixed dynamic/static write `BID` response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded mixed dynamic/static write `BID` response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded mixed dynamic/static write `BID` response-demux with static concrete-ID reservation away from dynamic capture.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static read response-demux readiness after bounded mixed dynamic/static write `BID` response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited mixed dynamic/static read response-demux readiness and selected public contract selection for bounded mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded mixed dynamic/static read single-beat `RID` response-demux with static concrete-ID reservation away from dynamic capture.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static read burst-last `RID && RLAST` readiness after bounded mixed dynamic/static read single-beat `RID` response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited mixed dynamic/static read burst-last `RID && RLAST` readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded mixed dynamic/static read burst-last `RID && RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded mixed dynamic/static read burst-last `RID && RLAST` response-demux with final-beat completion and raw `RID` beat assertions.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data readiness after bounded mixed dynamic/static read burst-last `RID && RLAST` response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md` — audited mixed dynamic/static read-data readiness and selected public contract selection before behavior.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded scalar read-data over generated mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md` — shipped generated bounded scalar read-data capture over generated mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static report-only raw-ARLEN burst-length readiness after scalar mixed read-data shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited mixed dynamic/static read-data burst-length readiness and selected direct report-only raw-ARLEN capture behavior.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over generated mixed dynamic/static read burst-last response-demux and scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited mixed dynamic/static runtime beat-count/`RLAST` validation readiness after report-only raw-`ARLEN` capture and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over generated mixed dynamic/static read burst-last response-demux and scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited mixed dynamic/static multi-beat output-bank readiness after generated mixed runtime validation and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped generated mixed dynamic/static multi-beat output banks over generated mixed runtime validation.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected multiple mixed dynamic/static transaction cardinality readiness after generated mixed dynamic/static multi-beat output banks shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple mixed dynamic/static transaction cardinality and selected public contract selection for bounded multiple mixed dynamic/static write `BID` response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple mixed dynamic/static write `BID` response-demux with one dynamic and two concrete static write transactions.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple mixed dynamic/static write `BID` response-demux with one dynamic and two concrete static write transactions.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md` — selected multiple mixed dynamic/static read response-demux readiness after bounded multiple mixed dynamic/static write `BID` response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple mixed dynamic/static read response-demux readiness and selected public contract selection for bounded multiple mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple mixed dynamic/static read single-beat `RID` response-demux with one dynamic and two concrete static read transactions.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple mixed dynamic/static read single-beat `RID` response-demux with one dynamic and two concrete static read transactions.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md` — selected multiple mixed dynamic/static read burst-last `RID && RLAST` readiness after bounded multiple mixed dynamic/static read single-beat `RID` response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple mixed dynamic/static read burst-last `RID && RLAST` readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded multiple mixed dynamic/static read burst-last `RID && RLAST` response-demux with one dynamic and two concrete static read transactions.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded multiple mixed dynamic/static read burst-last `RID && RLAST` response-demux with one dynamic and two concrete static read transactions.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md` — selected scalar read-data readiness after bounded multiple mixed dynamic/static read single-beat and burst-last response-demux shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md` — audited scalar read-data readiness over generated multiple mixed dynamic/static read response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded scalar read-data over generated multiple mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md` — shipped generated bounded scalar read-data over generated multiple mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` burst-length readiness after multiple mixed scalar read-data shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length readiness over generated multiple mixed dynamic/static last-beat read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over generated multiple mixed dynamic/static read burst-last response-demux and scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime beat-count/`RLAST` validation readiness over generated multiple mixed dynamic/static raw-`ARLEN` last-beat read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over generated multiple mixed dynamic/static raw-`ARLEN` last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited multiple mixed dynamic/static multi-beat output-bank readiness over generated runtime validation and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped generated multiple mixed dynamic/static multi-beat output banks over generated runtime validation.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected broader mixed dynamic/static transaction cardinality readiness after generated multiple mixed dynamic/static multi-beat output banks shipped.
- `docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_READINESS_AUDIT.md` — audited broader mixed dynamic/static cardinality readiness and selected public contract selection before behavior changes.
- `docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_CONTRACT_SELECTION.md` — selected one dynamic plus three concrete static write `BID` response-demux as the first broader mixed cardinality behavior.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md` — selected one dynamic plus three concrete static mixed dynamic/static read response-demux readiness after the three-static write demux shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited one dynamic plus three concrete static mixed dynamic/static read response-demux readiness and selected public contract selection for the single-beat `RID` boundary.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for one dynamic plus three concrete static mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated one dynamic plus three concrete static write `BID` response-demux while preserving the existing multi-mixed write report mode.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated one dynamic plus three concrete static mixed dynamic/static read single-beat `RID` response-demux while preserving the existing multi-mixed read report mode.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md` — selected one dynamic plus three concrete static mixed dynamic/static read burst-last `RID && RLAST` readiness after the three-static read single-beat demux shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited one dynamic plus three concrete static mixed dynamic/static read burst-last `RID && RLAST` readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for one dynamic plus three concrete static mixed dynamic/static read burst-last `RID && RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated one dynamic plus three concrete static mixed dynamic/static read burst-last `RID && RLAST` response-demux while preserving the existing multi-mixed read report mode.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md` — selected scalar read-data readiness after the three-static read burst-last demux shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md` — audited scalar read-data readiness over generated one dynamic plus three concrete static mixed dynamic/static read response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded scalar read-data over generated one dynamic plus three concrete static mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md` — shipped generated scalar read-data over generated one dynamic plus three concrete static mixed dynamic/static read response-demux.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` burst-length readiness after three-static scalar read-data shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited three-static mixed dynamic/static read-data report-only raw-`ARLEN` burst-length readiness and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` burst-length capture over generated one dynamic plus three concrete static mixed dynamic/static last-beat read-data.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited three-static mixed dynamic/static runtime beat-count/`RLAST` validation readiness and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated runtime beat-count/`RLAST` validation over generated one dynamic plus three concrete static mixed dynamic/static raw-`ARLEN` last-beat read-data.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited three-static mixed dynamic/static multi-beat output-bank readiness and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped generated multi-beat output banks over generated one dynamic plus three concrete static mixed dynamic/static runtime-validation read-data.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected readiness audit for two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux after the three-static mixed read-data chain reached multi-beat output banks.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected direct generated behavior for bounded two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated bounded two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_READINESS_AUDIT.md` — audited scalar last-beat read-data readiness over the two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated behavior for scalar last-beat read-data over the two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BEHAVIOR.md` — shipped scalar last-beat read-data capture over the generated two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST` response-demux.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` burst-length readiness audit after two-dynamic-plus-one-static mixed dynamic/static read burst-last read-data shipped.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length readiness over generated two-dynamic-plus-one-static mixed dynamic/static read burst-last read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped report-only raw-`ARLEN` burst-length capture over generated two-dynamic-plus-one-static mixed dynamic/static read burst-last read-data.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime beat-count/`RLAST` validation readiness over generated two-dynamic-plus-one-static mixed dynamic/static raw-`ARLEN` read burst-last read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped runtime beat-count/`RLAST` validation over generated two-dynamic-plus-one-static mixed dynamic/static raw-`ARLEN` read burst-last read-data.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited multi-beat output-bank readiness over generated two-dynamic-plus-one-static mixed dynamic/static runtime-validation read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped generated multi-beat output banks over generated two-dynamic-plus-one-static mixed dynamic/static runtime-validation read-data.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected scalar single-beat read-data readiness audit after the two-dynamic-plus-one-static mixed dynamic/static read-data chain reached multi-beat output banks.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md` — audited scalar single-beat read-data readiness over the generated two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md` — selected direct generated scalar single-beat read-data behavior over the generated two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md` — shipped scalar single-beat read-data capture over the generated two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` response-demux.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md` — selected same-cycle request/response and release-and-recapture readiness audit after the two-dynamic-plus-one-static mixed dynamic/static read-data sibling shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_MIXED_SAME_CYCLE_READINESS_AUDIT.md` — audited same-cycle request/response and release-and-recapture readiness for generated dynamic/mixed response-demux/read-data shapes and selected the single-active dynamic write contract-selection boundary.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md` — audited mixed dynamic/static same-cycle release-and-recapture readiness and selected mixed dynamic/static write `BID` public contract selection as the next owner.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct mixed dynamic/static write `BID` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md` — shipped mixed dynamic/static write `BID` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected public contract selection for mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture after mixed write recapture shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md` — selected direct mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md` — shipped mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture after mixed read single-beat recapture shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md` — audited mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md` — selected direct mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md` — shipped mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected broader mixed dynamic/static same-cycle release-and-recapture readiness audit after the one-dynamic plus one-static mixed recapture family shipped.
- `docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md` — audited broader mixed dynamic/static same-cycle release-and-recapture readiness and selected one-dynamic plus two-static mixed write `BID` public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic plus two-static mixed dynamic/static write `BID` same-cycle release-and-recapture implementation under the existing multi-static public sample.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic plus two-static mixed dynamic/static write `BID` same-cycle release-and-recapture under the existing multi-static public sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected public contract selection for one-dynamic plus three-static mixed dynamic/static write `BID` same-cycle release-and-recapture after the two-static recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic plus three-static mixed dynamic/static write `BID` same-cycle release-and-recapture implementation under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic plus three-static mixed dynamic/static write `BID` same-cycle release-and-recapture under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle release-and-recapture after the three-static recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_READINESS_AUDIT.md` — audited two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md` — shipped two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture after broader mixed write recapture shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md` — audited one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture after the single-beat two-static recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md` — audited one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture implementation under the existing public sample.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture after the two-static read recapture family shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md` — audited one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture implementation under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture after the single-beat three-static recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md` — audited one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md` — selected direct one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture implementation under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md` — shipped one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture under the existing three-static public sample.
- `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture after the one-dynamic-plus-three-static burst-last recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md` — audited readiness for two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md` — selected direct implementation of the two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture contract.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md` — shipped two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture after the single-beat two-dynamic recapture sibling shipped.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md` — audited readiness for two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md` — selected direct implementation of the two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture contract.
- `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md` — shipped two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture under the existing public sample.
- `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected dynamic same-ID issue-order readiness audit after the bounded dynamic/mixed response-demux, read-data, multi-beat, and recapture chain reached two-dynamic-plus-one-static mixed read burst-last recapture.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_READINESS_AUDIT.md` — audited dynamic same-ID policy readiness after bounded dynamic/mixed recapture completion and selected public dynamic same-ID policy contract selection before queues or scoreboards.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION.md` — selected additive `(dynamic-id-reuse reject)` public contract and metadata-first parser/report readiness audit before implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_READINESS_AUDIT.md` — audited metadata-first implementation readiness for `(dynamic-id-reuse reject)` and selected direct parser/report implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_FIRST_SLICE.md` — shipped metadata-first parser/report support for `(dynamic-id-reuse reject)`, including report fields, diagnostics, sample/support accounting, and deferred generated enforcement.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_READINESS_AUDIT.md` — audited generated dynamic same-ID reject enforcement mapping readiness and selected a narrow multi-active dynamic/mixed response-demux report mapping.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md` — shipped generated dynamic same-ID reject enforcement report mapping over covered multi-active dynamic/mixed response-demux assertions.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md` — selected single-active dynamic same-ID reject mapping readiness audit after the multi-active generated reject mapping shipped.
- `docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md` — audited single-active dynamic same-ID reject mapping readiness and selected public report contract selection.
- `docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md` — selected direct implementation of the single-active dynamic same-ID reject report/acceptance mapping contract.
- `docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md` — shipped single-active dynamic same-ID reject report/acceptance mapping over existing generated idle-or-releasing response-demux assertions.
- `docs/AXI_IAL2_MANAGER_POST_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md` — selected one-dynamic mixed dynamic/static dynamic same-ID reject mapping readiness audit after the single-active generated reject mapping shipped.
- `docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md` — audited one-dynamic mixed dynamic/static dynamic same-ID reject mapping readiness and selected public report contract selection.
- `docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md` — selected direct implementation of the one-dynamic mixed dynamic/static dynamic same-ID reject report/acceptance mapping contract.
- `docs/AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md` — shipped one-dynamic mixed dynamic/static dynamic same-ID reject report/acceptance mapping over existing generated static-ID exclusion response-demux assertions.
- `docs/AXI_IAL2_MANAGER_POST_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md` — selected dynamic same-ID `issue-order-queue` policy contract readiness after all bounded dynamic reject mappings shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_READINESS_AUDIT.md` — audited dynamic same-ID `issue-order-queue` policy readiness and selected public contract selection before parser/report changes.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_CONTRACT_SELECTION.md` — selected metadata-first parser/report support for dynamic same-ID `issue-order-queue` policy before generated queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_METADATA_FIRST_BEHAVIOR.md` — shipped metadata-first parser/report support and a public PPIF sample for dynamic same-ID `issue-order-queue` policy.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_NEXT_SLICE_SELECTION.md` — selected generated dynamic same-ID `issue-order-queue` behavior readiness after metadata-first dynamic issue-order policy support.
- `docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated dynamic same-ID `issue-order-queue` readiness and selected public contract selection before implementation.
- `docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md` — selected runtime-ID queue-state representation before the first generated dynamic same-ID `issue-order-queue` behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_ID_QUEUE_STATE_REPRESENTATION_SELECTION.md` — selected compact runtime-ID issue-order slots before generated dynamic write `BID` queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated bounded two-transaction all-dynamic write `BID` dynamic issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected dynamic read same-ID `issue-order-queue` readiness after the generated dynamic write `BID` queue shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited dynamic read same-ID `issue-order-queue` readiness and selected public contract selection for the first all-dynamic read single-beat `RID` queue.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md` — selected the public contract for the bounded two-transaction all-dynamic read single-beat `RID` dynamic same-ID `issue-order-queue` behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated bounded two-transaction all-dynamic read single-beat `RID` dynamic same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected generated dynamic read burst-last `RID && RLAST` same-ID issue-order queue readiness after the single-beat read queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated dynamic read burst-last `RID && RLAST` same-ID issue-order queue readiness and selected public contract selection.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md` — selected the public contract for the first generated dynamic read burst-last `RID && RLAST` same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated bounded two-transaction all-dynamic read burst-last `RID && RLAST` dynamic same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected read-data over generated dynamic read same-ID issue-order queue readiness after generated dynamic read burst-last same-ID queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md` — audited read-data over generated dynamic read same-ID issue-order queue completions and selected paired scalar public contract selection.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_CONTRACT_SELECTION.md` — selected direct implementation of paired scalar read-data over generated dynamic read same-ID issue-order queue completions.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md` — shipped paired scalar read-data over generated dynamic read same-ID issue-order queue completions.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length readiness over generated dynamic read same-ID issue-order queue last-beat read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped report-only raw-`ARLEN` burst-length capture over generated dynamic read same-ID issue-order queue last-beat read-data.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime beat-count/`RLAST` validation readiness over generated dynamic read same-ID issue-order queue raw-`ARLEN` read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped runtime beat-count/`RLAST` validation over generated dynamic read same-ID issue-order queue raw-`ARLEN` read-data.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited multi-beat output-bank readiness over generated dynamic read same-ID issue-order queue runtime-validation read-data and selected direct implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped multi-beat output banks over generated dynamic read same-ID issue-order queue runtime-validation read-data.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_READINESS_AUDIT.md` — audited queue recapture readiness after generated dynamic read same-ID issue-order queue multi-beat output banks and selected report/static contract selection.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_REPORT_CONTRACT_SELECTION.md` — selected identity-preserving same-transaction queue recapture ID-refresh readiness before adding any positive queue recapture report field.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_READINESS_AUDIT.md` — audited identity-preserving same-transaction queue recapture ID refresh and selected direct implementation of state-key-preserving dynamic queue update rules.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_BEHAVIOR.md` — shipped state-key-preserving dynamic same-ID issue-order queue recapture ID refresh for generated two-transaction dynamic queue families.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_CONTRACT_SELECTION.md` — selected queue-owned public report fields for generated dynamic same-ID issue-order queue identity recapture.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_BEHAVIOR.md` — shipped queue-owned `same_transaction_*` report fields for generated dynamic same-ID issue-order queue identity recapture.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_QUEUE_RECAPTURE_REPORT_NEXT_SLICE_SELECTION.md` — selected depth-3 all-dynamic write BID same-ID issue-order queue readiness as the next dynamic queue widening audit after identity-recapture report alignment.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated all-dynamic write BID depth-3 same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated all-dynamic write BID depth-3 same-ID issue-order queue behavior with rule-name disambiguation for ambiguous cross-transaction enqueue rules.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected generated all-dynamic read single-beat RID depth-3 same-ID issue-order queue readiness as the next dynamic queue widening audit after write depth-3 behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated all-dynamic read single-beat RID depth-3 same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated all-dynamic read single-beat RID depth-3 same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — shipped generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected scalar last-beat read-data over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue behavior as the next readiness audit.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md` — audited scalar last-beat read-data over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue behavior and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md` — shipped scalar last-beat read-data over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue behavior.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_NEXT_SLICE_SELECTION.md` — selected report-only raw-`ARLEN` readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue read-data as the next audit.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue read-data and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — shipped report-only raw-`ARLEN` burst-length capture over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue read-data.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected runtime beat-count/`RLAST` validation readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue raw-`ARLEN` read-data as the next audit.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audited runtime beat-count/`RLAST` validation readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue raw-`ARLEN` read-data and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped runtime beat-count/`RLAST` validation over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue raw-`ARLEN` read-data.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected multi-beat output-bank readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue runtime-validation read-data as the next audit.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audited multi-beat output-bank readiness over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue runtime-validation read-data and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — shipped multi-beat output banks over generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID issue-order queue runtime-validation read-data.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected generated mixed dynamic/static write `BID` same-ID issue-order queue readiness after the all-dynamic depth-3 dynamic queue/read-data ladder closed.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated mixed dynamic/static write `BID` same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — documents generated mixed dynamic/static write `BID` same-ID issue-order queue behavior for one dynamic plus one concrete static transaction.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static read single-beat `RID` same-ID issue-order queue readiness after the first mixed write `BID` issue-order queue shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated mixed dynamic/static read single-beat `RID` same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — documents generated mixed dynamic/static read single-beat `RID` same-ID issue-order queue behavior for one dynamic plus one concrete static transaction.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md` — selected generated mixed dynamic/static read burst-last `RID && RLAST` same-ID issue-order queue readiness after the mixed read single-beat `RID` queue shipped.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited generated mixed dynamic/static read burst-last `RID && RLAST` same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — documents generated mixed dynamic/static read burst-last `RID && RLAST` same-ID issue-order queue behavior for one dynamic plus one concrete static transaction.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC.md` — synchronized the public `.ppif` boundary after generated mixed dynamic/static same-ID issue-order queue behavior shipped.
- `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC_NEXT_SLICE_SELECTION.md` — selected mixed dynamic/static issue-order queue scalar read-data readiness after public-surface synchronization.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md` — audited scalar read-data readiness over generated mixed dynamic/static read same-ID issue-order queue completions and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md` — documents paired scalar read-data over generated mixed dynamic/static read same-ID issue-order queue completions.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md` — audited report-only raw-`ARLEN` burst-length readiness over generated mixed dynamic/static read burst-last same-ID issue-order queue read-data and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md` — documents report-only raw-`ARLEN` burst-length capture over generated mixed dynamic/static read burst-last same-ID issue-order queue read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md` — audits runtime beat-count/`RLAST` validation readiness over generated mixed dynamic/static read burst-last same-ID issue-order queue raw-`ARLEN` read-data and selects direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md` — documents runtime beat-count/`RLAST` validation over generated mixed dynamic/static read burst-last same-ID issue-order queue raw-`ARLEN` read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md` — audits multi-beat output-bank readiness over generated mixed dynamic/static read burst-last same-ID issue-order queue runtime-validation read-data and selects direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md` — documents shipped multi-beat output banks over generated mixed dynamic/static read burst-last same-ID issue-order queue runtime-validation read-data.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md` — audited one-dynamic plus two-concrete-static mixed dynamic/static write `BID` same-ID issue-order queue readiness and selected direct bounded implementation.
- `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md` — documents generated mixed dynamic/static write `BID` same-ID issue-order queue behavior for one dynamic plus two concrete static transactions.
- `docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_SELECTION.md` — selected an IAL2 protocol/platform generality guardrail audit after the deep AXI first-example chain, preserving AXI as a profile/example rather than the whole IAL2 language.
- `docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_AUDIT.md` — audited the IAL2 protocol/platform generality guardrail and selected public-surface cleanup so downstream/public `.ppif` summaries lead with AXI as the first shipped IAL2 profile/example, not the IAL2 definition.
- `docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_PUBLIC_SURFACE_SYNC.md` — synchronized the public `.ppif` contract, downstream handoff, and capability-manifest language-surface boundary with the IAL2 protocol/platform generality guardrail.
- `docs/IAL2_POST_GUARDRAIL_NEXT_SLICE_SELECTION.md` — selected a readiness audit for a protocol-neutral/non-AXI Valid-Ready `.ppif` example boundary as the next IAL2 generality exercise.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_READINESS_AUDIT.md` — audited protocol-neutral/non-AXI Valid-Ready `.ppif` readiness and selected public profile/source vocabulary contract selection before any non-AXI sample or behavior change.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_CONTRACT_SELECTION.md` — selected `(profile valid-ready)`, `ppif/valid_ready_handshake.ppif`, and `intent.ppif_valid_ready_handshake` for the first protocol-neutral/non-AXI Valid-Ready `.ppif` implementation slice.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_BEHAVIOR.md` — documents the shipped protocol-neutral `(profile valid-ready)` `.ppif` sample, report fields, support accounting, and deferred boundaries.
- `docs/IAL2_POST_NEUTRAL_VALID_READY_PPIF_NEXT_SLICE_SELECTION.md` — selected protocol-neutral/non-AXI Valid-Ready `.ppif` bundle readiness as the next IAL2 generality owner after the first neutral sample shipped.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_READINESS_AUDIT.md` — audited protocol-neutral/non-AXI Valid-Ready bundle readiness and selected public contract selection before neutral bundle behavior changes.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_CONTRACT_SELECTION.md` — selected `ppif/valid_ready_dual_channel_bundle.ppif`, `intent.ppif_valid_ready_dual_channel_bundle`, and the generic aggregate residue contract for the first protocol-neutral/non-AXI Valid-Ready bundle implementation.
- `docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_BEHAVIOR.md` — documents the shipped protocol-neutral/non-AXI dual-channel Valid-Ready `.ppif` bundle, support accounting, generated artifacts, generic aggregate residue, and preserved AXI AW/W residue boundary.
- `docs/IAL2_POST_NEUTRAL_VALID_READY_BUNDLE_NEXT_SLICE_SELECTION.md` — selected profile-alias readiness as the next IAL2 owner after the neutral Valid-Ready bundle shipped.
- `docs/IAL2_PROFILE_ALIAS_SUFFIX_READINESS_AUDIT.md` — audited future IAL2 profile-alias suffix readiness and selected public unsupported-alias inventory synchronization before any suffix behavior change.
- `docs/IAL2_PROFILE_ALIAS_UNSUPPORTED_INVENTORY_SYNC.md` — synchronizes the public unsupported-alias inventory for future IAL2 profile-alias suffixes and selects first-alias contract selection.
- `docs/IAL2_FIRST_PROFILE_ALIAS_CONTRACT_SELECTION.md` — selects `.axi` as the first IAL2 profile-alias contract while keeping AXI as an example over IAL2, not the IAL2 definition.
- `docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md` — documents the shipped `.axi` IAL2 profile-alias behavior, explicit AXI-family profile matching, generated `.isf`/`.fsm` review artifacts, support accounting, and remaining unsupported aliases.
- `docs/IAL2_POST_AXI_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md` — selects the post-`.axi` IAL2 generality readiness audit and records the Knowledge Map routing correction for historical pre-implementation alias facts.
- `docs/IAL2_POST_AXI_GENERALITY_READINESS_AUDIT.md` — audits post-`.axi` generality readiness and selects public historical wording sync before another behavior owner.
- `docs/IAL2_PROFILE_ALIAS_PUBLIC_CHRONOLOGY_SYNC.md` — synchronizes README, ROADMAP_V2, and mdBook wording so `.537`/`.538` profile-alias notes are explicitly historical pre-`.540` state while `.axi` remains only the first shipped IAL2 profile-alias example.
- `docs/IAL2_NON_AXI_PROFILE_ALIAS_READINESS_SELECTION.md` — selects the non-AXI profile-alias readiness audit after the public chronology sync, explicitly avoiding another AXI implementation.
- `docs/IAL2_NON_AXI_PROFILE_ALIAS_READINESS_AUDIT.md` — audits non-AXI profile-alias readiness and selects a taxonomy/evidence prerequisite before any non-AXI suffix contract.
- `docs/IAL2_NON_AXI_PROFILE_ALIAS_TAXONOMY_EVIDENCE_PREREQUISITE.md` — separates `.pif`/`.ppi` generic-container candidates from non-AXI protocol-profile alias candidates and selects a generic-container alias policy owner.
- `docs/IAL2_PIF_PPI_GENERIC_CONTAINER_ALIAS_POLICY_SELECTION.md` — keeps `.pif`/`.ppi` unsupported historical generic-container spellings and selects an APB IAL2 source-shape readiness audit.
- `docs/IAL2_APB_SOURCE_SHAPE_READINESS_AUDIT.md` — audits APB lower-layer evidence and selects APB `.ppif` source-shape public contract selection before any APB behavior or `.apb` suffix support.
- `docs/IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md` — selects `(profile apb)`, the first `(apb-requester ...)` source shape, `ppif/apb_requester_transfer.ppif`, `intent.ppif_apb_requester_transfer`, and direct implementation as the next exact owner.
- `docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md` — ships the first APB `.ppif` requester-transfer behavior with `ppif/apb_requester_transfer.ppif`, generated `apb_requester.isf`/`apb_requester.fsm`, and report schema `fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`; the later `.apb` alias is documented separately.
- `docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md` — ships the first APB `.ppif` completer behavior with `ppif/apb_completer.ppif`, generated `apb_completer.isf`/`apb_completer.fsm`, report schema `fsmgen.ial2.protocol_intent.apb_completer.v1`, address-0 register read/write, runtime `wait_cycles`, unmapped-address `PSLVERR`, and later `.apb` alias exposure through `ppif/apb_completer.apb`.
- `docs/IAL2_POST_APB_REQUESTER_TRANSFER_NEXT_SLICE_SELECTION.md` — selects APB `.apb` profile-alias readiness audit after APB `.ppif` requester-transfer behavior, without accepting `.apb` or changing behavior.
- `docs/IAL2_APB_PROFILE_ALIAS_READINESS_AUDIT.md` — audits APB `.apb` profile-alias readiness and selects public `.apb` contract selection while keeping `.apb` unsupported at `.552` closeout.
- `docs/IAL2_APB_PROFILE_ALIAS_CONTRACT_SELECTION.md` — selects direct bounded implementation of the first APB `.apb` profile alias at `ppif/apb_requester_transfer.apb`, with explicit `(profile apb)` and generated `.isf` review preservation.
- `docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md` — ships `.apb` as the bounded APB requester-transfer, APB completer, and fixed APB requester/completer composition IAL2 profile alias with explicit `(profile apb)`, generated `.isf`/`.fsm` review artifacts, and support identities `intent.apb_profile_alias_requester_transfer`, `intent.apb_profile_alias_completer`, and `intent.apb_profile_alias_composition`.
- `docs/IAL2_POST_APB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md` — selects a no-behavior public-surface sync after APB `.apb` shipped so current `.axi`/`.apb` alias wording and Knowledge Map routing stay aligned.
- `docs/IAL2_POST_APB_PROFILE_ALIAS_PUBLIC_SURFACE_SYNC.md` — synchronizes current `.axi`/`.apb` profile-alias public surfaces so `.apb` is no longer listed as unsupported after `.554`.
- `docs/IAL2_POST_APB_SURFACE_SYNC_NEXT_SLICE_SELECTION.md` — selects APB completer/interconnect generation readiness audit after the post-APB public-surface sync.
- `docs/IAL2_APB_COMPLETER_INTERCONNECT_READINESS_AUDIT.md` — audits APB completer/interconnect generation readiness and selects public contract selection before any APB completer/interconnect behavior.
- `docs/IAL2_APB_COMPLETER_INTERCONNECT_CONTRACT_SELECTION.md` — selects a split APB completer-first `.ppif` contract and routes the next slice to generated-IAL1 substrate audit before implementation.
- `docs/IAL2_APB_COMPLETER_GENERATED_IAL1_SUBSTRATE_AUDIT.md` — audits generated-IAL1 substrate readiness for APB completer and selects expression entry-guard rendering repair before APB completer behavior.
- `docs/IAL1_EXPRESSION_ENTRY_GUARD_RENDERING_BEHAVIOR.md` — ships the IAL1 expression entry-guard rendering repair so first-clause `(when EXPR (sample ...))` generated `.fsm` sample enables and entry transitions use rendered expression guard text instead of `ARRAY(...)`.
- `docs/IAL2_POST_APB_COMPLETER_NEXT_SLICE_SELECTION.md` — selects APB interconnect/composition readiness audit after generated APB requester and completer `.ppif` endpoints both exist; later slices ship fixed composition and `.apb` completer/composition alias exposure.
- `docs/IAL2_APB_INTERCONNECT_COMPOSITION_READINESS_AUDIT.md` — audits APB interconnect/composition readiness after generated APB requester/completer endpoints and selects public contract selection before any generated composition behavior.
- `docs/IAL2_APB_INTERCONNECT_COMPOSITION_CONTRACT_SELECTION.md` — selects the explicit APB `.ppif` requester/completer composition contract and routes the next slice to direct bounded implementation.
- `docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md` — ships the first fixed one-requester/one-completer APB `.ppif` composition behavior with `ppif/apb_composition.ppif`, generated endpoint `.isf`/`.fsm` review artifacts, selected `apb_tb.fsm` HDL entry, report schema `fsmgen.ial2.protocol_intent.apb_composition.v1`, support identity `intent.ppif_apb_composition`, and later `.apb` alias exposure through `ppif/apb_composition.apb`.
- `docs/IAL2_POST_APB_COMPOSITION_NEXT_SLICE_SELECTION.md` — selects APB `.apb` profile-alias public contract selection for the shipped APB completer and fixed APB composition `.ppif` shapes, without changing behavior.
- `docs/IAL2_APB_PROFILE_ALIAS_COMPLETER_COMPOSITION_CONTRACT_SELECTION.md` — selects direct bounded implementation of APB `.apb` alias widening for `ppif/apb_completer.apb` and `ppif/apb_composition.apb`, with explicit `(profile apb)`, generated review-artifact preservation, support identities `intent.apb_profile_alias_completer` and `intent.apb_profile_alias_composition`, and no behavior change in the selector slice.
- `docs/IAL2_POST_APB_ALIAS_WIDENING_NEXT_SLICE_SELECTION.md` — selects APB requester busy/status public contract selection after requester-transfer, completer, fixed composition, and bounded `.apb` alias coverage all shipped, without changing behavior.
- `docs/IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION.md` — selects additive busy-only APB requester status exposure through new `.ppif`/`.apb` requester-transfer and fixed-composition samples while keeping existing APB samples unchanged and named status fields deferred.
- `docs/IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR.md` — ships additive busy-only APB requester output behavior through `ppif/apb_requester_transfer_busy.ppif`, `ppif/apb_requester_transfer_busy.apb`, `ppif/apb_composition_busy.ppif`, and `ppif/apb_composition_busy.apb`, preserving no-busy APB samples and keeping named status fields deferred.
- `docs/IAL2_POST_APB_BUSY_OUTPUT_NEXT_SLICE_SELECTION.md` — selects no-behavior public-surface and `bin/fsmgen` import-tree synchronization after APB busy output, before any further behavior work.
- `docs/IAL2_POST_APB_PUBLIC_SYNC_NEXT_SLICE_SELECTION.md` — selects APB requester named status-field public contract selection after APB public-surface/import-tree synchronization, without changing behavior.
- `docs/IAL2_APB_REQUESTER_STATUS_FIELD_CONTRACT_SELECTION.md` — selects additive 2-bit APB requester named status-field exposure through new busy-plus-status requester-transfer and fixed-composition `.ppif`/`.apb` samples, while keeping existing no-busy and busy-only APB samples unchanged.
- `docs/IAL2_APB_REQUESTER_STATUS_FIELD_BEHAVIOR.md` — ships additive busy-plus-status APB requester output behavior through `ppif/apb_requester_transfer_status.ppif`, `ppif/apb_requester_transfer_status.apb`, `ppif/apb_composition_status.ppif`, and `ppif/apb_composition_status.apb`, preserving existing APB samples and removing requester busy/status residues only from status-capable reports.
- `docs/IAL2_POST_APB_STATUS_FIELD_NEXT_SLICE_SELECTION.md` — selects APB multi-register decode readiness audit after APB requester status-field behavior, without changing behavior.
- `docs/IAL2_APB_MULTI_REGISTER_DECODE_READINESS_AUDIT.md` — audits APB multi-register decode readiness and selects public APB multi-register completer decode contract selection before implementation.
- `docs/IAL2_APB_MULTI_REGISTER_DECODE_CONTRACT_SELECTION.md` — selects repeated-register APB multi-register completer decode syntax, report shape, samples, diagnostics, and direct bounded implementation.
- `docs/IAL2_APB_MULTI_REGISTER_DECODE_BEHAVIOR.md` — ships additive APB multi-register completer decode through standalone completer and status-capable composition `.ppif`/`.apb` samples, with source-order `registers[]` report fields and preserved one-register APB behavior.
- `docs/IAL2_POST_APB_MULTI_REGISTER_NEXT_SLICE_SELECTION.md` — selects APB multi-peripheral interconnect/decode readiness audit after APB multi-register completer decode, without changing behavior.
- `docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_READINESS_AUDIT.md` — audits APB multi-peripheral interconnect/decode readiness, selects public contract selection before behavior work, and records the APB-specific generated reusable IAL1 review artifact direction.
- `docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_CONTRACT_SELECTION.md` — selects the APB multi-peripheral interconnect/decode source contract, generated `apb_interconnect.isf` review artifact, report fields, samples, diagnostics, and direct bounded implementation owner.
- `docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md` — ships bounded APB multi-peripheral interconnect/decode through generated APB composition `.ppif` and `.apb` sources, including `apb_interconnect.isf`/`.fsm`, static address windows, response muxing, unmapped error response, and collision-free generated instance aliases.
- `docs/IAL2_POST_APB_MULTI_PERIPHERAL_NEXT_SLICE_SELECTION.md` — selects APB sidebands/strobes/byte-lane readiness audit after APB multi-peripheral interconnect/decode behavior, without changing behavior.
- `docs/IAL2_APB_SIDEBAND_STROBE_READINESS_AUDIT.md` — audits APB `PPROT`/`PSTRB`/byte-lane readiness and selects public sideband/strobe contract selection before behavior work.
- `docs/IAL2_APB_SIDEBAND_STROBE_CONTRACT_SELECTION.md` — selects the APB `PPROT`/`PSTRB` source syntax, fixed 32-bit byte-lane semantics, report/support shape, diagnostics, and direct bounded implementation owner.
- `docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md` — ships bounded APB `PPROT`/`PSTRB` propagation and `PSTRB` byte-lane register writes through sideband-aware requester, completer, fixed-composition, and multi-peripheral composition `.ppif`/`.apb` samples.
- `docs/IAL2_POST_APB_SIDEBAND_STROBE_NEXT_SLICE_SELECTION.md` — selects APB public-surface/report-static cleanup after APB sideband/strobe behavior, without changing behavior.
- `docs/IAL2_APB_PUBLIC_SURFACE_REPORT_STATIC_SYNC.md` — synchronizes generic `.ppif` and `.apb` static public-surface wording with shipped sideband-aware APB coverage and selects APB alternate-width readiness audit.
- `docs/IAL2_APB_ALTERNATE_WIDTH_READINESS_AUDIT.md` — audits APB alternate-width readiness and selects public APB alternate-width contract selection before behavior changes.
- `docs/IAL2_APB_ALTERNATE_WIDTH_CONTRACT_SELECTION.md` — selects sideband-aware 16-bit APB data/strobe variants as the first alternate-width implementation contract.
- `docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md` — ships selected sideband-aware APB data16 requester, completer, fixed-composition, and multi-peripheral composition behavior.
- `docs/IAL2_APB_PPROT_EFFECTS_READINESS_AUDIT.md` — audits APB `PPROT` access-control effects readiness and selects public policy contract selection before behavior changes.
- `docs/IAL2_APB_PPROT_EFFECTS_CONTRACT_SELECTION.md` — selects register-local APB `PPROT` access-policy syntax, privileged predicate semantics, denied-access response behavior, reports, diagnostics, and direct implementation ownership.
- `docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md` — ships register-local APB `PPROT[0]` privileged access-policy enforcement for sideband-aware 32-bit multi-register completers, fixed composition, and multi-peripheral composition.
- `docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md` — ships the selected `sideband_data16_protection` extension of register-local APB `PPROT[0]` privileged access-policy enforcement for sideband-aware 16-bit completers, fixed composition, and multi-peripheral composition.
- `docs/IAL2_POST_APB_DATA16_PPROT_NEXT_SLICE_SELECTION.md` — selects APB back-to-back transfer policy readiness audit after data16 `PPROT` policy behavior, without behavior changes.
- `docs/IAL2_APB_BACK_TO_BACK_READINESS_AUDIT.md` — audits APB requester queued admission, completer setup admission, and composition propagation readiness, then selects public back-to-back timing-policy contract selection before behavior changes.
- `docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects explicit APB requester `(timing-policy (back-to-back queued) (queue-depth 1) (overflow reject))`, completer `(setup-admission adjacent)`, accepted/busy/status response requirements, first fixed-composition sample family, reports, diagnostics, validation, rollback, and deferrals before behavior changes.
- `docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md` — ships the selected APB depth-1 queued requester, adjacent completer setup admission, and compatible fixed-composition propagation for the status back-to-back sample family.
- `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_READINESS_AUDIT.md` — audits APB multi-peripheral back-to-back propagation after fixed-composition behavior shipped and selects a narrow 32-bit no-sideband implementation owner.
- `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md` — ships the selected 32-bit no-sideband two-peripheral APB status back-to-back family, with depth-1 queued requester propagation through the generated interconnect and narrowed future-policy residue.
- `docs/IAL2_POST_APB_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects APB sideband-aware back-to-back readiness audit after no-sideband fixed and multi-peripheral timing-policy behavior shipped, without changing behavior.
- `docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_READINESS_AUDIT.md` — audits APB sideband-aware back-to-back readiness and selects requester-first queued `PPROT/PSTRB` implementation before composition propagation.
- `docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_BEHAVIOR.md` — ships the selected 32-bit sideband-aware APB requester back-to-back behavior, including queued `PPROT/PSTRB` capture and relaunch for the status requester `.ppif`/`.apb` samples.
- `docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_READINESS_AUDIT.md` — audits APB sideband-aware completer and composition timing-policy readiness after requester queue capture and selects public contract selection before fixed-composition implementation.
- `docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects the bounded sideband-aware APB completer plus fixed-composition back-to-back public contract before implementation.
- `docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_BEHAVIOR.md` — ships selected 32-bit sideband-aware APB adjacent completer setup plus fixed-composition queued sideband `PPROT/PSTRB` propagation.
- `docs/IAL2_POST_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects public contract selection for bounded 32-bit sideband-aware APB multi-peripheral back-to-back propagation after fixed composition shipped.
- `docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects the bounded 32-bit sideband-aware APB two-peripheral status back-to-back public contract before implementation.
- `docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md` — ships selected 32-bit sideband-aware APB multi-peripheral status back-to-back propagation through the generated interconnect.
- `docs/IAL2_POST_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects APB data16/protection back-to-back timing-policy readiness audit after selected sideband multi-peripheral timing shipped.
- `docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_READINESS_AUDIT.md` — audits APB data16/protection back-to-back readiness and selects sideband-aware multi-register timing-policy contract selection as the prerequisite.
- `docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects the bounded standalone completer plus fixed-composition APB sideband-aware multi-register back-to-back public contract before implementation.
- `docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md` — ships selected 32-bit sideband-aware APB two-register adjacent setup plus fixed-composition queued sideband propagation.
- `docs/IAL2_POST_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects APB sideband-aware data16 back-to-back public contract selection after selected sideband multi-register timing shipped.
- `docs/IAL2_APB_DATA16_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects the bounded APB sideband-aware data16 requester, standalone completer, and fixed-composition back-to-back public contract before implementation.
- `docs/IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB sideband-aware data16 requester, standalone two-register completer, and fixed-composition back-to-back timing behavior.
- `docs/IAL2_POST_APB_DATA16_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects APB sideband-aware protection back-to-back public contract selection after selected data16 timing shipped.
- `docs/IAL2_APB_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects the bounded APB sideband-aware protection standalone completer and fixed-composition back-to-back public contract before implementation.
- `docs/IAL2_APB_PROTECTION_BACK_TO_BACK_BEHAVIOR.md` — ships selected 32-bit sideband-aware APB protection standalone completer and fixed-composition back-to-back timing behavior.
- `docs/IAL2_POST_APB_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects APB sideband-aware data16-protection back-to-back public contract selection after selected protection timing shipped.
- `docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects the bounded APB sideband-aware data16-protection standalone completer and fixed-composition back-to-back public contract before implementation.
- `docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB sideband-aware data16-protection standalone completer and fixed-composition back-to-back timing behavior.
- `docs/IAL2_POST_APB_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects APB sideband-aware multi-peripheral data16-protection back-to-back public contract selection after selected fixed data16-protection timing shipped.
- `docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects the bounded APB sideband-aware multi-peripheral data16-protection back-to-back public contract before implementation.
- `docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB sideband-aware multi-peripheral data16-protection back-to-back timing behavior.
- `docs/IAL2_POST_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects broader APB multi-peripheral multi-register back-to-back timing readiness audit after selected multi-peripheral data16-protection timing shipped.
- `docs/IAL2_APB_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md` — audits broader APB multi-peripheral multi-register timing readiness and selects bounded 32-bit sideband-aware protection multi-peripheral contract selection.
- `docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects the bounded APB sideband-aware multi-peripheral protection back-to-back public contract before implementation.
- `docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB sideband-aware multi-peripheral protection back-to-back timing behavior.
- `docs/IAL2_POST_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects APB no-policy multi-peripheral multi-register back-to-back timing readiness audit after selected protected multi-peripheral timing shipped.
- `docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md` — audits APB no-policy multi-peripheral multi-register timing readiness and selects bounded 32-bit sideband-aware public contract selection.
- `docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects exact APB no-policy multi-peripheral multi-register back-to-back public sources before implementation.
- `docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB no-policy multi-peripheral multi-register back-to-back timing behavior.
- `docs/IAL2_POST_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects APB sideband-aware data16 no-policy multi-peripheral multi-register back-to-back public contract selection after selected 32-bit no-policy multi-register timing shipped.
- `docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects exact APB data16 no-policy multi-peripheral multi-register back-to-back public sources before implementation.
- `docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB data16 no-policy multi-peripheral multi-register back-to-back timing behavior.
- `docs/IAL2_POST_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects APB data16-protection generalization readiness audit after selected data16 no-policy multi-peripheral multi-register timing shipped.
- `docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md` — audits APB data16-protection multi-peripheral multi-register timing readiness and selects public contract selection.
- `docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects exact APB data16-protection multi-peripheral multi-register back-to-back public sources before implementation.
- `docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB data16-protection multi-peripheral multi-register back-to-back timing behavior.
- `docs/IAL2_POST_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects APB status/control protected-storage generalization readiness audit after selected data16-protection multi-peripheral multi-register timing shipped.
- `docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_READINESS_AUDIT.md` — audits APB status/control protected-storage generalization readiness and selects public contract selection before behavior changes.
- `docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_CONTRACT_SELECTION.md` — selects residue/static cleanup for the already-shipped APB status/control protected-storage generalization contract.
- `docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_RESIDUE_CLEANUP.md` — ships APB status/control protected-storage residue cleanup and selects generalized multi-peripheral multi-register timing readiness next.
- `docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_TIMING_READINESS_AUDIT.md` — audits generalized APB multi-peripheral multi-register timing readiness and selects bounded 32-bit protected `reg0`/`reg1` contract selection next.
- `docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects exact APB 32-bit protected `reg0`/`reg1` multi-peripheral multi-register back-to-back public sources before implementation.
- `docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB 32-bit protection multi-peripheral multi-register back-to-back timing behavior.
- `docs/IAL2_POST_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects generalized APB multi-peripheral multi-register source-shape readiness audit after selected 32-bit protection multi-register timing shipped.
- `docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_READINESS_AUDIT.md` — audits generalized APB multi-peripheral multi-register source-shape readiness and selects bounded source-shape contract selection before behavior changes.
- `docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_CONTRACT_SELECTION.md` — selects bounded APB sideband-aware no-policy generalized `reg0..regN` register-set public sources before implementation.
- `docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB sideband-aware no-policy generalized `reg0..regN` register-set multi-peripheral back-to-back timing behavior.
- `docs/IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects bounded APB sideband-aware data16 no-policy generalized `reg0..regN` register-set implementation next.
- `docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB sideband-aware data16 no-policy generalized `reg0..regN` register-set multi-peripheral back-to-back timing behavior.
- `docs/IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects public contract selection for bounded APB sideband-aware 32-bit protected generalized `reg0..regN` register-set timing next.
- `docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects bounded APB sideband-aware 32-bit protected generalized `reg0..regN` register-set public sources before implementation.
- `docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB sideband-aware 32-bit protected generalized `reg0..regN` register-set multi-peripheral back-to-back timing behavior.
- `docs/IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects public contract selection for bounded APB sideband-aware data16 protected generalized `reg0..regN` register-set timing next.
- `docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md` — selects bounded APB sideband-aware data16 protected generalized `reg0..regN` register-set public sources before implementation.
- `docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md` — ships selected APB sideband-aware data16 protected generalized `reg0..regN` register-set multi-peripheral back-to-back timing behavior.
- `docs/IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md` — selects broader APB generalized register-set cardinality readiness audit next.
- `docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_READINESS_AUDIT.md` — audits broader APB generalized register-set cardinality readiness and selects first 32-bit no-policy five-register contract selection next.
- `docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md` — selects bounded APB sideband-aware 32-bit no-policy five-register generalized `reg0..regN` register-set public sources before implementation.
- `docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md` — ships bounded APB sideband-aware 32-bit no-policy five-register generalized `reg0..regN` register-set multi-peripheral timing behavior.
- `docs/IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md` — selects bounded APB sideband-aware data16 no-policy five-register generalized `reg0..regN` register-set public contract selection next.
- `docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md` — selects bounded APB sideband-aware data16 no-policy five-register generalized `reg0..regN` register-set public sources before implementation.
- `docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md` — ships bounded APB sideband-aware data16 no-policy five-register generalized `reg0..regN` register-set multi-peripheral timing behavior.
- `docs/IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md` — selects bounded APB sideband-aware 32-bit protected five-register generalized `reg0..regN` register-set public contract selection next.
- `docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md` — selects bounded APB sideband-aware 32-bit protected five-register generalized `reg0..regN` register-set public sources before implementation.
- `docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md` — ships bounded APB sideband-aware 32-bit protected five-register generalized `reg0..regN` register-set multi-peripheral timing behavior.
- `docs/IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md` — selects bounded APB sideband-aware data16 protected five-register generalized `reg0..regN` register-set public contract selection next.
- `docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md` — selects bounded APB sideband-aware data16 protected five-register generalized `reg0..regN` register-set public sources before implementation.
- `docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md` — ships bounded APB sideband-aware data16 protected five-register generalized `reg0..regN` register-set multi-peripheral timing behavior.
- `docs/IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md` — selects broader APB generalized register-set cardinality readiness audit next.
- `docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BROADER_CARDINALITY_READINESS_AUDIT.md` — audits broader APB generalized register-set cardinality and selects first 32-bit no-policy six-register contract selection next.
- `docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_CONTRACT_SELECTION.md` — selects bounded APB sideband-aware 32-bit no-policy six-register generalized `reg0..regN` public sources before implementation.
- `docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_BEHAVIOR.md` — ships bounded APB sideband-aware 32-bit no-policy six-register generalized `reg0..regN` register-set multi-peripheral timing behavior.
- `docs/IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_NEXT_SLICE_SELECTION.md` — selects bounded APB sideband-aware data16 no-policy six-register generalized `reg0..regN` public contract selection next.
- `docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_CONTRACT_SELECTION.md` — selects bounded APB sideband-aware data16 no-policy six-register generalized `reg0..regN` public sources before implementation.
- `docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_BEHAVIOR.md` — ships bounded APB sideband-aware data16 no-policy six-register generalized `reg0..regN` register-set multi-peripheral timing behavior.
- `docs/IAL2_AXI_APB_AHB_TRIMODE_MDBOOK_COVERAGE_AUDIT.md` — selects the IAL2 AXI/APB/AHB tri-mode mdBook documentation coverage plan and follow-on leaves.
- `docs/IAL2_POST_TRIMODE_MDBOOK_NEXT_SLICE_SELECTION.md` — selects the AHB IAL2 source-shape readiness audit after tri-mode mdBook coverage completed.
- `docs/IAL2_AHB_SOURCE_SHAPE_READINESS_AUDIT.md` — selects AHB requester `.ppif` public contract selection before any AHB implementation or `.ahb` alias support.
- `docs/IAL2_AHB_REQUESTER_PPIF_PUBLIC_CONTRACT_SELECTION.md` — selects the first AHB requester generic `.ppif` public contract and the follow-on implementation owner.
- `docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md` — documents the shipped bounded AHB requester generic `.ppif` behavior, generated `.isf`/`.fsm` review artifacts, support accounting, diagnostics, validation, and broader-AHB residue.
- `docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_CONTRACT_SELECTION.md` — selects the additive bounded requester-side single-BUSY public source contract while preserving the base requester and its `.ahb` alias.
- `docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_BEHAVIOR.md` — documents the shipped bounded requester-side single-BUSY insertion behavior, held pending transfer, resumed `SEQ`, report/support surfaces, diagnostics, and remaining broader-BUSY residue.
- `docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_CONTRACT_SELECTION.md` — selects direct data-only implementation of the matching requester BUSY-insertion `.ahb` profile alias with unchanged generated behavior.
- `docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_BEHAVIOR.md` — documents the shipped requester BUSY-insertion `.ahb` alias, byte-identical generic-source parity, support accounting, alias-only residue cleanup, validation, and deferrals.
- `docs/IAL2_POST_AHB_REQUESTER_BUSY_INSERTION_ALIAS_NEXT_SLICE_SELECTION.md` — records the `.791` no-behavior selection of `.792`, a readiness audit for one paired BUSY-inserting-requester/BUSY-parking-subordinate aggregate; captures the already-composable endpoint/artifact shape and the aggregate child-report omission of requester `busy_insertion` that must be settled before implementation.
- `docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md` — records the `.792` no-behavior audit: the one-subordinate paired BUSY aggregate needs no parser/endpoint/wiring/top/HDL substrate repair, aggregate requester-child `busy_insertion` needs one additive conditional clone, generated `ahb_tb` has sufficient runtime observation points, and `.793` owns exact public contract selection.
- `docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md` — records the `.793` exact contract for `.794`: one additive generic `.ppif` aggregate, requester-child `busy_insertion` plus aggregate `parks_on=[busy]`, support/accounting identities, t/1513 generated-HDL proof through final `32'h44332211` storage, preservation, and deferred alias/two-subordinate variants.
- `docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md` — documents the `.794` shipped paired generic AHB BUSY aggregate, conditional requester-child `busy_insertion`, subordinate/aggregate `parks_on=[busy]`, generated phase-ownership prerequisites, clean public HDL verification, t/1513 runtime proof, support accounting, preservation, and explicit pipeline/alias/two-subordinate deferrals.
- `docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md` — records the `.795` selection of `.796`, data-only implementation of the matching paired-BUSY `.ahb` profile alias; the alias is a second public source surface for the same generated architecture, not another generator, and reuses t/1513 runtime behavior while t/1514 owns alias parity/CLI proof.
- `docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.796` shipped paired-BUSY `.ahb` profile alias, byte-identical `.ppif` parity, one shared generator/lowering architecture, support identity, alias-only residue cleanup, t/1514 public-surface proof, and retained t/1513 runtime proof.
- `docs/IAL2_POST_AHB_PAIRED_BUSY_FAMILY_NEXT_SLICE_SELECTION.md` — records the `.797` no-behavior selection of `.798`, two-subordinate paired BUSY readiness; captures the successful four-child in-memory composition probe, the required status/control-window runtime proof, and the contradictory broader-versus-burst BUSY residue that the audit must resolve before implementation.
- `docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_READINESS_AUDIT.md` — records the `.798` candidate proof across check/schedule/semantic/artifact/SystemVerilog/Yosys surfaces, exact future status/control runtime observation plan, absence of generator prerequisites, and selection of `.799` report-only BUSY-residue repair before `.800` paired public contract selection.
- `docs/IAL2_AHB_TWO_SUBORDINATE_BUSY_REPORT_REPAIR.md` — records the `.799` report-only truthfulness repair: parked two-subordinate generic/alias surfaces claim shipped BUSY parking consistently, non-parking surfaces retain BUSY-continuation deferral, and sources/artifacts/support/HDL behavior stay unchanged before `.800` contract selection.
- `docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_CONTRACT_SELECTION.md` — records the `.800` exact generic source/support/report/artifact contract, t/1515 two-command status/control runtime proof, 313/354 accounting target, preservation/diagnostics/resource/rollback boundaries, later alias sequencing, and `.801` direct implementation owner.
- `docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md` — documents the `.801` shipped generic four-child paired-BUSY aggregate, one existing generator architecture, exact report/artifact/support surfaces, and generated-HDL status/control proof through retained `32'h44332211`/`32'h88776655` storage.
- `docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md` — records the `.802` selection of `.803`, a byte-identical data-only `.ahb` alias with 314/355 accounting targets, t/1516 parity/public-surface proof, retained t/1515 runtime, existing alias-residue cleanup, and no new generator.
- `docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.803` shipped byte-identical `.ahb` alias, shared four-child generator architecture/runtime, exact support/artifact/report surfaces, alias-only residue cleanup, t/1516 proof, and 314/355 accounting.
- `docs/IAL2_POST_TWO_SUBORDINATE_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md` — records the `.804` no-behavior selection of the canonical requester WRAP-progression audit, the sequential mutation/retest risk, the missing runtime WRAP4 address-sequence proof, deferred alternatives, and the clean-pivot activation boundary.
- `docs/IAL2_AHB_REQUESTER_WRAP_PROGRESSION_RUNTIME_AUDIT.md` — preserves the `.1` generated-HDL proof that pre-repair byte WRAP4 start 3 presented `3,1,2,3` instead of `3,0,1,2`, the numbered-state mutation/retest root cause shared by fixed wrapping modes, and the selected `.2` increment-then-wrap repair.
- `docs/IAL2_AHB_REQUESTER_WRAP_PROGRESSION_REPAIR.md` — records the `.2` generated/direct requester increment-then-wrap repair, exact WRAP4/8/16 address sequences, public-contract stability, preservation gates, scope boundaries, and rollback rule.
- `docs/IAL2_POST_REQUESTER_WRAP_REPAIR_NEXT_OWNER_SELECTION.md` — records the `.805` proof that six shipped aggregate/paired AHB `.ahb` aliases contradict stale current mdBook/behavior/fact deferrals, selects `.806` current-surface truthfulness repair with t/1518, preserves historical records, and keeps the boundary-free audit plus decision 0020 inactive.
- `docs/IAL2_AHB_CURRENT_SURFACE_ALIAS_TRUTHFULNESS_REPAIR.md` — records the `.806` current mdBook/behavior/fact repair for six shipped aggregate/paired AHB aliases, the historical-record boundary, focused t/1518 regression lock, unchanged runtime/public contracts, remaining frontier, and rollback.
- `docs/IAL2_POST_CURRENT_SURFACE_REPAIR_NEXT_OWNER_SELECTION.md` — records the `.807` selection of the canonical boundary-free AHB active-transfer audit, the current admit/release gap and bounded paired-requester proof, exact generated-HDL audit contract, deferred alternatives, clean-pivot boundary, preservation, and rollback.
- `docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md` — records the `.1` generated-HDL proof that two direct ready/OKAY NONSEQ/SEQ address phases produce only one internal admission/completion and one storage effect, why an endpoint-only boundary contract cannot fail closed safely, and selection of `.2` completion-boundary phase-recapture contract work.
- `docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md` — freezes the `.2` depth-one accepted address/control bank at the bus-visible ready/completion edge, data-phase HWDATA ownership, sequence/error ordering, additive report contract, `.3` implementation gates, and `.4` direct-seed audit boundary.
- `docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md` — records the `.3` coupled generated subordinate/requester/interconnect phase repair, additive phase/data-owner reports, exact t/1519 and paired runtime proofs, stable public identities, depth-one boundary, and `.4` direct-seed handoff.
- `docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md` — records the `.4` generated-HDL proof that the distinct direct subordinate seed drops active phases accepted on successful/final-ERROR completion edges, the IDLE-only capture root cause, unchanged behavior, and `.5`/`.6` handoff.
- `docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md` — preserves the superseded `.5` no-bank completion-edge dispatch selection, its still-valid external exactly-once/HWDATA goals, and the `.6` lowering-evidence supersession route.
- `docs/IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md` — records the `.6` emitted-HDL proof that direct register-input mux reuse lets next control alter current completion, the deterministic suppressed-write failure, full behavior restoration, and corrected-contract handoff.
- `docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_CONTRACT_SELECTION.md` — freezes the `.7` Q-named `<-` four-state completion dispatcher, warning-clean four-scenario feasibility proof, rejected UNOPTFLAT bank/relaunch alternative, `.8` gates, and rollback.
- `docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_REPAIR.md` — records the `.8` shipped Q-named four-state direct-seed repair, exact t1520 success/ERROR/SEQ/IDLE proof, stable support/public boundaries, and rollback.
- `docs/IAL2_POST_AHB_PHASE_REPAIR_NEXT_OWNER_SELECTION.md` — records `.808` selection of a no-behavior readiness audit for bounded multiple requester BUSY presentations, including the ready-acceptance question and larger deferred alternatives.
- `docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md` — records the `.1` source-backed/runtime finding that pre-repair `beats=single` spanned ten ready-qualified BUSY edges, corrects the fixed-length ready-low BUSY-to-SEQ premise, proves assertion-enabled exact-one/exact-two candidates, selects `.2` single-event repair contract work, and routes a separate output-priority lowering gap.
- `docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR_CONTRACT_SELECTION.md` — records `.2` selection of exactly one grant-and-ready-qualified BUSY event, stable pending BUSY across ready/grant stalls, the existing address-pending `SEQ` handoff, assertion-enabled public stall proofs, unchanged public/report surfaces, `.3` implementation gates, and multiple-BUSY deferral.
- `docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR.md` — records the `.3` shipped conditional BUSY acceptance/hold repair, assertion-enabled continuous/32-clock-ready-low/32-clock-grant-low requester proofs, exact generic/alias paired qualified-event counts, unchanged public/report/support/artifact surfaces, and the separate pre-existing interconnect assertion boundary.
- `docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_CONTRACT_SELECTION.md` — records `.4` selection of optional literal `(busy-beats 2)`, the additive generic exact-two requester identity, width-two qualified-event counter/SEQ handoff, numeric `busy_insertion.beats=2`, assertion-enabled t1521 contract, preservation/accounting boundaries, `.5` implementation, and broader-count/alias/composition deferral.
- `docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_BEHAVIOR.md` — documents the `.5` shipped generic exact-two requester source, existing-generator architecture, actor-owned qualified-event counter and checker-required priority, numeric report/support surfaces, assertion-enabled t1521 runtime, and `.6`/`.7` exact-two alias handoff.
- `docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md` — records `.6` selection of a byte-identical exact-two `.ahb` profile alias, its support/report/artifact/semantic/MCP parity contract, projected 316/357/40 accounting, shared t1521 runtime, focused t1522 proof boundary, `.7` implementation handoff, and explicit non-selections.
- `docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.7` shipped byte-identical exact-two `.ahb` alias, same-generator lowering, alias-only residue cleanup, 316/357/40 support boundary, strict semantic JSON and real read-only MCP introspection, focused t1522 parity, and shared t1521 runtime.
- `docs/IAL2_POST_REQUESTER_MULTI_BUSY_NEXT_OWNER_SELECTION.md` — records `.809` selection of one-subordinate exact-two requester/BUSY-parking-subordinate runtime readiness, the successful static three-child/artifact/report probe, semantic/MCP cross-cutting requirement, rejected broader owners, proposed audit activation boundary, and rollback.
- `docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md` — records the child `.1` disposable generated-HDL proof of two qualified BUSY events, stable requester/subordinate/interconnect ownership and storage, one resumed `SEQ`, four clean data beats, final `32'h44332211`, no required substrate repair, and proposed `.2` generic public-contract handoff with existing semantic/MCP parity required.
- `docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md` — records `.2` selection of the long-form generic exact-two paired source, reuse of the existing three-child architecture, exact report/residue/artifact/support identities, projected 317/358/41 accounting, t1523 runtime, normalized semantic JSON and real read-only MCP parity, `.3` implementation handoff, and separate alias/two-subordinate deferral.
- `docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md` — documents the `.3` shipped generic exact-two paired source, unchanged three-generator/top architecture, numeric requester child and BUSY-parking propagation reports, 317/358/41 accounting, t1523 runtime, and normalized semantic JSON/read-only MCP parity.
- `docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md` — records `.4` selection of the byte-identical matching `.ahb` alias, existing suffix-only residue cleanup, projected 318/359/42 accounting, t1524 normalized semantic/read-only MCP parity, shared t1523 runtime, and proposed `.5` data-only implementation.
- `docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.5` shipped byte-identical matching `.ahb` alias, unchanged generator/artifact/report architecture, alias-only residue cleanup, 318/359/42 accounting, focused t1524 normalized semantic/read-only MCP parity, and shared t1523 runtime.
- `docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md` — records `.6` disposable four-child static/semantic/real read-only MCP and generated-HDL proof across both status/control windows, exact-two qualified-event and resumed-SEQ totals, stable selected/unselected/data-owner state, no required repair, and proposed `.7` public-contract handoff without shipped behavior.
- `docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md` — records `.7` topology-first generic source identity, exact four-child report/artifact/window/owner contract, t1525 two-window exact-two runtime, normalized semantic/read-only MCP parity, projected 319/360/43 accounting, `.8` implementation handoff, and separate alias/transaction-layer boundaries.
- `docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md` — documents `.8` shipment of the topology-first generic source through existing generators, 319/360/43 accounting, exact four-child artifacts/windows/ownership, focused t1525 two-command runtime, and ongoing normalized semantic/read-only MCP parity.
- `docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md` — records `.810` selection of the byte-identical matching `.ahb` alias, existing suffix-only residue cleanup, projected 320/361/44 accounting, t1526 normalized semantic/read-only MCP parity, shared t1525 runtime, and proposed `.811` implementation.
- `docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md` — documents `.811` shipment of the byte-identical matching `.ahb` alias, 320/361/44 accounting, unchanged four-child artifacts/windows/ownership, focused t1526 normalized semantic/read-only MCP/artifact/verifier parity, and shared t1525 runtime.
- `docs/IAL2_POST_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md` — records `.812` selection of a no-behavior literal-three requester BUSY readiness audit: the shipped width-two counter statically fits three, while guarded assertion-enabled continuous/ready-low/grant-low runtime remains required before any public contract.
- `docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md` — records the guarded disposable exact-three proof: internal width-two counter `3 -> 2 -> 1 -> 0`, continuous/32-ready-low/32-grant-low cardinality and stall stability, strict/schedule/semantic/read-only MCP parity, exact-one/two/base preservation, no lower-layer repair, and proposed public-contract `.2` handoff.
- `docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_CONTRACT_SELECTION.md` — records `.2` selection of bounded literal `busy-beats` values 2..3, the additive generic exact-three identities, unchanged width-two retirement/priority/SEQ contract, numeric report/residue truth, projected 321/362/45 accounting, direct-counter runtime gates, `.3` implementation, and later separate alias cadence.
- `docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_BEHAVIOR.md` — documents `.3` shipment of the generic exact-three requester, literal range 2..3, unchanged width-two lowering, direct `3 -> 2 -> 1 -> 0` continuous/stall runtime plus strengthened exact-two proof, semantic/read-only MCP parity, truthful residue, and the later matching alias handoff.
- `docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md` — records `.4` selection of a byte-identical exact-three `.ahb` profile alias, its support/report/artifact/semantic/MCP parity contract, projected 322/363/46 accounting split 23/23, shared t1528 runtime, focused t1529 proof boundary, and `.5` implementation handoff.
- `docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md` — documents `.5` shipment of the byte-identical exact-three `.ahb` alias, exact support/semantic identity, numeric `beats=3`, alias-only residue cleanup, 322/363/46 accounting split 23/23, focused t1529 parity, and shared t1528 runtime.
- `docs/IAL2_POST_EXACT_THREE_REQUESTER_ALIAS_NEXT_OWNER_SELECTION.md` — records `.813` selection of the AHB interconnect default/decode output-arbitration audit before more paired expansion, because mapped public aggregates still require `--no-assert` around a known selector overlap.
- `docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_AUDIT.md` — records fresh mapped address-zero/nonzero assertion failures, the exact five-output one-window/seven-output two-window overlap, historical origin, generated-IAL0 ownership, and the proposed mutually exclusive arbitration contract handoff without behavior changes.
- `docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md` — freezes complementary per-window decode modes, exclusive global response modes, assertion-preserving owner handling, direct-fabric t1530, and the separate subordinate assertion boundary.
- `docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_BEHAVIOR.md` — documents the shipped assertion-clean generated interconnect modes, preserved AHB behavior/public surfaces, focused one-/two-window runtime, and the historical subordinate-owned assertion boundary later retired by the endpoint repair.
- `docs/IAL2_POST_INTERCONNECT_ARBITRATION_NEXT_OWNER_SELECTION.md` — records `.814` selection of the subordinate default/phase output-arbitration audit because it is the sole known remaining reason paired AHB aggregates disable assertions.
- `docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_AUDIT.md` — maps every generated endpoint selector family, reproduces direct/paired idle+capture, idle+hold, and ERROR-retire+capture overlaps, keeps generic assertions authoritative, and separates the hand-authored direct IAL0 seed gap.
- `docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md` — selects exactly five redundant generated-IAL1 write removals while freezing assertion-enabled base/rich direct and one-/two-window paired gates.
- `docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_BEHAVIOR.md` — documents the shipped five-write endpoint repair, unchanged phase/data/ERROR behavior and public surfaces, assertion-enabled base/rich direct proof, retired paired `--no-assert` boundary, and separately parked direct IAL0 seed.
- `docs/IAL2_POST_SUBORDINATE_ARBITRATION_NEXT_OWNER_SELECTION.md` — records `.815` selection of direct IAL0 AHB subordinate output arbitration because t1520 is the sole remaining audited AHB `--no-assert` boundary.
- `docs/IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md` — selects exactly four redundant direct-seed zero-write removals, preserves explicit unsupported HREADYOUT/HRDATA ownership, and freezes assertion-enabled t1520 implementation `.2`.
- `docs/IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_BEHAVIOR.md` — documents the shipped four-write direct-seed arbitration repair, emitted implicit-zero baselines, retained unsupported owners, assertion-enabled t1520 proof, and unchanged public/HIAL/VIAL boundaries.
- `docs/IAL2_POST_DIRECT_ARBITRATION_NEXT_OWNER_SELECTION.md` — records `.816` selection of the proposed generic one-subordinate exact-three paired-BUSY readiness audit after all audited AHB lower layers became assertion-clean, including the disposable 5/4/1/3/1/`44332211` feasibility boundary and separate alias/two-window/broader-policy/HIAL-VIAL deferrals.
- `docs/IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md` — records `.1` proof that the existing exact-three requester, BUSY-parking subordinate, and fabric compose directly with all assertions, exact 3 IAL1/4 IAL0 artifacts, 5/4/1/3/1/`44332211` runtime, normalized semantic/read-only MCP parity, and projected 323/364/47 accounting before public contract selection.
- `docs/IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md` — freezes `.2` one-source generic contract, exact intent/object/anchor/support identities, existing 3 IAL1/4 IAL0 architecture, assertion-enabled t1531 5/4/1/3/1/`44332211` proof, normalized semantic/read-only MCP parity, projected 323/364/47 accounting, and separate `.3` implementation.
- `docs/IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md` — documents `.3` shipment of the generic exact-three paired source and `.818` shipment of its byte-identical `.ahb` alias through existing generators, exact support/report/artifact/semantic/read-only-MCP surfaces, assertion-enabled shared t1531 5/4/1/3/1/`44332211` runtime, focused t1532 alias parity, and the later 326/367/50 checkpoint after the two-window exact-three generic/profile pair shipped.
- `docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md` — proves the exact future two-window candidate through real read-only MCP, public verify-HDL, and assertion-enabled 10/8/2/6/2/`44332211`/`88776655` runtime without a lower-layer repair.
- `docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md` — freezes the topology-first generic source, exact 4 IAL1/5 IAL0 architecture, support identity, t1533 boundary, and projected 325/366/49 accounting before implementation.
- `docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md` — documents shipment of the generic two-window exact-three paired source through existing generators, exact semantic/read-only-MCP/support surfaces, assertion-enabled t1533 runtime, and the later matching alias's 326/367/50 checkpoint before the generic exact-four requester established 327/368/51.
- `docs/IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md` — records `.820` selection of the byte-identical matching `.ahb` alias, exact projected support/t1534 boundary at 326/367/50 split 25/25, shared t1533 runtime, and separate HIAL/VIAL/full-language-simulator work.
- `docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md` — documents `.821` shipment of that byte-identical `.ahb` alias, exact support/report/artifact/semantic/read-only-MCP/verifier parity in t1534, shared assertion-enabled t1533 runtime, its 326/367/50 checkpoint, the exact-four requester pair's 328/369/52 checkpoint, and the later exact-four paired generic/profile pair's 330/371/54 current boundary.
- `docs/IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md` — records `.822` selection of exact-four requester BUSY counter-width readiness after a same-volume candidate fails closed at the intentional literal-2..3/width-two boundary, with HIAL/VIAL and broader BUSY semantics kept separate.
- `docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_INSERTION_READINESS_AUDIT.md` — proves exact-four lower-layer readiness with an assertion-enabled disposable width-three `4 -> 3 -> 2 -> 1 -> 0` runtime across continuously qualified, ready-low, and grant-low scenarios, and selects preserving minimum-width lowering.
- `docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_CONTRACT_SELECTION.md` — freezes the additive generic exact-four source identity, literal-2..4 range, minimum counter widths 2/2/3, reports, support, t1535, cleanup, deferrals, and rollback before implementation.
- `docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_BEHAVIOR.md` — documents shipment of the generic exact-four requester, width-three lowering with exact-two/three preservation, assertion-enabled `4 -> 3 -> 2 -> 1 -> 0` continuous/stall runtime, semantic/read-only MCP parity, and later matching-alias handoff.
- `docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md` — selects a byte-identical exact-four `.ahb` alias through existing machinery, projected 328/369/52 accounting split 26/26, focused t1536 parity, and t1535 as the sole shared runtime.
- `docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md` — documents shipment of that byte-identical `.ahb` alias, exact width-three/report/artifact/semantic/read-only-MCP/verifier parity, its 328/369/52 requester-pair checkpoint and the later 330/371/54 paired current boundary, focused t1536 without simulation, and shared assertion-enabled t1535 runtime.
- `docs/IAL2_POST_EXACT_FOUR_REQUESTER_ALIAS_NEXT_OWNER_SELECTION.md` — records `.823` selection of one-window exact-four paired-BUSY readiness after a 9-file same-volume candidate strict-checks, lowers, and verifies cleanly, while assertion runtime and real MCP remain owned by the audit.
- `docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md` — proves direct one-window exact-four composition through strict/artifact/normalized-semantic/real read-only-MCP/public-verifier surfaces and assertion-enabled 5/4/1/4/1/`44332211` runtime, then selects a separate generic public contract.
- `docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md` — freezes `.2` one-source generic contract, exact intent/object/anchor/support identities, existing 3 IAL1/4 IAL0 architecture, assertion-enabled t1537 5/4/1/4/1/`44332211` proof, normalized semantic/read-only MCP parity, projected 329/370/53 accounting, and separate `.3` implementation.
- `docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md` — documents shipment of the byte-identical generic/`.ahb` one-subordinate exact-four paired sources, exact 3 IAL1/4 IAL0 architecture, width-three `4 -> 3 -> 2 -> 1 -> 0` retirement, semantic/read-only-MCP/public-verifier parity, focused t1538 alias proof without another simulation, shared assertion-enabled t1537 5/4/1/4/1/`44332211` runtime, same-volume temporary output, and current 330/371/54 split 27/27 accounting.
- `docs/IAL2_POST_EXACT_FOUR_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md` — records `.824` selection and `.825` shipment of the byte-identical exact-four paired `.ahb` alias, exact support identity, current 330/371/54 split 27/27, focused t1538 parity, shared t1537 runtime, pending `.826`, and separate two-window/HIAL-VIAL/broader owners.
- `docs/IAL2_POST_EXACT_FOUR_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md` — records `.826` selection of proposed two-subordinate exact-four paired-BUSY readiness after strict/lowering/semantic/real-MCP/HDL feasibility, with assertion-enabled two-command runtime left to the audit and broader HIAL/VIAL/VHDL/scale work separate.
- `docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md` — proves direct two-window exact-four composition through strict/artifact/semantic/read-only-MCP/verifier surfaces and assertion-enabled 10/8/2/8/2/`44332211`/`88776655` runtime, then selects a separate generic public contract.
- `docs/IAL2_AHB_PROFILE_ALIAS_READINESS_AUDIT.md` — selects AHB `.ahb` public profile-alias contract selection before any `.ahb` implementation or behavior change.
- `docs/IAL2_AHB_PROFILE_ALIAS_CONTRACT_SELECTION.md` — selects bounded AHB `.ahb` profile-alias implementation and the exact future alias/support-accounting contract.
- `docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md` — documents the shipped bounded AHB `.ahb` profile-alias behavior, generated review artifacts, support accounting, diagnostics, validation, and remaining broader-AHB residue.
- `docs/IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md` — selects AHB completer/subordinate readiness audit after requester `.ppif` and `.ahb` support shipped.
- `docs/IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md` — selects lower-layer AHB subordinate seed contract selection before any IAL2 AHB completer/subordinate contract or behavior.
- `docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md` — selects AHB subordinate source-reference and seed-evidence audit before lower-layer seed contract selection.
- `docs/IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md` — selects AHB/AHB-Lite local source-reference import prerequisite before source-fact extraction or seed contract selection.
- `docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER.md` — records the historical `.705` blocker: no approved/provided repo-local AHB/AHB-Lite source artifact existed before `.706`.
- `docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md` — records the `.706` import of the user-approved Arm AMBA AHB Protocol Specification PDF under `docs/vendor/arm/amba/ahb/`, its SHA-256, git-trackability, and the `.707` source-fact extraction follow-on.
- `docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md` — records the `.707` first source-backed AHB/AHB-Lite subordinate fact inventory and selects `.708`, lower-layer AHB subordinate seed contract selection.
- `docs/IAL2_AHB_SUBORDINATE_SEED_CONTRACT_SELECTION.md` — selects the `.708` lower-layer AHB-Lite/common-AHB subordinate direct seed contract: future `fsm/ahb_lite_subordinate.fsm`, module `ahb_lite_subordinate`, support-accounting identity `protocol.ahb_lite_subordinate`, selected port/reset/transfer/response policy, and `.709` implementation owner.
- `docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md` — documents the `.709` shipped direct `fsm/ahb_lite_subordinate.fsm` seed, support-accounting entry `protocol.ahb_lite_subordinate`, validation, generated-HDL inspection, and `.710` readiness-audit follow-on.
- `docs/IAL2_AHB_COMPLETER_SUBORDINATE_POST_SEED_READINESS_AUDIT.md` — records the `.710` no-behavior readiness audit after the direct seed and selects `.711`, public IAL2 AHB subordinate/completer contract selection.
- `docs/IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION.md` — selects the `.711` future public source `ppif/ahb_lite_subordinate.ppif`, object `(ahb-subordinate ahb_lite_subordinate ...)`, generated `ahb_lite_subordinate.isf` before `ahb_lite_subordinate.fsm`, report schema `fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, support identity `intent.ppif_ahb_lite_subordinate`, and `.712` generated-substrate audit follow-on.
- `docs/IAL2_AHB_SUBORDINATE_GENERATED_IAL1_SUBSTRATE_AUDIT.md` — records the `.712` generated-substrate audit, confirms the core AHB subordinate transaction flow is representable, blocks direct implementation on generated-IAL1 output default/reset semantics, and selects `.713`.
- `docs/IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_CONTRACT_SELECTION.md` — selects the `.713` generated-IAL1 actor interface output `(reset VALUE)` and `(default VALUE)` contract and routes implementation to `.714`.
- `docs/IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_BEHAVIOR.md` — records the `.714` generated-IAL1 output reset/default parser/lowering/SystemVerilog substrate and selects `.715` for public AHB subordinate implementation.
- `docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md` — documents the `.715` shipped public `ppif/ahb_lite_subordinate.ppif` behavior, generated `.isf`/`.fsm` review artifacts, report schema, support accounting, reset/default metadata, validation, and remaining AHB residue.
- `docs/IAL2_POST_AHB_SUBORDINATE_PPIF_NEXT_SLICE_SELECTION.md` — records the `.716` no-behavior selector after AHB subordinate `.ppif` shipment and selects `.717`, public AHB subordinate `.ahb` profile-alias contract selection.
- `docs/IAL2_AHB_SUBORDINATE_PROFILE_ALIAS_CONTRACT_SELECTION.md` — records the `.717` no-behavior selector and selects `.718`, bounded public AHB subordinate `.ahb` profile-alias implementation at `ppif/ahb_lite_subordinate.ahb` with support identity `intent.ahb_profile_alias_subordinate`.
- `docs/IAL2_AHB_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.718` shipped public `ppif/ahb_lite_subordinate.ahb` profile-alias behavior, support accounting, generated review artifacts, residue movement, diagnostics, and validation.
- `docs/IAL2_POST_AHB_SUBORDINATE_ALIAS_NEXT_SLICE_SELECTION.md` — records the `.719` no-behavior selector after requester and subordinate `.ppif`/`.ahb` entrypoints shipped and selects `.720`, AHB interconnect/decode readiness audit.
- `docs/IAL2_AHB_INTERCONNECT_DECODE_READINESS_AUDIT.md` — records the `.720` no-behavior readiness audit and selects `.721`, public AHB interconnect/decode contract selection for a conservative one-requester/one-subordinate generic `.ppif` boundary.
- `docs/IAL2_AHB_INTERCONNECT_DECODE_CONTRACT_SELECTION.md` — records the `.721` no-behavior contract selection for future `ppif/ahb_interconnect.ppif`, support identity `intent.ppif_ahb_interconnect`, generated AHB interconnect review artifacts, aggregate `ahb_tb.fsm`, and `.722` substrate audit.
- `docs/IAL2_AHB_INTERCONNECT_DECODE_GENERATED_SUBSTRATE_AUDIT.md` — records the `.722` no-behavior generated-substrate audit, finds no lower-layer repair is required before the selected bounded AHB interconnect/decode implementation, and selects `.723`.
- `docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md` — documents the `.723` shipped public `ppif/ahb_interconnect.ppif` behavior, generated requester/subordinate/interconnect review artifacts, aggregate `ahb_tb.fsm`, report schema, support accounting, validation, and remaining AHB residue.
- `docs/IAL2_POST_AHB_INTERCONNECT_PPIF_NEXT_SLICE_SELECTION.md` — records the `.724` no-behavior selector after AHB interconnect `.ppif` shipment and selects `.725`, aggregate AHB `.ahb` profile-alias contract selection.
- `docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_CONTRACT_SELECTION.md` — records the `.725` no-behavior contract selection for `ppif/ahb_interconnect.ahb`, support identity `intent.ahb_profile_alias_interconnect`, generated aggregate review artifacts, and `.726` implementation owner.
- `docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.726` shipped public `ppif/ahb_interconnect.ahb` aggregate profile alias, support accounting, residue removal, generated review artifacts, and validation.
- `docs/IAL2_POST_AHB_INTERCONNECT_ALIAS_NEXT_SLICE_SELECTION.md` — records the `.727` no-behavior selector after aggregate `.ahb` alias shipment and selects `.728`, bounded multi-subordinate AHB interconnect/decode readiness audit.
- `docs/IAL2_AHB_MULTI_SUBORDINATE_DECODE_READINESS_AUDIT.md` — records the `.728` no-behavior readiness audit for bounded multi-subordinate AHB interconnect/decode and selects `.729`, public contract selection for a first bounded two-subordinate surface.
- `docs/IAL2_AHB_TWO_SUBORDINATE_CONTRACT_SELECTION.md` — records the `.729` no-behavior public contract selection for `ppif/ahb_interconnect_two_subordinate.ppif`, support identity `intent.ppif_ahb_interconnect_two_subordinate`, generated two-subordinate aggregate artifacts, and `.730` implementation owner.
- `docs/IAL2_AHB_TWO_SUBORDINATE_BEHAVIOR.md` — documents the `.730` shipped public generic `ppif/ahb_interconnect_two_subordinate.ppif` behavior, support accounting, generated review artifacts, report topology, validation, and remaining `.ahb` alias residue.
- `docs/IAL2_POST_AHB_TWO_SUBORDINATE_PPIF_NEXT_SLICE_SELECTION.md` — records the `.731` no-behavior selector and selects `.732`, matching bounded public `ppif/ahb_interconnect_two_subordinate.ahb` profile-alias implementation with support identity `intent.ahb_profile_alias_interconnect_two_subordinate`.
- `docs/IAL2_AHB_TWO_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.732` shipped public `ppif/ahb_interconnect_two_subordinate.ahb` profile alias, support accounting, generated review artifacts, residue movement, diagnostics, and validation.
- `docs/IAL2_POST_AHB_TWO_SUBORDINATE_ALIAS_NEXT_SLICE_SELECTION.md` — records the `.733` no-behavior selector after the eight-entrypoint AHB surface shipped and selects `.734`, remaining AHB residue readiness audit.
- `docs/IAL2_AHB_REMAINING_RESIDUE_READINESS_AUDIT.md` — records the `.734` no-behavior audit of remaining AHB residue and selects `.735`, first bounded AHB byte-lane/narrow-transfer readiness audit.
- `docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_READINESS_AUDIT.md` — records the `.735` no-behavior audit for first bounded AHB byte-lane/narrow-transfer readiness and selects `.736`, public contract selection for a new generic subordinate `.ppif` source.
- `docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_CONTRACT_SELECTION.md` — records the `.736` no-behavior contract selection for `ppif/ahb_lite_subordinate_byte_lane.ppif`, support identity `intent.ppif_ahb_lite_subordinate_byte_lane`, selected byte/halfword/word lane semantics, and `.737` implementation owner.
- `docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_BEHAVIOR.md` — documents the `.737` shipped public `ppif/ahb_lite_subordinate_byte_lane.ppif` behavior, generated review artifacts, support accounting, `narrow_transfer_policy` report block, byte/halfword/word lane semantics, validation, preservation of the word-only subordinate sources, and remaining AHB residue.
- `docs/IAL2_POST_AHB_BYTE_LANE_PPIF_NEXT_SLICE_SELECTION.md` — records the `.738` no-behavior selector for the matching `ppif/ahb_lite_subordinate_byte_lane.ahb` profile alias, support identity `intent.ahb_profile_alias_subordinate_byte_lane`, validation strategy, rollback, and `.739` implementation owner.
- `docs/IAL2_AHB_BYTE_LANE_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.739` shipped public `ppif/ahb_lite_subordinate_byte_lane.ahb` profile alias, generated review artifacts, support accounting, `narrow_transfer_policy` preservation, alias-residue movement, validation, and preserved word-only/generic byte-lane boundaries.
- `docs/IAL2_POST_AHB_BYTE_LANE_ALIAS_NEXT_SLICE_SELECTION.md` — records the `.740` no-behavior selector after the byte-lane `.ahb` alias shipment and selects `.741`, aggregate/interconnect byte-lane propagation readiness audit.
- `docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_READINESS_AUDIT.md` — records the `.741` no-behavior readiness audit for AHB aggregate/interconnect byte-lane propagation and selects `.742`, public contract selection for a combined bounded generic `.ppif` aggregate byte-lane family.
- `docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_CONTRACT_SELECTION.md` — records the `.742` no-behavior contract selection for `ppif/ahb_interconnect_byte_lane.ppif` and `ppif/ahb_interconnect_two_subordinate_byte_lane.ppif`, support identities, `composition.byte_lane_propagation`, and `.743` implementation owner.
- `docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_BEHAVIOR.md` — documents the `.743` shipped generic aggregate byte-lane `.ppif` behavior, generated review artifacts, support accounting, `composition.byte_lane_propagation`, child `narrow_transfer_policy` propagation, residue movement, validation, and later `.ahb` alias handoff.
- `docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_PPIF_NEXT_SLICE_SELECTION.md` — records the `.744` no-behavior selector for the matching aggregate byte-lane `.ahb` profile aliases, selected support identities, validation strategy, rollback, and `.745` implementation owner.
- `docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.745` shipped public `ppif/ahb_interconnect_byte_lane.ahb` and `ppif/ahb_interconnect_two_subordinate_byte_lane.ahb` aliases, support accounting, generated review artifacts, `composition.byte_lane_propagation` preservation, alias-residue movement, validation, and remaining AHB residue.
- `docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_ALIAS_NEXT_SLICE_SELECTION.md` — records the `.746` no-behavior selector for aggregate `.ahb` alias nested profile-alias residue cleanup and selects `.747`, public report-contract selection.
- `docs/IAL2_AHB_AGGREGATE_ALIAS_NESTED_PROFILE_RESIDUE_CONTRACT_SELECTION.md` — records the `.747` no-behavior contract selection for aggregate `.ahb` alias nested endpoint profile-residue cleanup and selects `.748`, direct report cleanup.
- `docs/IAL2_AHB_AGGREGATE_ALIAS_NESTED_PROFILE_RESIDUE_BEHAVIOR.md` — documents the `.748` shipped report-only cleanup for aggregate `.ahb` alias nested endpoint profile-residue and the preserved generic `.ppif` source-surface residue.
- `docs/IAL2_POST_AHB_AGGREGATE_ALIAS_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md` — records the `.749` no-behavior selector after aggregate alias residue cleanup and selects `.750`, bounded AHB burst `SEQ` readiness audit.
- `docs/IAL2_AHB_BURST_SEQ_READINESS_AUDIT.md` — records the `.750` no-behavior readiness audit for bounded AHB burst `SEQ` and selects `.751`, public contract selection for subordinate-side `SEQ` support.
- `docs/IAL2_AHB_BURST_SEQ_CONTRACT_SELECTION.md` — records the `.751` no-behavior public contract selection for a new generic byte-lane in-word `SEQ` subordinate source and selects `.752` implementation.
- `docs/IAL2_AHB_BYTE_LANE_SEQ_BEHAVIOR.md` — documents the `.752` shipped generic `ppif/ahb_lite_subordinate_byte_lane_seq.ppif` behavior, generated review artifacts, support accounting, `transfer.seq_policy` report block, byte/halfword in-word `SEQ` progression, preservation checks, validation, and remaining AHB residue.
- `docs/IAL2_POST_AHB_BYTE_LANE_SEQ_NEXT_SLICE_SELECTION.md` — records the `.753` no-behavior selector after the generic byte-lane in-word `SEQ` `.ppif` shipment and selects `.754`, matching `.ahb` profile-alias implementation.
- `docs/IAL2_AHB_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.754` shipped public `ppif/ahb_lite_subordinate_byte_lane_seq.ahb` profile alias, support accounting, generated review artifacts, `narrow_transfer_policy` and `transfer.seq_policy` preservation, alias-only residue cleanup, validation, and preserved generic `.ppif` source-surface residue.
- `docs/IAL2_POST_AHB_BYTE_LANE_SEQ_ALIAS_NEXT_SLICE_SELECTION.md` — records the `.755` no-behavior selector after the byte-lane in-word `SEQ` `.ahb` alias shipment and selects `.756`, aggregate byte-lane in-word `SEQ` propagation readiness audit.
- `docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_READINESS_AUDIT.md` — records the `.756` no-behavior readiness audit for bounded AHB aggregate byte-lane in-word `SEQ` propagation and selects `.757`, public contract selection for the combined generic `.ppif` aggregate family.
- `docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_CONTRACT_SELECTION.md` — records the `.757` no-behavior public contract selection for `ppif/ahb_interconnect_byte_lane_seq.ppif` and `ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif`, selected support identities, `composition.seq_policy_propagation`, residue movement, validation, rollback, and `.758` implementation owner.
- `docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_BEHAVIOR.md` — documents the `.758` shipped generic aggregate byte-lane in-word `SEQ` `.ppif` sources, generated review artifacts, support accounting, `composition.seq_policy_propagation`, child `transfer.seq_policy` propagation, residue movement, preservation checks, validation, and remaining burst/backend/protocol residue.
- `docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_PPIF_NEXT_SLICE_SELECTION.md` — records the `.759` no-behavior selector after generic aggregate byte-lane in-word `SEQ` `.ppif` shipment and selects `.760`, matching aggregate byte-lane `SEQ` `.ahb` profile-alias implementation.
- `docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.760` shipped public `ppif/ahb_interconnect_byte_lane_seq.ahb` and `ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb` aliases, support accounting, generated review artifacts, `composition.byte_lane_propagation`, `composition.seq_policy_propagation`, child `narrow_transfer_policy` and `transfer.seq_policy` preservation, alias-only residue cleanup, validation, and preserved generic `.ppif` source-surface residue.
- `docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_ALIAS_NEXT_SLICE_SELECTION.md` — records the `.761` no-behavior selector after aggregate byte-lane `SEQ` `.ahb` alias shipment and selects `.762`, HBURST-driven length/wrap readiness audit.
- `docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_READINESS_AUDIT.md` — records the `.762` no-behavior readiness audit for bounded AHB HBURST-driven length/wrap `SEQ` semantics and selects `.763`, public contract selection for a new endpoint-only HBURST-aware byte-lane `SEQ` source family.
- `docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_CONTRACT_SELECTION.md` — records the `.763` no-behavior public contract selection for `ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif`, `(burst HBURST width 3)`, `(seq-policy hburst-in-word-progressive)`, selected byte-only `WRAP4`/`INCR4` semantics, report/residue movement, validation, rollback, and `.764` implementation owner.
- `docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_BEHAVIOR.md` — documents the `.764` shipped generic `ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif` behavior, generated review artifacts, support accounting, `bindings.bus.burst`, `transfer.seq_policy.mode = hburst_in_word_progressive`, byte-only `WRAP4`/`INCR4` semantics, preservation checks, validation, and remaining alias/aggregate/burst/backend/protocol residue.
- `docs/IAL2_POST_AHB_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION.md` — records the `.765` no-behavior selector after the shipped generic AHB HBURST-aware byte-lane `SEQ` `.ppif` source and selects `.766`, direct implementation of the matching `ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb` profile alias with support identity `intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq`.
- `docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.766` shipped matching `ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb` profile alias, support accounting, alias-only residue cleanup, generated review artifacts, preservation checks, validation, and remaining aggregate/burst/backend/protocol residue.
- `docs/IAL2_POST_AHB_HBURST_SEQ_ALIAS_NEXT_SLICE_SELECTION.md` — records the `.767` no-behavior selector after the endpoint HBURST-aware `.ahb` alias shipment and selects `.768`, aggregate AHB HBURST propagation readiness audit after current aggregate candidate probes fail closed on missing subordinate-local HBURST wiring.
- `docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_READINESS_AUDIT.md` — records the `.768` no-behavior readiness audit for bounded aggregate AHB HBURST propagation and selects `.769`, public contract selection for likely `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif` sources.
- `docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_CONTRACT_SELECTION.md` — records the `.769` no-behavior public contract selection for bounded generic aggregate AHB HBURST propagation and selects `.770`, direct implementation of `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`.
- `docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md` — documents the `.770` shipped generic aggregate HBURST-aware byte-lane `SEQ` `.ppif` sources, generated review artifacts, support accounting, child HBURST fanout, `composition.seq_policy_propagation`, residue movement, preservation checks, validation, and remaining alias/burst/backend/protocol residue.
- `docs/IAL2_POST_AHB_AGGREGATE_HBURST_SEQ_PPIF_NEXT_SLICE_SELECTION.md` — records the `.770` no-behavior selector after generic aggregate HBURST-aware byte-lane `SEQ` `.ppif` shipment and selects `.771`, matching aggregate HBURST-aware `.ahb` profile-alias contract selection.
- `docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_ALIAS_CONTRACT_SELECTION.md` — records the `.771` no-behavior contract selection for the matching aggregate HBURST-aware `.ahb` profile aliases and selects `.772`, direct implementation of `ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` and `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb`.
- `docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.772` shipped matching aggregate HBURST-aware byte-lane `SEQ` `.ahb` profile aliases, support accounting, alias-only residue cleanup, generated review artifacts, preservation checks, validation, and remaining burst/backend/protocol residue.
- `docs/IAL2_POST_AHB_AGGREGATE_HBURST_ALIAS_NEXT_SLICE_SELECTION.md` — records the `.773` no-behavior selector after the aggregate HBURST-aware `.ahb` alias family and selects `.774`, a readiness audit for bounded AHB subordinate BUSY-in-burst parking (holding the in-word `SEQ` burst context across an `HTRANS = BUSY` beat rather than clearing it), the smallest next burst-`SEQ` increment on the shipped byte-only `WRAP4`/`INCR4` substrate.
- `docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_READINESS_AUDIT.md` — records the `.774` no-behavior readiness audit for AHB subordinate BUSY-in-burst parking, finds the burst machinery ready and the behavior delta bounded (stop `ahb_seq_idle_clear` from firing on BUSY), notes the shipped requester never drives `HTRANS = BUSY`, and selects `.775`, the public contract selection for the endpoint BUSY-parking source.
- `docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_CONTRACT_SELECTION.md` — records the `.775` no-behavior contract selection for the endpoint BUSY-parking source: a new additive stem `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`, the `(parked-transfer busy)` vocabulary, the `parked_transfer` parser field, IDLE-only `ahb_seq_idle_clear` firing, a `parks_on` report field, residue narrowing, and the `seq_ok_base` fail-closed path; selects `.776`, its direct implementation.
- `docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_ALIAS_CONTRACT_SELECTION.md` — records the `.777` no-behavior contract selection for the matching endpoint BUSY-park `.ahb` profile alias `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb` (support identity `intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park`, coverage `ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`, source kind `ial2_profile_alias`), proves the alias is data-only via a reserved `.ahb`-label probe that preserves the `parks_on`/`clears_on` report and drops the endpoint profile-alias residue through the existing suffix-keyed suppression, and selects `.778`, its direct implementation.
- `docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.778` shipped matching endpoint BUSY-park `.ahb` profile alias `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb`, its support accounting, byte-identical mirror, generated review artifacts, preserved `parks_on`/`clears_on` BUSY-park report, alias-only residue cleanup, `t/1495` coverage, and remaining burst/backend/protocol residue.
- Runnable `.ppif` / `.isf` / `.fsm` corpus samples are **not listed here** — this
  index covers `.md` files. The authoritative inventory is the support-accounting
  catalog `perl/FSM/Support/RegressionCorpus.pm`, mechanically proven complete by
  `prove -Iperl t/248-regression-corpus-accounting.t`, with the human-readable
  companion at `docs/REGRESSION_CORPUS.md`.
- `docs/IAL2_POST_AHB_ENDPOINT_BUSY_PARK_NEXT_SLICE_SELECTION.md` — records the `.779` no-behavior selection of `.780`, a readiness audit for bounded aggregate AHB BUSY-parking propagation: the endpoint → aggregate cadence, the endpoint residue deferring `aggregate propagation` and the aggregate residue still listing `BUSY-in-burst handling`, the bounded mechanism (the interconnect `_seq_policy_propagation_report` clones each child `seq_policy` verbatim so a `(parked-transfer busy)` child auto-forwards `parks_on = [busy]`), the audit scope, and why requester-side BUSY insertion, halfword/word burst `SEQ`, wider/indefinite bursts, and optional AHB signals are larger and deferred.
- `docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_READINESS_AUDIT.md` — records the `.780` no-behavior readiness audit: the interconnect composes child subordinate FSMs via `AhbSubordinate->generate` (`AhbInterconnect.pm:38`–`41`) and clones each child `seq_policy` verbatim (`:1177`/`:1207`), so a `(parked-transfer busy)` child parks BUSY through the shipped endpoint machinery with no interconnect generator/parser/report change and the child `seq_ok_base` fail-closed path carries through composition; the bounded delta is new aggregate stems plus residue narrowing; selects `.781`, the public contract selection for the aggregate BUSY-park source(s).
- `docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_CONTRACT_SELECTION.md` — records the `.781` no-behavior contract selection: `.782` ships both aggregate BUSY-park `.ppif` stems `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif` (support identity `intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park`, child count 3) and its two-subordinate sibling (child count 4), each a copy of the shipped aggregate HBURST `SEQ` source with the inlined child transfer `(ignored-transfer busy)` replaced by `(parked-transfer busy)`; the delta is source data plus narrowing only the aggregate HBURST residue at `AhbInterconnect.pm:1401` (no interconnect code change; the verbatim `seq_policy` clone forwards `parks_on = [busy]`), with focused `t/1496`, `t/248` moving to 295 protocol / 336 total, and the matching aggregate `.ahb` aliases deferred to a later slice.
- `docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md` — documents the `.782` shipped aggregate BUSY-park `.ppif` sources, byte-for-byte copies of the aggregate HBURST `SEQ` sources with each child transfer's `(ignored-transfer busy)` replaced by `(parked-transfer busy)`; records support accounting, the verbatim `seq_policy` clone that forwards `parks_on = [busy]`/BUSY-free `clears_on` per child with no interconnect code change, the `_all_subordinates_park_busy`-gated aggregate HBURST residue narrowing at `AhbInterconnect.pm:1401`, `t/1496` coverage, preservation checks, validation, and remaining alias/burst/backend/protocol residue.
- `docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_ALIAS_CONTRACT_SELECTION.md` — records the `.783` no-behavior contract selection for the matching aggregate BUSY-park `.ahb` profile aliases `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb` and its two-subordinate sibling (support identities `intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park`/`..._two_subordinate_..._busy_park`, coverage `..._pipeline_cli`, source kind `ial2_profile_alias`, child counts 3/4), proves the aliases are data-only via a reserved `.ahb`-label probe that keeps the aggregate topology, preserves each child `parks_on = [busy]`/BUSY-free `clears_on`, and drops the aggregate + embedded profile-alias residue through the existing suffix-keyed suppression, and selects `.784`, its direct implementation.
- `docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_PROFILE_ALIAS_BEHAVIOR.md` — documents the `.784` shipped matching aggregate BUSY-park `.ahb` profile aliases `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb` and its two-subordinate sibling, byte-identical mirrors of the generic `.ppif` sources; records support accounting (`ial2_profile_alias`, module `ahb_tb`, child counts 3/4), identical generated artifacts/HDL/`parks_on = [busy]` reports, alias-only residue cleanup through the existing suffix-keyed suppression, `t/1497` coverage, and remaining burst/backend/protocol residue.
- `docs/book/src/16-ial2-protocol-platform-intent.md` — user-facing IAL2 protocol/platform intent map with tri-mode authoring guidance and AXI/APB/AHB shipped-versus-deferred boundaries.
- `docs/book/src/16a-ial2-axi.md` — user-facing AXI IAL2 tri-mode examples with generated review artifacts, validation commands, and residue.
- `docs/book/src/16b-ial2-apb.md` — user-facing APB IAL2 tri-mode examples with `.ppif`/`.apb` alias parity, generated requester/completer/interconnect review artifacts, validation commands, and residue.
- `docs/book/src/16c-ial2-ahb.md` — user-facing AHB chapter covering shipped requester, subordinate, byte-lane `SEQ`, interconnect, aggregate byte-lane, aggregate byte-lane `SEQ` `.ppif` support, aggregate HBURST-aware byte-lane `SEQ` `.ppif` support, matching `.ahb` profile-alias support, direct `.fsm` seeds, generated review artifacts, and broader AHB residue.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct single-active dynamic write `BID` same-cycle release-and-recapture behavior under the existing dynamic write response-demux public sample.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md` — shipped single-active dynamic write `BID` same-cycle release-and-recapture under the existing dynamic write response-demux public sample.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected `.367`, public contract selection for first single-active dynamic read same-cycle release-and-recapture after dynamic write recapture shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct single-active dynamic read single-beat `RID` same-cycle release-and-recapture behavior under the existing dynamic read response-demux public sample.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md` — shipped single-active dynamic read single-beat `RID` same-cycle release-and-recapture under the existing dynamic read response-demux public sample.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for single-active dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture after single-beat read recapture shipped.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md` — audited single-active dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture readiness and selected public contract selection before behavior changes.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md` — selected direct single-active dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture behavior under the existing burst-last dynamic read response-demux public sample.
- `docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md` — shipped single-active dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture under the existing burst-last dynamic read response-demux public sample.
- `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected readiness audit for multiple all-dynamic same-cycle release-and-recapture after single-active dynamic read burst-last recapture shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_READINESS_AUDIT.md` — audited multiple all-dynamic same-cycle release-and-recapture readiness and selected generated support-detail prose alignment before broader recapture selection.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_CONTRACT_OWNER_SELECTION.md` — selected multiple all-dynamic write `BID` recapture as the first broader same-cycle recapture owner.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md` — selected direct multiple all-dynamic write `BID` same-cycle release-and-recapture under the existing multiple dynamic write response-demux public sample.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_BEHAVIOR.md` — shipped multiple all-dynamic write `BID` same-cycle release-and-recapture under the existing multiple dynamic write response-demux public sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md` — selected multiple all-dynamic read single-beat `RID` recapture contract selection after multiple dynamic write recapture shipped.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_CONTRACT_SELECTION.md` — selected direct multiple all-dynamic read single-beat `RID` same-cycle release-and-recapture under the existing multiple dynamic read response-demux public sample.
- `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR.md` — shipped multiple all-dynamic read single-beat `RID` same-cycle release-and-recapture under the existing multiple dynamic read response-demux public sample.
- `docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md` — selected first AXI-derived IAL2 implementation subset and pre-code contract.
- `docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md` — code/test/docs/report owner map for a future AXI Valid-Ready IAL2 implementation slice.
- `docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md` — first in-process AXI Valid-Ready IAL2 generator slice and report surface.
- `docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md` — first public `.ppif` parser/CLI slice for one AXI Valid-Ready source object.
- `docs/IAL2_PPIF_MULTI_VALID_READY_READINESS.md` — readiness map for future multi-channel `.ppif` Valid-Ready support.
- `docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md` — selected future aggregate bundle contract for multi-channel `.ppif` Valid-Ready support.
- `docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md` — shipped bounded multi-channel `.ppif` Valid-Ready bundle report/review-artifact behavior.
- `docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md` — shipped aggregate semantic JSON for multi-channel `.ppif` bundles.
- `docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md` — selected aggregate wrapper/top HDL entry contract for multi-channel `.ppif` bundles.
- `docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md` — shipped aggregate wrapper/top HDL entry for the tracked multi-channel `.ppif` bundle.
- `docs/PDF_EXTRACTION_WORKFLOW.md` — portable workflow for task-owned source-anchored PDF text, table, diagram, and image extraction.
- `docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md` — generic IAL2 file-surface candidates and layered lowering decision.
- `docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md` — IAL2 protocol-profile extension refinement.
- `docs/decisions/0016-ppif-is-first-public-ial2-container.md` — selects `.ppif` as the first public generic IAL2 file surface.
- `docs/decisions/0017-ppif-valid-ready-bundle-contract.md` — future multi-channel `.ppif` bundle contract decision.
- `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md` — IAL contracts and mdBook stay backend-language-neutral for future Rust, Rust/Wasm, browser-capable JavaScript, and Dart/web parity.
- `docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf` — tracked repo-local raw AXI protocol specification reference for future task-tree-owned IAL2 probes.
- `docs/vendor/accellera/systemrdl/SystemRDL_2.0_Jan2018.pdf` — tracked repo-local raw Accellera SystemRDL 2.0 reference for future task-tree-owned register/interface intent probes.
- `docs/vendor/accellera/pss/Portable_Test_Stimulus_Standard_v3.0.pdf` — tracked repo-local raw Accellera Portable Test and Stimulus 3.0 reference for future task-tree-owned portable scenario/test intent probes.
- `docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf` — tracked repo-local raw Accellera UVM 1.2 class reference for future task-tree-owned verification-integration probes.
- `docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf` — tracked repo-local raw Accellera UVM 1.2 user guide for future task-tree-owned verification-integration probes.
- `docs/FEATURE_BACKLOG.md` — repo-level pointer to the canonical mdBook backlog for deferred/not-fully-shipped user-visible features.
- `docs/VHDL_SCOPE.md` — scoped VHDL backend plan and shipped direct-root scaffold boundary.
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
- `bin/fsmgen-mcp` — read-only local JSON-RPC stdio adapter over the
  `semantic_introspection` manifest contract.
- `bin/fsmgen-issue-bundle` — downstream issue-bundle helper that captures
  reproducible FSMGen command artifacts for local triage.
- `perl/FSM/Adapter/ISF.pm` — `.isf` parser facade for intent-scheduling sources.
- `perl/FSM/Scheduler/ISF.pm` — `.isf` lowering facade that emits scheduled `.fsm` and schedule JSON reports.
- `perl/FSM/Scheduler/ISF/LoweringIR.pm` — typed lowering IR builder for `.isf` actors, transactions, drives, control flow, and spawned children.
- `perl/FSM/Scheduler/ISF/ATLGeneratedTop.pm` — private ATL generated-top helper for schedule-report projection and data-link child-interface marking.
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm` — scheduled `.fsm` emitter for `.isf` lowering results.
- `perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm` — generated `?top` emitter for ISF spawned-child parent/child handoff.
- `perl/FSM/Scheduler/ISF/Emitter/JSON.pm` — machine-readable schedule-report emitter for `.isf` lowering results.
- `perl/FSM/VerificationOutput/UVM/PassiveMonitorSkeleton.pm` — explicit verification-output builder for the inert UVM passive-monitor skeleton package and artifact manifest.
- `perl/FSM/VerificationOutput/VHDL/ObservationPackageSkeleton.pm` — explicit verification-output builder for the inert VHDL observation metadata package and artifact manifest.
- `perl/FSM/Pipeline/HDLGenerator.pm` — thin public generation facade around source/direct/composition orchestrators; accepts supported `.fsm`, `.isf`, and `.ppif` source roots.
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
- `perl/FSM/Support/LanguageSurfaceContract.pm` — bounded manifest-facing contract for the `language_surface` section's public top-level, first nested key lists, file-surface discovery keys, and per-suffix supported CLI-mode metadata.
- `perl/FSM/Support/VerificationOutputsContract.pm` — bounded manifest-facing contract for generated verification-output target discovery and artifact-manifest key families.
- `perl/FSM/Support/VerificationOutputsSection.pm` — capability-manifest `verification_outputs` section builder for the shipped UVM passive-monitor skeleton and VHDL observation package targets.
- `perl/FSM/Support/ProducerContract.pm` — bounded manifest-facing contract for the `producer` section's public identity/build metadata keys.
- `perl/FSM/Support/SemanticExportsContract.pm` — bounded manifest-facing contract for the `semantic_exports` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/SemanticIntrospectionContract.pm` — bounded manifest-facing first-class semantic-introspection contract with query domains, query families, MCP resource/tool mappings, safety policy, and public surface ownership.
- `perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` — read-only
  semantic-introspection adapter that exposes manifest-selected MCP
  resources/tools over local JSON-RPC stdio without write/generation tools.
- `perl/FSM/Support/SemanticIntrospectionSection.pm` — dedicated `semantic_introspection` manifest-section builder.
- `perl/FSM/Support/CheckDiagnostics.pm` — bounded `--check --json` report builder and stable-code classifier.
- `perl/FSM/Support/CheckDiagnosticsContract.pm` — bounded `--check --json` key-presence contract advertised through the capability manifest.
- `perl/FSM/Support/CheckFailureDiagnosticContract.pm` — shared bounded nested-object contract for failure `diagnostic` payloads in public check JSON and normalized semantic JSON.
- `perl/FSM/Support/CheckResultContract.pm` — bounded nested-object contract for successful public check JSON `result` payloads.
- `perl/FSM/Support/CompositionReportContract.pm` — bounded sanitized composition provenance/report contract for semantic JSON.
- `perl/FSM/Support/NormalizedSemanticCompositionContract.pm` — bounded nested-object contract for the `semantic.composition` summary in successful public normalized semantic JSON composition sources, including bounded `children[]`, `children[].parameter_overrides[]`, `generated_children[]`, `generated_children[].parameter_overrides[]`, `standalone_dt_children[]`, and `shared_datapath_candidates[]` shallow/alias entry key families.
- `perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm` — bounded nested-object contract for the `semantic.explicit_system_contract` summary in successful public normalized semantic JSON when that authored explicit contract is preserved.
- `perl/FSM/Support/NormalizedSemanticForwardIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.lowered_rtl_ir` summary in successful public normalized semantic JSON, including output-drive, selector-conflict, standalone-DT multi-drive, and composition-only extension key families.
- `perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.structural_rtl_ir` summary in successful public normalized semantic JSON, including bounded `assignment_records[]` structured generated-enable entries, bounded `auxiliary_assignments[]` scalar-string compatibility values, bounded `ports[]` core keys, direct input-port `targets[]` extension/entry keys, `nets[]`, generated-enable net `source`/`targets[]` connectivity entry keys, `declared_links[]`, `resolved_links[]`, shallow `instances[]`, nested `instances[].interface_ports[]`, nested `instances[].parameter_overrides[]` core plus optional raw-value/value-metadata extension keys, and nested `instances[].port_bindings[]` core plus typed-extension entry keys.
- `perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.intent_hir` summary in successful public normalized semantic JSON, including its composition-only extension keys and composition-child alias key families.
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
- `ppif/` — sample/input `.ppif` files for shipped IAL2 public surfaces.
- `t/` — regression and behavior tests.
- `t/fixtures/semantic_introspection_mcp/` — bounded read-only MCP resource/tool envelope snapshots for client compatibility.
- `scripts/check_doctrines.sh` — doctrine-enforcement driver for registered
  deterministic repo rules.
- `scripts/check_doctrine_bootstrap.sh` — doctrine adoption self-check for root
  doctrine/toolbox docs, bootstrap pointers, hook wiring, and CI wiring.
- `scripts/check_docs_relative_paths.sh` — docs path-hygiene doctrine wrapper
  over `t/1414-docs-relative-paths-audit.t`.
- `scripts/check_memory_architecture.sh` — memory-architecture doctrine check
  registered under the doctrine driver.
- `docs/` — user and technical docs.
- `generated/` — generated parser/output artifacts.
- `grammars/` — grammar definitions.
- `rust/Cargo.toml` — additive Rust experiment workspace for the backend-language portability smoke.
- `rust/fsmgen-portable-api/` — incomplete `fsmgen_portable_api` contract crate; currently supports only the `feature.direct_sreset_active_high` `.fsm` check smoke, exposes a test-only parity projection binary for that smoke, and otherwise fails closed without Perl runtime integration.

## Quick start
```bash
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen --output .artifacts/sv/trial_0.sv fsm/trial_0.fsm
./bin/fsmgen --debug=3 fsm/lte_dif_pmaster.fsm
./bin/fsmgen --verify-hdl --output .artifacts/sv/lte_dif_pmaster.sv fsm/lte_dif_pmaster.fsm
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --emit-schedule-json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --emit-verification-output uvm-passive-monitor --verification-outdir .artifacts/verification/uvm-passive-monitor isf/verification_observation_metadata.isf
./bin/fsmgen --emit-verification-output vhdl-observation-package --verification-outdir .artifacts/verification/vhdl-observation-package isf/verification_observation_metadata.isf
./bin/fsmgen --capability-manifest
perl bin/fsmgen-mcp --request-json '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

When `--output` is omitted, generated HDL is written under the git-ignored
`.artifacts/<language>/` directory, such as `.artifacts/sv/trial_0.sv` or
`.artifacts/vhd/direct_assignment_pair_form.vhd`. Use `--output` when you want
an exact repository-contained destination path. Project-owned output paths may
not escape the repository; external source inputs remain caller-authorized,
read-only inputs.
Verification-output mode is separate from HDL generation: it requires
`--verification-outdir DIR` and writes the selected artifact tree there instead
of using `.artifacts/<language>/`; `DIR` must also remain inside the repository.

For a read-only MCP client, configure the local command as
`perl /path/to/fsmgen/bin/fsmgen-mcp --workspace-root /path/to/workspace`.
For one-shot probes, use `--request-json` with JSON-RPC 2.0 requests; for
example, call `fsmgen_capability_query`, `fsmgen_support_summary`,
`fsmgen_explain_diagnostic`, `fsmgen_discover_sources`,
`fsmgen_find_examples`, `fsmgen_check`, `fsmgen_semantic_introspect`, or
`fsmgen_schedule_preview`. Source discovery supports `query`, `limit`,
`file_kind`, `source_kind`, and `classification` filters over the bounded
catalog. Source-bound calls use a workspace-relative `source_path`.

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
scripts/check_doctrines.sh
./bin/ci-regression quick
./bin/ci-regression smoke
./bin/ci-regression isf
./bin/ci-regression
./bin/ci-regression --list
```
- `scripts/check_doctrines.sh` is the fast doctrine gate used by pre-commit and
  CI; it currently runs doctrine-bootstrap, memory architecture, Knowledge
  Map, and docs path checks.
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

## Local RAM guard for heavy runs
Broad `prove`, supported-corpus, and direct `fsmgen` runs can spawn large Perl
children. Agent-launched heavyweight local commands must use the RAM guard or
an equivalent active monitor:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh --process-max-rss-mb 3072 -- ./bin/fsmgen --check-json ppif/axi_aw_valid_ready.ppif
```

The guard defaults to stopping the command tree when host memory reaches 88%
or when any descendant reaches 4096 MiB RSS. That keeps local runs below the
90% danger zone. If the guard trips, stop the broad run, record the resource
caveat in the owning task-tree leaf, and continue only with a narrower focused
check unless the user explicitly authorizes a different cap.

## CLI quick reference
```bash
./bin/fsmgen [options] <fsm_file_or_isf_file>
```
- `-o, --output <file>`: explicit output path.
- With no `--output`, generated HDL is saved under `.artifacts/<language>/`.
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
- `--emit-verification-output uvm-passive-monitor`: for `.isf` input with passive `verification_observations[]`, emit the inert UVM passive-monitor skeleton package and artifact manifest.
- `--emit-verification-output vhdl-observation-package`: for `.isf` input with passive `verification_observations[]`, emit the inert VHDL observation metadata package and artifact manifest.
- `--verification-outdir <dir>`: required destination directory for `--emit-verification-output`.
- `--verify-hdl`: after writing generated SystemVerilog, run Verilator lint and ABC-free Yosys structural synthesis; optional ABC executable discovery is reported for contract visibility but ABC is not required or run by the CLI. In-process callers can explicitly opt into ABC-backed Yosys mapping validation with `FSM::Support::HDLExternalValidation::validate_systemverilog_file(..., abc_mapping => 1)`.
- `-q, --quiet`: suppress informational output.

Inputs ending in `.isf` are parsed by the intent scheduler, lowered to one or
more explicit `.fsm` sources, and then fed through the normal `.fsm` pipeline
unless `--emit-schedule-json` or `--emit-verification-output` is requested.
For `.isf` inputs, `--check --json` and `--check-json` emit structured
`success: false` JSON for parser, lowering, report-building, and downstream
semantic check failures instead of leaving stdout empty.
For successful `.isf` and `.ppif` inputs that lower through generated `.fsm`
temporaries, public check JSON and normalized semantic JSON keep
`source.resolved_path` on the original resolved `.isf`/`.ppif` file and can
match support accounting against those public source paths. The normalized
semantic payload still describes the generated `.fsm` semantic root.

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
That payload owner now advertises `optional_child_presence_keys` for
`composition` and `symbol_contract`, and the normalized semantic report
contract republishes the same family as
`success_semantic_optional_child_presence_keys` so embedders can discover those
optional success children without inferring them from prose.
For composition sources, the nested `semantic.composition` owner also
advertises bounded `children[]`, `children[].parameter_overrides[]`,
`generated_children[]`, `generated_children[].parameter_overrides[]`, and
`standalone_dt_children[]` shallow/alias entry key families. Standalone-DT child
entries include the current reusable-DT names, enable-family metadata, module
enable-family metadata, and nested multi-drive target metadata. Each child
entry's `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries, and
the nested standalone-DT multi-drive assertion shape, remain delegated to their
existing bounded contracts:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm).
The composition-side `shared_datapath_candidates[]` collection is also
advertised there as an alias of the already bounded lowered-RTL
`composition_shared_datapath_candidates[]` candidate, contributor,
drive-intent, aggregate-enable, assertion, and bound-connection schemas instead
of duplicating those internals.
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
also has its own bounded owner for the current lowered-RTL shell, including
the bounded `output_drive_families[]` entry schema, selector-conflict target
count/list metadata, the bounded `selector_conflict_targets[]` entry schema,
standalone-DT multi-drive target metadata, the bounded
`standalone_dt_multi_drive_targets[]` entry schema and nested
`multi_drive_assertion` metadata keys, and the current composition-only
extension keys. For composition roots, that same contract also advertises the
bounded `composition_shared_datapath_candidates[]` entry schema, optional
declared-type extension keys, contributor entries and `bound_connection_expr`
metadata, contributor `drive_intent` entries plus nested drive-intent
`rhs_enable_families[]` entries, aggregate enable-family entries,
aggregate-family contributors, and multi/same-value assertion metadata.
Contributor child `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir`
summaries remain delegated to their existing bounded contracts:
[perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm).
The nested `semantic.forward_ir.structural_rtl_ir` summary inside that branch
now also has its own bounded owner for the current structural-RTL shell,
including bounded `assignment_records[]` structured generated-enable entry
keys, bounded `auxiliary_assignments[]` scalar-string compatibility values,
bounded `ports[]` core entry keys, composition-top port extension keys,
bounded `nets[]` entry keys, generated-enable net `source`/`targets[]`
connectivity entry keys, and bounded `declared_links[]` plus `resolved_links[]`
entry keys, plus bounded shallow `instances[]` entry keys, nested
`instances[].interface_ports[]` entry keys, and nested
`instances[].parameter_overrides[]` core plus optional raw-value/value-metadata
extension keys, plus nested `instances[].port_bindings[]` core plus
typed-extension entry keys:
[perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm).
Direct roots now populate `structural_rtl_ir.nets[]` with declaration-only
internal storage/helper nets projected from the backend internal declaration
plan plus generated enable wires projected from the already-prepared direct
backend enable registries and assignment analysis. Those direct net entries
preserve width, signedness, state-model, and declared-type metadata where
available. Direct generated enable assignments now live in
`structural_rtl_ir.assignment_records[]` as machine-readable continuous
assignment records with structured `lhs`, `rhs`, rendered text, and
provenance. Generated-enable net entries now also populate structured
`source` objects for assignment-record drivers and structured `targets[]`
entries for direct nets consumed by another generated-enable assignment-record
RHS. `structural_rtl_ir.auxiliary_assignments[]` mirrors those rendered lines
as scalar strings for compatibility. The direct SystemVerilog top
state/standalone-DT generated-enable condition block is now rerouted through
those `StructuralRTLIR` assignment records by an explicit backend marker
handoff that is removed before final HDL is returned. Direct input ports
consumed by generated-enable assignment-record RHS ASTs now also expose
structured `targets[]` entries on `structural_rtl_ir.ports[]` using the same
assignment-record target endpoint shape as generated-enable net targets.
Direct output ports whose names match bounded lowered output-drive families now
also expose a structured `source` summary on `structural_rtl_ir.ports[]` with
`kind`, `signal_name`, `multiplexer_type`, `driver_count`, `driver_blocks`,
`rhs_values`, `driver_enable_signals`, and `family_enable_signals`. Broader
output-drive/always-block body consumer modeling remains outside that compact
summary. Direct instance/link selector
`R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` confirms direct roots intentionally
keep `instances[]`, `declared_links[]`, and `resolved_links[]` empty; populated
instances and links remain a composition-top structural contract. Selector
`R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` confirms broader/full direct
SystemVerilog rerouting through `StructuralRTLIR` is still outside that
projection until direct behavior-body, state-update, output, and assertion
regions are structurally owned. Direct VHDL backend/reroute work remains
outside the projection and is deferred by
`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` until the SystemVerilog-backed
IAL0/IAL1/IAL2 path is feature complete.
The nested `semantic.forward_ir.intent_hir` summary inside that branch now
also has its own bounded owner for the current intent-hir shell plus the
current composition-only extension keys. For composition roots, that same owner
also advertises bounded alias key families for
`composition_children[]`, `composition_generated_children[]`, and
`composition_standalone_dt_children[]` by delegating to the already bounded
`semantic.composition` child and standalone-DT child schema owners. The
`composition_children[].parameter_overrides[]` and
`composition_generated_children[].parameter_overrides[]` alias key families are
likewise bounded and delegate to the structural instance parameter-override
schema owner. Nested child `intent_hir`, `lowered_rtl_ir`, and
`structural_rtl_ir`
summaries stay delegated to their existing bounded contracts:
[perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm).
The optional `semantic.symbol_contract` summary inside that payload now also
has its own bounded owner for symbol-rich sources:
[perl/FSM/Support/NormalizedSemanticSymbolContract.pm](perl/FSM/Support/NormalizedSemanticSymbolContract.pm).
The nested `semantic.module` summary inside that payload now also has its own
bounded owner for the core module keys plus the current optional metric-key
family:
[perl/FSM/Support/NormalizedSemanticModuleContract.pm](perl/FSM/Support/NormalizedSemanticModuleContract.pm).
The nested `semantic.composition` summary inside that payload now also has its
own bounded owner for composition sources, including bounded
`children[].parameter_overrides[]` and
`generated_children[].parameter_overrides[]` alias key families that delegate to
`semantic.forward_ir.structural_rtl_ir.instances[].parameter_overrides[]`:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm).
The generated-child public-export hardening edge now publishes
`parameter_override_count`, `parameter_overrides[]`, and bounded
parameter-override alias key families for
`semantic.composition.generated_children[]` and
`semantic.forward_ir.intent_hir.composition_generated_children[]`.
The symbol-contract constants public-export hardening edge now publishes
bounded scalar/list value key families for
`semantic.symbol_contract.constants` and
`semantic.forward_ir.intent_hir.symbol_contract.constants`. Every advertised
constant value carries `kind`; scalar values add `payload`, and list values add
`items`. That constants edge did not widen enum/type nested schemas,
package-import internals, or full normalized semantic export stabilization.
The symbol-contract enum public-export hardening edge now publishes enum
value-kind families for `semantic.symbol_contract.enums` and
`semantic.forward_ir.intent_hir.symbol_contract.enums`: enum entries are
member-payload maps, and dynamic enum members carry scalar payloads.
The symbol-contract type public-export hardening edge now publishes bounded
recursive type-entry schema metadata for `semantic.symbol_contract.types` and
`semantic.forward_ir.intent_hir.symbol_contract.types`: scalar entries carry
`kind`, `signed`, `width`, and optional `state_model`, while aggregate entries
carry recursive `items` or `members` plus `member_order`.
The symbol-contract package-import public-export hardening edge now publishes
explicit scalar package-name entry metadata for
`semantic.symbol_contract.package_imports` and
`semantic.forward_ir.intent_hir.symbol_contract.package_imports`.
`package_import_entry_value_kinds` is `[scalar_package_name]`, and
`package_import_entry_value_meaning` is `authored package-import package-name
string` on the top-level contract surface. Inside grouped
`presence_key_family_map` discovery maps, the corresponding
`*_package_import_entry_value_meaning` entries are single-element arrays
containing that same meaning string, preserving the invariant that every
grouped family-map value is array-valued. That edge does not expose raw
`FSM::Package::Spec` internals,
package source AST, package symbols, VHDL package declaration/emission, or full
normalized semantic export stabilization.
The direct VHDL scaffold now lowers generated two-state vector `bit [N:0]`
internal declarations to VHDL `std_logic_vector` signals while preserving
scalar `bit` as `std_logic`. Typed read-only direct-root two-state ports that
generate `input bit NAME` or `input bit [N:0] NAME` now lower to VHDL
`std_logic` / `std_logic_vector` input ports. Typed read-only non-signed
four-state ports that generate `input logic NAME` or
`input logic [N:0] NAME` now lower to VHDL `std_logic` /
`std_logic_vector` input ports. It also lowers generated vector `logic signed`
internal declarations to VHDL `signed` signals and generated signed vector
direct-root ports to VHDL `signed` ports. Same-width signed vector
addition/subtraction/multiplication/division/modulo RHS assignments now lower
as native signed VHDL arithmetic when the target and all operands are same-width
signed vectors, with multiplication/division/modulo target-width resized. The
scaffold also lowers signed vector numeric-literal addition/subtraction and
multiplication/division/modulo RHS assignments through target-width
`to_signed` literal conversion, with multiplication/division/modulo resized to
the target width. The direct VHDL scaffold also lowers the bounded generated
AMBA wrap arithmetic family in `fsm/amba_requester.fsm`, including
`beats_total_q * addr_step_q`, `addr_q - addr_q % (beats_total_q * addr_step_q)`,
and the matching wrap-high expression, through explicit unsigned target-width
resizes. Bounded direct aggregate-output packed-vector lowering is also shipped
for `t/corpus/direct_rhs_concat_target_autogrowth.fsm` and
`t/corpus/direct_aggregate_constant_target_autogrowth.fsm`; the maintained
supported direct-root VHDL sweep now runs clean. The first bounded composition
VHDL structural top is also shipped for the C3 external-RTL literal/concat
fixture in `t/corpus/composition_intent_integer_literals.fsm`, emitting VHDL
concurrent literal/concat assignments and an `entity work.uart_tx` port map
without SystemVerilog `module`/`assign` syntax. A second bounded composition
VHDL structural top is shipped for the C1 standalone-DT passthrough fixture in
`t/corpus/standalone_dtc_explicit_system_autowire.fsm`, emitting the VHDL child
entity plus a top-level `entity work.standalone_route_src` port map for the
explicit passthrough ports. The same bounded C1 standalone-DT family also
emits scalar integer generic maps such as `WIDTH => 16`, scalar expression
generic maps such as `EXPR_WIDTH => (8 + 1)`, and one-bit sized bitstring
generic maps such as `ENABLE_DEFAULT => '1'`, and multi-bit sized bitstring
generic maps such as `RESET_VALUE => "10100101"` before the standalone-DT
child port map; packed-list generic maps such as
`LANES => "1010010100111100"` and packed-map generic maps such as
`FRAME => "101"` also emit before that port map. The bounded C2 generated-FSM scalar-autowire top
is also shipped for `t/corpus/implicit_composition_system_autowire.fsm`, emitting
VHDL-safe generated-child shared-datapath export ports/assignments, scalar
structural signals, and both generated child entity port maps. The same
bounded C2 generated-FSM family also emits scalar integer generic maps such as
`WIDTH => 16` and scalar expression generic maps such as
`EXPR_WIDTH => (16 + 1)`, one-bit sized bitstring generic maps such as
`ENABLE_DEFAULT => '1'`, multi-bit sized bitstring generic maps such as
`RESET_VALUE => "10100101"`, and resolved packed aggregate generic maps such
as `LANES => "1010010100111100"` and `FRAME => "101"` before a generated
child port map. The bounded
APB/C4 generated-FSM top is shipped for `fsm/apb_tb.fsm`, emitting
`apb_requester` and `apb_completer` child VHDL entities, vector APB structural
signals, deterministic shared-datapath sink signals, and both child entity port
maps. The same APB/C4 family also emits scalar integer generic maps such as
`TIMEOUT_CYCLES => 8` and `TIMEOUT_CYCLES => 6`, scalar expression generic maps
such as `TIMEOUT_CYCLES => (4 + 1)` and `TIMEOUT_CYCLES => (3 + 3)`, and
one-bit sized bitstring generic maps such as `ENABLE_DEFAULT => '1'`, plus
multi-bit sized bitstring generic maps such as `RESET_VALUE => "10100101"` and
`RESET_VALUE => "00111100"`, and resolved packed aggregate generic maps such
as `LANES => "0011110010100101"` and `FRAME => "101"` before the
requester/completer child port maps. Qualified package constants in the same
APB/C4 subset are resolved before VHDL emission, so `param_pkg.TIMEOUT_8` and
`param_pkg.RESET_A5` emit `TIMEOUT_CYCLES => 8` and
`RESET_VALUE => "10100101"` without leaking package tokens.
Signed scalar division/modulo and mixed signed/unsigned scalar arithmetic
remain explicitly fail-closed; full aggregate
VHDL record/array lowering, broader generated-FSM/C4 composition VHDL beyond
the exact shipped fixtures, internal-net-heavy/bus-heavy tops beyond APB,
generic-map families outside the shipped external-RTL scalar literal/expression,
metadata-backed one-bit sized bitstring, multi-bit sized bitstring
literal/resolved-package-constant, resolved packed aggregate actuals,
standalone-DT scalar integer/expression/one-bit sized bitstring/multi-bit sized bitstring/packed-list/packed-map actuals and generated-FSM scalar
integer/expression, one-bit sized bitstring, multi-bit sized bitstring, and
resolved packed aggregate actuals, plus APB/C4 generated-FSM scalar integer,
scalar expression, one-bit sized bitstring, and multi-bit sized bitstring
actuals, resolved packed aggregate actuals, and resolved package-backed
actuals, external-RTL aggregate actuals that do not lower to one packed
literal, standalone-DT aggregate actuals that do not lower to one packed
literal, APB/C4 aggregate actuals that do not lower to one packed literal,
generated-FSM aggregate actuals that do not lower to one packed literal now
locked fail-closed before VHDL emission,
VHDL package
declaration/emission, GHDL validation, broad expression parity beyond the
shipped AMBA wrap family, package-import internals, unrelated forward-IR
payloads, and full normalized semantic export stabilization remain out of scope
until later exact leaves own them.
Package-root direct HDL generation is locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.100.1`: `?pkg` roots remain import-only
declaration containers, not standalone SystemVerilog or VHDL package output
roots.
Declared aggregate structural VHDL ports/nets/types are locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.101.1`: composition tops with declared
aggregate structural surfaces do not emit VHDL record/array declarations until a
future exact aggregate-lowering leaf owns them.
GHDL validation blocker reconfirmation is locked by
`BACKEND-API-VALIDATION-FRONTIER.102.1`: `ghdl` is unavailable in the current
environment, so external HDL validation remains SystemVerilog-only until a
future exact GHDL lane can run the tool.
Completed backend/API frontier leaf
`BACKEND-API-VALIDATION-FRONTIER.132` exhausted the active backend/API selector:
the supported-smoke `.fsm` corpus passes under `--language vhdl`, `ghdl` remains
unavailable, and remaining broad backend/API directions require future exact
owners before implementation. Completed selector leaf
`ARCHITECTURE-DEBT-FRONTIER.3` deferred ISF
parser/lowerer extraction until a stable family is proven by a future exact
owner. Completed implementation leaf
`R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2` projects top-level direct state
and standalone-DT enable wires into `structural_rtl_ir.nets[]` without
claiming DT-specific/LHS WEN/EN wires, assignment connectivity, instances,
links, auxiliary assignments, or rerouting HDL emission. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1` projects direct
DT-specific and LHS-level WEN/EN wires into `structural_rtl_ir.nets[]` as
declaration-only one-bit nets without claiming assignment connectivity,
instances, links, auxiliary assignments, or rerouting HDL emission. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.2` projects
already-rendered direct generated enable assignment lines into
`structural_rtl_ir.auxiliary_assignments[]` as scalar strings without claiming
assignment records, direct net connectivity, instances, links, or rerouting
HDL emission. Completed implementation leaf
`R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.2` projects those same generated
enable assignments into machine-readable `structural_rtl_ir.assignment_records[]`
entries while retaining `auxiliary_assignments[]` as the compatibility mirror
and without rerouting HDL emission. Completed implementation leaf
`R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2` populates generated-enable direct
net `source` objects for assignment-record drivers and `targets[]` entries for
direct nets consumed by another generated-enable assignment-record RHS.
Completed implementation leaf `R11-DIRECT-STRUCTURAL-HDL-REROUTING.2`
reroutes the direct SystemVerilog top state/standalone-DT generated-enable
condition block through `StructuralRTLIR` assignment records by using explicit
backend markers that are removed before final HDL is returned. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2`
populates direct input-port generated-enable RHS target connectivity on
`structural_rtl_ir.ports[]` without changing HDL emission. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2` populates
direct output-port `source` summaries from lowered output-drive families
without changing HDL emission. Completed selector leaf
`R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` confirms direct roots intentionally
keep empty instance/link arrays and no direct implementation leaf is warranted
today. Completed selector leaf
`R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` defers broader/full direct
SystemVerilog rerouting until direct behavior-body, state-update, output, and
assertion regions have exact structural ownership. Completed selector leaf
`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` defers direct VHDL backend/reroute
work until the SystemVerilog-backed IAL0/IAL1/IAL2 path is feature complete.
Completed
implementation leaf `ARCHITECTURE-DEBT-FRONTIER.2.1` projects direct backend
storage/helper declaration-plan entries into `structural_rtl_ir.nets[]`
without rerouting HDL emission. The shipped literal-literal positive modulo
edge lowers
an 8-bit non-signed `REM = (% 2 3)` fixture to
`REM <= std_logic_vector(resize(to_unsigned(2, 8) mod to_unsigned(3, 8), 8));`.
The shipped literal-literal positive division edge
lowers an 8-bit non-signed `QUOT = (/ 2 3)` fixture to
`QUOT <= std_logic_vector(resize(to_unsigned(2, 8) / to_unsigned(3, 8), 8));`.
The shipped literal-literal positive multiplication edge lowers an 8-bit non-signed `PROD = (* 2 3)` fixture to
`PROD <= std_logic_vector(resize(to_unsigned(2, 8) * to_unsigned(3, 8), 8));`.
The shipped literal-first positive modulo edge lowers an
8-bit non-signed `REM = (% 2 A)` fixture to
`REM <= std_logic_vector(resize(to_unsigned(2, 8) mod unsigned(A), 8));`.
The shipped literal-first positive division edge lowers
an 8-bit non-signed `QUOT = (/ 2 A)` fixture to
`QUOT <= std_logic_vector(resize(to_unsigned(2, 8) / unsigned(A), 8));`.
The shipped literal-first positive multiplication
edge lowers an 8-bit non-signed `PROD = (* 2 A)` fixture to
`PROD <= std_logic_vector(resize(to_unsigned(2, 8) * unsigned(A), 8));`.
The shipped signal-first positive
modulo edge lowers an 8-bit non-signed
`REM = (% A 2)` fixture to
`REM <= std_logic_vector(resize(unsigned(A) mod to_unsigned(2, 8), 8));`.
The shipped signal-first positive division edge lowers an 8-bit
non-signed `QUOT = (/ A 2)` fixture to
`QUOT <= std_logic_vector(resize(unsigned(A) / to_unsigned(2, 8), 8));`.
The shipped signal-first positive multiplication edge lowers an 8-bit non-signed
`PROD = (* A 2)` fixture to
`PROD <= std_logic_vector(resize(unsigned(A) * to_unsigned(2, 8), 8));`.
Broad VHDL expression-literal parity remains deferred beyond this bounded
literal-literal arithmetic subset.
The shipped non-signed negative modulo edge lowers an 8-bit
non-signed `REM = (% A -2)` fixture to
`REM <= std_logic_vector(resize(unsigned(A) mod unsigned(to_signed(-2, 8)), 8));`.
The shipped non-signed division edge
lowers an 8-bit non-signed `QUOT = (/ A -2)` fixture to
`QUOT <= std_logic_vector(resize(unsigned(A) / unsigned(to_signed(-2, 8)), 8));`.
The shipped non-signed multiplication edge
lowers an 8-bit non-signed `PROD = (* A -2)` fixture to
`PROD <= std_logic_vector(resize(unsigned(A) * unsigned(to_signed(-2, 8)), 8));`.
The shipped non-signed subtraction edge lowers an 8-bit non-signed
`DIFF = (- A -1)` fixture to
`DIFF <= std_logic_vector(unsigned(A) - unsigned(to_signed(-1, 8)));`.
Broad VHDL expression parity, aggregate, package, GHDL, composition-parity,
and normalized semantic stabilization work remain deferred until exact leaves
own them.
The manifest is still not a full normalized semantic export stabilization
promise.
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
and `embedding.serializable_generation_result_snapshot`, owned by
[perl/FSM/Support/SerializableGenerationResultSnapshot.pm](perl/FSM/Support/SerializableGenerationResultSnapshot.pm),
so callers can discover the shipped in-process runtime, facade, and report
boundaries from the manifest instead of inferring them from Perl implementation
files.
The snapshot child advertises the JSON-safe `HDLGenerator` result summary
contract directly, while the existing
`embedding.serializable_plan_reports.generation_result_snapshot_contract`
reference remains available for plan/report compatibility.
The facade child reports `default_generation_mode: flattened_debug_first` and
does not expose a public `generation_mode` constructor option; structured
non-flattened generation remains a separate backend path to implement later.
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
The manifest's `semantic_introspection` section is the first-class query
contract for AI/tooling integration:
[perl/FSM/Support/SemanticIntrospectionSection.pm](perl/FSM/Support/SemanticIntrospectionSection.pm)
publishes query domains, query families, versioning/provenance/safety policy,
contract-surface ownership, MCP adapter entrypoints, MCP resource URI
templates, and MCP tool names, while
[perl/FSM/Support/SemanticIntrospectionContract.pm](perl/FSM/Support/SemanticIntrospectionContract.pm)
owns the bounded schema advertised through
`semantic_introspection.section_contract`.
[perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm](perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm)
and [bin/fsmgen-mcp](bin/fsmgen-mcp) implement the first read-only local
JSON-RPC stdio adapter over that contract. The section reports
`mcp_adapter_implemented: true` and `write_generation_tools_enabled: false`;
source-bound responses include `adapter_provenance`, normalize workspace/repo
absolute paths to relative source identities, and redact other absolute paths.
Protocol-level JSON-RPC failures use `-32700` for parse errors, `-32600` for
invalid requests, `-32601` for unknown methods, and `-32000` for adapter call
errors. Write/generation, network, shell, mutation, commit, and push tools are
still not part of the public semantic-introspection surface. The
`fsmgen_support_summary` tool returns bounded support-accounting aggregates,
`fsmgen_discover_sources` returns catalog-backed relative source identities
without workspace traversal, `fsmgen_find_examples` includes support-summary
context, and `fsmgen_explain_diagnostic` links stable diagnostic metadata to
matching support-accounting examples.
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
authored language is frozen. The bounded `language_surface.file_surfaces`
section advertises the shipped `.fsm`/`.isf`/`.ppif` file suffixes, including
the `.ppif` bounded-public rule that IAL2 lowers through generated `.isf`
before generated `.fsm`, and publishes the supported CLI modes plus current
support/deferral boundary for each shipped suffix.
The manifest's `verification_outputs` section is the bounded discovery surface
for generated verification artifacts:
[perl/FSM/Support/VerificationOutputsSection.pm](perl/FSM/Support/VerificationOutputsSection.pm)
publishes the shipped `uvm_passive_monitor_skeleton` target, its
`uvm-passive-monitor` CLI target, `.isf` source restriction,
`uvm/<actor>_observation_uvm_pkg.sv` artifact path pattern, manifest path, and
no-UVM-compile-support validation boundary. It also publishes the shipped
`vhdl_observation_package_skeleton` target, its `vhdl-observation-package` CLI
target, `.isf` source restriction,
`vhdl/<actor>_observation_vhdl_pkg.vhd` artifact path pattern, manifest path,
and no-VHDL-compile/no-VHDL-syntax/no-PSL validation boundary, while
[perl/FSM/Support/VerificationOutputsContract.pm](perl/FSM/Support/VerificationOutputsContract.pm)
owns the bounded target, artifact-manifest, observation, signal, source, and
validation key families advertised through
`verification_outputs.section_contract`.
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
