# ISF-PUBLIC-CONTRACT: Spec, Book, Manifest, And Contract Synchronization

## Metadata

- Tree ID: `ISF-PUBLIC-CONTRACT`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
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
  `ISF-PUBLIC-CONTRACT.3`, `ISF-PUBLIC-CONTRACT.4`

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

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-PUBLIC-CONTRACT.1` | `pending` | The current ISF public-doc/contract owner set must be inventoried before a reusable sync checklist is made normative. |

## Decisions

- `2026-05-14`: This tree is cross-cutting and feature-driven. It should not
  displace public-facing ISF feature work unless the selected feature changes a
  public surface.

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-PUBLIC-CONTRACT` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |

## Changelog

- `2026-05-14`: Created the active ISF public-contract synchronization task tree.
