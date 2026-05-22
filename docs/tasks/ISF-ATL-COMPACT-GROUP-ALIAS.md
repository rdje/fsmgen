# ISF-ATL-COMPACT-GROUP-ALIAS: ATL Compact Concurrent Group Alias

## Metadata

- Tree ID: `ISF-ATL-COMPACT-GROUP-ALIAS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Ship the reserved compact ATL concurrent-group alias as a semantics-preserving
readability form for the already shipped verbose static group declaration.

The selected source shape is:

```lisp
(concurrent pipeline reader filter writer)
```

It must normalize to the same bounded report-only group metadata as:

```lisp
(group pipeline
  (members reader filter writer)
  (mode concurrent))
```

## Non-Goals

- Do not add new scheduling behavior for groups.
- Do not make group membership permanent runtime coupling beyond existing
  report-only metadata.
- Do not add group endpoints, group-level trigger scheduling, compact
  movement syntax, or generated HDL group behavior.
- Do not change the verbose `(group ...)` contract.

## Acceptance Criteria

- The selected compact alias is documented before code changes.
- `(concurrent NAME ACTOR...)` is accepted only as a direct actor-body clause.
- `NAME` and every actor member keep the existing HDL identifier and declared
  static actor checks.
- At least two actor members are required, matching the verbose group surface.
- The schedule report keeps the existing `actor_network.groups[]` shape and
  marks the declaration spelling transparently enough for downstream review.
- Existing verbose group behavior and diagnostics remain unchanged.
- ISF spec, downstream handoff if impacted, public contract if impacted, ATL
  design proposal, mdBook, roadmap, task tree, and live docs are synchronized
  with the shipped behavior and non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-COMPACT-GROUP-ALIAS`
  Status: `done`
  Goal: `ship compact ATL concurrent group alias`
  Children: `ISF-ATL-COMPACT-GROUP-ALIAS.1`,
  `ISF-ATL-COMPACT-GROUP-ALIAS.2`

- ID: `ISF-ATL-COMPACT-GROUP-ALIAS.1`
  Status: `done`
  Goal: `select the compact ATL concurrent group alias task tree`
  Acceptance: `task-tree owner, source shape, boundaries, and implementation leaf are recorded before code changes`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `8c67b523 ISF-ATL-COMPACT-GROUP-ALIAS.1: select compact ATL group alias`

- ID: `ISF-ATL-COMPACT-GROUP-ALIAS.2`
  Status: `done`
  Goal: `implement compact concurrent group alias normalization and coverage`
  Acceptance: `compact concurrent groups lower to the same report-only static group metadata surface as verbose groups while preserving transparent declaration provenance and fail-closed boundaries`
  Verification: `parser/public-contract/test syntax checks`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1332-isf-atl-doc-status-audit.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1328-isf-atl-trigger-wait-fixture-coverage.t t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Compact concurrent group aliases are shipped; the next PNT selection should use the roadmap/task-tree frontier outside this tree. |

## Decisions

- `2026-05-22`: Selected `(concurrent NAME ACTOR...)` as an alias only for
  verbose `(group NAME (members ACTOR...) (mode concurrent))`.
- `2026-05-22`: Kept group behavior report-only. Runtime group scheduling,
  group endpoints, group handoff routing, and compact movement syntax remain
  separate future work.

## Open Questions

- None blocking the selected bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-COMPACT-GROUP-ALIAS.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-22` | `ISF-ATL-COMPACT-GROUP-ALIAS.2` | `parser/public-contract/test syntax checks`; `prove -Iperl t/1322-isf-actor-network-static.t`; public/doc audit group; ATL fixture group; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-COMPACT-GROUP-ALIAS.1` | `8c67b523 ISF-ATL-COMPACT-GROUP-ALIAS.1: select compact ATL group alias` | Selection commit. |
| `ISF-ATL-COMPACT-GROUP-ALIAS.2` | `pending this commit: ISF-ATL-COMPACT-GROUP-ALIAS.2: ship compact ATL group alias` | Implementation commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the compact
  concurrent group alias implementation sequence.
- `2026-05-22`: Shipped the compact alias as report-only static group
  metadata with `declaration: "concurrent_alias"` provenance and closed the
  task tree.
