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

**Current lowering**:
1. Parent emits an await-shaped state guarded by `child_done`
2. Child's idle state is rewired to watch `child_start`
3. Child's terminal state assigns `child_done`
4. Parent-side child-start binding still uses an internal `_start` placeholder

```lisp
(parent_do_1
  (<- (_start 1))
  (<read_phase_done
    (-> parent_do_2)))

(read_phase_idle_0
  (<read_phase_start
    (-> read_phase_drive_0)))

(read_phase_done_5
  (<- (done 1))
  (<- (read_phase_done 1))
  (-> read_phase_idle_0))
```

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

**Lowering**:
- One `.fsm` per unique child module
- Parent `.fsm` declares per-instance `name_start`/`name_done` signals
- `(await_all done)` → nested guards for all done signals
- `(await_any done)` currently waits on the first collected done signal

Driving the per-instance start signals, full composition-top instantiation, and
spawn parameter binding are still deferred.

```lisp
(parent_main_await_all_4
  (<w2_done
  (<w1_done
  (<w0_done
    (-> parent_main_done_5)))))
```

## `(await_all port)` / `(await_any port)`

```lisp
(await_all done)     ;; wait for ALL spawned children
(await_any done)     ;; current lowering waits for the first collected child
```

## Composition Architecture

```
spawn_parent.isf
    │
    ▼ LoweringIR
    │
    ├── child_worker.fsm    (child module with start/done ports)
    └── spawn_parent.fsm    (parent with per-instance signals)
```

The `--outdir DIR` flag writes all generated `.fsm` files:

```bash
./bin/fsmgen --strict --outdir output/ isf/spawn_parent.isf
# Writes: output/child_worker.fsm, output/spawn_parent.fsm
```

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
