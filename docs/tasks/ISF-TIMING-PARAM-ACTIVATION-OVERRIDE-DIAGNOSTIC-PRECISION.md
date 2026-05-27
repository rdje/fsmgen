# ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION: Sub-Axis Static-Timing Override Diagnostic

## Metadata

- Tree ID: `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Sharpen the activation-site override gate diagnostic that currently
emits the generic phrase "static-timing parameter" for four distinct
sub-axes: repeat counts, wait counts, latency bounds, and top-level
await-local watchdog limits. An author who hits the gate today cannot
tell from the diagnostic which timing axis their override impinges on.
This slice splits the single gate into four sub-axis-specific gates,
each naming its own sub-axis and its own deferral phrase, so authors
learn exactly which deferred feature is blocking their override.

## Non-Goals

- Do not implement activation-site parameter override-specialized
  repeat counts, wait counts, latency bounds, or watchdog limits. The
  broader implementations remain deferred.
- Do not change the same-value-preserving acceptance path. Overrides
  that match the default still flow through.
- Do not change the unknown-parameter or shape-mismatch precedence.
- Do not touch the contract-window, data-op width, or transaction
  port-width gates. They already emit targeted diagnostics.

## Acceptance Criteria

- When an activation-site override on a child transaction names a
  parameter used by exactly one of the four sub-axes (`(repeat NAME)`,
  `(wait NAME)`, `(latency (min NAME) ...)`, or top-level await
  `(watchdog NAME)`), the validator emits a sub-axis-specific
  diagnostic naming that sub-axis (`repeat-count parameter`,
  `wait-count parameter`, `latency-bound parameter`, or
  `watchdog-limit parameter`) and its specific deferral phrase
  (`repeat counts remain deferred`, `wait counts remain deferred`,
  `latency bounds remain deferred`, `watchdog limits remain
  deferred`).
- Existing focused regression `t/1369-isf-timing-param-activation-override-gates.t`
  is refreshed to expect the sub-axis-specific diagnostics for its
  four cases (DELAY/ITER/LAT/WD_LIMIT).
- Existing focused regression `t/1370-isf-data-op-activation-override-width-gate.t`
  is refreshed to expect the new wait-count diagnostic for its
  cross-axis negative-control case (DELAY).
- A new focused regression `t/1373-isf-timing-param-sub-axis-diagnostic.t`
  covers each of the four sub-axes across the three keyword sites
  (`spawn`, `do`, `rule trigger`) plus negative controls confirming
  same-value overrides still flow and the unknown/shape diagnostics
  still take precedence.
- Doc surfaces in `docs/ISF_SPEC.md`,
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and
  `docs/book/src/14-feature-backlog.md` reflect the new sub-axis
  diagnostics. `ISF_SPEC.md` focused-tests list registers `t/1373`.
- mdBook builds clean; `git diff --check` clean; focused tests pass;
  `./bin/ci-regression isf --no-book` passes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION`
  Status: `pending`
  Goal: `Split the static-timing override gate into four sub-axis-specific gates with targeted diagnostics.`
  Children:
    `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.1`,
    `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.2`

- ID: `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.1`
  Status: `pending`
  Goal: `Select the sub-axis diagnostic-precision slice; record scope, sub-axes covered, regression target, and doc-sync targets.`
  Acceptance: `Task tree exists and is committed before any validator change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.2`
  Status: `pending`
  Goal: `Ship per-sub-axis gates at the two activation-override sites plus regression t/1373 plus t/1369/t/1370 refresh plus doc updates.`
  Acceptance: `Each sub-axis emits its targeted diagnostic at all three keyword sites; same-value paths unchanged; t/1373 passes; ISF CI passes.`
  Verification: `prove -Iperl t/1369 t/1370 t/1373 t/1250; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped. `.2` landed the four sub-axis-specific gates at the spawn/do and rule-trigger activation sites, regression `t/1373`, refreshed `t/1369` + `t/1370` expectations, and doc-surface updates. |

## Decisions

- `2026-05-27`: Picked from the activation-override gate family.
  Probed current behavior: a `(do worker (params (LOOPS 4)))` override
  on a child whose `LOOPS` is consumed only by `(repeat LOOPS ...)`
  currently emits "static-timing parameter ... activation-site
  parameter override-specialized static timing remains deferred"
  because `_transaction_static_timing_param_names` aggregates four
  distinct sub-axes (repeat-count, wait-count, latency-bound,
  watchdog-limit) into one set checked by a single gate. The
  diagnostic does not name which axis is at issue, so the author
  cannot tell which deferred feature lane is blocking the override.
- `2026-05-27`: Chose sub-axis names that match the existing
  `_validate_transaction_parameter_clauses` confess message wording
  ("repeat counts", "wait counts", "latency bounds", "top-level
  await-local watchdog limits") so user-facing terminology stays
  coherent across the validator surface.

## Open Questions

- None blocking this slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit |
| `2026-05-27` | `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.2` | `prove -Iperl t/1369 t/1370 t/1373` (Files=3, Tests=12); `./bin/ci-regression isf --no-book` (Files=279, Tests=2037); `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.1` | `2ae1690e ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.1: select static-timing override sub-axis diagnostic precision` | Selection commit. |
| `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.2` | `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.2: ship static-timing override sub-axis diagnostic precision` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created active R14 task tree for the static-timing
  override sub-axis diagnostic precision slice. Aggregated
  static-timing diagnostic remains in place until `.2` ships the four
  sub-axis-specific gates.
- `2026-05-27`: Shipped `.2`. Validator at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm` now emits four sub-axis-specific
  diagnostics at both activation-override sites (spawn/do and rule
  trigger). The single `$static_timing_params` check was replaced with
  four sub-axis checks computed from the existing per-axis helpers
  (`_transaction_repeat_count_param_names`,
  `_transaction_wait_count_param_names`,
  `_transaction_latency_bound_param_names`,
  `_transaction_watchdog_limit_param_names`). The aggregator helper
  `_transaction_static_timing_param_names` was removed (no remaining
  callers) and the single
  `_activation_override_preserves_static_timing_param` was replaced by
  four sub-axis preserves helpers
  (`_activation_override_preserves_repeat_count_param`,
  `_activation_override_preserves_wait_count_param`,
  `_activation_override_preserves_latency_bound_param`,
  `_activation_override_preserves_watchdog_limit_param`) all delegating
  to the shared `_activation_override_preserves_static_integer_param`
  value-equality check. New regression `t/1373` covers the four
  sub-axes across the three keyword sites plus same-value acceptance
  and unknown/shape precedence. `t/1369` and `t/1370` expectations
  refreshed for the targeted diagnostics. Doc surfaces synchronized in
  `ISF_SPEC.md` (focused-tests + sub-axis paragraph),
  `ISF_DOWNSTREAM_INTEGRATION_SPEC.md` (sub-axis note), and
  `14-feature-backlog.md` (sub-axis sentence).
