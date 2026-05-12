# Intent Scheduling Format (`.isf`) — Specification v0.6

Source material:
- [docs/INTENT_SCHEDULING_BRAINSTORM.md](INTENT_SCHEDULING_BRAINSTORM.md)
- [docs/book/src/13-intent-scheduling.md](book/src/13-intent-scheduling.md)
- [docs/book/src/13h-lowering-reference.md](book/src/13h-lowering-reference.md)

## 1. Purpose and Positioning

```text
SPECFORGE IntentIR -> .isf -> scheduled .fsm -> SystemVerilog / Verilog
```

`.isf` is a Lisp-ish hardware intent format above explicit cycle-authored
`.fsm`. Authors describe transactions, drives, waits, simple control flow, and
data movement. FSMGen lowers that intent into explicit scheduled `.fsm` text,
then uses the ordinary `.fsm` pipeline for HDL generation.

Cycles are not hidden. They are inferred into a generated `.fsm` artifact and a
schedule JSON report that can be reviewed.

## 2. CLI Contract

`bin/fsmgen` accepts `.isf` inputs anywhere it accepts a source path:

```bash
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --strict --outdir /tmp/isf-build isf/spawn_parent.isf
```

Current CLI behavior:
- `.isf` source lookup uses the same source resolver family as `.fsm` lookup.
- `--emit-schedule-json` emits the scheduler report and exits before HDL
  generation.
- Without `--emit-schedule-json`, a single generated `.fsm` file is written to a
  temporary file and fed into the normal `.fsm` pipeline.
- If lowering produces multiple `.fsm` files, `--outdir DIR` writes every file
  there and the parent actor file is fed into the normal pipeline.

## 3. Source Root

The root form is:

```lisp
(actor name
  actor_clause...)
```

The active parser accepts one actor root from the Lispish source and normalizes
the Lispish nested-head shape into canonical `(actor name ...)`.

Supported actor clauses:
- `(clock name)`
- `(reset name)` or `(reset (name async active_low))`
- `(watchdog N)`
- `(interface ...)`
- actor-level `(drive ...)` definitions
- `(transaction name ...)`
- `(rule name ...)`
- `(resources ...)`
- `(priority ...)`

Parser-carried but not currently semantically enforced by the scheduler:
- actor-level `(phase ...)`
- actor-level `(stage ...)`
- `(resources ...)`
- `(priority ...)`

Deprecated compatibility:
- `(handshake ...)` is accepted and ignored. The current activation model is
  direct `(on port ...)` plus the scheduler-created `can_accept` signal.

## 4. Clock, Reset, Watchdog

```lisp
(clock clk)
(reset rst_n)
(reset (rst_n async active_low))
(watchdog 65536)
```

Reset rules:
- Flat `(reset name)` defaults to synchronous reset.
- Names ending in `_n` or `_b` infer `active_low`; other names infer
  `active_high`.
- List form may include `async`, `active_low`, or `active_high`.
- Async resets lower to `.fsm` `(areset name)`.
- Sync resets lower to `.fsm` `(sreset name)`.

Watchdog rules:
- `(watchdog N)` is the actor default for every `(await ...)`.
- `(await port (watchdog M))` overrides the default for that wait.
- Await states decrement an inferred watchdog counter and transition to a
  timeout state at zero.

## 5. Interface

```lisp
(interface
  (input  name)
  (input  name (width N))
  (output name)
  (output name (width N)))
```

Default width is `1`. Interface entries lower into `.fsm` `+size` entries.
If an inferred scheduler storage name matches a declared interface port, the
declared port entry is kept and the inferred duplicate is suppressed.
Output ports are marked as public outputs by the `.fsm` emitter when assigned
from drive/rule output paths.

## 6. Drive Definitions and Calls

Drive definitions are actor-level reusable output phases.

Simple drive:

```lisp
(drive setup_phase
  (PADDR addr)
  (PWRITE is_write)
  (PSEL 1))
```

Parameterized drive:

```lisp
(drive (scl val)
  (scl val))
```

Drive call:

```lisp
(drive setup_phase)
(drive scl 1)
```

Current lowering:
- Each drive definition becomes a non-state DT block named `-drive_name`.
- Each drive call becomes one scheduled state.
- The call asserts `drive_name_start`.
- Parameterized calls also assign one inferred parameter signal per formal,
  such as `scl_val`.
- Drive DT assignments use flopped output assignment (`<-`) by default, so a
  drive call consumes one state and the driven port updates on the next clock.
- DT timing is assignment-family driven: `=` assignments are combinational;
  `<-` and `<=` assignments are sequential/flopped, whether they appear in a
  state DT `(state_name ...)` or a non-state DT `(-name ...)`.
- Adjacent drive calls are not merged. To drive several ports in the same
  cycle, put those port-value pairs in one drive definition.

## 7. Transactions

