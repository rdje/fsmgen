# FSMGEN-HIR-ROADMAP-FRONTIER: Source-Facing HIR Roadmap Frontier

## Metadata

- Tree ID: `FSMGEN-HIR-ROADMAP-FRONTIER`
- Status: `active`
- Roadmap lane: `architecture / high-level frontend IR`
- Created: `2026-06-28`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Track FSMGEN HIR as a critical roadmap phase: a source-facing, FSMGEN-native
high-level IR that high-level language frontends can lower into, after which
FSMGen validates/canonicalizes the HIR and lowers it to IAL2 or IAL1 through
the existing pipeline.

The intent is to avoid one frontend per target-language matrix. Multiple
future high-level syntaxes or builder APIs should converge through one checked
semantic model rather than each learning every IAL1/IAL2 detail, protocol
intent rule, scheduling rule, width rule, reset rule, diagnostic convention,
and future IAL evolution.

## Non-Goals

- Do not replace IAL1 or IAL2. HIR sits above them as a semantic input layer.
- Do not create a general-purpose compiler IR or a general software-to-hardware
  compiler.
- Do not infer hardware from arbitrary software semantics.
- Do not bypass the existing `IAL2 -> IAL1 -> IAL0` and `IAL1 -> IAL0`
  lowering chains.
- Do not add parser, compiler, source, generated-artifact, config, or behavior
  changes before an active HIR leaf selects the exact boundary and satisfies
  [docs/IR_POLICY.md](../IR_POLICY.md).
- Do not assume the final implementation must be a new Perl package if the
  selection leaf proves that an existing `IntentHIR` extension or bounded
  projection is the correct home.

## Acceptance Criteria

- The HIR roadmap phase is durably captured as a task-tree-owned roadmap item.
- The HIR direction is distinguished from the existing internal forward
  `IntentHIR`, `LoweredRTLIR`, and `StructuralRTLIR` layers.
- The first executable activation leaf starts with architecture selection, not
  implementation.
- Activation criteria require an exact producer/consumer/invariant/public-
  private/migration record per `docs/IR_POLICY.md`.
- Future high-level language or builder work must consult this tree before
  choosing direct lowering to IAL2 or IAL1.
