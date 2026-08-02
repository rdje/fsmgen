# FSMGen Roadmap v2

This is FSMGen's bounded strategic roadmap: why the project is moving, which
capabilities it is building, how those capabilities depend on one another, and
which longer-term directions remain deliberately gated.

It does not duplicate execution state or shipped-behavior detail:

- [MEMORY.md](MEMORY.md) is the current resume pointer.
- [docs/TASK_TREE.md](docs/TASK_TREE.md) and the owning file under
  [docs/tasks/](docs/tasks/) identify active work, exact frontiers, blockers,
  acceptance evidence, and the next selectable slice.
- [the mdBook](docs/book/src/SUMMARY.md) documents shipped behavior and
  user-facing examples.
- [decision records](docs/decisions/INDEX.md) preserve cross-cutting choices.
- Git preserves exact work-unit chronology.

Decision
[0049](docs/decisions/0049-roadmap-status-is-roadmap-task-trees-memory-and-git.md)
defines that authority split. The final section below gives exact recovery for
the detailed pre-containment roadmap chronology.

## Product objective

FSMGen should turn concise, reviewable hardware intent into deterministic,
high-quality HDL and equally reviewable semantic artifacts. It should be
useful as both a command-line tool and a compiler platform, while keeping the
authored language clearer and more stable than the backend syntax it emits.

The post-`R0`..`R7` objective is no longer merely to finish a refactor. It is to
make the modernized implementation a strict, explicit, trustworthy language
and tool contract that can scale to richer intent, additional backends, and
downstream automation without semantic drift.

## Governing principles

- Prefer explicit language contracts over accidental parser acceptance.
- Distinguish implemented behavior from supported public behavior.
- Treat diagnostics, provenance, reports, and examples as product surfaces.
- Grow syntax only when its semantics are crisp and regression-backed.
- Keep composition and extension growth deliberate and typed.
- Lower through explicit semantic IRs; backends should render established
  meaning rather than rediscover it.
- Preserve one backend-neutral contract across Perl, future Rust/Wasm, and
  browser-capable implementations.
- Alternate consolidation with visible capability work when both are ready.
- Keep every project-owned output, cache, dependency store, fixture, log, and
  temporary workspace repository-derived and on the repository volume.
- Keep live documentation bounded and route exact history to verified durable
  storage instead of appending chronology to current-state views.

## Strategic workstreams

The workstream numbers preserve the roadmap's stable vocabulary. They express
direction, not live completion state; the task-tree index is authoritative for
what is active now.

### R8. Language-contract hardening

Goal: make the supported `.fsm` boundary normative and mechanically provable.

Direction:

- give every parser-visible construct one explicit support classification;
- keep canonical syntax, compatibility residue, experimental/deferred syntax,
  and rejected syntax distinguishable;
- make types, imports, assignments, reset behavior, packages, composition,
  and generated-child semantics part of one coherent language contract; and
- require focused regression evidence before a support claim changes.

Milestone outcome: the mdBook, support accounting, strict-mode tests, and
semantic reports now expose far more of this boundary than the original
parser-defined contract. Remaining changes should close named gaps rather than
re-open the language wholesale.

### R9. Strict mode and support-tier enforcement

Goal: let users choose the canonical supported language without silently
accepting compatibility residue.

Direction:

- keep strict mode available through the CLI and pipeline;
- reject non-canonical roots, sections, aliases, and ambiguous compatibility
  forms with targeted diagnostics;
- retain default-mode compatibility only where it remains deliberate; and
- add a canonical replacement before removing a compatibility form when users
  still need the underlying capability.

Milestone outcome: strict mode is a real, regression-backed contract rather
than a documentation label. Future tightening belongs in small construct-
specific slices.

### R10. Source provenance and diagnostics

Goal: make failures precise, actionable, source-local, and safe to consume
from both humans and tools.

Direction:

- carry file, construct, and generated-child provenance through parsing,
  lowering, validation, and emission;
- preserve parent/child and searched-artifact context across composition;
- use stable diagnostic codes and bounded summaries where a public contract is
  warranted; and
- keep ordinary failures free of raw stack traces or machine-local leakage.

Milestone outcome: CLI, pipeline, composition, semantic-report, and MCP paths
share substantially stronger source-local diagnostics. Deeper span precision
and remaining raw-failure pockets should converge on the same model.

### R11. Composition, types, and compiler ownership

Goal: deepen composition and reusable module/type contracts while making the
compiler pipeline structurally honest.

Direction:

- keep `.rtlif`, generated-child, standalone-DT, reusable-module,
  shared-datapath, wiring, parameter, and package behavior explicit;
