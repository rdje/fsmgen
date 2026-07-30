# FSMGEN-HIR-ROADMAP-FRONTIER: Source-Facing HIR Roadmap Frontier

## Metadata

- Tree ID: `FSMGEN-HIR-ROADMAP-FRONTIER`
- Status: `proposed`
- Roadmap lane: `architecture / high-level frontend IR`
- Created: `2026-06-28`
- Last updated: `2026-06-28`
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
  Status: `proposed`
  Goal: `Own the source-facing FSMGEN HIR roadmap phase above IAL2 and IAL1.`
  Children: `FSMGEN-HIR-ROADMAP-FRONTIER.1`, `FSMGEN-HIR-ROADMAP-FRONTIER.2`

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER.1`
  Status: `done`
  Goal: `Capture the FSMGEN HIR roadmap phase and activation criteria.`
  Acceptance: `Record the HIR concept as a critical task-tree-owned roadmap phase, preserve the direct-lowering-versus-HIR architecture rationale, name the first activation leaf, sync roadmap/task-tree/Memory/Knowledge Map/book surfaces, and confirm no code, parser, source, generated-artifact, config, or behavior change occurs.`
  Verification: `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; `scripts/check_doctrines.sh`
  Commit: `FSMGEN-HIR-ROADMAP-FRONTIER.1: capture FSMGEN HIR roadmap phase`

- ID: `FSMGEN-HIR-ROADMAP-FRONTIER.2`
  Status: `proposed`
  Goal: `Select the first source-facing HIR architecture boundary.`
  Acceptance: `Audit docs/IR_POLICY.md, docs/tasks/FSMGEN-IR-AUDIT.md, existing IntentHIR/LoweredRTLIR/StructuralRTLIR owners, IAL1 and IAL2 public source surfaces, normalized semantic/report contracts, and IAL2-HOST-LANGUAGE-BUILDER-FRONTIER. Decide whether the first source-facing HIR should extend an existing IntentHIR-adjacent layer, create a new named surface, or remain a textual IAL handoff for the first prototype. Define producers, consumers, invariants, mutation policy, public/private status, source-span diagnostics, validation, docs impact, migration/retirement rules, first exact frontend or builder, and first golden fixture. No implementation begins in this leaf unless split into a later active implementation leaf.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

Parent selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.841` selects `.2` as the
next exact no-behavior architecture owner. The tree and leaf remain proposed
until that selector commits cleanly and a separate continuity commit activates
them. The first activation leaf is deliberately a design selection leaf because
the HIR must satisfy the repo IR policy before source or compiler behavior
changes.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `FSMGEN-HIR-ROADMAP-FRONTIER.1` | `done` | Captured the roadmap phase and activation criteria without behavior changes. |
| 2 | `FSMGEN-HIR-ROADMAP-FRONTIER.2` | `proposed` | Select the first exact source-facing HIR boundary before implementation. |

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

## Open Questions

- Should the first source-facing HIR reuse or extend the current
  `FSM::IR::IntentHIR`, or should it be a separate HIR that lowers into
  `IntentHIR`/IAL2/IAL1?
- What is the safest first frontend or builder: a constrained embedded DSL, a
  host-language builder API, or a small standalone source language?
- What first golden fixture best proves value: a protocol-neutral valid-ready
  source, a simple APB completer, or a small concrete FSM/control example?
- How should source spans and diagnostics map from frontend source through HIR
  to IAL2/IAL1 and generated artifacts?
- What public projection, if any, should expose HIR facts without exporting raw
  private compiler objects?

## Blockers

- Not blocked. It is intentionally proposed until selected by roadmap or user
  priority. Activation may start incrementally once `.2` can choose one exact
  boundary and one exact fixture.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-28` | `FSMGEN-HIR-ROADMAP-FRONTIER.1` | `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; `scripts/check_doctrines.sh` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `FSMGEN-HIR-ROADMAP-FRONTIER.1` | `FSMGEN-HIR-ROADMAP-FRONTIER.1: capture FSMGEN HIR roadmap phase` | Captures the HIR roadmap phase; no compiler behavior changed. |
| `FSMGEN-HIR-ROADMAP-FRONTIER.2` | `pending` | Proposed first activation/design-selection leaf. |

## Changelog

- `2026-06-28`: Captured FSMGEN HIR as a critical proposed roadmap phase above
  IAL2 and IAL1, with activation gated on an IR-policy-compliant boundary
  selection leaf.