- Each completed active leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER`
  Status: `active`
  Goal: `Own the source-facing FSMGEN HIR roadmap phase above IAL2 and IAL1.`
  Children: `FSMGEN-HIR-ROADMAP-FRONTIER.1`, `FSMGEN-HIR-ROADMAP-FRONTIER.2`, `FSMGEN-HIR-ROADMAP-FRONTIER.3`, `FSMGEN-HIR-ROADMAP-FRONTIER.4`, `FSMGEN-HIR-ROADMAP-FRONTIER.5`, `FSMGEN-HIR-ROADMAP-FRONTIER.6`, `FSMGEN-HIR-ROADMAP-FRONTIER.7`, `FSMGEN-HIR-ROADMAP-FRONTIER.8`

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER.1`
  Status: `done`
  Goal: `Capture the FSMGEN HIR roadmap phase and activation criteria.`
  Acceptance: `Record the HIR concept as a critical task-tree-owned roadmap phase, preserve the direct-lowering-versus-HIR architecture rationale, name the first activation leaf, sync roadmap/task-tree/Memory/Knowledge Map/book surfaces, and confirm no code, parser, source, generated-artifact, config, or behavior change occurs.`
  Verification: `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; `scripts/check_doctrines.sh`
  Commit: `FSMGEN-HIR-ROADMAP-FRONTIER.1: capture FSMGEN HIR roadmap phase`

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER.2`
  Status: `done`
  Goal: `Select the first source-facing HIR architecture boundary.`
  Acceptance: `Audit docs/IR_POLICY.md, docs/tasks/FSMGEN-IR-AUDIT.md, existing IntentHIR/LoweredRTLIR/StructuralRTLIR owners, IAL1 and IAL2 public source surfaces, normalized semantic/report contracts, and IAL2-HOST-LANGUAGE-BUILDER-FRONTIER. Decide whether the first source-facing HIR should extend an existing IntentHIR-adjacent layer, create a new named surface, or remain a textual IAL handoff for the first prototype. Define producers, consumers, invariants, mutation policy, public/private status, source-span diagnostics, validation, docs impact, migration/retirement rules, first exact frontend or builder, and first golden fixture. No implementation begins in this leaf unless split into a later active implementation leaf.`
  Verification: `IR-policy audit selects distinct private FSM::IR::SourceHIR rather than extending the post-parse IntentHIR or using a text-only semantic model. Exact owner family, first internal Perl builder, canonical PPIF handoff, source-location/source-map policy, validation, privacy, no-public-schema rule, migration/retirement rule, and byte-identical ppif/valid_ready_handshake.ppif golden are recorded in docs/FSMGEN_SOURCE_HIR_ARCHITECTURE_SELECTION.md and decision 0028. Baseline public PPIF strict check and schedule JSON succeed; focused current IR/contract/valid-ready tests pass with Files=6, Tests=12. Feature-backlog, live-book-path, and relative-path audits pass with Files=3, Tests=40; all 36 mdBook chapters pass executable-example testing; the 72-file HTML build passes and its exact repository-local output is removed. Knowledge Map generation/check passes at 1076 facts / 5547 question keys; memory architecture passes with MEMORY.md at 47 lines; diff hygiene and all seven doctrine gates pass. No implementation, source fixture, generated artifact, config, API/report schema, support accounting, HDL/runtime, frozen status file, or public behavior changes.`
  Commit: `FSMGEN-HIR-ROADMAP-FRONTIER.2: select private SourceHIR boundary`

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER.3`
  Status: `done`
  Goal: `Freeze the exact SourceHIR version-1 contract before implementation.`
  Acceptance: `Define the exact immutable object keys/types/order, valid-ready-only constraints, provenance/source-span shape, semantic paths, diagnostic and downstream-remap fallback rules, renderer result/source-map shape, byte-equivalence oracle, negative cases, package APIs, and focused test ownership for the private internal Perl builder. Change no code, parser, source fixture, generated artifact, config, public API/report schema, support accounting, HDL/runtime, or behavior.`
  Verification: `Clean activation commit 63fe1c716 permits only exact contract selection. docs/FSMGEN_SOURCE_HIR_V1_CONTRACT.md freezes the closed v1 tree, class-method and immutable-object APIs, normalization/validation order, semantic paths, same-volume provenance, private diagnostic hashes/codes/formatting, renderer result/source map, line-remap/root-fallback algorithm, t/1547 ownership, and exact 14-line/428-byte/SHA-256 valid-ready fixture oracle. Independent line/byte/SHA checks pass. Feature-backlog, live-book-path, and relative-path audits pass with Files=3, Tests=40; all 36 mdBook chapters pass executable-example testing; the 72-file HTML build passes and its exact repository-local output is removed. Knowledge Map generation/check passes at 1077 facts / 5553 question keys; memory architecture passes with MEMORY.md at 47 lines; diff hygiene and all seven doctrine gates pass. No code, test, parser, fixture, artifact, config, CLI/API/report/accounting, HDL/runtime, frozen status file, or behavior changes.`
  Commit: `FSMGEN-HIR-ROADMAP-FRONTIER.3: freeze SourceHIR v1 contract`

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER.4`
  Status: `done`
  Goal: `Implement the private valid-ready SourceHIR golden path.`
  Acceptance: `Implement only the policy-selected SourceHIR, SourceHIRBuilder, and SourceHIRPPIFRenderer private package family after .3 is done. Prove construction/rejection, immutability, deterministic byte-identical rendering of ppif/valid_ready_handshake.ppif, provenance diagnostics, PPIF reparse, and unchanged generated IAL1/IAL0 semantics. Add no public frontend, CLI mode, report key, manifest field, or support-accounting entry.`
  Verification: `Clean activation commit b9d0c9fba permits only the contract-selected private implementation. The three SourceHIR packages and t1547 implement closed deterministic validation, immutable defensive access, exact/ancestor/root provenance, canonical ordered PPIF plus source map, stack-sanitized line-remap/root-fallback diagnostics, alternate role/reset/list variants, and byte-identical 14-line/428-byte/SHA-256 golden output. Generated text reparses through the existing adapter with equal IAL1, IAL0, schedule, and protocol reports and no direct generator dependency. Focused plus current IR/contract/valid-ready baseline passes with Files=7, Tests=21; all four new Perl/test files report syntax OK. Feature-backlog, live-book-path, and relative-path audits pass with Files=3, Tests=40; all 36 mdBook chapters pass executable-example testing; the 72-file HTML build passes and its exact repository-local output is removed. Knowledge Map generation/check passes at 1078 facts / 5558 question keys; memory architecture passes with MEMORY.md at 47 lines; diff hygiene and all seven staged doctrine gates pass. No CLI, parser, fixture, config, public API/report/manifest/accounting, HDL/runtime, frozen status file, or existing behavior changes.`
  Commit: `FSMGEN-HIR-ROADMAP-FRONTIER.4: implement private SourceHIR golden path`

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER.5`
  Status: `done`
  Goal: `Audit private SourceHIR prototype promotion or retirement.`
  Acceptance: `After .4, decide from evidence whether to promote a first public frontend/builder and bounded projection, keep the prototype private for another fixture, or retire it. Coordinate any public-host-language selection with IAL2-HOST-LANGUAGE-BUILDER-FRONTIER; do not assume promotion.`
  Verification: `Clean activation commit 2881a664c permits only the evidence audit. docs/FSMGEN_SOURCE_HIR_POST_PROTOTYPE_AUDIT.md and decision 0029 select continued private iteration: t1547 passes Files=1, Tests=9 and proves a healthy deterministic IAL2 valid-ready boundary, so retirement is rejected; repository source usage remains limited to the three private packages plus t1547, with one test-only producer, one schema, no concrete-control-to-IAL1 route, and no public host-language/versioning/compatibility contract, so promotion is premature. A read-only isf/phase_test.isf readiness probe passes strict check at five states/five signals and schedule generation at one five-state transaction/three ports, proving a second-route candidate class exists without selecting the fixture. Proposed design-only .6 selects the exact private concrete-control-to-IAL1 boundary, .7 implements it, and .8 repeats the evidence audit. Public builder ownership remains proposed and separate. Feature-backlog, live-book-path, and relative-path audits pass with Files=3, Tests=40; all 36 mdBook chapters pass executable-example testing; the 72-file HTML build passes and its exact repository-local output is removed. Knowledge Map generation/check passes at 1079 facts / 5563 question keys; memory architecture passes with MEMORY.md at 47 lines; diff hygiene and all seven staged doctrine gates pass. No code, test, parser, fixture, artifact, config, CLI/API/report/manifest/accounting, HDL/runtime, frozen status file, or behavior changes.`
  Commit: `FSMGEN-HIR-ROADMAP-FRONTIER.5: keep SourceHIR private through IAL1 proof`

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER.6`
  Status: `active`
  Goal: `Select the private concrete-control-to-IAL1 SourceHIR boundary.`
  Acceptance: `After .5 commits cleanly, audit the shipped IAL1 source/parser/lowering contract and small checked concrete-control fixtures. Select or reject one exact version-2 SourceHIR object/schema evolution, private builder and canonical IAL1 renderer API, provenance/source-map/diagnostic rules, tracked byte-identical IAL1 golden, focused test owner, downstream IAL0/schedule equivalence oracle, migration/retirement rule, and complete non-goals. Prefer the smallest representative concrete FSM/control fixture; do not merely add another valid-ready/PPIF variant. Change no code, tests, parser, fixture, generated artifact, configuration, public API/report/manifest/accounting, HDL/runtime, or behavior.`
  Verification: `Activated continuity-only after clean audit commit 5d018edbd. Activation changes only task/index, architecture/audit/decision/fact continuity, roadmap, mdBook backlog, Memory, changelog, and regenerated Knowledge Map. Exact fixture, schema, package/API, renderer, provenance/source-map/diagnostic contract, test, code, parser, artifacts, public surfaces, HDL/runtime, and behavior remain unselected and unchanged. Feature-backlog, live-book-path, and relative-path audits pass with Files=3, Tests=40; all 36 mdBook chapters pass executable-example testing; the 72-file HTML build passes and its exact repository-local output is removed. Knowledge Map generation/check passes at 1079 facts / 5563 question keys; memory architecture passes with MEMORY.md at 46 lines; diff hygiene and all seven staged doctrine gates pass. Both frozen status files remain untouched.`
  Commit: `FSMGEN-HIR-ROADMAP-FRONTIER.6: activate private SourceHIR IAL1 selection`

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER.7`
  Status: `proposed`
  Goal: `Implement the selected private concrete-control-to-IAL1 SourceHIR golden path.`
  Acceptance: `Only after .6 selects a viable exact contract, implement that private contract and focused equivalence proof. Preserve the version-1 valid-ready path and all public surfaces. If .6 rejects a coherent shared boundary, do not activate this leaf.`
  Verification: `pending`
  Commit: `FSMGEN-HIR-ROADMAP-FRONTIER.7: implement private SourceHIR IAL1 golden path`

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER.8`
  Status: `proposed`
  Goal: `Re-audit SourceHIR promotion after both private lowering routes.`
  Acceptance: `After .7, compare promotion, continued private iteration, narrowing/renaming, and retirement using both private route proofs. Coordinate any public selection with IAL2-HOST-LANGUAGE-BUILDER-FRONTIER; a second route alone does not authorize a public API.`
  Verification: `pending`
  Commit: `FSMGEN-HIR-ROADMAP-FRONTIER.8: audit SourceHIR promotion after IAL1 proof`