```lisp
(transaction name
  clause...)
```

Current transaction clauses:
- `(on port body...)`
- `(when condition body...)`
- `(drive name args...)`
- `(await port)` and `(await port (watchdog N))`
- `(sample port as name)`
- `(repeat count body...)`
- `(switch signal (value body...)...)`
- `(update var expr)`
- `(shift_left reg bit)`
- `(shift_right reg bit)`
- `(assemble part... as var)`
- `(extract word as field...)`
- `(do transaction)`
- `(spawn transaction as instance)`
- `(await_all done_port)`
- `(await_any done_port)`
- `(complete port)`
- `(latency (min N) (max M))`

### 7.1 Activation

`(on port ...)` creates an entry/idle state guarded by `port`.

The scheduler also creates `can_accept` and asserts it in entry states. This is
the current replacement for the old handshake-ready spelling.

Samples inside `(on ...)` lower to guarded D-input assignments (`<=`) on the
entry transition.

`(when condition ...)` may be used as the first transaction clause as an
activation guard. It may also appear later as inline branching.

### 7.2 Sampling and Variables

```lisp
(sample req_addr as addr)
```

Current lowering:
- Samples lower to `.fsm` D-input assignments (`<=`).
- Samples in `(on ...)` fire with the entry guard.
- Samples collected before a later drive/await are piggybacked onto that next
  scheduled state.
- Entry-state sample materialization and drive/await piggybacking are locked by
  [t/1100-isf-sample-piggyback.t](../t/1100-isf-sample-piggyback.t).
- The current implementation treats sampled names as inferred storage; richer
  wire-vs-register optimization is still future work.

### 7.3 Await and Timeout

```lisp
(await ready)
(await ready (watchdog 32))
```

Current lowering:
- The await state decrements `{transaction}_wd`.
- The normal transition fires when the awaited port is true.
- A timeout transition fires when the watchdog counter is zero.
- Timeout states assign `done` and `last_error` with flopped output
  assignments.

### 7.4 Repeat

```lisp
(repeat beats
  (await ready)
  (sample rdata as word))
```

Current lowering:
- The scheduler creates `{transaction}_cnt`.
- The repeat init state loads the count with `<=`.
- The repeat body is expanded inline.
- The repeat check state decrements with `<-` and loops while the counter is
  nonzero.
- Repeat counter width is inferred. Decimal literal counts use the minimum
  width that can represent the loaded count; named counts use the known
  interface/sample width; unknown count forms fall back to `8`.
- Top-level repeats and switch-nested repeats register the shared transaction
  counter at the widest required width.
- Repeat bodies lower named drive calls plus `await`, `sample`, `update`,
  `shift_left`, `shift_right`, `assemble`, and `extract`.

### 7.5 Inline Control Flow

`(when condition body...)` creates one decision state plus body states. The
true path enters the body, and the false path skips to the first state after
the whole `when` body. Current body support includes drive, await, sample,
complete, repeat, update, shift/assemble/extract data operations, and nested
`when`. Nested repeats inside `when` bodies register the shared transaction
counter width like top-level and switch-nested repeats.

`(switch signal (value body...)...)` creates one decision state with one branch
per unique value. Duplicate values are rejected. Current branch-body support
includes drive, await, sample, repeat, update, shift/assemble/extract data
operations, and nested `when`. Branch bodies exit to the first state after the
whole switch, so multi-state branches and repeat checks do not fall through
into later branch bodies.

### 7.6 Data Manipulation

```lisp
(update var expr)
(shift_left reg bit)
(shift_right reg bit)
(assemble header payload crc as packet)
(extract packet as header payload crc)
```

Current lowering:
- `update` emits one flopped assignment to `var`.
- `shift_left` emits a left shift plus inserted bit.
- `shift_right` emits a right shift plus inserted bit. When the shifted signal
  has a known interface or sampled-source width, the insert position uses that
  width; unknown-width values still fall back to the placeholder width
  expression.
- `assemble` emits a concat expression into the target variable.
- `extract` emits one extraction state. When the source word and destination
  fields have known widths, fields are assigned exact descending slices; if a
  width is unknown, the emitter keeps placeholder slice bounds for that field
  and any later field whose position can no longer be proven.

## 8. Composition Between Transactions

### 8.1 Blocking Sequence

```lisp
(do child_transaction)
```

Current lowering:
- The parent emits an await-shaped state guarded by `child_transaction_done`.
- The child idle state is rewired to wait on `child_transaction_start`.
- The child's terminal state assigns `child_transaction_done`.
- The parent `do` state asserts `child_transaction_start` directly.

### 8.2 Spawn

```lisp
(spawn child_worker as w0)
(await_all done)
```

