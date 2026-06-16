# IAL1 Verification Observation Contract Selection

## Metadata

- Owner leaf: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3`
- Date: `2026-06-16`
- Status: `complete`
- Selected implementation owner: `ISF-VERIFICATION-OBSERVATION-METADATA.1`

## Decision

The first IAL1 verification-specific source feature is an actor-level,
metadata-only passive observation declaration. It gives future generated
verification outputs a stable source identity and observed interface-signal
set without changing scheduled `.fsm`, RTL, or existing assertion behavior.

Selected source spelling:

```lisp
(actor observed_link
  (clock clk)
  (reset rst_n)
  (interface
    (input valid)
    (input data (width 8))
    (output ready)
    (output done))
  (observe link_rx
    (role passive_monitor)
    (signals valid ready data))
  (transaction main
    (on valid)
    (complete done)))
```

## Selected Contract

`(observe NAME (role passive_monitor) (signals SIG...))` is an actor-body
declaration. It is report-only in the first slice.

The implementation owner must make these promises exact:

- `NAME` is a scalar HDL identifier and is unique among observation
  declarations in the actor.
- `role` is required and accepts only `passive_monitor` in the first slice.
- `signals` is required, non-empty, source-ordered, and may list each signal
  at most once.
- Every observed signal must be a scalar actor interface input or output.
  Actor-owned storage, generated/internal signals, dotted endpoints,
  expressions, aggregate paths, transaction-local ports, and child endpoints
  remain deferred.
- The observation inherits the actor's effective clock/reset. Clock-domain
  overrides and multi-domain observation partitioning remain deferred.
- The declaration produces no scheduled state, no `.fsm` carrier, no HDL, and
  no UVM/VHDL artifact in the first slice.

## Report Surface

The first implementation should add a schedule JSON top-level array:

```text
verification_observations[]
```

Entry keys selected for the first slice:

```text
name
role
clock
reset
signals
```

Each `signals[]` entry should expose:

```text
name
direction
width
```

The public contract must advertise the new top-level key, entry key family,
signal-entry key family, and role value family. The schedule JSON schema
version stays `1` because the field is additive and optional by empty array.

## Implementation Owner

Create and activate `docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md`.
Its first executable leaf is `ISF-VERIFICATION-OBSERVATION-METADATA.1`,
which owns the parser, report, public contract, support-accounting, focused
tests, mdBook, README/roadmap/task-tree, Memory, and Knowledge Map updates
for the exact metadata-only `observe` slice above.

## Deferrals

- UVM monitor, checker, agent, scoreboard, subscriber, coverage, sequence
  item, and reusable VIP generation remain behind
  `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`.
- VHDL/PSL/testbench verification output remains behind
  `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5`.
- Direct IAL2-to-verification routing remains behind
  `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6`.
- CLI output directories, generated verification artifact review surfaces,
  and output support-accounting behavior remain behind
  `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`.
- Transaction object extraction, observed events, expected/actual pairing,
  scoreboarding hooks, coverage-intent bins/crosses, domain overrides,
  aggregate observations, child endpoints, and protocol-specific IAL2
  annotations are intentionally not selected by this first source feature.

