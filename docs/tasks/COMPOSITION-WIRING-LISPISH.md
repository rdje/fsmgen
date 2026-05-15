# COMPOSITION-WIRING-LISPISH: Lisp-ish `?wiring` Forms

## Metadata

- Tree ID: `COMPOSITION-WIRING-LISPISH`
- Status: `done`
- Roadmap lane: `R11`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Make explicit composition wiring read like the rest of the Lisp-ish source
language by using `?wiring` blocks with list-form links such as
`(source target)` and `(connect source target)`, while keeping the older
`/source/target/` token as compatibility input.

## Non-Goals

- Do not remove the legacy slash-token form.
- Do not redesign the explicit-link planning or endpoint-resolution semantics.

## Acceptance Criteria

- Authored `?wiring` blocks accept `(source target)` compact links.
- Authored `?wiring` blocks accept `(connect source target)` verbose links.
- The older `/source/target/` spelling remains accepted.
- ISF-generated composition tops emit the new canonical list-link spelling.
- Focused parser, composition, ISF generated-top, and diagnostic tests pass.
- The mdBook, live docs, roadmap/task-tree status, and continuity docs are
  synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `COMPOSITION-WIRING-LISPISH`
  Status: `done`
  Goal: `Ship Lisp-ish explicit wiring forms without breaking slash-token compatibility.`
  Children: `COMPOSITION-WIRING-LISPISH.1`

- ID: `COMPOSITION-WIRING-LISPISH.1`
  Status: `done`
  Goal: `Parse, emit, test, and document Lisp-ish explicit wiring forms.`
  Acceptance: `Parser accepts compact and verbose link forms, ISF top emission uses them, compatibility and diagnostics remain covered, and docs describe the canonical spelling.`
  Verification: syntax checks for composition parser/planner/emitter modules; focused `prove -Iperl` composition, diagnostic, generated-ISF-top, and defensive-copy tests; `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check`
  Commit: `COMPOSITION-WIRING-LISPISH.1: ship Lisp-ish wiring forms`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `COMPOSITION-WIRING-LISPISH.1` | `done` | It ships the accepted canonical Lisp-ish `?wiring` link forms. |

## Decisions

- `2026-05-15`: The canonical compact explicit-link spelling is `(source target)`.
- `2026-05-15`: The verbose explicit-link spelling is `(connect source target)`.
- `2026-05-15`: `/source/target/` remains compatibility input, but generated
  ISF composition tops should use the canonical list form so new artifacts are
  reviewable in one Lisp-ish style.
- `2026-05-15`: `?wiring` is the canonical shipped block name. Parser
  diagnostics, generated ISF composition tops, examples, tests, and user-facing
  docs now use that spelling.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `COMPOSITION-WIRING-LISPISH.1` | Syntax checks for [perl/FSM/Composition/Parser.pm](perl/FSM/Composition/Parser.pm), [perl/FSM/Composition/FailureReportBuilder.pm](perl/FSM/Composition/FailureReportBuilder.pm), [perl/FSM/Composition/LinkedPlanBuilder.pm](perl/FSM/Composition/LinkedPlanBuilder.pm), [perl/FSM/Composition/PlanBuilder.pm](perl/FSM/Composition/PlanBuilder.pm), [perl/FSM/Composition/TopPortInferenceBuilder.pm](perl/FSM/Composition/TopPortInferenceBuilder.pm), [perl/FSM/Composition/WiringBlock.pm](perl/FSM/Composition/WiringBlock.pm), [perl/FSM/Composition/SourceExpressionSpecSupport.pm](perl/FSM/Composition/SourceExpressionSpecSupport.pm), and [perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm](perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm); focused `prove -Iperl` over 14 parser/composition/ISF tests; `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `COMPOSITION-WIRING-LISPISH.1` | `COMPOSITION-WIRING-LISPISH.1: ship Lisp-ish wiring forms` | Parser, generated-top emitter, diagnostics, tests, mdBook, task tree, roadmap, and live docs synchronized. |

## Changelog

- `2026-05-15`: Created task tree and started the first implementation leaf.
- `2026-05-15`: Completed `COMPOSITION-WIRING-LISPISH.1`; `?wiring`
  blocks accept `(source target)` and `(connect source target)` forms while
  preserving slash-token compatibility.
