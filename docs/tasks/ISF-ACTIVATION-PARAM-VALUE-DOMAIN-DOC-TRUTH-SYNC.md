# ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC: Activation Parameter Value Domain Truth Sync

## Metadata

- Tree ID: `ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Synchronize the remaining activation-parameter value-domain prose after
`ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2` shipped actor-local scalar parameter
defaults as generated activation parameter override values.

## Non-Goals

- Do not change parser, scheduler, report, generated artifact, HDL, CLI, or
  public API behavior.
- Do not widen direct `(on ...)` activation parameter override syntax.
- Do not widen reusable-library use-site actor constant or actor parameter
  override semantics.

## Acceptance Criteria

- The mdBook feature backlog no longer describes activation override values as
  actor constants plus enum members only.
- The ISF spec and public interface contract explicitly name actor-local
  scalar parameter defaults wherever they summarize activation override value
  resolution.
- The synchronized docs continue to name transaction parameters, runtime
  signals, arbitrary expressions, non-scalar actor parameters, direct `(on
  ...)` activation params, and reusable-library use-site actor constants or
  actor parameters as deferred.
- Focused doc audits, mdBook build, and diff check pass.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize activation parameter value-domain docs`
  Children: `ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.1`

- ID: `ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Sync remaining activation parameter value-domain prose`
  Acceptance: `The book, ISF spec, and public contract name actor-local scalar parameter defaults consistently for generated activation parameter overrides while preserving explicit deferrals.`
  Verification: `passed`
  Commit: `ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.1: sync activation param docs`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | All planned leaves are complete. |

## Decisions

- `2026-05-24`: This is a documentation truth-sync only. The behavior was
  shipped by `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2`; this tree only removes
  remaining stale prose.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.1` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.1` | `ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.1: sync activation param docs` | `documentation truth-sync slice` |

## Changelog

- `2026-05-24`: Synced remaining activation parameter value-domain prose in
  the mdBook feature backlog, ISF spec, and public contract.
