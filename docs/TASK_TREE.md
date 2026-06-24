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

| Tree | Status | Roadmap lane | Current frontier | File |
| --- | --- | --- | --- | --- |
| `RHS-LOGIC-SIMPLIFICATION-FRONTIER` | `done` | `HDL quality / expression minimization` | complete (`.1`-`.2`; generated RHS ASTs now simplify through a shared width-safe logic-equivalence pass before HDL rendering, including boolean and width-proven vector/multi-bit bitwise expressions while preserving unsafe width-changing masks) | [docs/tasks/RHS-LOGIC-SIMPLIFICATION-FRONTIER.md](docs/tasks/RHS-LOGIC-SIMPLIFICATION-FRONTIER.md) |
| `GENERATED-HDL-ARTIFACT-PLACEMENT` | `done` | `artifact hygiene / CLI generated HDL placement` | complete (`.1`; implicit generated HDL now lands under git-ignored `.artifacts/<language>/`, explicit output paths remain exact, and prior ignored root `.sv`/`.vhd` artifacts were moved) | [docs/tasks/GENERATED-HDL-ARTIFACT-PLACEMENT.md](docs/tasks/GENERATED-HDL-ARTIFACT-PLACEMENT.md) |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER` | `active` | `IAL2 / SV-backed feature completeness` | `.424` select next AXI IAL2 slice after three-static mixed read RLAST recapture | [docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md) |
| `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE` | `done` | `Downstream ISF handoff / ISF storage metadata` | complete (`.2`; answered SPECFORGE's declarative field-structured storage request and routed implementation selection to `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1`) | [docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.md](docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.md) |
| `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER` | `done` | `R14 / ISF storage metadata` | complete (`.5`; scalar storage fields are checked, reported, documented, support-accounted, and broader behavior/layout/semantic-payload work is deferred to future exact leaves) | [docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md](docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md) |
| `DOCTRINE-ENFORCEMENT-ADOPTION` | `done` | `infra/continuity/doctrine enforcement` | complete (`.1`; adopted root doctrine enforcement, FSMGEN toolbox, doctrine driver/registry, bootstrap self-check, docs path wrapper, pre-commit wiring, and hosted CI wiring) | [docs/tasks/DOCTRINE-ENFORCEMENT-ADOPTION.md](docs/tasks/DOCTRINE-ENFORCEMENT-ADOPTION.md) |
| `AGENT-RUNTIME-RAM-GUARD` | `done` | `infra/continuity` | complete (`.1`; fail-closed wrapper now guards heavyweight agent-launched local commands at host RAM 88% / descendant RSS 4096 MiB by default) | [docs/tasks/AGENT-RUNTIME-RAM-GUARD.md](docs/tasks/AGENT-RUNTIME-RAM-GUARD.md) |
| `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR` | `done` | `CI / regression integrity` | complete (`.1`; PPIF CLI `--verify-hdl` tests now skip only external-tool-dependent checks when Verilator/Yosys are absent and still pass with tools installed) | [docs/tasks/CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.md](docs/tasks/CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.md) |
| `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER` | `active` | `Verification code generation / IAL1` | `.4` select the first SV/UVM verification output contract now that observation metadata ships | [docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md](docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md) |
| `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE` | `done` | `Downstream ISF handoff / verification-generation alignment` | complete (`.2`; answered SPECFORGE's transaction phase-membership/value/order request, kept `.isf` as the synthesizable target, and left checked phase-group metadata for a future owner) | [docs/tasks/ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.md](docs/tasks/ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.md) |
| `ISF-VERIFICATION-OBSERVATION-METADATA` | `done` | `Verification code generation / IAL1 source feature` | complete (`.1`; actor-level passive observation metadata and `verification_observations[]` schedule JSON projection shipped report-only) | [docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md](docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md) |
| `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER` | `active` | `Backend portability / public contracts` | `.2.2` audit backend-language-neutral contract and infrastructure readiness after downstream-consumer contract sync | [docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md](docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md) |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER` | `done` | `Embedding And Public APIs / AI integration` | complete (`.30`; immediate read-only semantic/MCP pass exhausted after catalog-backed source discovery; active priority returned to IAL2) | [docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md](docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md) |
| `CI-PERL-FSM-REGRESSION-JUN15-REPAIR` | `done` | `CI / regression integrity` | complete (`.1`; repaired GitHub run `27531373582` Perl regression failure cluster; full `./bin/ci-regression`, mdBook, Knowledge Map, memory, path, README, and diff gates pass) | [docs/tasks/CI-PERL-FSM-REGRESSION-JUN15-REPAIR.md](docs/tasks/CI-PERL-FSM-REGRESSION-JUN15-REPAIR.md) |
| `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE` | `done` | `R14` | complete (`.9`; simplified public contract docs from enumerated activation lists to construction rules; next executable frontier is `ISF-SCHEDULING-BACKLOG-FRONTIER.4.1`) | [docs/tasks/ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.md](docs/tasks/ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE.md) |
| `ISF-SCHEDULING-BACKLOG-FRONTIER` | `done` | `R14` | complete (`.8.2`; shipped resolved-child trigger-batch generated top; no active next leaf remains in this tree) | [docs/tasks/ISF-SCHEDULING-BACKLOG-FRONTIER.md](docs/tasks/ISF-SCHEDULING-BACKLOG-FRONTIER.md) |
| `CI-SHARED-DP-SURFACE-REPAIR` | `done` | CI/composition contract integrity | complete (`.1`; repaired reproduced GitHub run `27086344097` composition shared-datapath surface and stale contract fixture failures; focused cluster, contract tests, quick regression, mdBook, Knowledge Map, memory, path, and diff gates pass) | [docs/tasks/CI-SHARED-DP-SURFACE-REPAIR.md](docs/tasks/CI-SHARED-DP-SURFACE-REPAIR.md) |
| `COMPOSITION-T84-NET-COUNT-REPAIR` | `done` | composition/test integrity | complete (`.1`; `t/84` now proves the explicit child-to-child carrier and accepts documented `shared_dp_unused_*` sink nets; quick suite passes) | [docs/tasks/COMPOSITION-T84-NET-COUNT-REPAIR.md](docs/tasks/COMPOSITION-T84-NET-COUNT-REPAIR.md) |
| `MDBOOK-CODEBASE-SYNC-AUDIT-JUN07` | `done` | roadmap/documentation alignment | complete (`.1`; mdBook/public-contract/book-example/feature/backlog/path/memory/Knowledge Map/docs-contract/ISF gates passed; stale `t/84` composition plan-net count assertion was later repaired by `COMPOSITION-T84-NET-COUNT-REPAIR.1`) | [docs/tasks/MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.md](docs/tasks/MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.md) |
| `BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH` | `done` | bootstrap architecture maintenance | complete (`.1`; refreshed `bin/fsmgen` import-tree note to `204` total / `203` `.pm`; AXI manager capacity/status PPIF owner now reachable) | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN14-REFRESH.md) |
| `BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH` | `done` | bootstrap architecture maintenance | complete (`.1`; refreshed `bin/fsmgen` import-tree note to `206` total / `205` `.pm`, with semantic-introspection support reachability and AXI manager line-count drift) | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.md) |
| `BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH` | `done` | bootstrap architecture maintenance | complete (`.1`; refreshed stale measured line counts after dynamic transaction-ID metadata growth; topology remains `206` total / `205` `.pm`) | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.md) |
| `BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH` | `done` | bootstrap architecture maintenance | complete (`.1`; refreshed stale measured line counts after mixed dynamic/static write demux; topology remains `206` total / `205` `.pm`) | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.md) |
| `FX-UNTRACKED-LEGACY-REMOVAL` | `done` | artifact cleanup / continuity | complete (`.1`; removed unused untracked legacy `fx/` after confirming active FSMGen had no tracked files under it) | [docs/tasks/FX-UNTRACKED-LEGACY-REMOVAL.md](docs/tasks/FX-UNTRACKED-LEGACY-REMOVAL.md) |
| `BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH` | `done` | bootstrap architecture maintenance | complete (`.1`; refreshed `bin/fsmgen` import-tree note to `198` total / `197` `.pm`; VHDL backend owners now reachable; stale line counts refreshed) | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN07-REFRESH.md) |
| `DOC-PATH-RELATIVE-KNOWLEDGE-MAP` | `done` | infra/continuity | complete (`.1`; decision `0012`; guard `t/1414` now scans `docs/**/*.md` plus root `KNOWLEDGE_MAP.md`; fact card added; no absolute machine-local paths found) | [docs/tasks/DOC-PATH-RELATIVE-KNOWLEDGE-MAP.md](docs/tasks/DOC-PATH-RELATIVE-KNOWLEDGE-MAP.md) |
| `TRACE-SEVERITY-NEVER-GATED` | `done` | infra/observability | complete (`.1`–`.4`; ungated `fsm_warn`/`fsm_error`/`fsm_fatal` in `FSM::Debug`; genuine warnings/errors rerouted off the gated path, routine notes kept gated + reworded; guard `t/1415`; decision `0010`) | [docs/tasks/TRACE-SEVERITY-NEVER-GATED.md](docs/tasks/TRACE-SEVERITY-NEVER-GATED.md) |
| `ISF-TRIGGER-ANCHOR` | `done` | `R14` | complete — event `(after …)` + inline/monitor `(monitor (within S N))` + Ref `(point …)`/`(at …)`/`(on … as …)` triggers, all signal-anchored (ISF↔FSM boundary); window-source parity; **`(contract …)` removed** (closes `0008`); 7 runnable synced mdBook examples; residual "contract" wording neutralized | [docs/tasks/ISF-TRIGGER-ANCHOR.md](docs/tasks/ISF-TRIGGER-ANCHOR.md) |
| `ISF-ASSERT-CONCURRENT` | `done` | `R14` | complete (`.1`–`.2`; assert/assume/cover now lower to clocked concurrent SV properties `<kind> property (@(posedge clk) disable iff (reset) (COND))` — reset-gated, clock-edge-sampled; verified silent-during-reset/fires-on-violation) | [docs/tasks/ISF-ASSERT-CONCURRENT.md](docs/tasks/ISF-ASSERT-CONCURRENT.md) |
| `ISF-PROPERTY-IMPLICATION` | `done` | `R14` | complete (`.1`–`.3`; `(=> A B)` → `(A) \|-> (B)` simulable, `(next X)`/`(within X N)` → `##1`/`##[1:N]` formal-only under `ifdef FORMAL`; verilator-simulable vs formal split per decision 0008) | [docs/tasks/ISF-PROPERTY-IMPLICATION.md](docs/tasks/ISF-PROPERTY-IMPLICATION.md) |
| `ISF-COVER-ASSUME` | `done` | `R14` | complete (`.1`–`.2`; `(cover COND [label])` / `(assume COND [message])` — the verification-intent siblings of `(assert …)`, one kind-tagged immediate-check family; `cover (COND);` / `assume (COND) else $error(…)`) | [docs/tasks/ISF-COVER-ASSUME.md](docs/tasks/ISF-COVER-ASSUME.md) |
| `MEMORY-ARCHITECTURE-ADOPTION` | `done` | infra/continuity | complete (`.1`–`.5`; durable-agent-memory standard adopted — layers A/C + tool-neutral bootstrap + E1–E4 enforcement; `MEMORY.md` demoted 38,776 → 24 lines; gates proven to bite) | [docs/tasks/MEMORY-ARCHITECTURE-ADOPTION.md](docs/tasks/MEMORY-ARCHITECTURE-ADOPTION.md) |
| `KNOWLEDGE-MAP-ADOPT` | `done` | infra/continuity | complete (`.1`-`.3`; Knowledge Map retrieval layer adopted with question→fact index, two-gate hook + CI, seed cards; optional future decision-record folding requires a new exact leaf) | [docs/tasks/KNOWLEDGE-MAP-ADOPT.md](docs/tasks/KNOWLEDGE-MAP-ADOPT.md) |
| `BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH` | `done` | bootstrap architecture maintenance | complete (`.1`–`.2`; refreshed stale ISF import-tree line counts after the 2026-06-05 bootstrap audit; topology unchanged at `196` total / `195` `.pm`) | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN05-REFRESH.md) |
| `PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP` | `done` | roadmap maintenance | complete (`.1`; every item from the 2026-06-05 remaining-work inventory now has an existing active owner or a new broad owner tree; active focus switched to Composition/type) | [docs/tasks/PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.md](docs/tasks/PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.md) |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION` | `done` | Composition / Aggregate Types And Data | complete (`.1`-`.13`; shipped aggregate parameter/generic equality/inequality and closed remaining Composition/type backlog behind exact prerequisites; VHDL work routed to active `BACKEND-API-VALIDATION-FRONTIER`) | [docs/tasks/COMPOSITION-TYPE-BACKLOG-EXHAUSTION.md](docs/tasks/COMPOSITION-TYPE-BACKLOG-EXHAUSTION.md) |
| `ISF-ASSERT` | `done` | `R14` | complete (`.1`–`.4`; `(assert COND [message])` verification invariant → fires-on-violation SVA via a `+assert` `.fsm` carrier; keeps assert-referenced inputs alive; 13d/13k docs) | [docs/tasks/ISF-ASSERT.md](docs/tasks/ISF-ASSERT.md) |
| `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING` | `done` | `R14` | complete (`.1`–`.7` done; cross-domain blocking `(do)` via a declared activation crossing) | [docs/tasks/ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.md](docs/tasks/ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.md) |
| `ISF-NESTED-CROSS-DOMAIN-ACTIVATION` | `done` | `R14` | complete (`.1`-`.10`; blocking cross-domain `(do)` through an explicit activation crossing now ships for top-level, top-level repeat, top-level branch/loop, branch-contained repeat, nested `when` chains, and repeats under nested `when` chains; residual cross-domain `spawn`/payload/auto-crossing and prerequisite-bound repeat-contained branch/nested switch/while/until work require new owner leaves) | [docs/tasks/ISF-NESTED-CROSS-DOMAIN-ACTIVATION.md](docs/tasks/ISF-NESTED-CROSS-DOMAIN-ACTIVATION.md) |
| `ISF-LOOP-EARLY-EXIT` | `done` | `R14` | complete (`.1`-`.5`; `(exit-when cond)` exits a `while`/`until` loop directly or from a nested `when`; `loop_early_exits[]` reports `exit_when`/`continue_when` sites; docs/examples consolidation audited in sync) | [docs/tasks/ISF-LOOP-EARLY-EXIT.md](docs/tasks/ISF-LOOP-EARLY-EXIT.md) |
| `ISF-PROPERTY-SAMPLED-VALUE` | `done` | `R14` | complete (`.1`-`.3`; `(stable/changed/rose/fell SIG)` → `$stable/$changed/$rose/$fell(SIG)` in `assert/assume/cover` shipped as verilator-simulable property leaves; value-returning `(past SIG [N])` explicitly deferred behind expression-level property composition) | [docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md](docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md) |
| `ISF-PROPERTY-WINDOW-RANGE` | `done` | `R14` | complete (`.1`–`.2`) — `(within B MIN MAX)` → `##[MIN:MAX]` bounded window (`min > 1`, literal `1 <= MIN <= MAX`; formal-only; `t/1418`); closes the second SPECFORGE temporal delta | [docs/tasks/ISF-PROPERTY-WINDOW-RANGE.md](docs/tasks/ISF-PROPERTY-WINDOW-RANGE.md) |
| `ISF-REGISTER-RESET-VALUES` | `done` | `R14` | `closed (.1–.5; (reset V) on (local …) and (storage (var …)) → register/CSR powers up at V; .fsm carrier + ISF surface + register maps + runnable book example; verilator-clean; unspecified → all-0s)` | [docs/tasks/ISF-REGISTER-RESET-VALUES.md](docs/tasks/ISF-REGISTER-RESET-VALUES.md) |
| `ISF-FOR-LOOP` | `done` | `R14` | `closed (.1–.7; indexed counted loop — count, explicit-width/variable-count, range, strided step, nested, and embedded-in-control-flow via index hoisting; all simulated)` | [docs/tasks/ISF-FOR-LOOP.md](docs/tasks/ISF-FOR-LOOP.md) |
| `ISF-COMPOUND-ASSIGN` | `done` | `R14` | complete (`.1`–`.2`; `(incr/decr NAME [by N])` compound-assignment sugar — parser desugar to `(set NAME (± NAME N))`, N default 1; malformed forms fail closed; 13e documented) | [docs/tasks/ISF-COMPOUND-ASSIGN.md](docs/tasks/ISF-COMPOUND-ASSIGN.md) |
| `ISF-COND` | `done` | `R14` | `closed (.1–.2; (cond …) if/else-if/else priority chain — parser desugar to a negated-guard when-chain; first true branch wins; simulation-confirmed)` | [docs/tasks/ISF-COND.md](docs/tasks/ISF-COND.md) |
| `ISF-NESTED-COUNTED-REPEAT` | `done` | `R14` | `closed (.1–.2; nested counted (repeat M (repeat N body)) with per-instance counters — body runs M*N times; simulated + --verify-hdl clean; substrate for nested for-loops)` | [docs/tasks/ISF-NESTED-COUNTED-REPEAT.md](docs/tasks/ISF-NESTED-COUNTED-REPEAT.md) |
| `ISF-COUNTED-REPEAT-TERMINATION` | `done` | `R14` | complete (`.1`–`.4`; check-first lowering terminates exactly-N for static/runtime/zero; `(!=0)` decision edge passes `--verify-hdl`; leading runtime waits in repeat bodies now reload/enter/zero-bypass from `repeat_check`) | [docs/tasks/ISF-COUNTED-REPEAT-TERMINATION.md](docs/tasks/ISF-COUNTED-REPEAT-TERMINATION.md) |
| `ISF-REMAINING-BROAD-FRONTIER` | `done` | `R14` | complete (`.1`-`.12`; broad remaining ISF/R14 frontier exhausted: ATL/IAL2/parity/resource/priority/port/temporal/report/CDC/full-width surfaces either shipped, synced, or deferred to future exact owners) | [docs/tasks/ISF-REMAINING-BROAD-FRONTIER.md](docs/tasks/ISF-REMAINING-BROAD-FRONTIER.md) |
| `BACKEND-API-VALIDATION-FRONTIER` | `done` | Backends And Validation / Embedding And Public APIs | complete through `BACKEND-API-VALIDATION-FRONTIER.132`; all supported-smoke `.fsm` entries pass under `--language vhdl`, GHDL remains unavailable, and broad backend/API work is behind future exact owners | [docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md](docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md) |
| `ARCHITECTURE-DEBT-FRONTIER` | `done` | architecture | complete through `.3`; direct structural internal declaration nets shipped in `.2.1`, and ISF parser/lowerer extraction remains deferred until a stable family is proven by a future exact owner | [docs/tasks/ARCHITECTURE-DEBT-FRONTIER.md](docs/tasks/ARCHITECTURE-DEBT-FRONTIER.md) |
| `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION` | `done` | architecture backlog | complete (`.2`; extracted private ATL generated-top report projection and child-interface marking helpers without behavior drift; no active next leaf remains in this tree) | [docs/tasks/ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.md](docs/tasks/ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.md) |
| `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION` | `done` | IAL2 horizon exploration | complete (`.2`; wrote the first non-code protocol/platform intent evaluation note and selected no IAL2 source/lowering implementation; no active next leaf remains in this tree) | [docs/tasks/IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.md](docs/tasks/IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.md) |
| `AXI-SPEC-LOCAL-REFERENCE-IMPORT` | `done` | IAL2 horizon exploration | complete (`.1`; copied and documented the provided AXI spec PDF reference artifact; no active next leaf remains in this tree) | [docs/tasks/AXI-SPEC-LOCAL-REFERENCE-IMPORT.md](docs/tasks/AXI-SPEC-LOCAL-REFERENCE-IMPORT.md) |
| `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT` | `done` | standards reference artifacts | complete (`.1`; copied and documented provided Accellera SystemRDL, PSS, and UVM PDF standards as tracked references, plus ignored local-only UVM 1.2 and SystemVerilog LRM Markdown mirrors) | [docs/tasks/ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.md](docs/tasks/ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.md) |
| `AXI-VALID-READY-INTENT-PROBE` | `done` | IAL2 horizon exploration | complete (`.2`; recorded the first AXI Valid-Ready source-anchor evidence inventory, with no parser/lowering implementation selected) | [docs/tasks/AXI-VALID-READY-INTENT-PROBE.md](docs/tasks/AXI-VALID-READY-INTENT-PROBE.md) |
| `AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE` | `done` | IAL2 horizon exploration | complete (`.1`; captured the AXI manager Easy/Power/supervised Raw IAL2 user-facing API direction, with no implementation selected) | [docs/tasks/AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.md](docs/tasks/AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.md) |
| `IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE` | `done` | IAL2 horizon exploration | complete (`.1`; recorded protocol/platform-generic IAL2 surface candidates and forbids direct IAL2-to-IAL0 lowering) | [docs/tasks/IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE.md](docs/tasks/IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE.md) |
| `IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE` | `done` | IAL2 horizon exploration | complete (`.1`; refined IAL2 file-surface guidance so protocol-specific extensions may be future vocabulary/profile aliases, not separate layers) | [docs/tasks/IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE.md](docs/tasks/IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE.md) |
| `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE` | `done` | IAL2 horizon exploration | complete (`.1`; recorded the first AXI ID/order/concurrency source-anchor evidence inventory, with no parser/lowering/HDL implementation selected) | [docs/tasks/AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.md](docs/tasks/AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.md) |
| `AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE` | `done` | IAL2 horizon exploration | complete (`.1`; classified captured AXI evidence into a first future manager rule matrix, with no implementation selected) | [docs/tasks/AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE.md](docs/tasks/AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE.md) |
| `PDF-EXTRACTION-WORKFLOW-CAPTURE` | `done` | documentation / workflow portability | complete (`.1`; wrote and tracked the portable PDF extraction workflow, including future flow-update policy) | [docs/tasks/PDF-EXTRACTION-WORKFLOW-CAPTURE.md](docs/tasks/PDF-EXTRACTION-WORKFLOW-CAPTURE.md) |
| `AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION` | `done` | IAL2 horizon exploration | complete (`.1`; selected the AXI Valid-Ready channel contract/monitor as the first AXI-derived IAL2 implementation subset and pre-code contract) | [docs/tasks/AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION.md](docs/tasks/AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION.md) |
| `AXI-IAL2-VALID-READY-READINESS-AUDIT` | `done` | IAL2 horizon exploration | complete (`.1`; mapped code/test/docs/report owners and safe first implementation boundaries before behavior changes) | [docs/tasks/AXI-IAL2-VALID-READY-READINESS-AUDIT.md](docs/tasks/AXI-IAL2-VALID-READY-READINESS-AUDIT.md) |
| `AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE` | `done` | IAL2 horizon exploration | complete (`.1`; added the in-process AXI Valid-Ready generator, report, tests, and docs without public CLI suffix support) | [docs/tasks/AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.md](docs/tasks/AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.md) |
| `IAL2-PUBLIC-PPIF-SURFACE-SELECTION` | `done` | IAL2 horizon exploration | complete (`.1`; selected `.ppif` as the generic public IAL2 file surface and recorded the first Valid-Ready syntax boundary before parser/CLI code) | [docs/tasks/IAL2-PUBLIC-PPIF-SURFACE-SELECTION.md](docs/tasks/IAL2-PUBLIC-PPIF-SURFACE-SELECTION.md) |
| `IAL2-PPIF-PARSER-CLI-FIRST-SLICE` | `done` | IAL2 horizon exploration | complete (`.1`; added the first public `.ppif` parser/CLI path for one Valid-Ready contract, preserving `.ppif -> generated .isf -> generated .fsm`) | [docs/tasks/IAL2-PPIF-PARSER-CLI-FIRST-SLICE.md](docs/tasks/IAL2-PPIF-PARSER-CLI-FIRST-SLICE.md) |
| `IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE` | `done` | IAL2 horizon exploration | complete (`.1`; added and validated the first tracked runnable `.ppif` sample fixture) | [docs/tasks/IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE.md](docs/tasks/IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE.md) |
| `IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST` | `done` | IAL2 horizon exploration | complete (`.1`; advertised shipped `.fsm`/`.isf`/`.ppif` file surfaces in the capability manifest) | [docs/tasks/IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST.md](docs/tasks/IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST.md) |
| `CHECK-JSON-PUBLIC-SOURCE-IDENTITY` | `done` | Embedding And Public APIs | complete (`.1`; preserved check JSON source identity and support-accounting coverage for lowered `.isf`/`.ppif` public inputs) | [docs/tasks/CHECK-JSON-PUBLIC-SOURCE-IDENTITY.md](docs/tasks/CHECK-JSON-PUBLIC-SOURCE-IDENTITY.md) |
| `NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY` | `done` | Embedding And Public APIs | complete (`.1`; preserved normalized semantic JSON source identity and support-accounting coverage for lowered `.isf`/`.ppif` public inputs) | [docs/tasks/NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY.md](docs/tasks/NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY.md) |
| `PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE` | `done` | IAL2 horizon exploration / Embedding And Public APIs | complete (`.1`; locked focused PPIF semantic JSON source-identity coverage) | [docs/tasks/PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE.md](docs/tasks/PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE.md) |
| `PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE` | `done` | IAL2 horizon exploration / Embedding And Public APIs | complete (`.1`; documented `.ppif --emit-semantic-json` usage) | [docs/tasks/PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE.md](docs/tasks/PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE.md) |
| `PPIF-SOURCE-INTENT-NAME-REPORT` | `done` | IAL2 horizon exploration | complete (`.1`; preserved `.ppif` top-level intent name in reports) | [docs/tasks/PPIF-SOURCE-INTENT-NAME-REPORT.md](docs/tasks/PPIF-SOURCE-INTENT-NAME-REPORT.md) |
| `LANGUAGE-SURFACE-FILE-CLI-MODES` | `done` | Embedding And Public APIs | complete (`.1`; advertised supported CLI modes per shipped file suffix) | [docs/tasks/LANGUAGE-SURFACE-FILE-CLI-MODES.md](docs/tasks/LANGUAGE-SURFACE-FILE-CLI-MODES.md) |
| `PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC` | `done` | IAL2 horizon exploration / mdBook truth sync | complete (`.1`; synced feature-backlog IAL2 section with `.ppif` manifest CLI-mode metadata) | [docs/tasks/PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC.md](docs/tasks/PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC.md) |
| `IAL2-PPIF-MULTI-VALID-READY-READINESS` | `done` | IAL2 horizon exploration | complete (`.1`; mapped current single-object `.ppif` assumptions and the required aggregate contract before any future multi-channel parser/generator behavior change) | [docs/tasks/IAL2-PPIF-MULTI-VALID-READY-READINESS.md](docs/tasks/IAL2-PPIF-MULTI-VALID-READY-READINESS.md) |
| `IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION` | `done` | IAL2 horizon exploration | complete (`.1`; selected the future multi Valid-Ready `.ppif` aggregate bundle source/report/artifact/CLI contract before behavior changes) | [docs/tasks/IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.md](docs/tasks/IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.md) |
| `IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE` | `done` | IAL2 horizon exploration | complete (`.1`; shipped bounded multi-channel `.ppif` bundle report/review-artifact behavior; later semantic JSON and HDL-entry leaves extended the bundle) | [docs/tasks/IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.md](docs/tasks/IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.md) |
| `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE` | `done` | IAL2 horizon exploration / Embedding And Public APIs | complete (`.1`; shipped aggregate bundle semantic JSON without choosing one generated channel `.fsm` as the root) | [docs/tasks/IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.md](docs/tasks/IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.md) |
| `IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION` | `done` | IAL2 horizon exploration | complete (`.1`; selected aggregate wrapper/top as the HDL entry contract and rejected first-channel root selection) | [docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.md](docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.md) |
| `IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE` | `done` | IAL2 horizon exploration | complete (`.1`; shipped aggregate wrapper/top `.fsm` entry, default SystemVerilog generation, and `--verify-hdl` for the tracked AW/W PPIF bundle sample) | [docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.md](docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.md) |
| `TASK-TREE-STALE-STATUS-DRIFT-REPAIR` | `done` | `infra/continuity` | complete (`.1`; normalized stale active/pending/proposed markers in completed task-tree files so exhausted PNT recovery is unambiguous) | [docs/tasks/TASK-TREE-STALE-STATUS-DRIFT-REPAIR.md](docs/tasks/TASK-TREE-STALE-STATUS-DRIFT-REPAIR.md) |
| `TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR` | `done` | `infra/continuity` | complete (`.1`; normalized the stale hyphenated `in-progress` marker in completed `ISF-TRIGGER-ANCHOR` metadata and hardened the status-drift fact recheck) | [docs/tasks/TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR.md](docs/tasks/TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR.md) |
| `BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH` | `done` | bootstrap architecture maintenance | complete (`.1`; refreshed stale live `bin/fsmgen` import-tree counts, PPIF/IAL2 reachability, and measured line-count drift after protocol-intent bundle growth) | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN12-REFRESH.md) |
| `R11-DIRECT-BACKEND-COORDINATION-FRONTIER` | `done` | `R11` | complete (`.2`; projected top-level direct state/standalone-DT enable wires into direct `StructuralRTLIR` nets without rerouting HDL emission) | [docs/tasks/R11-DIRECT-BACKEND-COORDINATION-FRONTIER.md](docs/tasks/R11-DIRECT-BACKEND-COORDINATION-FRONTIER.md) |
| `NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT` | `done` | `Embedding And Public APIs / IAL2` | complete (`.1`; repaired stale optional-child contract test expectations for already-shipped `semantic.protocol_intent_bundle`) | [docs/tasks/NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT.md](docs/tasks/NORMALIZED-SEMANTIC-PROTOCOL-BUNDLE-CONTRACT-DRIFT.md) |
| `R11-DIRECT-STRUCTURAL-WEN-EN-NETS` | `done` | `R11` | complete (`.1`; projected direct DT-specific and LHS-level WEN/EN wires into `StructuralRTLIR` nets without claiming assignment connectivity) | [docs/tasks/R11-DIRECT-STRUCTURAL-WEN-EN-NETS.md](docs/tasks/R11-DIRECT-STRUCTURAL-WEN-EN-NETS.md) |
| `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS` | `done` | `R11` | complete (`.2`; projected already-rendered direct generated enable assignment lines into `StructuralRTLIR.auxiliary_assignments[]` without changing HDL emission) | [docs/tasks/R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.md](docs/tasks/R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.md) |
| `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS` | `done` | `R11` | complete (`.2`; projected direct generated enable assignments into machine-readable `StructuralRTLIR.assignment_records[]` while retaining scalar auxiliary compatibility) | [docs/tasks/R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.md](docs/tasks/R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.md) |
| `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY` | `done` | `R11` | complete (`.2`; populated generated-enable assignment-record source/target connectivity on direct `StructuralRTLIR.nets[]` without changing HDL emission) | [docs/tasks/R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.md](docs/tasks/R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.md) |
| `R11-DIRECT-STRUCTURAL-HDL-REROUTING` | `done` | `R11` | complete (`.2`; rerouted direct SystemVerilog top state/standalone-DT generated-enable condition emission through `StructuralRTLIR` without full direct module reroute) | [docs/tasks/R11-DIRECT-STRUCTURAL-HDL-REROUTING.md](docs/tasks/R11-DIRECT-STRUCTURAL-HDL-REROUTING.md) |
| `R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE` | `done` | `R11` | complete (`.1`; created exact proposed owners for remaining roadmap-named direct `StructuralRTLIR` gaps before any further implementation) | [docs/tasks/R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE.md](docs/tasks/R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE.md) |
| `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY` | `done` | `R11` | complete (`.2`; populated direct input-port generated-enable RHS target connectivity on `StructuralRTLIR.ports[]`) | [docs/tasks/R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.md](docs/tasks/R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.md) |
| `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS` | `done` | `R11` | complete (`.2`; populated direct output-port source summaries from lowered output-drive families) | [docs/tasks/R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.md](docs/tasks/R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.md) |
| `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS` | `done` | `R11` | complete (`.1`; selected an empty direct-root instance/link contract and left populated instances/links with composition-top structural IR) | [docs/tasks/R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.md](docs/tasks/R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.md) |
| `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING` | `deferred` | `R11` | deferred (`.1`; no broader direct SystemVerilog reroute is safe until direct behavior-body structural prerequisites exist) | [docs/tasks/R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.md](docs/tasks/R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.md) |
| `R11-DIRECT-STRUCTURAL-VHDL-REROUTING` | `deferred` | `R11` | deferred (`.1`; no VHDL backend/reroute target selection before SV-backed IAL0/IAL1/IAL2 feature completeness) | [docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md](docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md) |