## Current Frontier

Clean post-prototype audit commit `5d018edbd` activates `.6` continuity-only.
The leaf must now select or reject the exact private concrete-control-to-IAL1
boundary and golden.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `FSMGEN-HIR-ROADMAP-FRONTIER.1` | `done` | Captured the roadmap phase and activation criteria without behavior changes. |
| 2 | `FSMGEN-HIR-ROADMAP-FRONTIER.2` | `done` | Selected a distinct private SourceHIR, internal Perl builder, canonical PPIF handoff, and valid-ready golden. |
| 3 | `FSMGEN-HIR-ROADMAP-FRONTIER.3` | `done` | Froze the exact closed object, APIs, provenance/diagnostics, renderer/source-map, test, and golden oracle. |
| 4 | `FSMGEN-HIR-ROADMAP-FRONTIER.4` | `done` | Implemented the three private packages and t1547 exact golden/downstream-equivalence proof. |
| 5 | `FSMGEN-HIR-ROADMAP-FRONTIER.5` | `done` | Kept SourceHIR private because one IAL2 schema is healthy but insufficient for promotion. |
| 6 | `FSMGEN-HIR-ROADMAP-FRONTIER.6` | `active` | Select the exact concrete-control-to-IAL1 private boundary and golden. |
| 7 | `FSMGEN-HIR-ROADMAP-FRONTIER.7` | `proposed` | Implement only the selected second private route. |
| 8 | `FSMGEN-HIR-ROADMAP-FRONTIER.8` | `proposed` | Repeat the promotion audit across both lowering routes. |

