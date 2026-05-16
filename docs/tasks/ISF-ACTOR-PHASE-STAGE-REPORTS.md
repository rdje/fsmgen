# ISF-ACTOR-PHASE-STAGE-REPORTS: Actor Metadata Schedule Reports

## Metadata

- Tree ID: `ISF-ACTOR-PHASE-STAGE-REPORTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Expose parser-validated actor-level `(phase ...)` and `(stage ...)` metadata
through the bounded ISF schedule report so downstream consumers can inspect
that authored metadata without depending on the raw parser actor hash.

## Non-Goals

- Do not add runtime semantics for actor-level phases or stages.
- Do not lower actor-level phase/stage metadata into scheduled `.fsm`,
  generated composition tops, or HDL.
- Do not widen transaction-level `(stage ...)` beyond the shipped top-level
  ready/valid barrier subset.

## Acceptance Criteria

- Public `FSM::Scheduler::ISF->report(...)` and `--emit-schedule-json` include
  actor-level phase and stage metadata for accepted single-clock actors.
- The report projection is bounded and advertised through the public ISF
  interface contract and capability manifest.
- Existing unsupported actor-level runtime semantics remain explicitly
  deferred in the spec, handoff, and book.
- Focused tests prove the in-process and CLI report shapes.
- Live docs and roadmap status are updated.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTOR-PHASE-STAGE-REPORTS`
  Status: `done`
  Goal: expose actor-level phase/stage metadata through public schedule reports
  without changing runtime semantics.
  Children: `ISF-ACTOR-PHASE-STAGE-REPORTS.1`

- ID: `ISF-ACTOR-PHASE-STAGE-REPORTS.1`
  Status: `done`
  Goal: add bounded `actor_phases[]` and `actor_stages[]` schedule-report
  projection for parser-validated actor metadata.
  Acceptance: reports include exact advertised `name` and `body` entries for
  actor-level phases/stages, public contract metadata lists the new top-level
  and nested keys, downstream-facing docs describe the shipped report surface
  and still mark runtime semantics as deferred, and focused checks pass.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`;
  `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`;
  `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `prove -Iperl t/1252-isf-actor-phase-stage-report.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1225-isf-stage-contract-schedule-report.t t/1227-isf-schedule-report-freeze-boundary.t t/1250-isf-spec-focused-test-index-audit.t`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-16`: Report actor-level metadata as bounded informational schedule
  report arrays. The report does not make actor-level phase/stage metadata
  executable, and the generated `.fsm`/HDL artifacts remain unchanged.
- `2026-05-16`: Preserve each metadata entry as `name` plus JSON-safe `body`
  list-form content rather than flattening to prose so downstream tools can
  inspect the exact parser-validated authored properties.

## Open Questions

- None for the current frontier. Future runtime semantics for actor-level
  phases/stages remain separate backlog work.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-ACTOR-PHASE-STAGE-REPORTS.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1252-isf-actor-phase-stage-report.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1225-isf-stage-contract-schedule-report.t t/1227-isf-schedule-report-freeze-boundary.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-05-16` | `ISF-ACTOR-PHASE-STAGE-REPORTS.1` | `prove -Iperl t/1096-isf-schedule-json-report.t t/1121-isf-public-cli-schedule-report-audit.t t/1128-isf-public-multifile-schedule-report-audit.t t/1139-isf-public-lower-result-metadata-audit.t t/1112-isf-public-interface-contract.t t/1113-isf-public-interface-contract-json-roundtrip-audit.t t/1114-isf-public-interface-contract-defensive-copy-audit.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1141-isf-public-identity-flags-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t` | `pass` |
| `2026-05-16` | `ISF-ACTOR-PHASE-STAGE-REPORTS.1` | `./bin/ci-regression isf` | `pass: 159 files, 548 tests, plus mdBook build` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-PHASE-STAGE-REPORTS.1` | `ISF-ACTOR-PHASE-STAGE-REPORTS.1: report actor metadata` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree and opened
  `ISF-ACTOR-PHASE-STAGE-REPORTS.1`.
- `2026-05-16`: Completed `ISF-ACTOR-PHASE-STAGE-REPORTS.1` and closed the
  tree.
