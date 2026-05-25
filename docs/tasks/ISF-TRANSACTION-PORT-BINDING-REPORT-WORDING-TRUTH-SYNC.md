# ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC: Binding Report Wording Truth Sync

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Clarify transaction-port binding report non-claim wording so it does not imply
that the already-shipped bounded `transaction_port_bindings[]` summary fields
are deferred.

## Non-Goals

- Do not change parser behavior, scheduler lowering, generated `.fsm`, HDL,
  schedule-report payloads, public contract code, or runtime behavior.
- Do not add new schedule-report fields.
- Do not freeze private `LoweringIR` binding internals.

## Acceptance Criteria

- Public contract, feature matrix, and mdBook backlog wording all distinguish
  the shipped bounded binding-summary field set from deferred future report
  expansions.
- The wording names the already-shipped base fields including `actor_signal`,
  `actor_expression`, endpoint kind, binding timing, and authored timing mode.
- Live docs, README task index, roadmap status, and task tree record the
  documentation-only boundary.
- Focused public-doc/book validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC`
  Status: `done`
  Goal: `Clarify binding report backlog wording.`
  Children: `ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.1`

- ID: `ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Synchronize user-facing binding report non-claims with shipped fields.`
  Acceptance: `Docs no longer imply shipped binding-summary fields are deferred.`
  Verification: `public contract/spec/book audits; mdBook build; git diff --check`
  Commit: `ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.1: clarify binding report wording`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Treat this as documentation truth synchronization only. The
  public key set is already defined by
  `schedule_report_transaction_port_binding_keys`; this slice only clarifies
  wording around future report expansions.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.1` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.1` | `ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.1: clarify binding report wording` | `documentation truth-sync commit` |

## Changelog

- `2026-05-25`: Created and completed the binding-report wording truth-sync
  tree.