## Decisions

- `2026-06-28`: A source-facing HIR is the preferred long-term architecture
  if FSMGen grows more than one high-level frontend. Direct lowering from each
  high-level language to IAL2 or IAL1 is acceptable for a single prototype, but
  it scales poorly because every frontend would need to understand every IAL
  target, protocol-intent rule, scheduling rule, width/reset convention, and
  diagnostic rule.
- `2026-06-28`: The intended shape is
  `high-level frontend -> FSMGEN HIR -> validation/canonicalization -> IAL2 or IAL1 -> existing lowering`.
  HIR should lower to IAL2 when the source expresses protocol/platform intent
  and to IAL1 when the source is already concrete FSM/control logic.
- `2026-06-28`: The HIR should model FSMGEN-native concepts first: typed
  signals and widths, state machines, transitions, guards, effects, channels
  and transactions, clocks and resets, protocol endpoints, resource policies,
  scheduling intent, and source spans for diagnostics.
- `2026-06-28`: Scope control is mandatory. The HIR must not become a broad
  general-purpose compiler IR. The first version must be derived from real
  shipped or actively planned FSMGen examples.
- `2026-06-28`: Do not replace IAL1 or IAL2. Keep them as committed lowering
  targets and put the source-facing HIR above them.
- `2026-06-28`: The existing proposed
  `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` remains relevant, but future host
  language builder work should activate through or after this HIR boundary
  selection instead of assuming direct IAL emission is the final architecture.
