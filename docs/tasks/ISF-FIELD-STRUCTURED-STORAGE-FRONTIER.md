# ISF-FIELD-STRUCTURED-STORAGE-FRONTIER: ISF Declarative Field-Structured Storage

## Metadata

- Tree ID: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER`
- Status: `active`
- Roadmap lane: `R14 / ISF storage metadata`
- Created: `2026-06-22`
- Last updated: `2026-06-22`
- Owner: repo-local workflow

## Goal

Select and implement a checked ISF surface for declarative named bit-fields
on storage/register-like scalar words and, if selected later, packet or
structure layouts.

## Non-Goals

- Do not change parser, scheduler, lowerer, generated `.fsm`, HDL,
  schedule JSON, semantic JSON, support accounting, tests, docs, or public
  contracts before an exact leaf owns that slice.
- Do not use runtime operations (`set-field`, `when-field`, `extract`,
  `assemble`) as a substitute for static field-map declarations.
- Do not infer undocumented reserved fields, access semantics, reset behavior,
  enum/type relationships, packet layouts, generated verification output, or
  HDL register models without an exact owner and regression-backed contract.
- Do not edit the SPECFORGE repository.

## Acceptance Criteria

- The first leaf audits the current ISF storage, aggregate, field-operation,
  reset, report, semantic JSON, support-accounting, mdBook, and downstream
  contract surfaces and selects the first implementation boundary.
- The selected first behavior slice, if any, records exact syntax,
  validation rules, normalized report/semantic projection, residue, tests,
  docs, and rollback before code changes.
- Any implementation leaf is checked metadata or generated behavior only as
  explicitly selected by the prior leaf.
- mdBook, downstream handoff docs, README, task-tree state, Memory, and
  Knowledge Map stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER`
  Status: `active`
  Goal: `Make ISF capable of carrying checked declarative named bit-field maps for storage/register-like words.`
  Children: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1`

- ID: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1`
  Status: `pending`
  Goal: `Audit readiness and select the first declarative field-structured storage contract.`
  Acceptance: `Read SPECFORGE's 2026-06-22 field-structured storage request; current ISF storage parser/scheduler/lowerer/report/semantic surfaces; actor-owned scalar and aggregate storage docs/tests; register reset values; runtime field operations set-field/when-field/extract/assemble; support-accounting fixtures; mdBook and downstream integration docs. Decide whether the first slice should be metadata-only scalar storage fields, reset-composition validation, enum/access metadata, aggregate/packet layout generalization, or a prerequisite cleanup. Record exact syntax, fail-closed validation, report and semantic JSON shape, docs/tests, explicit residue, and rollback before any behavior change.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1` | `pending` | SPECFORGE's request identified a real representational gap; the first safe step is a readiness/contract audit before parser or lowering changes. |

## Decisions

- `2026-06-22`: FSMGen accepts declarative field-structured storage as a
  directionally valid ISF feature request, but not as shipped behavior.
  Existing runtime field operations remain behavior, not static field-map
  metadata.
- `2026-06-22`: The first executable step is a readiness/contract audit. It
  must settle whether the first implementation is metadata-only, whether
  complete tiling is required or explicit reserved/gap metadata is allowed,
  how field resets relate to `(var ... (reset V))`, how enum/access metadata
  is represented, and how report/semantic JSON surfaces publish the result.

## Open Questions

- Should first-slice field ranges be required to tile the whole storage word,
  or may explicit gaps/reserved fields be represented without inferred names?
- Are field-level resets metadata-only in the first slice, or may a complete
  non-conflicting field reset map derive or validate storage reset behavior?
- Should enum values be inline field metadata, a reference to actor-local
  `(enums ...)`, or both?
- Is packet/structure layout generalization part of the first public syntax
  or a later sibling after scalar storage fields ship?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-22` | `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1` | `pending` | `pending` |

## Changelog

- `2026-06-22`: Created the implementation frontier selected by
  `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.2`.
