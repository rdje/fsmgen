# ISF-PUBLIC-CONTRACT: Spec, Book, Manifest, And Contract Synchronization

## Metadata

- Tree ID: `ISF-PUBLIC-CONTRACT`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Keep the ISF written specification, mdBook chapters, public interface contract,
capability-manifest advertisement, tests, and live docs synchronized as
features ship, without restarting standalone public-interface audit work as the
primary R14 focus.

## Non-Goals

- Do not select standalone contract-audit expansion ahead of feature delivery
  unless a shipped feature requires it.
- Do not promise the whole schedule JSON schema as frozen; that belongs to
  `ISF-SCHEDULE-REPORTS`.
- Do not duplicate each feature tree's technical implementation details here.

## Acceptance Criteria

- Current ISF documentation/contract owners and required sync points are
  inventoried.
- A reusable feature-slice synchronization checklist exists and is referenced
  by ISF task trees.
- Feature-driven public contract changes update code, docs, manifest metadata,
  and tests in the same slice.
- Live docs record status transitions without duplicating full task trees.
- Any intentional public-contract deferral is listed in the feature backlog or
  owning task tree with consequence and unblock condition.

## Task Tree

- ID: `ISF-PUBLIC-CONTRACT`
  Status: `active`
  Goal: `Keep ISF specs, book, public contract, manifest, and tests synchronized.`
  Children: `ISF-PUBLIC-CONTRACT.1`, `ISF-PUBLIC-CONTRACT.2`,
  `ISF-PUBLIC-CONTRACT.3`, `ISF-PUBLIC-CONTRACT.4`,
  `ISF-PUBLIC-CONTRACT.5`, `ISF-PUBLIC-CONTRACT.6`,
  `ISF-PUBLIC-CONTRACT.7`

- ID: `ISF-PUBLIC-CONTRACT.1`
  Status: `pending`
  Goal: `Inventory current ISF public documentation and contract owners.`
  Acceptance: `The task file lists ISF spec sections, mdBook chapters,
  manifest/contract modules, public tests, and live-doc touchpoints.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-PUBLIC-CONTRACT.2`
  Status: `pending`
  Goal: `Define reusable ISF feature-slice synchronization checklist.`
  Acceptance: `The tree records what every ISF feature slice must inspect and
  update across spec, book, contract module, manifest, tests, roadmap, and live
  docs.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-PUBLIC-CONTRACT.3`
  Status: `pending`
  Goal: `Apply checklist to active ISF task trees.`
  Acceptance: `Active ISF trees reference or incorporate the synchronization
  checklist in their acceptance criteria without duplicating it excessively.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-PUBLIC-CONTRACT.4`
  Status: `pending`
  Goal: `Add or adjust tests/docs for feature-driven public contract changes.`
  Acceptance: `When a feature changes public ISF behavior, the matching public
  contract and manifest tests move in the same feature slice.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-PUBLIC-CONTRACT.5`
  Status: `done`
  Goal: `Record the construct shipping invariant.`
  Acceptance: `The ISF book, spec, and public contract state that every
  current or future construct needs an explicit source shape, lowering path,
  runtime semantic, diagnostics boundary, downstream visibility contract, and
  regression evidence before it is considered shipped.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-PUBLIC-CONTRACT.5: document construct semantics invariant`

- ID: `ISF-PUBLIC-CONTRACT.6`
  Status: `done`
  Goal: `Record IAL0/IAL1 terminology and IAL2 criteria.`
  Acceptance: `The ISF book, spec, public contract, and backlog state that
  .fsm is IAL0, current .isf is IAL1, and any possible IAL2 requires a real
  protocol/platform semantic level rather than aliases, macros, or syntax
  sugar without a distinct runtime model.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-PUBLIC-CONTRACT.6: document intent abstraction layers`

- ID: `ISF-PUBLIC-CONTRACT.7`
  Status: `done`
  Goal: `Clarify the transaction-port authoring boundary in the book.`
  Acceptance: `The mdBook explains that transaction-port connectivity is an
  ergonomic ISF authoring surface that lowers into explicit scheduled .fsm
  handoff wiring, not a request for authors to write generated payload wires
  or generated-top bridge nets directly; companion spec/contract wording is
  kept aligned with the shipped port-binding surface.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-PUBLIC-CONTRACT.7: clarify port binding authoring boundary`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-PUBLIC-CONTRACT.1` | `pending` | The current ISF public-doc/contract owner set must be inventoried before a reusable sync checklist is made normative. |

## Decisions

- `2026-05-14`: This tree is cross-cutting and feature-driven. It should not
  displace public-facing ISF feature work unless the selected feature changes a
  public surface.
- `2026-05-14`: Parser acceptance is not a support claim for ISF. A construct
  is shipped only when source shape, lowering, runtime semantics, diagnostics,
  downstream visibility, and regression evidence are all explicit.
- `2026-05-14`: FSMGen uses IAL terminology for intent levels: `.fsm` is
  IAL0, current `.isf` is IAL1, and IAL2 remains an exploration topic only for
  real protocol/platform semantics above transactions.

## Open Questions

- Should the synchronization checklist live only in this task tree, or also in
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` once it is mature?
- Which public contract tests should be required for every feature slice versus
  only for schedule-report or facade changes?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-PUBLIC-CONTRACT` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-PUBLIC-CONTRACT.5` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-PUBLIC-CONTRACT.5` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-PUBLIC-CONTRACT.6` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-PUBLIC-CONTRACT.6` | `git diff --check` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.7` | `mdbook build docs/book` | `passed` |
| `2026-05-15` | `ISF-PUBLIC-CONTRACT.7` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-PUBLIC-CONTRACT` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-PUBLIC-CONTRACT.5` | `ISF-PUBLIC-CONTRACT.5: document construct semantics invariant` | Records that every shipped ISF construct must have explicit source, lowering, runtime, diagnostic, visibility, and regression semantics. |
| `ISF-PUBLIC-CONTRACT.6` | `ISF-PUBLIC-CONTRACT.6: document intent abstraction layers` | Records `.fsm` as IAL0, current `.isf` as IAL1, and the criteria/backlog for possible IAL2 exploration. |
| `ISF-PUBLIC-CONTRACT.7` | `ISF-PUBLIC-CONTRACT.7: clarify port binding authoring boundary` | Records that transaction-port connectivity is authored in ISF and lowered to reviewable `.fsm` handoff wiring. |

## Changelog

- `2026-05-14`: Created the active ISF public-contract synchronization task tree.
- `2026-05-14`: Completed `ISF-PUBLIC-CONTRACT.5` as a documentation-only
  invariant; current frontier remains `ISF-PUBLIC-CONTRACT.1`.
- `2026-05-14`: Completed `ISF-PUBLIC-CONTRACT.6` as a documentation-only
  terminology/backlog slice; current frontier remains `ISF-PUBLIC-CONTRACT.1`.
- `2026-05-15`: Completed `ISF-PUBLIC-CONTRACT.7` as a documentation-only
  port-binding authoring-boundary clarification; current frontier remains
  `ISF-PUBLIC-CONTRACT.1`.