## Proposed Task Trees

Proposed trees record accepted backlog direction, but they are not
PNT-eligible until explicitly activated or until the roadmap selects that lane.

| Tree | Status | Roadmap lane | Proposed first leaf | File |
| --- | --- | --- | --- | --- |

## Completed Task Trees

| Tree | Status | Roadmap lane | Completed frontier | File |
| --- | --- | --- | --- | --- |
| `ISF-LOOP-CONTINUE` | `done` | `R14` | `closed (.1–.3; (continue-when cond) skip-to-next-iteration in while/until + when-in-loop; companion to (exit-when))` | [docs/tasks/ISF-LOOP-CONTINUE.md](docs/tasks/ISF-LOOP-CONTINUE.md) |
| `ISF-LOCAL-VARIABLES` | `done` | `R14` | `closed (.1–.5; (local NAME (width N) [(default V)/(init V)]) declared internal registers + (let NAME EXPR) named intermediates; dedicated 13m chapter)` | [docs/tasks/ISF-LOCAL-VARIABLES.md](docs/tasks/ISF-LOCAL-VARIABLES.md) |
| `ISF-PROCEDURES` | `done` | `R14` | `closed (.1–.5; reusable (proc) callable inline (call N a) or handshake (call N a as INST), value-in + write-back-out params; dedicated 13l chapter)` | [docs/tasks/ISF-PROCEDURES.md](docs/tasks/ISF-PROCEDURES.md) |
| `ISF-CONDITIONAL-CHILD-ACTIVATION` | `done` | `R14` | `closed (.1–.7 done; conditional child activation complete: (do) local/bound/generated + (spawn) + await_all/await_any drains lower across top-level, repeat, and all four when/switch/while/until bodies)` | [docs/tasks/ISF-CONDITIONAL-CHILD-ACTIVATION.md](docs/tasks/ISF-CONDITIONAL-CHILD-ACTIVATION.md) |
| `ROADMAP-TASKTREE-MDBOOK-ALIGNMENT-AUDIT` | `done` | `R0` | `closed (doctrine fully implemented; tri-surface alignment verified, zero drift)` | [docs/tasks/ROADMAP-TASKTREE-MDBOOK-ALIGNMENT-AUDIT.md](docs/tasks/ROADMAP-TASKTREE-MDBOOK-ALIGNMENT-AUDIT.md) |
| `ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC` | `done` | `R14` | `closed (do/spawn clause-context limitation + rationale documented in 13d/13b)` | [docs/tasks/ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC.md](docs/tasks/ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC.md) |
| `ISF-FULL-WIDTH-INFERENCE` | `done` | `R14` | `closed (fail-closed terminal recorded)` | [docs/tasks/ISF-FULL-WIDTH-INFERENCE.md](docs/tasks/ISF-FULL-WIDTH-INFERENCE.md) |
| `ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES` | `done` | `R14` | `closed` | [docs/tasks/ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES.md](docs/tasks/ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES.md) |
| `ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING` | `done` | `R14` | `closed` | [docs/tasks/ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING.md](docs/tasks/ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING.md) |
| `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING` | `done` | `R14` | `closed` | [docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.md](docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.md) |
| `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING` | `done` | `R14` | `closed` | [docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.md](docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.md) |
| `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING` | `done` | `R14` | `closed` | [docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.md](docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.md) |
| `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING` | `done` | `R14` | `closed` | [docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.md](docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.md) |
| `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING` | `done` | `R14` | `closed` | [docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.md](docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.md) |
| `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.md](docs/tasks/ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.md) |
| `R14-ASPECT-COVERAGE-AUDIT` | `done` | `R14` | `closed` | [docs/tasks/R14-ASPECT-COVERAGE-AUDIT.md](docs/tasks/R14-ASPECT-COVERAGE-AUDIT.md) |
| `BOOK-COOKBOOK-COMPOSITION-RUNNABLE` | `done` | `R14` | `closed` | [docs/tasks/BOOK-COOKBOOK-COMPOSITION-RUNNABLE.md](docs/tasks/BOOK-COOKBOOK-COMPOSITION-RUNNABLE.md) |
| `BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS` | `done` | `R14` | `closed` | [docs/tasks/BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.md](docs/tasks/BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.md) |
| `CI-CORPUS-SYSTEM-INCOMPLETE-SECTION-FIX` | `done` | CI maintenance | `closed` | [docs/tasks/CI-CORPUS-SYSTEM-INCOMPLETE-SECTION-FIX.md](docs/tasks/CI-CORPUS-SYSTEM-INCOMPLETE-SECTION-FIX.md) |
| `ISF-G8-HEADING-DENSITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-G8-HEADING-DENSITY.md](docs/tasks/ISF-G8-HEADING-DENSITY.md) |
| `ISF-G4-BACKLOG-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-G4-BACKLOG-TRUTH-SYNC.md](docs/tasks/ISF-G4-BACKLOG-TRUTH-SYNC.md) |
| `ISF-G2-LOW-DENSITY-EXAMPLES` | `done` | `R14` | `closed` | [docs/tasks/ISF-G2-LOW-DENSITY-EXAMPLES.md](docs/tasks/ISF-G2-LOW-DENSITY-EXAMPLES.md) |
| `ISF-G5-13-INTENT-EXAMPLES` | `done` | `R14` | `closed` | [docs/tasks/ISF-G5-13-INTENT-EXAMPLES.md](docs/tasks/ISF-G5-13-INTENT-EXAMPLES.md) |
| `ISF-G6-13J-EXAMPLES` | `done` | `R14` | `closed` | [docs/tasks/ISF-G6-13J-EXAMPLES.md](docs/tasks/ISF-G6-13J-EXAMPLES.md) |
| `ISF-G7-13D-ACCEPT-PATH-EXAMPLES` | `done` | `R14` | `closed` | [docs/tasks/ISF-G7-13D-ACCEPT-PATH-EXAMPLES.md](docs/tasks/ISF-G7-13D-ACCEPT-PATH-EXAMPLES.md) |
| `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.md](docs/tasks/ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.md) |
| `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE` | `done` | `R14` | `closed` | [docs/tasks/ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.md](docs/tasks/ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.md) |
| `ISF-DIAGNOSTIC-EXAMPLES-G3` | `done` | `R14` | `closed` | [docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-G3.md](docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-G3.md) |
| `ISF-COOKBOOK-WALKTHROUGHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-COOKBOOK-WALKTHROUGHS.md](docs/tasks/ISF-COOKBOOK-WALKTHROUGHS.md) |
| `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX` | `done` | `R14` | `closed` | [docs/tasks/ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.md](docs/tasks/ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.md) |
| `ISF-COOKBOOK-RECIPES-G1` | `done` | `R14` | `closed` | [docs/tasks/ISF-COOKBOOK-RECIPES-G1.md](docs/tasks/ISF-COOKBOOK-RECIPES-G1.md) |
| `ISF-MDBOOK-COVERAGE-AUDIT` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-COVERAGE-AUDIT.md](docs/tasks/ISF-MDBOOK-COVERAGE-AUDIT.md) |
| `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.md](docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.md) |
| `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.md](docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.md) |
| `BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH` | `done` | `R14` | `closed` | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.md) |
| `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION` | `done` | `R14` | `closed` | [docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md](docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md) |
| `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION` | `done` | `R14` | `closed` | [docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md](docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md) |
| `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION` | `done` | `R14` | `closed` | [docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.md](docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.md) |
| `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION` | `done` | `R14` | `closed` | [docs/tasks/ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.md](docs/tasks/ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.md) |
| `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.md](docs/tasks/ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.md) |
| `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.md](docs/tasks/ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.md) |
| `ISF-REPEAT-GENDO-DOMAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-DOMAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-GENDO-DOMAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md) |
| `ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md) |
| `ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md) |
| `ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md) |
| `ISF-REPEAT-LOCALDO-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-LOCALDO-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-LOCALDO-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md) |
| `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md) |
| `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md) |
| `ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md) |
| `ISF-REPEAT-GENDO-PARAM-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PARAM-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-GENDO-PARAM-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md) |
| `ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md) |
| `ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.md](docs/tasks/ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.md) |
| `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md](docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md) |
| `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-DOMAIN-SECOND-AWAITANY-REFRESH` | `done` | `bootstrap architecture maintenance` | `closed` | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-DOMAIN-SECOND-AWAITANY-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-DOMAIN-SECOND-AWAITANY-REFRESH.md) |
| `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md](docs/tasks/ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md) |
| `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-BOUND-SECOND-AWAITANY-REFRESH` | `done` | `bootstrap architecture maintenance` | `closed` | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-BOUND-SECOND-AWAITANY-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-BOUND-SECOND-AWAITANY-REFRESH.md) |
| `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md](docs/tasks/ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md) |
| `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md](docs/tasks/ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md) |
| `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH` | `done` | `bootstrap architecture maintenance` | `closed` | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.md) |
| `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md](docs/tasks/ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md) |
| `BIN-FSMGEN-IMPORT-TREE-R14-REPEAT-REFRESH` | `done` | `bootstrap architecture maintenance` | `closed` | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-REPEAT-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-REPEAT-REFRESH.md) |
| `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md](docs/tasks/ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md) |
| `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.md](docs/tasks/ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.md) |
| `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.md](docs/tasks/ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.md) |
| `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-AFTER-DO` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-AFTER-DO.md](docs/tasks/ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-AFTER-DO.md) |
| `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.md](docs/tasks/ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.md) |
| `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.md](docs/tasks/ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.md) |
| `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.md](docs/tasks/ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.md) |
| `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.md](docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.md) |
| `ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO-POST-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO-POST-AWAITANY.md](docs/tasks/ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO-POST-AWAITANY.md) |
| `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-POST-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-POST-AWAITANY.md](docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-POST-AWAITANY.md) |
| `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO-POST-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO-POST-AWAITANY.md](docs/tasks/ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO-POST-AWAITANY.md) |
| `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.md](docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.md) |
| `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.md](docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.md) |
| `ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO.md](docs/tasks/ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO.md) |
| `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO.md](docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO.md) |
| `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO.md](docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO.md) |
| `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.md](docs/tasks/ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.md) |
| `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.md](docs/tasks/ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.md) |
| `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.md](docs/tasks/ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.md) |
| `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH` | `done` | `bootstrap architecture maintenance` | `closed` | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.md) |
| `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE` | `done` | `R14` | `closed` | [docs/tasks/ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.md](docs/tasks/ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.md) |
| `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE` | `done` | `R14` | `closed` | [docs/tasks/ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.md](docs/tasks/ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.md) |
| `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH` | `done` | `bootstrap architecture maintenance` | `closed` | [docs/tasks/BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.md](docs/tasks/BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.md) |
| `ROADMAP-R14-REPEAT-ZERO-STATUS-TRUTH-SYNC` | `done` | `R14 roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-R14-REPEAT-ZERO-STATUS-TRUTH-SYNC.md](docs/tasks/ROADMAP-R14-REPEAT-ZERO-STATUS-TRUTH-SYNC.md) |
| `ISF-STATIC-ZERO-REPEAT-NOOP` | `done` | `R14` | `closed` | [docs/tasks/ISF-STATIC-ZERO-REPEAT-NOOP.md](docs/tasks/ISF-STATIC-ZERO-REPEAT-NOOP.md) |
| `NO-RESET-SCHEDULED-FSM-HDL` | `done` | `R14` | `closed` | [docs/tasks/NO-RESET-SCHEDULED-FSM-HDL.md](docs/tasks/NO-RESET-SCHEDULED-FSM-HDL.md) |
| `ISF-CDC-NO-RESET-FIXTURE` | `done` | `R14` | `closed` | [docs/tasks/ISF-CDC-NO-RESET-FIXTURE.md](docs/tasks/ISF-CDC-NO-RESET-FIXTURE.md) |
| `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.md](docs/tasks/ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.md) |
| `ISF-SCHEDULE-REPORT-STORAGE-ROLES` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-STORAGE-ROLES.md](docs/tasks/ISF-SCHEDULE-REPORT-STORAGE-ROLES.md) |
| `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.md](docs/tasks/ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.md) |
| `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES` | `done` | `R14` | `closed` | [docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.md](docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.md) |
| `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.md](docs/tasks/ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.md) |
| `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS` | `done` | `R14` | `closed` | [docs/tasks/ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.md](docs/tasks/ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.md) |
| `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS` | `done` | `R14` | `closed` | [docs/tasks/ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.md](docs/tasks/ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.md) |
| `ISF-WAIT-TRANSACTION-PARAM-COUNTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-WAIT-TRANSACTION-PARAM-COUNTS.md](docs/tasks/ISF-WAIT-TRANSACTION-PARAM-COUNTS.md) |
| `ISF-REPEAT-TRANSACTION-PARAM-COUNTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNTS.md](docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNTS.md) |
| `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC` | `done` | `R14 roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.md](docs/tasks/ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.md) |
| `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.md](docs/tasks/ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.md) |
| `ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC` | `done` | `R14 roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC.md](docs/tasks/ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC.md) |
| `ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC` | `done` | `R14 roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC.md](docs/tasks/ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC.md) |
| `ISF-DIRECT-ON-PARAM-DIAGNOSTIC` | `done` | `R14` | `closed` | [docs/tasks/ISF-DIRECT-ON-PARAM-DIAGNOSTIC.md](docs/tasks/ISF-DIRECT-ON-PARAM-DIAGNOSTIC.md) |
| `ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC` | `done` | `R14 roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.md](docs/tasks/ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.md) |
| `ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.md](docs/tasks/ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.md) |
| `ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.md](docs/tasks/ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.md) |
| `ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.md](docs/tasks/ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.md) |
| `ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.md](docs/tasks/ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.md) |
| `ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.md](docs/tasks/ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.md) |
| `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.md](docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.md) |
| `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.md](docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.md) |
| `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.md](docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.md) |
| `ROADMAP-R14-LATEST-SLICE-TRUTH-SYNC` | `done` | `R14 roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-R14-LATEST-SLICE-TRUTH-SYNC.md](docs/tasks/ROADMAP-R14-LATEST-SLICE-TRUTH-SYNC.md) |
| `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.md](docs/tasks/ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.md) |
| `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.md](docs/tasks/ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.md) |
| `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.md](docs/tasks/ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.md) |
| `CI-STRICT-WIRING-DIAGNOSTIC-REPAIR` | `done` | `project operations` | `closed` | [docs/tasks/CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.md](docs/tasks/CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.md) |
| `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC` | `done` | `roadmap maintenance` | `closed` | [docs/tasks/TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.md](docs/tasks/TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.md) |
| `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC` | `done` | `roadmap maintenance` | `closed` | [docs/tasks/TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.md](docs/tasks/TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.md) |
| `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.md](docs/tasks/ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.md) |
| `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.md](docs/tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.md) |
| `ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC` | `done` | `R14 roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.md](docs/tasks/ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.md) |
| `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.md](docs/tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.md) |
| `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.md](docs/tasks/ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.md) |
| `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.md](docs/tasks/ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.md) |
| `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS` | `done` | `R14` | `closed` | [docs/tasks/ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.md](docs/tasks/ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.md) |
| `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.md](docs/tasks/ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.md) |
| `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS` | `done` | `R14` | `closed` | [docs/tasks/ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.md](docs/tasks/ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.md) |
| `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.md](docs/tasks/ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.md) |
| `ISF-WAIT-PACKAGE-CONSTANT-COUNTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-WAIT-PACKAGE-CONSTANT-COUNTS.md](docs/tasks/ISF-WAIT-PACKAGE-CONSTANT-COUNTS.md) |
| `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.md](docs/tasks/ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.md) |
| `ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.md](docs/tasks/ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.md) |
| `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.md](docs/tasks/ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.md) |
| `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.md](docs/tasks/ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.md) |
| `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.md](docs/tasks/ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.md) |
| `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.md](docs/tasks/ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.md) |
| `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.md](docs/tasks/ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.md) |
| `ISF-LIBRARY-USE-PACKAGE-CONSTANTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-LIBRARY-USE-PACKAGE-CONSTANTS.md](docs/tasks/ISF-LIBRARY-USE-PACKAGE-CONSTANTS.md) |
| `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.md](docs/tasks/ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.md) |
| `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.md](docs/tasks/ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.md) |
| `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.md](docs/tasks/ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.md) |
| `ROADMAP-CURRENT-ACTIVE-LANE-TRUTH-SYNC` | `done` | `roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-CURRENT-ACTIVE-LANE-TRUTH-SYNC.md](docs/tasks/ROADMAP-CURRENT-ACTIVE-LANE-TRUTH-SYNC.md) |
| `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.md](docs/tasks/ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.md) |
| `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.md](docs/tasks/ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.md) |
| `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.md](docs/tasks/ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.md) |
| `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.md](docs/tasks/ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.md) |
| `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES` | `done` | `R14` | `closed` | [docs/tasks/ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.md](docs/tasks/ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.md) |
| `ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.md](docs/tasks/ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.md) |
| `ISF-ACTIVATION-PARAM-ACTOR-PARAMS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTIVATION-PARAM-ACTOR-PARAMS.md](docs/tasks/ISF-ACTIVATION-PARAM-ACTOR-PARAMS.md) |
| `ROADMAP-ACTIVE-LANE-LATEST-SLICE-SYNC` | `done` | `roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-ACTIVE-LANE-LATEST-SLICE-SYNC.md](docs/tasks/ROADMAP-ACTIVE-LANE-LATEST-SLICE-SYNC.md) |
| `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.md](docs/tasks/ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.md) |
| `ISF-STORAGE-PORT-ROUND-ROBIN` | `done` | `R14` | `closed` | [docs/tasks/ISF-STORAGE-PORT-ROUND-ROBIN.md](docs/tasks/ISF-STORAGE-PORT-ROUND-ROBIN.md) |
| `ISF-OUTPUT-BUNDLE-ROUND-ROBIN` | `done` | `R14` | `closed` | [docs/tasks/ISF-OUTPUT-BUNDLE-ROUND-ROBIN.md](docs/tasks/ISF-OUTPUT-BUNDLE-ROUND-ROBIN.md) |
| `ISF-TRANSACTION-START-ROUND-ROBIN` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-START-ROUND-ROBIN.md](docs/tasks/ISF-TRANSACTION-START-ROUND-ROBIN.md) |
| `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT` | `done` | `R11` | `closed` | [docs/tasks/R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.md](docs/tasks/R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.md) |
| `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT` | `done` | `R11` | `closed` | [docs/tasks/R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.md](docs/tasks/R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.md) |
| `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT` | `done` | `R11` | `closed` | [docs/tasks/R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.md](docs/tasks/R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.md) |
| `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT` | `done` | `R11` | `closed` | [docs/tasks/R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.md](docs/tasks/R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.md) |
| `R11-PARAMETER-GENERIC-FRONTIER-AUDIT` | `done` | `R11` | `closed` | [docs/tasks/R11-PARAMETER-GENERIC-FRONTIER-AUDIT.md](docs/tasks/R11-PARAMETER-GENERIC-FRONTIER-AUDIT.md) |
| `R11-RTLIF-INTERFACE-SOURCE-DIRECTION` | `done` | `R11` | `closed` | [docs/tasks/R11-RTLIF-INTERFACE-SOURCE-DIRECTION.md](docs/tasks/R11-RTLIF-INTERFACE-SOURCE-DIRECTION.md) |
| `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT` | `done` | `R11` | `closed` | [docs/tasks/R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.md](docs/tasks/R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.md) |
| `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT` | `done` | `R10` | `closed` | [docs/tasks/R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.md](docs/tasks/R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.md) |
| `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP` | `done` | `R10` | `closed` | [docs/tasks/R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.md](docs/tasks/R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.md) |
| `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP` | `done` | `R10` | `closed` | [docs/tasks/R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.md](docs/tasks/R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.md) |
| `R10-CLI-QUIET-BANNER-CLEANUP` | `done` | `R10` | `closed` | [docs/tasks/R10-CLI-QUIET-BANNER-CLEANUP.md](docs/tasks/R10-CLI-QUIET-BANNER-CLEANUP.md) |
| `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT` | `done` | `R10` | `closed` | [docs/tasks/R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.md](docs/tasks/R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.md) |
| `R9-STRICT-MODE-FRONTIER-AUDIT` | `done` | `R9` | `closed` | [docs/tasks/R9-STRICT-MODE-FRONTIER-AUDIT.md](docs/tasks/R9-STRICT-MODE-FRONTIER-AUDIT.md) |
| `R8-LANGUAGE-CONTRACT-EXIT-AUDIT` | `done` | `R8` | `closed` | [docs/tasks/R8-LANGUAGE-CONTRACT-EXIT-AUDIT.md](docs/tasks/R8-LANGUAGE-CONTRACT-EXIT-AUDIT.md) |
| `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT` | `done` | `R8` | `closed` | [docs/tasks/R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.md](docs/tasks/R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.md) |
| `R8-STRICT-SUPPORT-TIER-CUTS` | `done` | `R8` | `closed` | [docs/tasks/R8-STRICT-SUPPORT-TIER-CUTS.md](docs/tasks/R8-STRICT-SUPPORT-TIER-CUTS.md) |
| `RICHER-AGGREGATE-OPERATORS` | `done` | `aggregate types and data` | `closed` | [docs/tasks/RICHER-AGGREGATE-OPERATORS.md](docs/tasks/RICHER-AGGREGATE-OPERATORS.md) |
| `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING` | `done` | `aggregate types and data` | `closed` | [docs/tasks/BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.md](docs/tasks/BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.md) |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE` | `done` | `aggregate types and data` | `closed` | [docs/tasks/AGGREGATE-AUTOGROWTH-FROM-USAGE.md](docs/tasks/AGGREGATE-AUTOGROWTH-FROM-USAGE.md) |
| `DYNAMIC-DIVISOR-SAFETY-FRONTIER` | `done` | `language ergonomics` | `closed` | [docs/tasks/DYNAMIC-DIVISOR-SAFETY-FRONTIER.md](docs/tasks/DYNAMIC-DIVISOR-SAFETY-FRONTIER.md) |
| `INFERENCE-FIRST-SCALAR-AUTHORING` | `done` | `language ergonomics` | `closed` | [docs/tasks/INFERENCE-FIRST-SCALAR-AUTHORING.md](docs/tasks/INFERENCE-FIRST-SCALAR-AUTHORING.md) |
| `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC` | `done` | `roadmap maintenance` | `closed` | [docs/tasks/FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.md](docs/tasks/FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.md) |
| `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION` | `done` | `R14` | `closed` | [docs/tasks/ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.md](docs/tasks/ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.md) |
| `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.md](docs/tasks/ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.md) |
| `CI-FEATURE-BACKLOG-STATUS-AUDIT` | `done` | `project operations` | `closed` | [docs/tasks/CI-FEATURE-BACKLOG-STATUS-AUDIT.md](docs/tasks/CI-FEATURE-BACKLOG-STATUS-AUDIT.md) |
| `ISF-STORAGE-PORT-RESOURCE-PRIORITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-STORAGE-PORT-RESOURCE-PRIORITY.md](docs/tasks/ISF-STORAGE-PORT-RESOURCE-PRIORITY.md) |
| `ISF-TRANSACTION-START-RESOURCE-PRIORITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-START-RESOURCE-PRIORITY.md](docs/tasks/ISF-TRANSACTION-START-RESOURCE-PRIORITY.md) |
| `ROADMAP-R14-OUTPUT-BUNDLE-WORDING-CLEANUP` | `done` | `R14 roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-R14-OUTPUT-BUNDLE-WORDING-CLEANUP.md](docs/tasks/ROADMAP-R14-OUTPUT-BUNDLE-WORDING-CLEANUP.md) |
| `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS` | `done` | `R14` | `closed` | [docs/tasks/ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.md](docs/tasks/ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.md) |
| `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC` | `done` | `R14 documentation truth sync` | `closed` | [docs/tasks/ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.md](docs/tasks/ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.md) |
| `ISF-OUTPUT-BUNDLE-MEMBER-LIST` | `done` | `R14` | `closed` | [docs/tasks/ISF-OUTPUT-BUNDLE-MEMBER-LIST.md](docs/tasks/ISF-OUTPUT-BUNDLE-MEMBER-LIST.md) |
| `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.md](docs/tasks/ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.md) |
| `ISF-TRANSACTION-OVER-RULE-PRIORITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-OVER-RULE-PRIORITY.md](docs/tasks/ISF-TRANSACTION-OVER-RULE-PRIORITY.md) |
| `ISF-ASSEMBLE-STATIC-PART-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ASSEMBLE-STATIC-PART-WIDTHS.md](docs/tasks/ISF-ASSEMBLE-STATIC-PART-WIDTHS.md) |
| `ISF-DATA-OP-STATIC-WIDTH-SOURCES` | `done` | `R14` | `closed` | [docs/tasks/ISF-DATA-OP-STATIC-WIDTH-SOURCES.md](docs/tasks/ISF-DATA-OP-STATIC-WIDTH-SOURCES.md) |
| `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.md](docs/tasks/ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.md) |
| `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.md](docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.md) |
| `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.md](docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.md) |
| `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.md](docs/tasks/ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.md) |
| `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.md](docs/tasks/ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.md) |
| `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.md](docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.md) |
| `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.md](docs/tasks/ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.md) |
| `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.md](docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.md) |
| `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.md](docs/tasks/ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.md) |
| `ISF-INTERFACE-ACTOR-PARAM-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-INTERFACE-ACTOR-PARAM-WIDTHS.md](docs/tasks/ISF-INTERFACE-ACTOR-PARAM-WIDTHS.md) |
| `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.md](docs/tasks/ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.md) |
| `ISF-REPEAT-ACTOR-PARAM-COUNTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-ACTOR-PARAM-COUNTS.md](docs/tasks/ISF-REPEAT-ACTOR-PARAM-COUNTS.md) |
| `ISF-WATCHDOG-ACTOR-PARAM-LIMITS` | `done` | `R14` | `closed` | [docs/tasks/ISF-WATCHDOG-ACTOR-PARAM-LIMITS.md](docs/tasks/ISF-WATCHDOG-ACTOR-PARAM-LIMITS.md) |
| `ISF-CONTRACT-ACTOR-PARAM-WINDOWS` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONTRACT-ACTOR-PARAM-WINDOWS.md](docs/tasks/ISF-CONTRACT-ACTOR-PARAM-WINDOWS.md) |
| `ISF-LATENCY-ACTOR-PARAM-BOUNDS` | `done` | `R14` | `closed` | [docs/tasks/ISF-LATENCY-ACTOR-PARAM-BOUNDS.md](docs/tasks/ISF-LATENCY-ACTOR-PARAM-BOUNDS.md) |
| `ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC` | `done` | `R14 roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.md](docs/tasks/ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.md) |
| `ISF-ATL-FRONTIER-TRUTH-SYNC` | `done` | `R14 roadmap maintenance` | `closed` | [docs/tasks/ISF-ATL-FRONTIER-TRUTH-SYNC.md](docs/tasks/ISF-ATL-FRONTIER-TRUTH-SYNC.md) |
| `ISF-DYNAMIC-DIVISOR-CONTROL-BANK-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-DIVISOR-CONTROL-BANK-COVERAGE.md](docs/tasks/ISF-DYNAMIC-DIVISOR-CONTROL-BANK-COVERAGE.md) |
| `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.md](docs/tasks/ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.md) |
| `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.md](docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.md) |
| `ISF-BACKLOG-OWNER-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-BACKLOG-OWNER-TRUTH-SYNC.md](docs/tasks/ISF-BACKLOG-OWNER-TRUTH-SYNC.md) |
| `ISF-REPEAT-COUNT-SOURCE-BOUNDARY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-COUNT-SOURCE-BOUNDARY.md](docs/tasks/ISF-REPEAT-COUNT-SOURCE-BOUNDARY.md) |
| `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.md](docs/tasks/ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.md) |
| `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.md](docs/tasks/ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.md) |
| `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.md](docs/tasks/ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.md) |
| `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS` | `done` | `R14` | `closed` | [docs/tasks/ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.md](docs/tasks/ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.md) |
| `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS` | `done` | `R14` | `closed` | [docs/tasks/ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.md](docs/tasks/ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.md) |
| `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.md](docs/tasks/ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.md) |
| `ISF-ATL-COMPACT-INSTANCE-ALIAS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-COMPACT-INSTANCE-ALIAS.md](docs/tasks/ISF-ATL-COMPACT-INSTANCE-ALIAS.md) |
| `ISF-ATL-COMPACT-GROUP-ALIAS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-COMPACT-GROUP-ALIAS.md](docs/tasks/ISF-ATL-COMPACT-GROUP-ALIAS.md) |
| `ISF-ATL-MULTI-EVENT-WAIT` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-MULTI-EVENT-WAIT.md](docs/tasks/ISF-ATL-MULTI-EVENT-WAIT.md) |
| `ISF-ATL-PIN-MIXED-ROUTE-SETS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-PIN-MIXED-ROUTE-SETS.md](docs/tasks/ISF-ATL-PIN-MIXED-ROUTE-SETS.md) |
| `ISF-ATL-PIN-VECTOR-MULTI-ROUTE` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-PIN-VECTOR-MULTI-ROUTE.md](docs/tasks/ISF-ATL-PIN-VECTOR-MULTI-ROUTE.md) |
| `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.md](docs/tasks/ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.md) |
| `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.md](docs/tasks/ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.md) |
| `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.md](docs/tasks/ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.md) |
| `ISF-ATL-PIN-EGRESS-MULTI-ROUTE` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-PIN-EGRESS-MULTI-ROUTE.md](docs/tasks/ISF-ATL-PIN-EGRESS-MULTI-ROUTE.md) |
| `ISF-ATL-PIN-INGRESS-MULTI-ROUTE` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-PIN-INGRESS-MULTI-ROUTE.md](docs/tasks/ISF-ATL-PIN-INGRESS-MULTI-ROUTE.md) |
| `ROADMAP-R14-FRONTIER-TRUTH-SYNC` | `done` | `roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-R14-FRONTIER-TRUTH-SYNC.md](docs/tasks/ROADMAP-R14-FRONTIER-TRUTH-SYNC.md) |
| `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.md](docs/tasks/ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.md) |
| `ROADMAP-ACTIVE-LANE-TRUTH-SYNC` | `done` | `roadmap maintenance` | `closed` | [docs/tasks/ROADMAP-ACTIVE-LANE-TRUTH-SYNC.md](docs/tasks/ROADMAP-ACTIVE-LANE-TRUTH-SYNC.md) |
| `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.md](docs/tasks/R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.md) |
| `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.md](docs/tasks/R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.md) |
| `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.md](docs/tasks/R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.md) |
| `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.md](docs/tasks/R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.md) |
| `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.md](docs/tasks/R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.md) |
| `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.md](docs/tasks/R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.md) |
| `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.md](docs/tasks/R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.md) |
| `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.md](docs/tasks/R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.md) |
| `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.md](docs/tasks/R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.md) |
| `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.md](docs/tasks/R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.md) |
| `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.md](docs/tasks/R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.md) |
| `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.md](docs/tasks/R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.md) |
| `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.md](docs/tasks/R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.md) |
| `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.md](docs/tasks/R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.md) |
| `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.md](docs/tasks/R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.md) |
| `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.md](docs/tasks/R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.md) |
| `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.md](docs/tasks/R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.md) |
| `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.md](docs/tasks/R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.md) |
| `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.md](docs/tasks/R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.md) |
| `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.md](docs/tasks/R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.md) |
| `R12-RESET-STATE-ALIAS-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-RESET-STATE-ALIAS-CORPUS-WIDENING.md](docs/tasks/R12-RESET-STATE-ALIAS-CORPUS-WIDENING.md) |
| `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.md](docs/tasks/R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.md) |
| `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.md](docs/tasks/R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.md) |
| `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.md](docs/tasks/R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.md) |
| `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.md](docs/tasks/R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.md) |
| `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.md](docs/tasks/R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.md) |
| `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.md](docs/tasks/R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.md) |
| `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.md](docs/tasks/R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.md) |
| `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.md](docs/tasks/R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.md) |
| `R12-GUARD-SHORTHAND-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-GUARD-SHORTHAND-CORPUS-WIDENING.md](docs/tasks/R12-GUARD-SHORTHAND-CORPUS-WIDENING.md) |
| `R12-STATE-DTE-GUARD-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-STATE-DTE-GUARD-CORPUS-WIDENING.md](docs/tasks/R12-STATE-DTE-GUARD-CORPUS-WIDENING.md) |
| `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.md](docs/tasks/R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.md) |
| `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.md](docs/tasks/R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.md) |
| `R12-TOP-LEVEL-FORM-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-TOP-LEVEL-FORM-CORPUS-WIDENING.md](docs/tasks/R12-TOP-LEVEL-FORM-CORPUS-WIDENING.md) |
| `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.md](docs/tasks/R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.md) |
| `R12-PLUS-FSM-BODY-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-PLUS-FSM-BODY-CORPUS-WIDENING.md](docs/tasks/R12-PLUS-FSM-BODY-CORPUS-WIDENING.md) |
| `R12-SYMBOL-TOKEN-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-SYMBOL-TOKEN-CORPUS-WIDENING.md](docs/tasks/R12-SYMBOL-TOKEN-CORPUS-WIDENING.md) |
| `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.md](docs/tasks/R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.md) |
| `R12-PARAM-DEPENDENCY-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-PARAM-DEPENDENCY-CORPUS-WIDENING.md](docs/tasks/R12-PARAM-DEPENDENCY-CORPUS-WIDENING.md) |
| `R12-SYMBOL-VALUE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-SYMBOL-VALUE-CORPUS-WIDENING.md](docs/tasks/R12-SYMBOL-VALUE-CORPUS-WIDENING.md) |
| `R12-SYMBOL-ENTRY-MALFORMED-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-SYMBOL-ENTRY-MALFORMED-CORPUS-WIDENING.md](docs/tasks/R12-SYMBOL-ENTRY-MALFORMED-CORPUS-WIDENING.md) |
| `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.md](docs/tasks/R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.md) |
| `R12-INIT-DIRECTIVE-SHAPE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-INIT-DIRECTIVE-SHAPE-CORPUS-WIDENING.md](docs/tasks/R12-INIT-DIRECTIVE-SHAPE-CORPUS-WIDENING.md) |
| `R12-CONDITION-EXPRESSION-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-CONDITION-EXPRESSION-CORPUS-WIDENING.md](docs/tasks/R12-CONDITION-EXPRESSION-CORPUS-WIDENING.md) |
| `R12-RHS-EXPRESSION-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-RHS-EXPRESSION-CORPUS-WIDENING.md](docs/tasks/R12-RHS-EXPRESSION-CORPUS-WIDENING.md) |
| `R12-FSM-ROOT-BODY-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-FSM-ROOT-BODY-CORPUS-WIDENING.md](docs/tasks/R12-FSM-ROOT-BODY-CORPUS-WIDENING.md) |
| `R12-STATE-BODY-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-STATE-BODY-CORPUS-WIDENING.md](docs/tasks/R12-STATE-BODY-CORPUS-WIDENING.md) |
| `R12-UPDATE-SHORTHAND-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-UPDATE-SHORTHAND-CORPUS-WIDENING.md](docs/tasks/R12-UPDATE-SHORTHAND-CORPUS-WIDENING.md) |
| `R12-INLINE-MODIFIER-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-INLINE-MODIFIER-CORPUS-WIDENING.md](docs/tasks/R12-INLINE-MODIFIER-CORPUS-WIDENING.md) |
| `R12-TEST-SELECTOR-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-TEST-SELECTOR-CORPUS-WIDENING.md](docs/tasks/R12-TEST-SELECTOR-CORPUS-WIDENING.md) |
| `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.md](docs/tasks/R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.md) |
| `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.md](docs/tasks/R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.md) |
| `R12-NAME-REFERENCE-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-NAME-REFERENCE-CORPUS-WIDENING.md](docs/tasks/R12-NAME-REFERENCE-CORPUS-WIDENING.md) |
| `R12-SYSTEM-SECTION-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-SYSTEM-SECTION-CORPUS-WIDENING.md](docs/tasks/R12-SYSTEM-SECTION-CORPUS-WIDENING.md) |
| `R12-MALFORMED-FORM-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-MALFORMED-FORM-CORPUS-WIDENING.md](docs/tasks/R12-MALFORMED-FORM-CORPUS-WIDENING.md) |
| `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING` | `done` | `R12` | `closed` | [docs/tasks/R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.md](docs/tasks/R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.md) |
| `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY` | `done` | `R9` | `closed` | [docs/tasks/R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.md](docs/tasks/R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.md) |
| `R8-PARTIAL-LHS-PULSE-BOUNDARY` | `done` | `R8` | `closed` | [docs/tasks/R8-PARTIAL-LHS-PULSE-BOUNDARY.md](docs/tasks/R8-PARTIAL-LHS-PULSE-BOUNDARY.md) |
| `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT` | `done` | `R8` | `closed` | [docs/tasks/R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.md](docs/tasks/R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.md) |
| `MODULE-INFO-PROJECTION-GUARD` | `done` | `architecture backlog` | `closed` | [docs/tasks/MODULE-INFO-PROJECTION-GUARD.md](docs/tasks/MODULE-INFO-PROJECTION-GUARD.md) |
| `ISF-LOWERINGIR-BOUNDARY-EXTRACTION` | `done` | `architecture backlog` | `closed` | [docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md](docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md) |
| `GLOBAL-AST-MANAGER-BOUNDARY` | `done` | `architecture backlog` | `closed` | [docs/tasks/GLOBAL-AST-MANAGER-BOUNDARY.md](docs/tasks/GLOBAL-AST-MANAGER-BOUNDARY.md) |
| `EXPR-NAMER-LEGACY-PARSE-BOUNDARY` | `done` | `architecture backlog` | `closed` | [docs/tasks/EXPR-NAMER-LEGACY-PARSE-BOUNDARY.md](docs/tasks/EXPR-NAMER-LEGACY-PARSE-BOUNDARY.md) |
| `EXPR-AST-UTILS-OWNER-CONSOLIDATION` | `done` | `architecture backlog` | `closed` | [docs/tasks/EXPR-AST-UTILS-OWNER-CONSOLIDATION.md](docs/tasks/EXPR-AST-UTILS-OWNER-CONSOLIDATION.md) |
| `EXPR-NAMER-TRACKED-COPY-CLEANUP` | `done` | `architecture backlog` | `closed` | [docs/tasks/EXPR-NAMER-TRACKED-COPY-CLEANUP.md](docs/tasks/EXPR-NAMER-TRACKED-COPY-CLEANUP.md) |
| `IR-EXPRESSION-AST-OWNERSHIP` | `done` | `architecture backlog` | `closed` | [docs/tasks/IR-EXPRESSION-AST-OWNERSHIP.md](docs/tasks/IR-EXPRESSION-AST-OWNERSHIP.md) |
| `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE` | `done` | `architecture backlog` | `closed` | [docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md](docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md) |
| `FSMGEN-IR-AUDIT` | `done` | `architecture backlog` | `closed` | [docs/tasks/FSMGEN-IR-AUDIT.md](docs/tasks/FSMGEN-IR-AUDIT.md) |
| `ISF-ATL-DOC-STATUS-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-ATL-DOC-STATUS-TRUTH-SYNC.md](docs/tasks/ISF-ATL-DOC-STATUS-TRUTH-SYNC.md) |
| `ISF-ACTOR-NETWORK-ORCHESTRATION` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md](docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md) |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md](docs/tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md) |
| `ISF-TIMING-CONVENTIONS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TIMING-CONVENTIONS.md](docs/tasks/ISF-TIMING-CONVENTIONS.md) |
| `MDBOOK-PARAGRAPH-SPACING` | `done` | `project documentation` | `closed` | [docs/tasks/MDBOOK-PARAGRAPH-SPACING.md](docs/tasks/MDBOOK-PARAGRAPH-SPACING.md) |
| `CI-HOSTED-ISF-REGRESSION-CASCADE` | `done` | `project operations` | `closed` | [docs/tasks/CI-HOSTED-ISF-REGRESSION-CASCADE.md](docs/tasks/CI-HOSTED-ISF-REGRESSION-CASCADE.md) |
| `CI-FULL-REGRESSION-GREEN` | `done` | `project operations` | `closed` | [docs/tasks/CI-FULL-REGRESSION-GREEN.md](docs/tasks/CI-FULL-REGRESSION-GREEN.md) |
| `CI-PERL-532-REGRESSION-COMPAT` | `done` | `project operations` | `closed` | [docs/tasks/CI-PERL-532-REGRESSION-COMPAT.md](docs/tasks/CI-PERL-532-REGRESSION-COMPAT.md) |
| `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS` | `done` | `R14` | `closed` | [docs/tasks/ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.md](docs/tasks/ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.md) |
| `GITHUB-PUBLIC-AUTOMATION-REENABLE` | `done` | `project operations` | `closed` | [docs/tasks/GITHUB-PUBLIC-AUTOMATION-REENABLE.md](docs/tasks/GITHUB-PUBLIC-AUTOMATION-REENABLE.md) |
| `ISF-REPEAT-SPAWN-PARAMS` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md](docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md) |
| `ISF-SPAWN-IN-REPEAT` | `done` | `R14` | `closed` | [docs/tasks/ISF-SPAWN-IN-REPEAT.md](docs/tasks/ISF-SPAWN-IN-REPEAT.md) |
| `ISF-DYNAMIC-WAIT-PHASE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-PHASE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-PHASE-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-SYNC-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-SYNC-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-SYNC-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.md](docs/tasks/ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.md) |
| `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-STAGE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-STAGE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-STAGE-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.md) |
| `ISF-PARAM-WAIT-COUNTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-PARAM-WAIT-COUNTS.md](docs/tasks/ISF-PARAM-WAIT-COUNTS.md) |
| `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md](docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md) |
| `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.md](docs/tasks/ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.md) |
| `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.md](docs/tasks/ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.md) |
| `ISF-SHIFT-LEFT-EXPLICIT-WIDTH` | `done` | `R14` | `closed` | [docs/tasks/ISF-SHIFT-LEFT-EXPLICIT-WIDTH.md](docs/tasks/ISF-SHIFT-LEFT-EXPLICIT-WIDTH.md) |
| `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.md](docs/tasks/ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.md) |
| `ISF-RULE-RESOURCE-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-RESOURCE-FIXTURE-PROMOTION.md](docs/tasks/ISF-RULE-RESOURCE-FIXTURE-PROMOTION.md) |
| `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.md](docs/tasks/ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.md) |
| `ISF-WHEN-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-WHEN-FIXTURE-PROMOTION.md](docs/tasks/ISF-WHEN-FIXTURE-PROMOTION.md) |
| `ISF-SWITCH-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-SWITCH-FIXTURE-PROMOTION.md](docs/tasks/ISF-SWITCH-FIXTURE-PROMOTION.md) |
| `ISF-PHASE-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-PHASE-FIXTURE-PROMOTION.md](docs/tasks/ISF-PHASE-FIXTURE-PROMOTION.md) |
| `ISF-UART-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-UART-FIXTURE-PROMOTION.md](docs/tasks/ISF-UART-FIXTURE-PROMOTION.md) |
| `ISF-BURST-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-BURST-FIXTURE-PROMOTION.md](docs/tasks/ISF-BURST-FIXTURE-PROMOTION.md) |
| `ISF-I2C-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-I2C-FIXTURE-PROMOTION.md](docs/tasks/ISF-I2C-FIXTURE-PROMOTION.md) |
| `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE` | `done` | `R14` | `closed` | [docs/tasks/ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.md](docs/tasks/ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.md) |
| `ISF-DYNAMIC-DIVISOR-CONSTANTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-DIVISOR-CONSTANTS.md](docs/tasks/ISF-DYNAMIC-DIVISOR-CONSTANTS.md) |
| `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE` | `done` | `R14` | `closed` | [docs/tasks/ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.md](docs/tasks/ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.md) |
| `ISF-DYNAMIC-DIVISOR-SAFETY` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-DIVISOR-SAFETY.md](docs/tasks/ISF-DYNAMIC-DIVISOR-SAFETY.md) |
| `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.md) |
| `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.md) |
| `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.md) |
| `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.md) |
| `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.md) |
| `ISF-LOOP-BODY-DOC-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-LOOP-BODY-DOC-TRUTH-SYNC.md](docs/tasks/ISF-LOOP-BODY-DOC-TRUTH-SYNC.md) |
| `ISF-RULE-GUARD-DOC-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-GUARD-DOC-TRUTH-SYNC.md](docs/tasks/ISF-RULE-GUARD-DOC-TRUTH-SYNC.md) |
| `ISF-MDBOOK-FEATURE-MATRIX` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX.md) |
| `ISF-REPEAT-BODY-DOC-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-BODY-DOC-TRUTH-SYNC.md](docs/tasks/ISF-REPEAT-BODY-DOC-TRUTH-SYNC.md) |
| `ISF-LIVE-BOOK-DOCUMENT-PATHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-LIVE-BOOK-DOCUMENT-PATHS.md](docs/tasks/ISF-LIVE-BOOK-DOCUMENT-PATHS.md) |
| `ISF-TYPE-AGGREGATE-PARITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md) |
| `ISF-CDC-FIXTURE-MATRIX` | `done` | `R14` | `closed` | [docs/tasks/ISF-CDC-FIXTURE-MATRIX.md](docs/tasks/ISF-CDC-FIXTURE-MATRIX.md) |
| `ISF-CLOCK-DOMAINS` | `done` | `R14` | `closed` | [docs/tasks/ISF-CLOCK-DOMAINS.md](docs/tasks/ISF-CLOCK-DOMAINS.md) |
| `ISF-DOWNSTREAM-INTEGRATION-SPEC` | `done` | `R14` | `closed` | [docs/tasks/ISF-DOWNSTREAM-INTEGRATION-SPEC.md](docs/tasks/ISF-DOWNSTREAM-INTEGRATION-SPEC.md) |
| `ISF-BACKLOG-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-BACKLOG-TRUTH-SYNC.md](docs/tasks/ISF-BACKLOG-TRUTH-SYNC.md) |
| `ISF-RESOURCE-BACKLOG-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-RESOURCE-BACKLOG-TRUTH-SYNC.md](docs/tasks/ISF-RESOURCE-BACKLOG-TRUTH-SYNC.md) |
| `ISF-FEATURE-BACKLOG-STATUS-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-FEATURE-BACKLOG-STATUS-SYNC.md](docs/tasks/ISF-FEATURE-BACKLOG-STATUS-SYNC.md) |
| `ISF-GENERATED-NAME-POLICY` | `done` | `R14` | `closed` | [docs/tasks/ISF-GENERATED-NAME-POLICY.md](docs/tasks/ISF-GENERATED-NAME-POLICY.md) |
| `ISF-SCHEDULE-REPORT-SCHEMA-VERSION` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-SCHEMA-VERSION.md](docs/tasks/ISF-SCHEDULE-REPORT-SCHEMA-VERSION.md) |
| `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.md](docs/tasks/ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.md) |
| `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.md](docs/tasks/ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.md) |
| `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md](docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md) |
| `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md](docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md) |
| `ISF-PARAM-OVERRIDE-CONSTANTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md](docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md) |
| `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.md](docs/tasks/ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.md) |
| `ISF-SPEC-TEST-INDEX-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-SPEC-TEST-INDEX-SYNC.md](docs/tasks/ISF-SPEC-TEST-INDEX-SYNC.md) |
| `DOWNSTREAM-ISSUE-REPRO-FLOW` | `done` | `R14` | `closed` | [docs/tasks/DOWNSTREAM-ISSUE-REPRO-FLOW.md](docs/tasks/DOWNSTREAM-ISSUE-REPRO-FLOW.md) |
| `ISF-ACTOR-PHASE-STAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTOR-PHASE-STAGE-REPORTS.md](docs/tasks/ISF-ACTOR-PHASE-STAGE-REPORTS.md) |
| `ISF-ACTOR-PARAM-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTOR-PARAM-REPORTS.md](docs/tasks/ISF-ACTOR-PARAM-REPORTS.md) |
| `ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md](docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md) |
| `ISF-TEMPORAL-CONTRACT-ASSERTIONS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md](docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md) |
| `ISF-DYNAMIC-WAIT-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-STORAGE-REPORTS.md](docs/tasks/ISF-DYNAMIC-WAIT-STORAGE-REPORTS.md) |
| `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.md](docs/tasks/ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.md) |
| `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.md](docs/tasks/ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.md) |
| `ISF-TRANSACTION-PORT-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-STORAGE-REPORTS.md](docs/tasks/ISF-TRANSACTION-PORT-STORAGE-REPORTS.md) |
| `ISF-RULE-TRIGGER-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-TRIGGER-STORAGE-REPORTS.md](docs/tasks/ISF-RULE-TRIGGER-STORAGE-REPORTS.md) |
| `ISF-ACTIVATION-PARAM-OVERRIDES` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTIVATION-PARAM-OVERRIDES.md](docs/tasks/ISF-ACTIVATION-PARAM-OVERRIDES.md) |
| `ISF-PUBLIC-CONTRACT` | `done` | `R14` | `closed` | [docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md](docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md) |
| `ISF-DYNAMIC-WAIT` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT.md](docs/tasks/ISF-DYNAMIC-WAIT.md) |
| `ISF-ACTIVATION-BIND-EXPRESSIONS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md](docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md) |
| `COMPOSITION-WIRING-LISPISH` | `done` | `R11` | `closed` | [docs/tasks/COMPOSITION-WIRING-LISPISH.md](docs/tasks/COMPOSITION-WIRING-LISPISH.md) |
| `ISF-WAIT-ZERO` | `done` | `R14` | `closed` | [docs/tasks/ISF-WAIT-ZERO.md](docs/tasks/ISF-WAIT-ZERO.md) |
| `ISF-STORAGE-VAR-SURFACE` | `done` | `R14` | `closed` | [docs/tasks/ISF-STORAGE-VAR-SURFACE.md](docs/tasks/ISF-STORAGE-VAR-SURFACE.md) |
| `ISF-STORAGE-VAR-ALIASES` | `done` | `R14` | `closed` | [docs/tasks/ISF-STORAGE-VAR-ALIASES.md](docs/tasks/ISF-STORAGE-VAR-ALIASES.md) |
| `ISF-LIBRARY-SYSTEM-BINDINGS` | `done` | `R14` | `closed` | [docs/tasks/ISF-LIBRARY-SYSTEM-BINDINGS.md](docs/tasks/ISF-LIBRARY-SYSTEM-BINDINGS.md) |
| `ISF-TRANSACTION-ACTIVATION` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-ACTIVATION.md](docs/tasks/ISF-TRANSACTION-ACTIVATION.md) |
| `ISF-SETTER-SYNTAX` | `done` | `R14` | `closed` | [docs/tasks/ISF-SETTER-SYNTAX.md](docs/tasks/ISF-SETTER-SYNTAX.md) |
| `ISF-CONTROL-FLOW` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONTROL-FLOW.md](docs/tasks/ISF-CONTROL-FLOW.md) |
| `ISF-PORT-BINDING` | `done` | `R14` | `closed` | [docs/tasks/ISF-PORT-BINDING.md](docs/tasks/ISF-PORT-BINDING.md) |
| `ISF-LIBRARIES` | `done` | `R14` | `closed` | [docs/tasks/ISF-LIBRARIES.md](docs/tasks/ISF-LIBRARIES.md) |
| `ISF-SCHEDULE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORTS.md](docs/tasks/ISF-SCHEDULE-REPORTS.md) |
| `ISF-DATA-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-DATA-WIDTHS.md](docs/tasks/ISF-DATA-WIDTHS.md) |
| `ISF-STAGES-CONTRACTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-STAGES-CONTRACTS.md](docs/tasks/ISF-STAGES-CONTRACTS.md) |
| `ISF-RULE-ACTIONS` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-ACTIONS.md](docs/tasks/ISF-RULE-ACTIONS.md) |
| `ISF-RESOURCE-CATALOG` | `done` | `R14` | `closed` | [docs/tasks/ISF-RESOURCE-CATALOG.md](docs/tasks/ISF-RESOURCE-CATALOG.md) |
| `ISF-RESOURCE-PRIORITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-RESOURCE-PRIORITY.md](docs/tasks/ISF-RESOURCE-PRIORITY.md) |
| `ISF-CONFLICTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONFLICT-RESOLUTION.md](docs/tasks/ISF-CONFLICT-RESOLUTION.md) |
| `ISF-COMPOSITION` | `done` | `R14` | `closed` | [docs/tasks/ISF-COMPOSITION-INSTANTIATION.md](docs/tasks/ISF-COMPOSITION-INSTANTIATION.md) |
| `ISF-FIXTURES` | `done` | `R14` | `closed` | [docs/tasks/ISF-FIXTURE-COVERAGE.md](docs/tasks/ISF-FIXTURE-COVERAGE.md) |
| `ISF-COMPATIBILITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-COMPATIBILITY-SURFACE.md](docs/tasks/ISF-COMPATIBILITY-SURFACE.md) |

