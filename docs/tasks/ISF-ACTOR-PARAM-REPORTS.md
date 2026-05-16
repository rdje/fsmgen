# ISF-ACTOR-PARAM-REPORTS: Actor Parameter Schedule Reports

## Metadata

- Tree ID: `ISF-ACTOR-PARAM-REPORTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Expose actor-level `(params ...)` default declarations through the bounded ISF
schedule report so downstream consumers can inspect reusable-actor
specialization defaults without parsing scheduled `.fsm` text or raw scheduler
IR.

## Non-Goals

- Do not widen the accepted actor-parameter value domain.
- Do not make actor parameters runtime signals.
- Do not change reusable-library override semantics, generated child
  parameter bindings, or generated `.fsm` `+params` emission.

## Acceptance Criteria

- Public `FSM::Scheduler::ISF->report(...)` and `--emit-schedule-json` include
  `actor_params[]` for accepted actors with actor-level `(params ...)`.
- Each report entry exposes the exact advertised `name` and `value` keys.
- The public ISF interface contract and capability manifest advertise the new
  top-level and nested key family.
- The ISF spec, downstream handoff, mdBook, and live docs distinguish actor
  parameters from actor constants and runtime signals.
- Focused tests prove in-process and CLI report projection.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTOR-PARAM-REPORTS`
  Status: `done`
  Goal: expose actor parameter defaults through bounded public schedule
  reports without changing parameter semantics.
  Children: `ISF-ACTOR-PARAM-REPORTS.1`

- ID: `ISF-ACTOR-PARAM-REPORTS.1`
  Status: `done`
  Goal: add bounded `actor_params[]` schedule-report projection for
  actor-level parameter defaults.
  Acceptance: reports include exact advertised `name` and `value` entries for
  actor parameter defaults, public contract metadata lists the new top-level
  and nested keys, downstream-facing docs describe the shipped report surface,
  and focused checks pass.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`;
  `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `prove -Iperl t/1253-isf-actor-param-report.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1096-isf-schedule-json-report.t t/1121-isf-public-cli-schedule-report-audit.t t/1227-isf-schedule-report-freeze-boundary.t t/1250-isf-spec-focused-test-index-audit.t`;
  `./bin/ci-regression isf`; `mdbook build docs/book`; `git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-16`: Report actor parameters as informational default declarations
  with `name` and JSON-safe `value`. Parameter override behavior remains owned
  by existing generated-composition and reusable-library report surfaces.

## Open Questions

- None for the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-ACTOR-PARAM-REPORTS.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1253-isf-actor-param-report.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1096-isf-schedule-json-report.t t/1121-isf-public-cli-schedule-report-audit.t t/1227-isf-schedule-report-freeze-boundary.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-PARAM-REPORTS.1` | `ISF-ACTOR-PARAM-REPORTS.1: report actor params` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree and opened
  `ISF-ACTOR-PARAM-REPORTS.1`.
- `2026-05-16`: Completed `ISF-ACTOR-PARAM-REPORTS.1` and closed the tree.