- `2026-07-30`: Parent selector `.841` selects proposed `.2` as the smallest
  foundational owner after the Chapter 16c AHB truth repair. `.2` remains
  inactive until the selector commits cleanly; no IR or behavior changes.
- `2026-07-30`: Clean selector commit `b4e66c067` activates `.2`
  continuity-only. Architecture choices and all implementation remain
  unchanged until the activation commit is clean.
- `2026-07-30`: `.2` selects a distinct private pre-IAL
  `FSM::IR::SourceHIR`; the existing post-parse `IntentHIR` remains unchanged.
  The first internal Perl builder renders canonical `.ppif` and must use the
  existing parser/validator and `IAL2 -> IAL1 -> IAL0` path.
- `2026-07-30`: `ppif/valid_ready_handshake.ppif` is the byte-for-byte first
  golden. The prototype exposes no CLI, public host-language API, public raw
  object, normalized-report key, support-accounting promise, or new behavior.
  Decision `0028` and
  `docs/FSMGEN_SOURCE_HIR_ARCHITECTURE_SELECTION.md` are canonical.
- `2026-07-30`: Clean architecture-selection commit `f0e88e9f7` activates
  `.3` continuity-only. The exact version-1 contract remains unselected until
  this activation commits cleanly.
- `2026-07-30`: `.3` freezes the private v1 contract in
  `docs/FSMGEN_SOURCE_HIR_V1_CONTRACT.md`: one closed valid-ready object,
  immutable access, deterministic canonical rendering, structured private
  diagnostics, JSON-Pointer provenance, current-adapter no-line fallback, and
  `t/1547` implementation ownership.
- `2026-07-30`: Clean v1-contract commit `3244f8817` activates `.4`
  continuity-only. Implementation remains unchanged until the activation
  commits cleanly.
- `2026-07-30`: `.4` implements the private closed SourceHIR object, builder,
  PPIF renderer/source map, and structured diagnostic remapper. T1547 proves
  exact fixture bytes and unchanged existing-parser downstream results.
- `2026-07-30`: Clean private implementation commit `b4733b879` activates
  `.5` continuity-only. Promotion, continued-private expansion, and retirement
  remain unselected until the activation commits cleanly.
- `2026-07-30`: `.5` keeps SourceHIR private through a second lowering-route
  proof. The valid-ready prototype is healthy enough to retain, but one test
  producer, one schema, and only the IAL2 route are insufficient evidence for
  public language/API/versioning compatibility. Decision `0029` refines
  `0028`; proposed `.6` selects concrete control to canonical IAL1, `.7`
  implements it, and `.8` repeats the audit.
- `2026-07-30`: Clean audit commit `5d018edbd` activates `.6`
  continuity-only. Exact second-route choices remain unselected until the
  activation commits cleanly.

## Open Questions

- Leaf `.6` must select or reject one coherent private concrete-control-to-IAL1
  SourceHIR contract and exact golden after activation commits cleanly.

## Blockers