## R14 ISF Objective Coverage

All currently documented ongoing or unresolved R14 ISF objective families have
task-tree ownership. Already-shipped base objectives such as parsing `.isf`
actors, lowering through `LoweringIR`, emitting scheduled `.fsm`, schedule JSON
emission, and HDL handoff remain recorded in [ROADMAP_STATUS.md](ROADMAP_STATUS.md)
as done work unless a future task reopens them.

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
| `Verification Code Generation` | `active IAL1-VERIFICATION-CODE-GENERATION-FRONTIER owns the first-class verification-generation lane; .3 selected actor-level passive observation metadata as the first IAL1 verification-specific source feature; active implementation owner ISF-VERIFICATION-OBSERVATION-METADATA.1 must ship before SV/UVM, VHDL, direct IAL2, or public artifact/report behavior` |
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
- Task tree: all known nodes, with status and short result intent.
- Current frontier: ordered leaf nodes that PNT may select next.
- Decisions: accepted technical decisions and their rationale.
- Open questions: unresolved questions that do not block the whole tree yet.
- Blockers: blockers with unblock conditions.
- Verification log: checks run for completed leaves.
- Commit log: leaf IDs mapped to completion commit subjects.
- Changelog: dated edits to the tree itself.

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

A node with children must not be marked `done` until every child is `done`,
`deferred`, or `superseded`, and every non-`done` child has a recorded reason.

