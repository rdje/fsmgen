# Lowering Reference

Every ISF construct mapped to its `.fsm` equivalent.

## Actor-Level Constructs

| ISF | .fsm |
|-----|------|
| `(actor name ...)` | `(?fsm:name ...)` |
| `(clock clk)` | `(+system (clock clk))` |
| `(reset (rst_n async active_low))` | `(areset rst_n)` |
| `(reset (rst async))` | `(areset rst)` |
| `(reset rst_n)` | `(sreset rst_n)` |
| `(watchdog N)` | watchdog counter + timeout state |
| `(interface (input p W) ...)` | `(+size (p W) ...)` |

## Transaction Clauses

| ISF | .fsm state kind | Generated |
|-----|----------------|-----------|
| `(on port ...)` | `entry` | Idle state: `(<port (<= ...) (-> next))` |
| `(sample port as name)` | piggyback | `(<= (name port))` in current/last state |
| `(drive name args...)` | `sequential` | Assert `name_start`, wire parameter signals |
| `(await port)` | `await` | `(-- wd) (<port (-> next)) (?wd (=0 → timeout))` |
| `(complete port)` | `terminal` | `(= (port> 1)) (-> idle)` |
| `(repeat N body...)` | `sequential` + `repeat_check` | Counter init → body → check with `?cnt` loop |
| `(when cond body...)` | `branch` | `(?cond (=1 → body) (=0 → skip))` |
| `(switch sig (v body...)...)` | `switch` | `(?sig (=v1 → b1) (=v2 → b2) ...)` |
| `(update var expr)` | `sequential` | `(<- (var expr))` |
| `(shift_left reg bit)` | `sequential` | `(<- (reg (| (<< reg 1) bit)))` |
| `(shift_right reg bit)` | `sequential` | `(<- (reg (| (>> reg 1) (<< bit W-1))))` |
| `(assemble (f1 f2) as v)` | `sequential` | `(<- (v (concat f1 f2)))` |
| `(extract w as (f1 f2))` | `sequential` | `(<= (f1 (slice w hi lo)))` per field |
| `(latency (min N) (max M))` | verification only | Cycle counter + comparators |

## Drive Definitions

| ISF | .fsm |
|-----|------|
| `(drive (name p1 p2) (port1 p1) ...)` | `(-name (= (port1> name_p1) <name_start) ...)` |
| `(drive name body...)` | `(-name (assignments <name_start))` |

## Rules

| ISF | .fsm |
|-----|------|
| `(rule name (when cond) (port val) ...)` | `(-name (= (port> val) <cond))` |
| `(rule name (when cond) (trigger tx))` | `(-name (= (tx_start 1) <cond))` |

## Composition

| ISF | .fsm |
|-----|------|
| `(do child)` | assert `child_start`, await `child_done` |
| `(spawn child as name)` | per-instance `name_start`/`name_done` |
| `(await_all port)` | `(<p2 (<p1 (<p0 (-> next))))` nested guards |
| `(await_any port)` | `(<p0 (-> next))` single guard |

## Implicit Signals

| Signal | Width | Purpose |
|--------|-------|---------|
| `can_accept` | 1 | Combinational ready: 1 in idle |
| `{drive}_start` | 1 | Fires combinational drive DT |
| `{drive}_{param}` | 1 | Per-parameter, wired to actual |
| `{transaction}_cnt` | 8 | Repeat counter |
| `{transaction}_wd` | log2(N) | Watchdog counter (decrements to 0) |
| `{transaction}_cc` | log2(M) | Latency cycle counter (increments) |
| `{transaction}_inc` | 1 | Latency increment enable |
| `{transaction}_lerr` | 1 | Latency error flag |
| `{child}_start` / `{child}_done` | 1 | Composition handshake |

## Signal Naming Convention

- Drive start signals: `{drive_name}_start`
- Drive parameters: `{drive_name}_{param_name}`
- Repeat counters: `{transaction}_cnt`
- Watchdog: `{transaction}_wd`
- Latency: `{transaction}_cc`, `_inc`, `_lerr`
- Child handshake: `{child}_start`, `{child}_done`
- Instance signals (spawn): `{instance_name}_start`, `{instance_name}_done`
