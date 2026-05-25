# ISF-REPEAT-SPAWN-PARAMS: Repeat-Body Spawn Parameter Overrides

## Metadata

- Tree ID: `ISF-REPEAT-SPAWN-PARAMS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow the shipped top-level repeat-body spawn subset to carry static
`(params ...)` specialization values while preserving the existing
same-body `await_all` re-entry proof.

## Non-Goals

- Supporting repeat-body spawn `(bind ...)` port handoffs in this tree.
- Supporting repeat-body spawn `(domain ...)` cross-domain activation in this
  tree.
- Supporting repeat-body `do`, `await_any`, or child activation nested under
  repeat-body branch/loop forms.
- Treating parameter overrides as per-iteration runtime values.
- Changing top-level spawn parameter override behavior outside repeat bodies.

## Acceptance Criteria

- The selected source contract is documented before implementation:
  top-level repeat bodies may contain `(spawn child as inst (params ...))`
  only when the same repeat body reaches `(await_all done)` before the repeat
  check can loop.
- The lexical spawn name denotes one static generated child instance in the
  generated top; its parameter overrides specialize that static instance once,
  not once per repeat iteration.
- Parameter values reuse the shipped spawn activation override value domain,
  duplicate checks, unknown-parameter checks, and child-default shape checks.
- Unsupported repeat-body activation forms continue to fail closed with
  targeted diagnostics.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized for any shipped behavior.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-SPAWN-PARAMS`
  Status: `done`
  Goal: `Ship static parameter overrides for repeat-body spawn.`
  Children: `ISF-REPEAT-SPAWN-PARAMS.1`, `ISF-REPEAT-SPAWN-PARAMS.2`

- ID: `ISF-REPEAT-SPAWN-PARAMS.1`
  Status: `done`
  Goal: `Select and document the repeat-body spawn parameter contract.`
  Acceptance: `Task tree and book backlog name the exact first parameterized subset and exclusions.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-SPAWN-PARAMS.1: select repeat spawn params contract`

- ID: `ISF-REPEAT-SPAWN-PARAMS.2`
  Status: `done`
  Goal: `Implement repeat-body spawn parameter overrides.`
  Acceptance: `Lowering, generated-top parameter wiring, fail-closed diagnostics, docs, and ISF gates prove the parameterized repeat-spawn subset.`
  Verification: `syntax checks; focused repeat/spawn/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-SPAWN-PARAMS.2: implement repeat spawn params`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-SPAWN-PARAMS.1` | `done` | The first parameterized repeat-body spawn contract is selected and documented. |
| 2 | `ISF-REPEAT-SPAWN-PARAMS.2` | `done` | Implemented the documented parameterized repeat-spawn subset. |

## Decisions

- `2026-05-16`: The first parameterized subset will be top-level repeat bodies
  containing `(spawn child as inst (params ...))` clauses whose pending child
  done ports are consumed by a same-body `(await_all done)` before the repeat
  check can loop.
- `2026-05-16`: Parameter overrides are static specialization values for the
  single lexical child instance. They do not vary per repeat iteration.
- `2026-05-16`: Repeat-body spawn `(bind ...)`, `(domain ...)`, `await_any`,
  repeat-body `do`, and nested branch/loop activation forms remain deferred.

## Open Questions

- None for the selected parameterized subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-05-16` | `ISF-REPEAT-SPAWN-PARAMS.1` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed` |
| `2026-05-16` | `ISF-REPEAT-SPAWN-PARAMS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1202-isf-repeat-clause-boundary.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused checks, book build, full ISF gate, and diff check passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-SPAWN-PARAMS.1` | `09c417cb ISF-REPEAT-SPAWN-PARAMS.1: select repeat spawn params contract` | `completion commit` |
| `ISF-REPEAT-SPAWN-PARAMS.2` | `52a5e9ed ISF-REPEAT-SPAWN-PARAMS.2: implement repeat spawn params` | `completion commit` |

## Changelog

- `2026-05-16`: Created task tree and selected static parameter overrides as
  the next safe repeat-body spawn subset after the plain-spawn plus same-body
  `await_all` re-entry contract shipped.
- `2026-05-16`: Closed `ISF-REPEAT-SPAWN-PARAMS.2` and the task tree after
  implementing repeat-body spawn `(params ...)`, documenting the shipped
  optional static specialization behavior, and validating the broad ISF gate.
