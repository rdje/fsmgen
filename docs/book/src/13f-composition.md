# Composition

Composition lets transactions call other transactions.

## `(do child)` — Blocking Call

```lisp
(transaction parent
  (on start)
  (do read_phase)
  (do write_phase)
  (complete done))
```

Sequential, blocking. One instance of each child is intended to be reused by
the parent transaction.

The form is exact: `(do child)`, with one scalar child transaction operand.
Malformed missing, nested, or extra operands fail before child-target
resolution.

**Current lowering**:
1. Parent asserts `child_start` and awaits `child_done`
2. Child's idle state is rewired to watch `child_start`
3. Child's terminal state pulses `child_done` with `<1`

The child target must name a declared transaction in the same actor. Forward
references are accepted because lowering validates after the full actor body
is parsed; missing targets fail before scheduled `.fsm` emission.

The rewired child idle state enters the first non-entry child state; the child
body may start with a drive, await, data operation, or other scheduled state.

```lisp
(parent_do_1
  (= (read_phase_start 1))
  (<read_phase_done
    (-> parent_do_2)))

(read_phase_idle_0
  (<read_phase_start
    (-> read_phase_drive_0)))

(read_phase_done_5
  (<1 (done> 1))
  (<1 (read_phase_done 1))
  (-> read_phase_idle_0))
```

The internal child-done signal is a one-cycle delayed pulse. This matters when
the parent invokes the same child more than once: each `(do child)` waits for a
fresh completion instead of seeing a sticky done bit left from the previous
call.

## `(spawn child as name)` — Parallel Fork

```lisp
(transaction parent
  (on start)
  (spawn worker as w0)
  (spawn worker as w1)
  (spawn worker as w2)
  (await_all done)
  (complete done))
```

Non-blocking. Each spawn declares a separate intended instance.

`spawn` is an elaboration construct with runtime activation semantics. The
generated hardware instance is static: it exists for the lifetime of the
generated module. Executing the spawn state at runtime asserts that instance's
start path; completing the child transaction returns the same static instance
to its start-gated idle state. Completion never destroys the instance, and a
later activation reuses the same child hardware.

This matters for loops. When `(spawn ...)` is eventually accepted inside a
`(repeat ...)` body, the repeat must not mean "create N child instances." It
must mean "activate the same lexically named child instance once per loop
iteration." A design that needs parallel workers should author distinct spawn
instance names, or use a future static-generation surface if one is added. A
spawn-in-repeat implementation also needs an explicit busy rule: the scheduler
must reject or sequence any path that could start an already active child
instance before its fresh `done` pulse has been observed.

The base form is exact: `(spawn child as name)`. The parameterized form adds
one nested override block: `(spawn child as name (params (NAME value) ...))`.
Both forms require scalar child and instance names plus the literal `as`
separator. Malformed spawn forms fail before spawned child collection, so the
scheduler does not invent a default instance name for an invalid clause.

**Lowering**:
- One `.fsm` per unique child module
- Spawn targets must name declared transactions in the same actor
- Parent `.fsm` declares per-instance `name_start`/`name_done` signals
- Each spawn state asserts its matching `name_start` signal
- `(await_all done)` → one transition guarded by the logical AND of all done
  signals
- `(await_any done)` → one guard per done signal, advancing on the first one
  that fires
Both synchronization forms have focused regressions.

Composition-top instantiation is shipped for the covered spawned-child fixture
set. Spawn parameter declaration, validation, scheduled child `+params`
emission, per-instance override preservation, and generated-top application now
flow through the existing composition pipeline:

- Multi-file spawn actors use an explicit generated top over the scheduled
  parent module and spawned child modules.
- The scheduled parent keeps the actor name; the generated top uses a distinct
  deterministic name, initially `{actor}_top`.
- The top re-exports the actor public interface.
- Per-instance `name_start` and `name_done` are internal top handoff links, not
  public top ports.
- The scheduled parent exposes `name_start` as an output and `name_done` as an
  input for each spawned instance.
- Each spawned child exposes `start` as an input and `done` as an output.
- Named drive calls in spawned children expose per-drive handoff outputs that
  the top wires back into parent per-instance handoff inputs.
- After completion, a spawned child returns to its `start`-guarded idle state
  and waits for the next start pulse.

Parameterized spawn uses one optional nested `params` block:

```lisp
(transaction worker
  (params
    (WIDTH 8))
  ...)

(transaction parent
  (on start)
  (spawn worker as w0
    (params
      (WIDTH 16)))
  (await_all done)
  (complete done))
```

