# ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA: Transaction Port Binding Timing Request Metadata

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Expose the authored timing assertion mode for transaction input bindings in
`transaction_port_bindings[]` reports, without changing binding timing,
generated `.fsm`, HDL, schedule-report schema version, or runtime behavior.

## Non-Goals

- Do not add behavior-changing snapshot/live timing conversion.
- Do not change the meaning of existing `binding_timing` report metadata.
- Do not add direct/local rule-trigger output bindings.
- Do not add new report fields beyond the selected authored timing mode field
  in this tree.

## Acceptance Criteria

- The selected public report key is named `authored_timing_mode`.
- The field reports `snapshot` or `live` when an input binding explicitly
  spells `(timing snapshot)` or `(timing live)`.
- The field reports `null` for bindings without an explicit timing clause,
  including output bindings.
- Public contract metadata advertises the new key and the non-null value
  family.
- Specs, downstream handoff, mdBook, task tree, roadmap status, and live docs
  describe the shipped surface and non-claims when the implementation leaf
  lands.
- Focused report/public-contract validation passes; broader ISF validation
  runs when the implementation blast radius warrants it.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA`
  Status: `active`
  Goal: `Expose authored timing assertion metadata without changing binding semantics.`
  Children: `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.1`,
  `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.2`

- ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.1`
  Status: `done`
  Goal: `Select the public authored timing mode report key and value boundary.`
  Acceptance: `The task tree, roadmap, live docs, and mdBook feature backlog select authored_timing_mode plus the snapshot/live/null value boundary while leaving implementation as the next frontier.`
  Verification: `feature-backlog/live-book/book matrix audits; mdBook build; git diff --check`
  Commit: `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.1: select authored timing metadata`

- ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.2`
  Status: `pending`
  Goal: `Implement and document authored_timing_mode report metadata.`
  Acceptance: `Every transaction_port_bindings[] entry carries authored_timing_mode as snapshot/live/null; public contract metadata and downstream/user docs are synchronized; timing behavior remains unchanged.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.2` | `pending` | Selection leaf is complete; implementation is the next bounded R14 report metadata slice. |

## Decisions

- `2026-05-25`: Use `authored_timing_mode` instead of overloading
  `binding_timing`. `binding_timing` reports the actual shipped transfer
  class, while `authored_timing_mode` reports whether source explicitly
  asserted `snapshot` or `live`.
- `2026-05-25`: Use JSON `null` for bindings without an explicit timing
  clause, including output bindings. This keeps every report entry shape
  stable while preserving the difference between "not authored" and an
  authored mode.
- `2026-05-25`: Keep behavior-changing timing conversion outside this tree.
  The selected field is observability only.

## Open Questions

- None for the selected frontier. Behavior-changing timing conversion remains
  a separate backlog item.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.1` | `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.1: select authored timing metadata` | `selection commit` |
| `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.2` | `pending` | `pending implementation` |

## Changelog

- `2026-05-25`: Created active task tree and completed the selection leaf for
  authored timing mode report metadata.