Current lowering:
- Spawned transactions are emitted as separate child `.fsm` files.
- Each child gets `start`, `done`, and `last_error` ports if missing.
- The parent declares per-instance `instance_start` and `instance_done` signals.
- Each spawn state asserts its matching `instance_start` signal.
- `await_all` waits for all collected spawned done ports.
- `await_any` emits one guard per collected spawned done port and advances when
  any one of them fires.

Top-level child instantiation and spawn parameter binding are not part of the
shipped lowering contract yet.

## 9. Rules

```lisp
(rule always_ready
  (when ready)
  (valid 1)
  (trigger main_transfer))
```

Current lowering:
- Each rule emits one non-state DT block.
- `(when condition)` supplies the guard. The shipped guard form is a single
  port/signal condition.
- `(port value)` actions lower as guarded flopped assignments to that port.
- `(trigger transaction)` lowers as a guarded flopped assignment to
  `transaction_start`.
- Inline `(priority ...)` is parsed and currently ignored by lowering.

Separate `(priority ...)` declarations are parsed but not currently enforced as
arbitration policy.

## 10. Schedule JSON Report

`--emit-schedule-json` emits the current `Emitter::JSON` surface:

```json
{
  "source": "actor_name.isf",
  "scheduled_fsm": "actor_name.fsm",
  "clock": "clk",
  "reset": {
    "name": "rst_n",
    "kind": "async",
    "polarity": "active_low"
  },
  "watchdog": "65536",
  "port_count": 0,
  "inputs": 0,
  "outputs": 0,
  "state_count": 0,
  "inferred_storage": [],
  "transactions": [],
  "dt_blocks": [],
  "compile_issues": []
}
```

This is a machine-readable schedule report, not a stable public API contract
yet. It is intentionally generated from the same lowering IR as `.fsm` output.
Current scalar source values such as `watchdog` are preserved as parser-carried
strings in the JSON report. Assigned scheduler counters using the generated
`*_wd`, `*_cc`, and `*_cnt` naming families are reported as `kind: counter`
with the width inferred by `LoweringIR`.

## 11. Current Regression Fixtures

Representative shipped fixtures:
- [isf/apb_requester.isf](../isf/apb_requester.isf)
- [isf/burst_reader.isf](../isf/burst_reader.isf)
- [isf/full_featured.isf](../isf/full_featured.isf)
- [isf/i2c_master.isf](../isf/i2c_master.isf)
- [isf/spawn_parent.isf](../isf/spawn_parent.isf)
- [isf/spi_master.isf](../isf/spi_master.isf)
- [isf/uart_tx.isf](../isf/uart_tx.isf)
- [isf/when_test.isf](../isf/when_test.isf)
- [isf/switch_test.isf](../isf/switch_test.isf)

Focused tests:
- [t/1091-isf-parser-apb-requester.t](../t/1091-isf-parser-apb-requester.t)
- [t/1092-isf-lispish-adapter.t](../t/1092-isf-lispish-adapter.t)
- [t/1093-isf-parser-full-featured.t](../t/1093-isf-parser-full-featured.t)
- [t/1094-isf-scheduler-module-header.t](../t/1094-isf-scheduler-module-header.t)
- [t/1095-isf-scheduler-burst-reader.t](../t/1095-isf-scheduler-burst-reader.t)
- [t/1096-isf-schedule-json-report.t](../t/1096-isf-schedule-json-report.t)
- [t/1097-isf-start-signal-binding.t](../t/1097-isf-start-signal-binding.t)
- [t/1098-isf-await-any-sync.t](../t/1098-isf-await-any-sync.t)
- [t/1099-isf-repeat-data-ops.t](../t/1099-isf-repeat-data-ops.t)
- [t/1100-isf-sample-piggyback.t](../t/1100-isf-sample-piggyback.t)
- [t/1101-isf-extract-slices.t](../t/1101-isf-extract-slices.t)
- [t/1102-isf-repeat-counter-widths.t](../t/1102-isf-repeat-counter-widths.t)
- [t/1103-isf-switch-branch-exits.t](../t/1103-isf-switch-branch-exits.t)
- [t/1104-isf-when-branch-exits.t](../t/1104-isf-when-branch-exits.t)
- [t/1105-isf-size-deduplication.t](../t/1105-isf-size-deduplication.t)
- [t/1106-isf-schedule-json-counter-storage.t](../t/1106-isf-schedule-json-counter-storage.t)
- [t/1107-isf-when-body-ops.t](../t/1107-isf-when-body-ops.t)

## 12. Explicitly Deferred

- Old `(handshake ...)` semantics beyond ignored compatibility parsing.
- The removed `(assign ...)` action keyword.
- Top-level child instantiation and spawn parameter binding.
- Enforced resource arbitration and priority resolution.
- Full temporal `(contract ...)` assertions.
- Rich storage-class optimization in schedule reports.
- Full width inference for unknown-width `shift_right` and `extract` values.
- Treating schedule JSON as a stable public schema.