The shipped parameter surface is spawn-only. `(do child)` remains
unparameterized. Override names must match child transaction parameters,
duplicate instance/parameter names fail, scalar literal overrides are
width-flexible, aggregate defaults require compatible aggregate overrides, and
symbolic constants wait for an explicit ISF constant/symbol surface. A spawned
child `.fsm` now emits the child transaction defaults in `+params`; parameter
declarations on non-spawned transactions fail closed; the parent lowerer IR
preserves per-instance override lists, and the generated top applies those
overrides through `?fsmc` `(params ...)` blocks.

```lisp
(parent_main_await_all_4
  (-> parent_main_done_5 <(& w0_done w1_done w2_done))
)
```

The compact transition suffix above is equivalent to nested guards over the
same done ports, but the scheduled `.fsm` artifact uses the direct conjunction
so the all-done condition is visible at the transition site.

## `(await_all port)` / `(await_any port)`

```lisp
(await_all done)     ;; wait for ALL spawned children
(await_any done)     ;; wait for ANY spawned child
```

The forms are exact: `(await_all done_port)` and `(await_any done_port)`, with
one scalar done-port operand. Malformed missing, nested, or extra operands fail
before sync-state emission.

## Composition Architecture

```
spawn_parent.isf
    │
    ▼ LoweringIR
    │
    ├── child_worker.fsm       (child module with start/done ports)
    ├── spawn_parent.fsm       (parent with per-instance handoff signals)
    └── spawn_parent_top.fsm   (generated composition top wiring parent and children)
```

The `--outdir DIR` flag writes all generated `.fsm` files:

```bash
./bin/fsmgen --strict --outdir output/ isf/spawn_parent.isf
# Writes: output/child_worker.fsm, output/spawn_parent.fsm,
#         and output/spawn_parent_top.fsm.
# If --output is also provided, HDL generation uses spawn_parent_top.fsm.
```

## Schedule Report Projection

The generated-composition schedule-report projection is a live bounded
downstream-discovery field. Successful reports keep ordinary transaction,
storage, and DT summaries parent-scoped, while the top-level
`generated_composition` field reports generated-top structure. For actors with
no generated composition top, that field is `null`. For spawned-child actors,
it is an object with only review-facing composition facts:

```json
{
  "kind": "spawn_generated_top",
  "top_module": "spawn_parent_top",
  "top_fsm": "spawn_parent_top.fsm",
  "parent": {
    "module": "spawn_parent",
    "scheduled_fsm": "spawn_parent.fsm"
  },
  "children": [
    {
      "transaction": "child_worker",
      "module": "child_worker",
      "scheduled_fsm": "child_worker.fsm",
      "parameters": [
        { "name": "WIDTH", "default": "8" }
      ]
    }
  ],
  "instances": [
    {
      "instance": "w0",
      "child": "child_worker",
      "start": { "parent_port": "w0_start", "child_port": "start" },
      "done": { "child_port": "done", "parent_port": "w0_done" },
      "parameter_bindings": [
        { "name": "WIDTH", "source": "override", "value": "16" }
      ],
      "drive_handoffs": [
        {
          "drive": "rdata",
          "request": {
            "child_port": "rdata_start",
            "parent_port": "w0_rdata_start"
          },
          "payloads": [
            {
              "parameter": "val",
              "child_port": "rdata_val",
              "parent_port": "w0_rdata_val",
              "width": 32
            }
          ]
        }
      ]
    }
  ]
}
```

The projection is intentionally not a raw `LoweringIR` dump and not a parsed
`?toplink` dump. It reports the current bounded names that downstream
consumers can use to discover the generated top, parent, child modules,
instance identity, start and done handoff, named-drive handoff, and
per-instance parameter binding. This is live public discovery metadata, not a
frozen schema for all future ISF releases.

## Complete Example

```lisp
(actor bus_controller
  (clock clk)
  (reset (rst_n async active_low))

  (interface
    (input  start)
    (output done)
    (output rdata (width 32)))

  ;; Worker transaction
  (transaction read_word
    (sample rdata as val)
    (drive work (rdata val))
    (complete done))

  ;; Parent: three parallel reads
  (transaction scatter_read
    (on start)
    (spawn read_word as r0)
    (spawn read_word as r1)
    (spawn read_word as r2)
    (await_all done)
    (complete done)))
```