- None. `.6` is active continuity-only after clean commit `5d018edbd`.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-28` | `FSMGEN-HIR-ROADMAP-FRONTIER.1` | `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; `scripts/check_doctrines.sh` | `passed` |
| `2026-07-30` | `FSMGEN-HIR-ROADMAP-FRONTIER.2` | public PPIF strict check + schedule JSON; `prove -Iperl t/155-forward-intent-hir-surface.t t/156-forward-lowered-rtl-ir-surface.t t/163-forward-structural-rtl-ir-surface.t t/334-normalized-semantic-forward-ir-contract.t t/339-normalized-semantic-intent-hir-contract.t t/1435-axi-ial2-valid-ready-generator.t`; documentation audits; Knowledge Map; memory architecture; `mdbook test docs/book`; `mdbook build docs/book`; diff hygiene; `scripts/check_doctrines.sh` | `passed`; no implementation or behavior change |
| `2026-07-30` | `FSMGEN-HIR-ROADMAP-FRONTIER.3` activation | documentation audits; Knowledge Map; memory architecture; `mdbook build docs/book`; output cleanup; diff hygiene; `scripts/check_doctrines.sh` | `passed`; continuity-only |
| `2026-07-30` | `FSMGEN-HIR-ROADMAP-FRONTIER.3` contract | fixture line/byte/SHA oracle; documentation audits; Knowledge Map; memory architecture; `mdbook test docs/book`; `mdbook build docs/book`; output cleanup; diff hygiene; `scripts/check_doctrines.sh` | `passed`; exact private contract only |
| `2026-07-30` | `FSMGEN-HIR-ROADMAP-FRONTIER.4` activation | documentation audits; Knowledge Map; memory architecture; `mdbook build docs/book`; output cleanup; diff hygiene; `scripts/check_doctrines.sh` | `passed`; continuity-only |
| `2026-07-30` | `FSMGEN-HIR-ROADMAP-FRONTIER.4` implementation | t1547 plus current forward-IR/contract/valid-ready baseline; four syntax checks; documentation audits; Knowledge Map; memory architecture; `mdbook test docs/book`; `mdbook build docs/book`; output cleanup; diff hygiene; staged `scripts/check_doctrines.sh` | `passed`; private golden path only |
| `2026-07-30` | `FSMGEN-HIR-ROADMAP-FRONTIER.5` activation | documentation audits; Knowledge Map; memory architecture; `mdbook test docs/book`; `mdbook build docs/book`; output cleanup; diff hygiene; staged `scripts/check_doctrines.sh` | `passed`; continuity-only |
| `2026-07-30` | `FSMGEN-HIR-ROADMAP-FRONTIER.5` audit | t1547; read-only candidate strict/schedule probes; implementation-reference census; documentation audits; Knowledge Map; memory architecture; `mdbook test docs/book`; `mdbook build docs/book`; output cleanup; diff hygiene; staged `scripts/check_doctrines.sh` | `passed`; remain private and select second route |
| `2026-07-30` | `FSMGEN-HIR-ROADMAP-FRONTIER.6` activation | documentation audits; Knowledge Map; memory architecture; `mdbook test docs/book`; `mdbook build docs/book`; output cleanup; diff hygiene; staged `scripts/check_doctrines.sh` | `passed`; continuity-only |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `FSMGEN-HIR-ROADMAP-FRONTIER.1` | `FSMGEN-HIR-ROADMAP-FRONTIER.1: capture FSMGEN HIR roadmap phase` | Captures the HIR roadmap phase; no compiler behavior changed. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.2` | `FSMGEN-HIR-ROADMAP-FRONTIER.2: activate source-facing HIR boundary` | Continuity-only activation; architecture selection follows after this commit is clean. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.2` | `FSMGEN-HIR-ROADMAP-FRONTIER.2: select private SourceHIR boundary` | Selects the complete IR-policy boundary, first internal builder, and valid-ready golden without implementation. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.3` | `pending` | Proposed exact-contract leaf; not active during `.2`. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.3` | `FSMGEN-HIR-ROADMAP-FRONTIER.3: activate SourceHIR v1 contract` | Continuity-only activation after the clean architecture selection. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.3` | `FSMGEN-HIR-ROADMAP-FRONTIER.3: freeze SourceHIR v1 contract` | Freezes the exact private contract and test oracle without implementation. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.4` | `pending` | Proposed private implementation leaf. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.4` | `FSMGEN-HIR-ROADMAP-FRONTIER.4: activate private SourceHIR implementation` | Continuity-only activation after the clean v1 contract. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.4` | `FSMGEN-HIR-ROADMAP-FRONTIER.4: implement private SourceHIR golden path` | Implements only the private three-package/t1547 contract. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.5` | `pending` | Proposed evidence-based promotion/retirement audit. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.5` | `FSMGEN-HIR-ROADMAP-FRONTIER.5: activate SourceHIR promotion audit` | Continuity-only activation after the clean private prototype. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.5` | `FSMGEN-HIR-ROADMAP-FRONTIER.5: keep SourceHIR private through IAL1 proof` | Retains the healthy prototype privately and selects a second lowering-route proof before promotion. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.6` | `FSMGEN-HIR-ROADMAP-FRONTIER.6: activate private SourceHIR IAL1 selection` | Continuity-only activation after the clean post-prototype audit. |

