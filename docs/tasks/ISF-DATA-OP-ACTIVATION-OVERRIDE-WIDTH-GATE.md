# ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE: Default-Preserving Gate For Data-Op Width Activation Overrides

## Metadata

- Tree ID: `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE`
- Status: `pending`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Extend the existing activation-site parameter override-specialized
default-preserving gate at `perl/FSM/Scheduler/ISF/LoweringIR.pm` from the
shipped timing-parameter contexts (`(wait)` counts, `(repeat)` counts,
`(latency (min) (max))` bounds, top-level await-local `(watchdog)` limits,
and `(contract ... within CYCLES)` windows) to data-operation width
contexts: `(shift_left REG BIT (width PARAM))`,
`(shift_right REG BIT (width PARAM))`,
`(assemble PART... as TARGET (widths PARAM...))`, and
`(extract WORD as FIELD... (widths PARAM...))`.

Currently a parent activation that passes mismatched
`(spawn child (params (W 16)))` or `(do child (params (W 16)))` or
`(trigger child (params (W 16)))` to a generated child whose body uses
`(shift_left reg bit (width W))` is silently accepted, even though the
child's static lowering still uses the child default `W` value. This is
the same silent-no-op hazard the timing gate already prevents for
wait/repeat/latency/watchdog; widening the gate to data-op widths makes
the diagnostic surface uniform.

## Non-Goals

- Do not implement per-activation static lowering specialization for any
  parameter (timing or data-op). Same-value overrides remain the only
  shipped acceptance; mismatches stay fail-closed until per-activation
  specialization is shipped.
- Do not change positive lowering behavior for transaction-param-backed
  data-op widths on direct or non-generated-child transactions; those
  remain accepted with the resolved integer value.
- Do not change validator behavior for actor-param/actor-constant/
  package-constant-backed data-op widths; those are not subject to
  activation overrides.
- Do not introduce new data-op syntax, fields, or report metadata.
- Do not edit the mdBook book chapters unless the matrix wording at
  `docs/book/src/13k-isf-feature-support-matrix.md` or
  `docs/book/src/14-feature-backlog.md` becomes stale because of the
  shipped gate.

## Acceptance Criteria

- Validator at `perl/FSM/Scheduler/ISF/LoweringIR.pm` fails closed when a
  generated-child activation (`spawn`, generated blocking `do`, or rule
  `trigger`) passes a parameter override whose name matches a child
  transaction parameter used as a data-op width and whose value differs
  from the child default. The targeted diagnostic mirrors the existing
  timing-gate confess wording: `Transaction '$tn': <activation kind>
  instance '$inst' overrides static-width parameter '$param' on child
  '$child'; activation-site parameter override-specialized static lowering
  remains deferred`.
- Same-value overrides remain accepted.
- Overrides that name child parameters not used by any data-op width remain
  unaffected.
- A new focused test (e.g., `t/1370-isf-data-op-activation-override-width-gate.t`)
  covers all four data-op contexts (`shift_left`, `shift_right`, `assemble`,
  `extract`) for spawn, generated blocking do, and rule trigger activation
  kinds, plus a same-value accepted case per context.
- The `docs/ISF_SPEC.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and
  `docs/book/src/13k-isf-feature-support-matrix.md` data-operation entries
  acknowledge the gate where they describe transaction-param-backed
  data-op widths.
- mdBook builds clean; `git diff --check` clean; focused tests pass;
  `./bin/ci-regression isf --no-book` passes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE`
  Status: `done`
  Goal: `Widen the activation-site override-specialized default-preserving gate to data-op widths.`
  Children:
    `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.1`,
    `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.2`

- ID: `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.1`
  Status: `done`
  Goal: `Select the gate widening: task-tree owner, scope, boundaries, regression target, doc-sync targets.`
  Acceptance: `Task tree exists and is committed before any validator change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.2`
  Status: `done`
  Goal: `Ship the gate: validator change in LoweringIR.pm, focused regression in t/1370, doc updates where data-op width contexts describe transaction-param backing.`
  Acceptance: `Validator rejects mismatched overrides for all four data-op width contexts (shift_left/shift_right/assemble/extract) across spawn, generated do, and rule trigger; same-value overrides accepted; existing wait/repeat/latency/watchdog/contract gate unchanged; t/1370 passes; ISF CI passes; doc surfaces are aligned with shipped behavior.`
  Verification: `prove -Iperl t/1370-isf-data-op-activation-override-width-gate.t t/1369-isf-timing-param-activation-override-gates.t t/1367-isf-data-op-transaction-param-widths.t; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped; `.2` landed the validator gate, regression `t/1370`, and doc-surface synchronization. |

## Decisions

- `2026-05-27`: Picked from the activation-override matrix gap. Probed the
  current behavior with a minimal fixture and confirmed a parent
  `(spawn worker as w0 (params (W 16)))` against
  `(transaction worker (params (W 8)) (shift_left reg_out bit_in (width W)))`
  is silently accepted today. The wait/repeat/latency/watchdog/contract
  gate already exists; widening to data-op widths matches the established
  default-preserving pattern.
- `2026-05-27`: Scope is narrow — same-value overrides keep working,
  unrelated overrides keep working, only mismatches in width-bearing
  parameters fail closed. No per-activation specialization of data-op
  widths is introduced.

## Open Questions

- Is the diagnostic wording `'static-width'` preferred over a per-context
  `'static-data-op'`/`'static-shift-left'`/etc.? The timing gate uses
  `'static-timing parameter'` as the kind tag; symmetric naming would be
  `'static-width parameter'` for data-op widths. Decision will be locked in
  the `.2` commit.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; mdBook built clean; selection-only commit, no behavior change |
| `2026-05-27` | `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.2` | `prove -Iperl t/1370 t/1369 t/1367 t/1366 t/1305 t/1307`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; focused `Files=6, Tests=715`; mdBook built clean; ISF CI passed; whitespace clean |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.1` | `fd12f04c ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.1: select data-op activation-override width gate` | Selection commit (task tree + live docs registration). |
| `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.2` | `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.2: ship data-op activation-override width gate` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created active R14 task tree to widen the activation-site
  override-specialized default-preserving gate from timing parameters to
  data-op width parameters.
- `2026-05-27`: Shipped `.2`. Validator at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm` now fails closed on mismatched
  generated-child activation overrides for transaction parameters used
  by `shift_left`/`shift_right`/`assemble`/`extract` widths. Same-value
  overrides remain accepted. New regression `t/1370` covers the four
  data-op contexts across spawn/do/trigger plus same-value,
  unrelated-param, and existing-timing-precedence cases. Doc surfaces
  synchronized in `ISF_SPEC.md`, `ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  `ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and `14-feature-backlog.md`.
