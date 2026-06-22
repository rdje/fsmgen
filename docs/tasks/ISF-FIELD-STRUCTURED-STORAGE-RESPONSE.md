# ISF-FIELD-STRUCTURED-STORAGE-RESPONSE: SPECFORGE Field-Structured Storage Response

## Metadata

- Tree ID: `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE`
- Status: `active`
- Roadmap lane: `Downstream ISF handoff / ISF storage metadata`
- Created: `2026-06-22`
- Last updated: `2026-06-22`
- Owner: repo-local workflow

## Goal

Answer SPECFORGE's `2026-06-22` feature request for declarative
field-structured storage in ISF and route any accepted implementation work to
an exact future owner before code changes.

## Non-Goals

- Do not change the parser, scheduler, lowerer, generated `.fsm`, HDL,
  schedule JSON, public contract code, semantic JSON, support accounting, or
  tests in the response-selection slice.
- Do not edit the SPECFORGE repository. FSMGen responds only in
  `docs/SPECFORGE_FEEDBACK_RESPONSE.md`.
- Do not implement declarative `(fields ...)` storage, packet/structure
  layouts, access-policy semantics, enum coupling, reset composition,
  normalized semantic export, support-accounting fixtures, or generated
  verification behavior in this response tree unless a later leaf explicitly
  selects that implementation boundary.
- Do not treat existing runtime field operations such as `set-field`,
  `when-field`, `extract`, or `assemble` as static field-map declarations.

## Acceptance Criteria

- The SPECFORGE request is read and summarized in FSMGen-owned task-tree
  state before the tracked response is edited.
- `docs/SPECFORGE_FEEDBACK_RESPONSE.md` gets a dated answer to the request in
  a later leaf.
- The answer distinguishes static declarative field maps from existing
  runtime bit-field operations and from opaque width-only storage.
- The answer either accepts, defers, or rejects the proposed ISF direction and
  records the exact future owner needed before parser/lowering behavior can
  change.
- Task-tree index, README, Memory, and Knowledge Map are synchronized if the
  response creates durable project state.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE`
  Status: `active`
  Goal: `Record FSMGen's response to SPECFORGE's declarative field-structured storage request.`
  Children: `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.1, ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.2`

- ID: `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.1`
  Status: `done`
  Goal: `Create the task-tree owner and select the response boundary.`
  Acceptance: `The SPECFORGE request is read, the response is scoped as documentation/contract guidance with no immediate runtime behavior change, and the response edit is owned before touching the response file.`
  Verification: `passed: read external SPECFORGE feedback request; read current FSMGen response and prior SPECFORGE response task-tree pattern; git diff --check; scripts/check_memory_architecture.sh; scripts/check_doctrines.sh`
  Commit: `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.1: select field storage response`

- ID: `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.2`
  Status: `pending`
  Goal: `Edit and commit the tracked FSMGen response.`
  Acceptance: `The response document records the dated answer; durable follow-on task-tree or Knowledge Map state is synchronized; docs-only validation passes; and the tree either closes or points at the exact next implementation/audit owner.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.2` | `pending` | `.1` created the owner and selected a docs/contract response before editing the response file. |

## Decisions

- `2026-06-22`: Treat SPECFORGE's declarative field-structured storage
  request as a tracked response first, not an immediate parser or lowering
  change. Existing runtime field operations are not a faithful static
  field-map declaration surface.
- `2026-06-22`: Any accepted declarative storage-field behavior must get a
  later exact owner before code, grammar, support-accounting, semantic JSON,
  schedule JSON, mdBook contract, or generated HDL behavior changes.

## Open Questions

- The exact future ISF syntax, validation rules, report/semantic projection,
  reset composition, access-policy vocabulary, enum relationship, and
  packet/structure layout generalization remain unselected until the tracked
  response chooses the next owner.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-22` | `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.1` | `Read external SPECFORGE feedback request and current FSMGen response`; `git diff --check`; `scripts/check_memory_architecture.sh`; `scripts/check_doctrines.sh` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.1` | `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.1: select field storage response` | `selection owner before response edit` |
| `ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.2` | `pending` | `pending` |

## Changelog

- `2026-06-22`: Created the task tree in response to SPECFORGE's declarative
  field-structured storage feature request and selected `.2` as the tracked
  response edit.