## Current Frontier Rules

The current frontier is the only list PNT uses when selecting work from a task
tree.

Rules:

- The frontier contains only leaf nodes.
- The frontier is ordered by intended priority.
- A container never appears in the frontier.
- A blocked node stays out of the frontier until unblocked.
- When a leaf is split, remove that leaf from the frontier, mark it `active`,
  add children, and place the first executable child or children in the
  frontier.
- When a leaf completes, remove it from the frontier and add the next eligible
  leaf or leaves.

## PNT Selection Rules

When PNT is asked to continue and at least one active task tree exists:

1. Read `docs/TASK_TREE.md`.
2. Read the active task file named in the `Active Task Trees` table.
3. Pick the first eligible leaf in that file's `Current Frontier`.
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
- `MEMORY.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`, and `ROADMAP_STATUS.md` are updated when the
  leaf changes project state.
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

- `ROADMAP_STATUS.md` remains the canonical high-level workstream status.
- `MEMORY.md` remains the recovery/handoff continuity log.
- `CHANGES.md` remains the chronological technical history.
- `DEVELOPMENT_NOTES.md` remains design rationale.
- `LIVE_ACHIEVEMENT_STATUS.md` remains the latest completed slice summary.
- The mdBook remains user-facing product/language documentation.

Do not duplicate the whole task tree into those files. Link to the task tree
and summarize only the part that changes live project state.

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
