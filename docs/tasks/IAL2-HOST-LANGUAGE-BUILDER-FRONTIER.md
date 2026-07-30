# IAL2-HOST-LANGUAGE-BUILDER-FRONTIER: IAL2 Host-Language Builder Frontier

## Metadata

- Tree ID: `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER`
- Status: `proposed`
- Roadmap lane: `IAL2 horizon exploration / authoring ergonomics`
- Created: `2026-06-28`
- Last updated: `2026-07-31`
- Owner: repo-local workflow

## Goal

Track the idea that IAL2/IAL1 can act like lower-level assembly languages for
higher-level, host-language construction APIs that build explicit protocol and
state-machine IR before emitting normal IAL2 or IAL1 sources.

## Non-Goals

- Do not pivot active IAL2/APB feature-completeness work.
- Do not implement a Python, Perl, Julia, C, or other host-language package in
  this capture.
- Do not compile arbitrary host-language control flow into hardware or IAL.
- Do not infer hardware from ordinary software semantics.
- Do not bypass the existing parser, validation, `IAL2 -> IAL1 -> IAL0`, or
  `IAL1 -> IAL0` lowering chains.
- Do not accept generated IAL2/IAL1 that lacks stable names, source locations,
  deterministic output, validation diagnostics, and golden equivalence evidence.
- Do not assume direct IAL2/IAL1 emission is the final architecture now that
  `FSMGEN-HIR-ROADMAP-FRONTIER` owns the source-facing HIR direction.

## Acceptance Criteria

- The higher-level-host-language idea is durably captured as a proposed
  task-tree owner rather than living only in session chat.
- Future activation starts with a design/selection leaf, not implementation.
- The first activation leaf decides the intended builder model, canonical
  in-memory AST/schema boundary, first host language, first exact fixture, and
  non-goals before source changes.
- Any later implementation leaf emits ordinary checked IAL2 or IAL1 artifacts
  and proves equivalence against existing hand-written fixtures.
- Each completed active leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER`
  Status: `proposed`
  Goal: `Track host-language builder APIs that construct explicit IAL2 or IAL1 IR rather than compiling arbitrary software.`
  Children: `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.1`

- ID: `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.1`
  Status: `proposed`
  Goal: `Select the first host-language builder contract and prototype boundary.`
  Acceptance: `Decide whether the first target is IAL2 or IAL1 emission, define the canonical in-memory object model boundary, choose one host language and one existing public fixture to reproduce exactly, name required diagnostics/source-location/golden-equivalence evidence, and record explicit non-goals for arbitrary host-language compilation. No implementation begins in this leaf unless it is split into a later active implementation leaf.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed and not PNT-eligible until the roadmap or user explicitly
activates it. The first activation should select the design contract before any
package, module, parser, source, or generated-artifact implementation work.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.1` | `proposed` | Decide the builder model and first exact prototype target before implementation. |

## Decisions

- `2026-06-28`: Capture the "IAL1/IAL2 as assembly language" idea as feasible
  only when the host language is a constrained construction API or embedded DSL
  that builds an explicit, static, inspectable IAL object graph. Arbitrary
  C/Python/Perl/Julia software compilation is not selected.
- `2026-06-28`: Prefer emitting IAL2 first for protocol-intent authoring, with
  IAL1 as a lower mechanical target when the intent layer has already been
  resolved.
- `2026-06-28`: Dynamic host-language features may be used only at generation
  time. The emitted object graph must be deterministic, validated, named, and
  reviewable before lowering.
- `2026-06-28`: `FSMGEN-HIR-ROADMAP-FRONTIER` supersedes direct-to-IAL builder
  assumptions as the preferred long-term architecture for multiple high-level
  frontends. Host-language builder activation should consult the HIR boundary
  selection before choosing direct IAL2 or IAL1 emission.
- `2026-07-30`: Parent selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.841`
  selects the prerequisite source-facing HIR boundary. This builder remains
  proposed and does not activate implicitly.
- `2026-07-30`: `FSMGEN-HIR-ROADMAP-FRONTIER.2` selects a private internal
  Perl `SourceHIRBuilder` prototype, not a public Perl API. This tree still
  owns later selection of any supported host language, ergonomic package,
  compatibility/versioning contract, and public promotion.
- `2026-07-30`: Private SourceHIR v1 is implemented and proved against the
  valid-ready golden. It remains an internal Perl construction path; this tree
  is still proposed and no public language/package is implied.
- `2026-07-30`: SourceHIR post-prototype audit `.5` keeps the boundary private
  through a second concrete-control-to-IAL1 proof. This tree remains proposed
  and still solely owns any later public language, package, versioning, and
  compatibility selection; the second private route will not activate it.
- `2026-07-30`: HIR `.6` selects a private semantic concrete-control-to-IAL1
  contract and phase-test golden. This tree remains proposed: the internal
  second route selects no supported host language, package, version, or public
  compatibility promise.
- `2026-07-31`: Parent selector `.844` selects the HIAL/VIAL architecture audit
  first. Decision `0031` keeps any supported producer/public projection an
  independent future choice; this builder remains proposed and inactive.

## Open Questions

- Which host language should be first if this activates: Python for user-facing
  ergonomics, Perl for in-repo proximity, Julia for generated-design workflows,
  or C only if a C-based generator audience is proven?
- Should the first prototype emit `.ppif`/IAL2 only, or also allow a direct
  IAL1 builder for already-lowered state-machine surfaces?
- Which existing fixture is the safest golden target: a simple APB completer, a
  sideband data16 APB fixture, or a protocol-neutral valid-ready source?
- What exact schema/API boundary prevents the builder from drifting into an
  unreviewable second frontend?

## Blockers

- Not blocked. It is intentionally proposed until selected by roadmap/user
  priority.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-28` | `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.1` | `pending` | Proposed design-selection leaf only; no implementation selected. |

## Changelog

- `2026-06-28`: Created proposed task tree to preserve the host-language builder
  idea for future selection.