## Changelog

- `2026-06-28`: Captured FSMGEN HIR as a critical proposed roadmap phase above
  IAL2 and IAL1, with activation gated on an IR-policy-compliant boundary
  selection leaf.
- `2026-07-30`: Selected distinct private `SourceHIR`, canonical PPIF
  rendering through the existing parser, an internal Perl builder, and the
  byte-identical protocol-neutral valid-ready golden. No implementation or
  public behavior changed.
- `2026-07-30`: Activated `.3` continuity-only after clean architecture
  selection; exact contract and implementation remain unchanged.
- `2026-07-30`: Froze the exact private v1 object/API/provenance/diagnostic/
  renderer/test contract and golden hash without implementation.
- `2026-07-30`: Activated `.4` continuity-only after the clean v1 contract;
  implementation and behavior remain unchanged.
- `2026-07-30`: Implemented and proved the private SourceHIR valid-ready
  golden path without advertising or changing any public surface.
- `2026-07-30`: Activated `.5` continuity-only for evidence-based promotion,
  continued-private, or retirement selection.
- `2026-07-30`: Kept SourceHIR private, rejected retirement and premature
  promotion, and selected proposed `.6`/`.7`/`.8` for concrete IAL1 design,
  implementation, and the next promotion audit.
- `2026-07-30`: Activated `.6` continuity-only for exact private
  concrete-control-to-IAL1 boundary selection.

## Acceptance Checklist (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Baseline `./bin/fsmgen --strict --check --json ppif/valid_ready_handshake.ppif` and `./bin/fsmgen --emit-schedule-json ppif/valid_ready_handshake.ppif` succeed only after the hand-written PPIF text enters `FSM::Adapter::IAL2::PPIF->parse_source`; source inspection locates that text-to-generator handoff at `perl/FSM/Adapter/IAL2/PPIF.pm` and confirms there was no pre-IAL structured producer.
- [x] **ADDRESSED (verified)** — `prove -Iperl t/1547-source-hir-valid-ready.t` reports `Files=1, Tests=9` and proves the closed private object/builder/renderer, exact 14-line/428-byte/SHA golden, provenance diagnostics, parser re-entry, ordered variants, and equal downstream artifacts/reports.
- [x] **NO REGRESSION** — `prove -Iperl t/1547-source-hir-valid-ready.t t/155-forward-intent-hir-surface.t t/156-forward-lowered-rtl-ir-surface.t t/163-forward-structural-rtl-ir-surface.t t/334-normalized-semantic-forward-ir-contract.t t/339-normalized-semantic-intent-hir-contract.t t/1435-axi-ial2-valid-ready-generator.t` reports `All tests successful` and `Files=7, Tests=21`; all new Perl/test files report `syntax OK`, and the staged doctrine driver reports `[doctrine] all doctrine checks passed`.
