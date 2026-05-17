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

The base form is exact: `(do child)`, with one scalar child transaction
operand. The parameterized/bound form accepts nested subclauses:
`(do child (domain NAME) (params (NAME value) ...) (bind ...))`. At most one
`domain` block, one `params` block, and one `bind` block may appear. Malformed
missing, nested, duplicate, or unsupported operands fail before child-target
resolution.

**Current local lowering**:
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

Top-level repeat bodies may also use the plain local `(do child)` form. In
that repeat-body subset, the child remains in the parent scheduled module, the
repeat-body `do` state waits for `child_done`, and the repeat check back-edge
is reachable only after that fresh done pulse. Repeat-body generated `do` may
use static `(params ...)`, optional `(bind ...)`, and optional same-domain
`(domain NAME)` metadata for one lexical generated instance. Cross-domain
repeat-body `do`, repeat-body `do` targeting an already generated child, and
sample-before/after-do timing are still backlog.

Parameterized blocking `do` uses the generated child activation path instead
of rewiring a local child body. The child is emitted as its own scheduled
module, the generated top instantiates a deterministic child instance named
`{parent}_{child}_do_{ordinal}`, and the parent asserts that instance's
`start` handoff while awaiting its `done` handoff. Parameter overrides are
applied in the generated top `?fsmc` `(params ...)` block:

```lisp
(transaction parent
  (on start)
  (do worker
    (params
      (WIDTH 16))
    (bind
      (input addr req_addr)
      (output data resp)))
  (complete done))
```

Representative scheduled parent artifacts:

```lisp
(parent_do_1
  (= (parent_worker_do_0_start> 1))
  (<parent_worker_do_0_done
    (-> parent_complete_2)))

(-parent_worker_do_0_port_bindings
  (= (parent_worker_do_0_addr> req_addr))
  (= (resp> parent_worker_do_0_data) <parent_worker_do_0_done))
```

Input bindings may use scalar signals, numeric/exact-width literals, or
non-empty list expressions as the parent-owned payload source. Spawned child
input-binding source signals are consumed by the explicit parent handoff and
are not also same-name wired into the child instance.

Representative generated top instance:

```lisp
(?fsmc:parent_worker_do_0 worker
  (params
    (WIDTH 16)))
```

Input bindings are same-cycle handoff assignments owned by the parent. Output
bindings are guarded by the generated child instance's `done` pulse so the
parent copies the child output when the blocking call completes. A plain
`(do child)` remains local when the child is not otherwise generated. If the
same child transaction is already emitted as a generated child because of
spawn or a parameterized `do`, a plain `do` to that child also uses a generated
activation instance so the parent never targets a skipped local child body.

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

This matters for loops. In the shipped repeat-body subset, `(spawn ...)` does
not mean "create N child instances." It means "activate the same lexically
named child instance once per loop iteration." A design that needs parallel
workers should author distinct spawn instance names, or use a future
static-generation surface if one is added. The shipped repeat-body subset
requires same-body `(await_all done)`, or same-body `(await_any done)` when
exactly one spawn is pending, before the repeat check can loop. The scheduler
rejects paths that could start the static child instance again before its
fresh `done` pulse has been observed.

The base form is exact: `(spawn child as name)`. Optional nested subclauses add
static parameter overrides, explicit port bindings, or declared same-domain
ownership metadata: `(spawn child as name (domain NAME) (params (NAME value)
...) (bind ...))`. The child, instance, and domain names must be scalar, and
the literal `as` separator is required. Malformed spawn forms fail before
spawned child collection, so the scheduler does not invent a default instance
name for an invalid clause.

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

Composition-top instantiation is shipped for the covered generated-child
fixture set. Spawn parameter declaration, blocking `do` parameter declaration,
validation, scheduled child `+params` emission, per-instance override
preservation, and generated-top application now flow through the existing
composition pipeline:

- Multi-file generated-child actors use an explicit generated top over the
  scheduled parent module and child modules.
- The scheduled parent keeps the actor name; the generated top uses a distinct
  deterministic name, initially `{actor}_top`.
- The top re-exports the actor public interface.
- Per-instance `name_start` and `name_done` are internal top handoff links, not
  public top ports.
- The scheduled parent exposes `name_start` as an output and `name_done` as an
  input for each spawned instance.
