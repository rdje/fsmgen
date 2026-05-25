# ISF-ATL-COMPACT-INSTANCE-ALIAS: ATL Compact Static Instance Alias

## Metadata

- Tree ID: `ISF-ATL-COMPACT-INSTANCE-ALIAS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Ship the compact ATL static-instance alias as a semantics-preserving
readability form for the already shipped verbose static actor instance
declaration.

The selected source shape is:

```lisp
(reader : packet_reader)
```

It must normalize to the same bounded static instance metadata as:

```lisp
(instance reader of packet_reader)
```

## Non-Goals

- Do not add new scheduling behavior for actor instances.
- Do not change actor type resolution, generated child emission, generated
  ATL top behavior, or library-qualified type semantics.
- Do not add a `(network ...)` wrapper, compact movement syntax, or route
  behavior.
- Do not change the verbose `(instance ...)` contract.

## Acceptance Criteria

- The selected compact alias is documented before code changes.
- `(NAME : ACTOR_TYPE)` is accepted only as a direct actor-body clause.
- `NAME` keeps the existing static instance HDL identifier checks.
- `ACTOR_TYPE` keeps the existing scalar HDL identifier or selected
  `ALIAS.EXPORT` type checks.
- The schedule report keeps the existing `actor_network.instances[]` shape and
  marks compact declaration provenance transparently for downstream review.
- Existing verbose instance behavior, diagnostics, and resolved-library
  metadata remain unchanged.
- ISF spec, downstream handoff if impacted, public contract if impacted, ATL
  design proposal, mdBook, roadmap, task tree, and live docs are synchronized
  with the shipped behavior and non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-COMPACT-INSTANCE-ALIAS`
  Status: `done`
  Goal: `ship compact ATL static instance alias`
  Children: `ISF-ATL-COMPACT-INSTANCE-ALIAS.1`,
  `ISF-ATL-COMPACT-INSTANCE-ALIAS.2`

- ID: `ISF-ATL-COMPACT-INSTANCE-ALIAS.1`
  Status: `done`
  Goal: `select the compact ATL static instance alias task tree`
  Acceptance: `task-tree owner, source shape, boundaries, and implementation leaf are recorded before code changes`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `6245e321 ISF-ATL-COMPACT-INSTANCE-ALIAS.1: select compact ATL instance alias`

- ID: `ISF-ATL-COMPACT-INSTANCE-ALIAS.2`
  Status: `done`
  Goal: `implement compact static instance alias normalization and coverage`
  Acceptance: `compact static instances lower to the same static actor instance metadata surface as verbose instances while preserving transparent declaration provenance and fail-closed boundaries`
  Verification: `parser/public-contract/test syntax checks`; `prove -Iperl t/1322-isf-actor-network-static.t`; public/doc audit group; ATL fixture group; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ff958c55 ISF-ATL-COMPACT-INSTANCE-ALIAS.2: ship compact ATL instance alias`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Compact static instance aliases are shipped; the next PNT selection should use the roadmap/task-tree frontier outside this tree. |

## Decisions

- `2026-05-22`: Selected `(NAME : ACTOR_TYPE)` as an alias only for verbose
  `(instance NAME of ACTOR_TYPE)`.
- `2026-05-22`: Selected transparent report provenance for compact instances;
  the implementation leaf should preserve existing instance metadata and add a
  distinct declaration spelling for downstream review.

## Open Questions

- None blocking the selected bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-COMPACT-INSTANCE-ALIAS.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-22` | `ISF-ATL-COMPACT-INSTANCE-ALIAS.2` | `parser/public-contract/test syntax checks`; `prove -Iperl t/1322-isf-actor-network-static.t`; public/doc audit group; ATL fixture group; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-COMPACT-INSTANCE-ALIAS.1` | `6245e321 ISF-ATL-COMPACT-INSTANCE-ALIAS.1: select compact ATL instance alias` | Selection commit. |
| `ISF-ATL-COMPACT-INSTANCE-ALIAS.2` | `ff958c55 ISF-ATL-COMPACT-INSTANCE-ALIAS.2: ship compact ATL instance alias` | Implementation commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the compact static
  instance alias implementation sequence.
- `2026-05-22`: Shipped the compact alias as static actor instance metadata
  with `declaration: "instance_alias"` provenance and closed the task tree.
