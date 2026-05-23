# ISF-LATENCY-ACTOR-PARAM-BOUNDS: Latency Actor-Parameter Bounds

## Metadata

- Tree ID: `ISF-LATENCY-ACTOR-PARAM-BOUNDS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow transaction latency `(min ...)` and `(max ...)` bounds to use actor-local
scalar parameter defaults when those defaults resolve to positive integer
literals.

## Non-Goals

- Do not support transaction parameters as latency bounds.
- Do not support runtime interface signals, storage signals, or arbitrary
  expressions as latency bounds.
- Do not specialize latency bounds through reusable-library use-site parameter
  overrides.
- Do not change latency counter timing, timeout-state semantics, schedule
  report storage roles, or generated HDL behavior beyond resolving one more
  static source kind before existing lowering.
- Do not add stage-local latency or actor-level stage runtime semantics.

## Acceptance Criteria

- `(latency (min MIN_PARAM) (max MAX_PARAM))` lowers when each token names an
  actor-local scalar parameter default whose resolved value is positive.
- Parameter-backed latency bounds lower exactly like equivalent positive
  literal/static bounds.
- Non-scalar, zero-valued, unknown, transaction-parameter, runtime, and
  expression-valued latency bounds remain fail-closed with targeted
  diagnostics.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LATENCY-ACTOR-PARAM-BOUNDS`
  Status: `active`
  Goal: `Ship actor-parameter-backed static transaction latency bounds.`
  Children: `ISF-LATENCY-ACTOR-PARAM-BOUNDS.1`,
  `ISF-LATENCY-ACTOR-PARAM-BOUNDS.2`

- ID: `ISF-LATENCY-ACTOR-PARAM-BOUNDS.1`
  Status: `done`
  Goal: `Select latency actor-parameter bounds.`
  Acceptance: `Create the active task tree, record the static actor-parameter
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending commit`

- ID: `ISF-LATENCY-ACTOR-PARAM-BOUNDS.2`
  Status: `pending`
  Goal: `Implement and document actor-parameter transaction latency bounds.`
  Acceptance: `Positive actor scalar parameters lower as literal latency
  bounds; unsupported bound tokens fail closed; specs, book, public contract,
  downstream handoff, and focused tests are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LATENCY-ACTOR-PARAM-BOUNDS.2` | `pending` | The source boundary is selected; implementation can reuse the existing static actor-parameter default model from wait counts. |

## Decisions

- `2026-05-22`: Select actor-local scalar parameter defaults only. They are
  compile-time static evidence in the current actor shell, matching shipped
  parameter-backed waits, while use-site override specialization and
  transaction parameters remain deferred.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-LATENCY-ACTOR-PARAM-BOUNDS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LATENCY-ACTOR-PARAM-BOUNDS.1` | `this commit: ISF-LATENCY-ACTOR-PARAM-BOUNDS.1: select latency actor-param bounds` | `selects static actor-parameter latency bound support` |
| `ISF-LATENCY-ACTOR-PARAM-BOUNDS.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected static actor-parameter
  transaction latency bounds.