- Each generated child exposes `start` as an input and `done` as an output.
- Named drive calls in spawned children expose per-drive handoff outputs that
  the top wires back into parent per-instance handoff inputs.
- After completion, a spawned child returns to its `start`-guarded idle state
  and waits for the next start pulse.

Parameterized spawn and parameterized blocking `do` use one optional nested
`params` block:

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

The shipped activation-parameter surface covers spawned child instances and
blocking `do` generated child activations. Override names must match child
transaction parameters, duplicate instance/parameter names fail, scalar
literal overrides are width-flexible, and aggregate defaults require
compatible aggregate overrides. Actor-local constants may be used as scalar
override values, or as scalar leaves inside aggregate/list override values;
they resolve to literal values before generated-top emission.
A generated child `.fsm` emits the child transaction defaults in `+params`;
parameter declarations on non-generated transactions fail closed; the parent
lowerer IR preserves per-instance override lists, and the generated top applies
those overrides through `?fsmc` `(params ...)` blocks.

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

## Reusable ISF Libraries

ISF libraries are reusable source-intent roots. They are not textual includes:
an imported definition still lowers to scheduled `.fsm` review artifacts before
HDL generation.

The first shipped root shape is:

```lisp
(library common.fifo
  (exports
    (actor fifo))

  (actor fifo
    ... reusable actor body ...))
```

Actor roots import libraries with `(imports (library name as alias) ...)` and
instantiate exported actors with `(use alias.actor as instance ...)`. Use-site
parameter overrides are instance-local, and bindings are explicit:

```lisp
(actor fifo_library_use
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input write_req)
    (input data_in (width 8))
    (input read_req)
    (output full)
    (output empty)
    (output data_out (width 8)))
  (imports
    (library common.fifo as fifo_lib))
  (use fifo_lib.fifo as u_fifo
    (params
      (DATA_WIDTH 8)
      (DEPTH 4)
      (PTR_WIDTH 2)
      (OCC_WIDTH 3))
    (bind
      (clock clk)
      (reset rst_n)
      (input write_req write_req)
      (input data_in data_in)
      (input read_req read_req)
      (output full full)
      (output empty empty)
      (output data_out data_out))))
```

The first shipped reusable definition is
[isf/common/fifo.isf](../../isf/common/fifo.isf), exported as
`common.fifo.fifo`, with
[isf/fifo_library_use.isf](../../isf/fifo_library_use.isf) as the file-backed
import/use fixture. It is a fixed-shape `DATA_WIDTH=8`, `DEPTH=4`,
`PTR_WIDTH=2`, `OCC_WIDTH=3` FIFO actor. The actor owns write and read
pointers, occupancy, full/empty flags, and a four-entry data bank. It models
idle, push-only, pop-only, and push-plus-pop cases every cycle, with
read-before-write bank semantics for same-cycle store/load.

The shipped catalog is
[docs/ISF_LIBRARY_CATALOG.md](../../ISF_LIBRARY_CATALOG.md). The public ISF
contract advertises the catalog through `library_catalog_paths`, the bounded
entry fields through `library_catalog_entry_keys`, and the current shipped
entries through `shipped_library_definitions`. Parameter-driven interface or
storage elaboration, memory-array backend emission, standalone transaction or
drive exports, and nested library imports remain future work.

## Schedule Report Projection

The generated-composition schedule-report projection is a live bounded
downstream-discovery field. Successful reports keep ordinary transaction,
storage, and DT summaries parent-scoped, while the top-level
`generated_composition` field reports generated-top structure. For actors with
no generated composition top, that field is `null`. For generated-child
actors, it is an object with only review-facing composition facts:

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
      "activation_kind": "spawn",
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
`?wiring` dump. It reports the current bounded names that downstream
consumers can use to discover the generated top, parent, child modules,
instance identity, activation kind, start and done handoff, named-drive
handoff, and per-instance parameter binding. The `kind` value is
`spawn_generated_top` for spawn-only generated tops and
`activation_generated_top` when another activation kind such as blocking `do`
participates. This is live public discovery metadata, not a frozen schema for
all future ISF releases.

Generated handoff names are reserved by the generated composition boundary. If
an actor interface already declares a would-be generated start/done handoff,
port-binding handoff, named-drive request handoff, or named-drive payload
handoff, lowering fails before emitting the generated top. The diagnostic names
the transaction, generated instance, and the handoff role; named-drive
diagnostics also name the drive and payload parameter when relevant.

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