- preserve semantic scalar and aggregate type identity through source,
  composition, IR, validation, and backend lowering;
- converge on explicit source/intent, lowered RTL, and structural connectivity
  IR boundaries governed by [docs/IR_POLICY.md](docs/IR_POLICY.md);
- keep `HDLGenerator` a thin public facade while dedicated owners perform
  frontend, planning, validation, IR construction, and emission work;
- make SystemVerilog and future VHDL consume backend-neutral meaning; and
- keep the architecture note in
  [docs/BIN_FSMGEN_IMPORT_TREE.md](docs/BIN_FSMGEN_IMPORT_TREE.md) only while
  its separately owned lifecycle audit finds it current and useful.

Milestone outcome: composition, typed aggregate boundaries, SourceHIR,
IntentHIR, StructuralRTLIR, direct SystemVerilog ownership, and validation have
all gained explicit owners. The remaining work is convergence and coverage,
not permission to preserve accidental monoliths.

### R12. Regression corpus and support accounting

Goal: make every support claim measurable and continuously checked.

Direction:

- classify representative sources as supported, expected failure, or retained
  legacy/out-of-scope behavior;
- combine semantic assertions with generated-artifact and external-tool checks
  where each adds independent evidence;
- keep examples, capability metadata, support accounting, and docs in
  lockstep; and
- qualify scale and portability with named profiles instead of anecdotes.

Milestone outcome: the repository has a machine-checked corpus, support
accounting, capability manifests, semantic outputs, and focused tool matrices.
New language or backend claims must enter those surfaces atomically.

### R13. Embedding, reports, and semantic introspection

Goal: make FSMGen intentionally usable as a library and read-only semantic
service, not only as a CLI that emits HDL.

Direction:

- stabilize JSON-safe, versionable request/result and plan/report contracts;
- replace raw in-process shells with bounded semantic snapshots where external
  consumers need durability;
- keep capability, diagnostic, source-discovery, support, semantic, schedule,
  and validation queries aligned;
- keep MCP an adapter over the semantic API rather than a second authority;
  and
- introduce mutation or service transports only under explicit later owners.

Milestone outcome: serializable plan/result/diagnostic surfaces and a bounded
read-only MCP adapter are shipped. Public API stabilization should build on
those contracts and preserve fail-closed workspace boundaries.

### R14. Intent scheduling and layered intent

Goal: let authors express hardware intent above manually chosen states and
cycles while keeping the resulting schedule explicit and reviewable.

Direction:

- keep `.fsm` as the explicit cycle-accurate design layer;
- use `.isf`/IAL1 for actors, transactions, rules, resources, phases,
  constraints, scheduling, and generated schedule reports;
- use IAL2 for higher protocol/platform intent that lowers through IAL1 and
  IAL0 rather than bypassing them;
- develop actor-network/ATL composition, protocol profiles, and HIAL/VIAL
  verification intent, with future exact PGEN parsing and NEXSIM simulation
  profiles, without conflating design and verification semantics or inferring
  runtime support from emitted artifacts;
- allow complete simulator-neutral UVM generation, static/visual review, and
  exact open-tool compile/elaboration probes to iterate before full runtime
  qualification, while keeping VIAL meaning stable as generated syntax evolves;
- use provider-free VHDL-2008 as the portable VIAL semantic core, exact GHDL
  profiles for open-source qualification, and OSVVM only as a separately
  capability-qualified advanced methodology provider; and
- fail with actionable ambiguity/conflict evidence instead of selecting a
  hidden schedule.

Milestone outcome: `.isf`, IAL1 scheduling, IAL2 protocol profiles, generated
artifacts, semantic reports, and the initial HIAL/VIAL architecture are real
repository contracts. Their exact feature frontiers remain task-tree owned.

## Dependency and sequencing policy

The original conceptual order remains useful:

1. harden the language contract (`R8`);
2. enforce its canonical tier (`R9`);
3. improve provenance and diagnostics (`R10`);
4. deepen composition, types, and compiler ownership (`R11`);
5. make claims measurable (`R12`);
6. stabilize embedding and semantic APIs (`R13`); and
7. build higher intent and scheduling on those foundations (`R14`).

Execution need not serialize entire workstreams. A slice may proceed when its
specific dependencies and task-tree blockers are closed. In particular,
regression/support accounting should accompany every workstream, diagnostics
should improve at newly exposed boundaries, and API changes should not outrun
the semantics they report.

## Current execution

The roadmap deliberately carries no hand-maintained active-status board.
Read, in order:

1. [MEMORY.md](MEMORY.md) for the single resume action;
2. [docs/TASK_TREE.md](docs/TASK_TREE.md) for active and proposed trees; and
3. the owning task file for its exact frontier and acceptance evidence.

This avoids reviving the former pattern in which thousands of completed leaf
updates obscured current direction. A completed milestone changes this roadmap
only when it changes strategy, dependencies, or a concise workstream outcome.

## Long-term horizon

Horizon items are intentional but are not active merely because they appear
here. Promotion requires an explicit task-tree selection after nearer contract
and stability prerequisites are met.

### H1. Rust and portable implementations

Carry the mature public language, IAL, report, diagnostic, and artifact
contracts into a Rust implementation, with Rust/Wasm as a deployment target.
Start beside the Perl reference/oracle in this repository so fixtures and
differential tests stay synchronized. Do not redesign the language as part of
the port, and do not expose host-only filesystem/process assumptions through
portable contracts.

Browser-capable JavaScript/Wasm and Dart/web implementations are sibling
options over the same contracts, not separate semantic products.

### H2. Public project website

Publish a polished, dynamic site for discovery, examples, documentation, and
adoption once the tool is strong and stable enough that the site amplifies the
product rather than compensating for it.

### H3. HDL import and intent recovery

Recover recognizable `.fsm`-style intent from synthesizable SystemVerilog or
VHDL without claiming lossless inversion of arbitrary handwritten HDL.

Start with FSMGen-generated SystemVerilog round trips, then a bounded
handwritten subset. Parse and elaborate into semantic HDL/RTL structure,
recover intent with provenance/confidence/residue, and converge with the
forward compiler on shared lowered and structural IR where meaning genuinely
matches. Ambiguous regions must remain explicit rather than being dressed up
as certain high-level intent.

### H4. Specification-driven intent capture

PDF/specification-to-intent capture is owned externally by SPECFORGE. FSMGen
retains method examples such as
[the AXI case study](docs/INTENT_CAPTURE_AXI_CASE_STUDY.md) and
[the APB worksheet](docs/APB_REQUESTER_CAPTURE_WORKSHEET.md), and owns the
downstream IAL2 onboarding workflow in
[docs/IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md](docs/IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md).

### H5. VHDL backend

Implement a real VHDL backend only after the SystemVerilog-backed IAL0/IAL1/
IAL2 path and portable type/IR contracts are sufficiently stable. Begin with
the single-FSM lane, reuse [docs/VHDL_SCOPE.md](docs/VHDL_SCOPE.md), and expand
composition only when parity and regression evidence justify it.

### H6. End-to-end large-design scalability

Qualify parsing, lowering, scheduling, analysis, review artifacts, HDL
emission, semantic exports, and tool handoff together. Named `big` and
`really_big` profiles must preserve correctness, deterministic outputs,
diagnostics, repository-local artifacts, peak descendant-memory/time evidence,
and graceful beyond-capacity behavior. The proposed
[scalability task tree](docs/tasks/FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.md)
owns promotion and qualification.

## Exact pre-containment roadmap recovery

The complete activation source remains exact and queryable:

```sh
git show dc1c64afb62bc128d2cf28c493d5eebc7726b02a:ROADMAP_V2.md
```

Descriptor `roadmap-v2-pre-containment-2026-08-01` records 10,451 lines,
772,074 bytes, longest line 2,297, and SHA-256
`6c7e00fe39cd8052b4a19d497d1fff60a37a1a6db9511126fa0735a030ade2b3`
under the repository's required-history retention contract.

The source disposition is complete:

| Activation-source range | Disposition |
| --- | --- |
| lines 1–41 | Product purpose and principles retained in bounded form here. |
| lines 42–79 | Package-breakdown completion narration preserved by the exact descriptor; current architecture belongs to source, decisions, task evidence, and the book. |
| lines 80–738 | `R8`–`R14` direction retained and condensed here; leaf chronology remains exact in the descriptor, task trees, and Git. |
| lines 739–755 | Dependency logic retained here. |
| lines 756–1,097 | `H1`–`H6` intent retained and condensed here; completed horizon experiments remain in task/book/Git evidence. |
| lines 1,098–10,451 | Appended `Current intent` chronology preserved by the exact descriptor; active state routes to Memory/task trees and shipped behavior routes to the mdBook. |

No activation-source line depends on inference for recovery: the descriptor
covers the entire original object, while this live view retains only current
strategy, dependencies, concise milestone outcomes, horizon intent, and the
canonical route to execution state.
