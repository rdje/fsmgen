# ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE: Default-Preserving Gate For Transaction Port Width Activation Overrides

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE`
- Status: `pending`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Extend the existing activation-site parameter override-specialized
default-preserving gate at `perl/FSM/Scheduler/ISF/LoweringIR.pm` from the
shipped contexts (`(wait)` counts, `(repeat)` counts, `(latency)` bounds,
top-level await-local `(watchdog)` limits, `(contract ... within CYCLES)`
windows, and data-op widths `(shift_left)`/`(shift_right)`/`(assemble)`/
`(extract)`) to transaction port width contexts:
`(ports (input NAME (width PARAM)))` and
`(ports (output NAME (width PARAM)))` where `PARAM` names a child
transaction parameter and the parent activation passes an override for
that parameter.

Currently a parent activation that passes mismatched
`(spawn child (params (W 16)))` (or `(do child)` or `(trigger child)`) to
a generated child whose body uses `(ports (input data (width W)))` is
silently accepted: the child's static port lowering still uses the child
default `W` value, so an author who thinks they specialized the child to
16-bit operation actually gets the 8-bit child silently. The hazard is
identical to the silent-no-op the timing/contract/data-op gates already
prevent.

## Non-Goals

- Do not implement per-activation static port-width specialization. Same-
  value overrides remain the only shipped acceptance; mismatches stay
  fail-closed until per-activation specialization is shipped.
- Do not change positive lowering behavior for transaction-param-backed
  port widths on direct or non-generated-child transactions; those remain
  accepted with the resolved integer value.
- Do not change validator behavior for actor-param/actor-constant/
  package-constant-backed port widths; those are not subject to
  activation overrides.
- Do not introduce new transaction port syntax, fields, or report
  metadata.
- Do not edit the mdBook book chapters unless wording at
  `docs/book/src/13k-isf-feature-support-matrix.md` or
  `docs/book/src/14-feature-backlog.md` becomes stale because of the
  shipped gate.

## Acceptance Criteria

- Validator at `perl/FSM/Scheduler/ISF/LoweringIR.pm` fails closed when a
  generated-child activation (`spawn`, generated blocking `do`, or rule
  `trigger`) passes a parameter override whose name matches a child
  transaction parameter used as a transaction port width and whose value
  differs from the child default. Targeted diagnostic mirrors the
  data-op width gate wording: `Transaction '<tn>': <activation kind>
  instance '<inst>' overrides static port-width parameter '<name>' on
  child '<child>'; activation-site parameter override-specialized
  transaction port widths remain deferred`.
- Same-value overrides remain accepted.
- Overrides that name child parameters not used by any transaction port
  width remain unaffected.
- A new focused test `t/1371-isf-transaction-port-activation-override-width-gate.t`
  covers both port directions (input and output) for spawn, generated
  blocking do, and rule trigger activation kinds, plus same-value
  accepted cases and the static-timing/data-op precedence case.
- `docs/ISF_SPEC.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and
  `docs/book/src/14-feature-backlog.md` acknowledge the gate where they
  describe transaction-param-backed transaction port widths. `ISF_SPEC.md`
  focused-tests list registers `t/1371` so
  `t/1250-isf-spec-focused-test-index-audit.t` stays green.
- mdBook builds clean; `git diff --check` clean; focused tests pass;
  `./bin/ci-regression isf --no-book` passes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE`
  Status: `done`
  Goal: `Widen the activation-site override-specialized default-preserving gate to transaction port widths.`
  Children:
    `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.1`,
    `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.2`

- ID: `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.1`
  Status: `done`
  Goal: `Select the gate widening: task-tree owner, scope, boundaries, regression target, doc-sync targets.`
  Acceptance: `Task tree exists and is committed before any validator change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.2`
  Status: `done`
  Goal: `Ship the gate: validator change in LoweringIR.pm, focused regression in t/1371, doc updates where transaction port width contexts describe transaction-param backing.`
  Acceptance: `Validator rejects mismatched overrides for transaction port widths across spawn, generated do, and rule trigger; same-value overrides accepted; existing wait/repeat/latency/watchdog/contract/data-op gates unchanged; t/1371 passes; ISF CI passes; doc surfaces aligned.`
  Verification: `prove -Iperl t/1371-isf-transaction-port-activation-override-width-gate.t t/1370 t/1369 t/1368 t/1250 t/1305; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped; `.2` landed the validator gate, regression `t/1371`, and doc-surface synchronization. |

## Decisions

- `2026-05-27`: Picked from the activation-override matrix gap. Probed the
  current behavior with a minimal fixture and confirmed a parent
  `(spawn worker as w0 (params (W 16)) (bind ...))` against
  `(transaction worker (params (W 8)) (ports (input data (width W)) (output result (width W))) ...)`
  silently accepts the activation (with matching 8-bit parent signals)
  even though the override is intended to specialize the child to 16-bit.
  The wait/repeat/latency/watchdog/contract/data-op gate matrix already
  exists; widening to transaction port widths matches the established
  default-preserving pattern.
- `2026-05-27`: Reuse the parser-precomputed `$tx->{_transaction_param_port_widths}`
  map that already feeds `_transaction_params_used_by_transaction_port_width`.

## Open Questions

- None blocking.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit, no behavior change |
| `2026-05-27` | `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.2` | `prove -Iperl t/1371 t/1370 t/1369 t/1368 t/1250 t/1305 t/1307`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; focused `Files=7, Tests=718`; mdBook built clean; ISF CI passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.1` | `f275b76b ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.1: select transaction port activation-override width gate` | Selection commit (task tree + live docs registration). |
| `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.2` | `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.2: ship transaction port activation-override width gate` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created active R14 task tree to widen the activation-site
  override-specialized default-preserving gate from timing/contract/data-op
  contexts to transaction port width contexts.
- `2026-05-27`: Shipped `.2`. Validator at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm` now fails closed on mismatched
  generated-child activation overrides for transaction parameters used
  by transaction port widths. Same-value overrides remain accepted. New
  regression `t/1371` covers spawn/do/trigger across input and output port
  directions, plus same-value, unrelated-param, and data-op precedence
  cases. Doc surfaces synchronized in `ISF_SPEC.md` (gate paragraph +
  focused-tests list), `ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  `ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and `14-feature-backlog.md`.
