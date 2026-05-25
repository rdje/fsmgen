# ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA: Transaction Port Binding Timing Metadata

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Expose bounded public timing metadata for each shipped
`transaction_port_bindings[]` entry so downstream users can tell whether a
binding is an activation-region copy, a generated-top live handoff, a
rule-trigger payload capture, or a done-guarded output copy.

## Non-Goals

- Do not add new binding timing syntax in this tree.
- Do not change default binding timing, `.fsm` lowering, HDL generation, or
  runtime behavior.
- Do not add direct/local rule-trigger output bindings.
- Do not expose raw `LoweringIR` assignment internals as public report API.

## Acceptance Criteria

- The selected public report key is named `binding_timing`.
- The selected value family is bounded to `activation_region`,
  `generated_live_handoff`, `trigger_payload`, and `done_guarded`.
- The implementation reports `binding_timing` for every
  `transaction_port_bindings[]` entry without changing existing timing.
- Public contract metadata advertises the new key and value family.
- Specs, downstream handoff, mdBook, task tree, roadmap status, and live docs
  describe the shipped surface and non-claims.
- Focused report/public-contract validation passes; broader ISF validation
  runs when the implementation blast radius warrants it.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA`
  Status: `active`
  Goal: `Expose bounded public binding timing metadata without changing binding semantics.`
  Children: `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.1`,
  `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.2`

- ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.1`
  Status: `done`
  Goal: `Select the public binding timing report key and bounded values.`
  Acceptance: `The task tree, roadmap, live docs, and mdBook feature backlog select binding_timing plus the four bounded value names while leaving implementation as the next frontier.`
  Verification: `feature-backlog/live-book/book matrix audits; mdBook build; git diff --check`
  Commit: `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.1: select binding timing metadata`

- ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.2`
  Status: `pending`
  Goal: `Implement and document binding_timing report metadata.`
  Acceptance: `Every transaction_port_bindings[] entry carries binding_timing with one advertised value, existing report keys/tests are updated, timing behavior remains unchanged, and docs/book/public contract describe the field.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.2` | `pending` | Selection leaf is complete; implementation is the next bounded R14 report-metadata slice. |

## Decisions

- `2026-05-25`: Use `binding_timing` as the public report key. It names the
  transfer timing class for the entry, not the private source kind or DT name.
- `2026-05-25`: Use four value names:
  `activation_region` for same activation-region copies,
  `generated_live_handoff` for generated-top handoff wiring,
  `trigger_payload` for rule-trigger input payload capture/fan-in, and
  `done_guarded` for output copies guarded by child completion or trigger done
  observation.
- `2026-05-25`: Do not add author-facing snapshot/live syntax in this tree.
  This tree first makes current timing reviewable and report-visible.

## Open Questions

- None for the selected frontier. Explicit source syntax for choosing
  snapshot-vs-live timing remains a later behavior-bearing tree.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.1` | `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.1: select binding timing metadata` | `selection commit` |
| `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.2` | `pending` | `pending implementation` |

## Changelog

- `2026-05-25`: Created active task tree and completed the selection leaf for
  bounded transaction-port binding timing report metadata.
