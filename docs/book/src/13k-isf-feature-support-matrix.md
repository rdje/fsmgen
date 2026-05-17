# ISF Shipped Feature Matrix

This chapter is the book-facing checklist for the `.isf` surface that is
currently shipped. It does not replace the detailed chapters, the live spec,
or the downstream handoff. It gives reviewers one place to confirm which
feature families are supported, where to find examples, and where the explicit
backlog boundary starts.

A feature is "shipped" here only when the source shape, scheduled `.fsm`
lowering, runtime meaning, diagnostics, reports or review artifacts, and
focused regression evidence exist. Parser acceptance alone is not a support
claim.

## Status Vocabulary

| Status | Meaning |
| --- | --- |
| `shipped` | The listed source shape has documented lowering, runtime behavior, and regression coverage. |
| `shipped bounded surface` | The named subset is shipped; nearby wider forms fail closed or remain backlog. |
| `fail-closed boundary` | FSMGen recognizes the family enough to reject unsupported forms deliberately. It is not a runtime support claim. |

Anything outside the shipped rows below should be treated as backlog unless a
detailed chapter, [ISF Downstream Integration](13i-downstream-integration.md),
[ISF Types, Enums, And Aggregates](13j-type-enum-aggregate.md), or
[Feature Backlog](14-feature-backlog.md) says otherwise.

## Matrix

| Feature family | Status | Accepted authoring surface | Generated and reported behavior |
| --- | --- | --- | --- |
| `.isf` CLI input | shipped | `./bin/fsmgen file.isf`, `--strict file.isf`, `--emit-schedule-json`, and `--outdir DIR` for multi-file lower results. | Single-file actors lower to scheduled `.fsm` before HDL. Multi-file generated-child and accepted multi-domain actors write every scheduled `.fsm` artifact, then use the generated top for HDL generation. |
| Public parser and scheduler facades | shipped bounded surface | `FSM::Adapter::ISF->new(debug => ...)`, `parse_file`, `parse_source`, `FSM::Scheduler::ISF->new(...)`, `lower`, and `report`. | Public methods validate receivers and argument shapes before private parsing/lowering. The capability manifest advertises the live public contract under `embedding.isf_public_interface`. |
| Actor envelope | shipped | `(actor NAME ...)` with singleton `(clock ...)`, `(clock-domains ...)`, `(reset ...)`, `(watchdog ...)`, `(interface ...)`, `(storage ...)`, `(types ...)`, `(enums ...)`, `(imports ...)`, `(constants ...)`, `(params ...)`, `(resources ...)`, and reusable-library `(use ...)` where documented. | The scheduled `.fsm` preserves reviewable system, size, constants, params, type, enum, import, storage, rule, drive, and transaction artifacts. Duplicate singleton clauses fail closed. |
| Actor report metadata and params | shipped bounded surface | Actor-level `(params ...)`, `(phase NAME ...)`, and `(stage NAME ...)` metadata where documented. | Parameter defaults preserve source-order report entries in `actor_params[]`. Actor-level phase/stage clauses are parser-validated and report-only through `actor_phases[]` and `actor_stages[]`; they do not add generated `.fsm` or HDL runtime scheduling behavior. |
| Single-clock timing | shipped | `(clock clk)` plus optional `(reset ...)` and `(watchdog N)`. | The actor has one clock domain. Resets lower to the matching `.fsm` system reset form. Watchdogs create inferred counters for accepted awaits. |
| Multi-clock domains | shipped bounded surface | Actor-level `(clock-domains ...)` with named domains, one default domain, optional per-domain resets, and `(domain NAME)` ownership annotations. | Lowering partitions the actor into one scheduled `.fsm` per domain plus a generated top. Direct cross-domain reads, writes, activations, and bindings fail closed unless a shipped crossing primitive owns the path. |
| Acknowledged event CDC | shipped bounded surface | `(crossings (event NAME (from SRC SRC_REQ) (to DST DST_PULSE) (ready SRC_READY)))`. | The generated top wires a concrete acknowledged-event CDC child. The source side sees `ready`; the destination side receives a one-cycle pulse. No data payload or same-cycle delivery is promised. |
| Interface ports | shipped | `(interface (input NAME [(width N)|(type T)] [(domain D)]) (output NAME ...))`. | Ports become scheduled `.fsm` `+size` entries and module ports. Names are unique across input and output directions. |
| Actor-owned scalar storage | shipped | `(storage (var NAME (width N)) ...)` and `(variable NAME (width N))`. | Storage lowers to internal scalar registers, contributes width evidence, and appears in reports with role `actor_storage`. |
| Actor-owned banks | shipped bounded surface | `(storage (bank NAME (width N) (depth N)))` with pointer-selected `(store BANK IDX VALUE)` and `(load BANK IDX as TARGET)`. | Banks lower to deterministic scalarized entries such as `data_0`, `data_1`, and so on. Same-cycle read/write behavior follows the documented scalarized FIFO path. |
| Type aliases and package imports | shipped bounded surface | Actor-local `(types ...)`, actor-local `(enums ...)`, `.fsm` package imports, scalar `(type NAME)` declarations, and actor-owned aggregate storage aliases. | Scheduled `.fsm` preserves `+types`, `+enums`, and `+import` review artifacts. Imported package roots are embedded for CLI HDL generation. |
| Enum member values | shipped bounded surface | Local and package enum members in constants, scalar and aggregate/list parameter leaves, activation overrides, reusable-library use-site overrides, transaction/rule/drive scalar values, scalar expression operands, switch values/selectors, and standalone conditions/guards. | Authored enum tokens are preserved where scheduled `.fsm` can carry them; static specialization contexts resolve to literals before generated-top emission. Enum targets and operator-position enum members fail closed. |
| Aggregate scalar leaves | shipped bounded surface | Scalar member/item paths from declared actor-owned aggregate storage in documented RHS, target, guard, condition, switch, drive, and drive-call contexts. | Scalar leaves preserve authored paths in scheduled `.fsm` or lower through computed selector syntax when needed. Whole-record/list values, subaggregate writes, aggregate ports, and aggregate banks remain backlog. |
| Transaction entry | shipped | `(transaction NAME (on START ...) body...)`, direct entry samples, transaction ports, and parameter declarations where generated-child behavior owns them. | Entry logic generates start/idle behavior, captures accepted samples, and records transaction order in schedule reports. Unsupported entry-body forms fail closed. |
| Transaction ports and activation bindings | shipped bounded surface | Transaction `(ports ...)` declarations plus activation-site `(bind ...)` blocks on `do`, `spawn`, and rule `trigger` where documented. | Ports materialize as transaction-local data/control boundaries and generated handoff assignments. Reports expose bounded `transaction_port_bindings[]` provenance. Rule-trigger output bindings and snapshot-vs-live binding timing remain backlog. |
| Transaction assignments | shipped | `(set TARGET EXPR)` and `(update VAR EXPR)` with scalar targets and expression payloads in the documented value domain. | Assignments lower to scheduled `.fsm` state assignments with correct flopped/combinational semantics for the form. Scalar aggregate leaves and enum members are accepted only in shipped contexts. |
| Runtime expression divisor safety | shipped bounded surface | Division and modulo in shipped runtime expression contexts such as transaction RHS, wait counts, activation input bindings, rule guards/actions, drive bodies/calls, inline drives, and bank access index/value expressions. | Numeric/exact-width literal-zero divisors and actor-constant-zero divisors fail closed before scheduled `.fsm` emission. Nonzero literal/actor-constant divisors and dynamic scalar divisors lower unchanged; full dynamic nonzero proof remains backlog. |
| Named and inline drives | shipped | Actor-level `(drive NAME [(PARAM ...)] body...)`; transaction body `(drive NAME actual...)`; inline drive assignments where documented. | A named drive emits a non-state DT. A drive call consumes one state and transfers actuals through generated drive parameter signals. Inline drive assignments become state assignments. |
| Await and latency | shipped | `(await PORT)`, actor watchdogs, and `(latency (min N) (max N))` on transactions. | Awaits lower to wait/test states and watchdog counters when configured. Latency counters and schedule-report storage metadata are emitted for the supported shapes. |
| Static and dynamic waits | shipped bounded surface | `(wait N)`, `(wait 0)`, actor-constant wait counts, actor-parameter wait counts, accepted runtime wait count expressions, consecutive runtime waits, bank access predecessors, and pending-sample runtime waits in documented contexts. | Static waits create explicit wait states unless zero-count bypass semantics apply. Runtime waits use generated counters. Bank `load`/`store` predecessors keep their guarded scalarized assignments while splitting the following runtime count edge. Pending samples use a first active wait state on positive paths and sample-preserving zero-count clones for compatible successors such as drives, awaits, static waits, completion, independent scalar setters, independent shifts, independent assemble states, independent extract states, independent bank loads, independent bank stores, top-level await_all/await_any sync states, top-level spawn states, top-level transaction phase states, top-level ready/valid stages, top-level contract arm states, and loop decision states. Consecutive top-level runtime waits carry pending samples through zero-count links with generated downstream wait-entry clones when needed. |
| Transaction control flow | shipped bounded surface | Body-bearing `(when COND body...)`, `(switch SELECTOR branches...)`, `(while COND body...)`, `(until COND body...)`, and `(repeat COUNT body...)`. | Control flow lowers to explicit decision states, branch states, loop counters, and exits. The shipped repeat-body clause surface is limited to documented drive, await, sample, update, set, shift, assemble, extract, store/load, wait clauses, top-level repeat-body local blocking do, top-level when-body nested repeat local do, top-level when-body nested repeat generated-child do, top-level when-body nested repeat generated do with static params, top-level when-body nested repeat generated do with static params, bind handoffs, and same-domain domain metadata, top-level when-body nested repeat single generated spawn with optional static params, bind handoffs, same-domain domain metadata, source-order samples, same-body await_all, and single-pending same-body await_any, top-level switch-branch nested repeat local do, top-level switch-branch nested repeat generated-child do, top-level switch-branch nested repeat generated do with static params, top-level switch-branch nested repeat generated do with static params, bind handoffs, and same-domain domain metadata, top-level switch-branch nested repeat single generated spawn with optional static params, bind handoffs, same-domain domain metadata, source-order samples, same-body await_all, and single-pending same-body await_any, top-level repeat-body generated-child blocking do, top-level repeat-body generated blocking do with static params, bind handoffs, and same-domain domain metadata, samples before or after repeat-body do before the repeat check, and top-level repeat-body spawn with optional static params, optional bind handoffs, optional same-domain domain metadata, samples before or after spawn before same-body sync, same-body await_all, single-pending same-body await_any, and multi-pending repeat-body await_any with mandatory same-body await_all drain. |
| Transaction stages | shipped bounded surface | Top-level `(stage NAME (input READY) (output VALID))` transaction clauses. | A stage lowers to one ready/valid barrier state that drives `VALID` while active and advances only when `READY` is true. Actor-level phase/stage metadata is report-visible but has no runtime scheduling semantics yet. |
| Temporal contracts | shipped bounded surface | Top-level `(contract NAME (eventually SIGNAL (within CYCLES)))`. | Lowering emits monitor state/storage in scheduled `.fsm`; SystemVerilog projects the sticky fail bit into a verification-only assertion under `` `ifndef SYNTHESIS``. Verilog output remains assertion-free. |
| Data manipulation | shipped bounded surface | `(shift_left REG BIT [(width N)])`, `(shift_right REG BIT [(width N)])`, `(assemble PART... as TARGET)`, and `(extract WORD as FIELD... [(widths N...)])`. | Width evidence comes from declarations, samples, operation-local options, and structural derivation. `shift_left` can accept optional width evidence without requiring it for plain shifts; `shift_right` uses width evidence for the inserted MSB position. `assemble` can infer exactly one missing part width from a known target and known siblings; `extract` can infer exactly one missing destination field width from a known source and known siblings. Accepted forms avoid placeholder widths; ambiguous, non-positive, or contradictory widths fail closed. |
| Rules and trigger fan-in | shipped | Shorthand and long-form `(rule NAME GUARD actions...)`, `(set TARGET EXPR)`, shorthand assignments, and `(trigger TRANSACTION ...)`. | Rules lower to non-state DTs with guarded assignment semantics. Trigger sources feed a generated transaction fan-in or generated-child trigger handoff for parameterized triggers. |
| Rule conflicts and priorities | shipped bounded surface | Same-target/same-value rule writes, conservative mutual-exclusion proofs, and rule-local or top-level rule priority edges. | Compatible writes are accepted, priority can suppress lower-priority conflicting rule assignments, and unresolvable conflicts fail closed. SystemVerilog gets verification-only selector assertions for analyzed muxes. |
| Resources | shipped bounded surface | `(resources (resource NAME (kind rule_slot) (arbiter priority) (users RULE...)))`. Parser-recognized backlog kinds are documented. | `rule_slot` plus `priority` arbitration gates the whole bound rule DT for one cycle. Backlog resource kinds or unsupported arbiter/kind combinations fail closed. |
| Blocking child activation | shipped bounded surface | `(do child)` locally, including the documented top-level repeat-body local do subset, top-level when-body nested repeat local do subset, top-level when-body nested repeat generated-child do subset, top-level when-body nested repeat generated do with static params subset, top-level when-body nested repeat generated do with static params and bind handoffs subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain domain metadata subset, top-level switch-branch nested repeat local do subset, top-level switch-branch nested repeat generated-child do subset, top-level switch-branch nested repeat generated do with static params subset, top-level switch-branch nested repeat generated do with static params and bind handoffs subset, top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain domain metadata subset, repeat-body plain `(do child)` targeting already generated children, samples before or after repeat-body do before the repeat check, `(do child (params ...))`, `(do child (params ...) (bind ...))`, and `(do child (params ...) [(bind ...)] (domain NAME))` as the documented top-level repeat-body generated blocking do subset, and `(do child (params ...) (bind ...))` through generated-child activation at top level. | Plain local `do` asserts child start and awaits a fresh child done pulse. Repeat-body local `do` reaches the repeat check only after that done pulse; when that repeat is directly inside a top-level `when` body or top-level `switch` branch, the local do state lives in the branch-owned repeat region and gates the nested repeat check on fresh child done. When a repeat directly inside a top-level `when` body or top-level `switch` branch uses plain `(do child)` for a target already generated elsewhere, or uses `(do child (params ...))`, lowering emits one generated instance named `{parent}_{child}_repeat_do_{ordinal}` for that lexical nested do site and gates the nested repeat check on that instance's done handoff. When-contained and switch-contained `(do child (params ...) (bind ...))` wire generated-top input/output payload handoffs once for the lexical nested do site; when-contained and switch-contained `(do child (params ...) [(bind ...)] (domain NAME))` also record same-domain generated-instance metadata for that lexical nested do site. Repeat-body generated-child blocking do emits the same deterministic generated instance shape for top-level repeat-body generated-child do sites. Samples before repeat-body do materialize before the do state; samples after repeat-body do materialize after the fresh done guard and before the repeat check. Repeat-body generated blocking do with static params, optional bind handoffs, and optional same-domain metadata adds generated-top parameter binding, generated-top input/output payload handoff wiring, and clock-domain child-instance metadata for that lexical do site. Top-level parameterized/bound `do` keeps its broader generated child handoff surface at top level. |
| Spawned generated children | shipped bounded surface | `(spawn child as instance [(params ...)] [(bind ...)] [(domain NAME)])`, `(await_all done)`, `(await_any done)`, the documented top-level repeat-body spawn with optional static params, optional bind handoffs, optional same-domain domain metadata, samples before or after spawn before same-body sync, same-body await_all, single-pending same-body await_any, and multi-pending repeat-body await_any with mandatory same-body await_all drain subset, plus the documented top-level when-body and switch-branch nested repeat single generated spawn with same-body await_all or single-pending same-body await_any subsets. | Lowering emits parent, child, and generated top scheduled `.fsm` artifacts. Instance start/done handoffs, named-drive handoffs, parameter overrides, port-binding handoffs, same-domain ownership metadata, and schedule-report generated-composition/clock-domain metadata are bounded public review surfaces. Repeat-body spawn reuses one static generated child instance across iterations after await_all, exactly-one-pending await_any, or multi-pending await_any followed by same-body await_all observes fresh done for all outstanding children before the repeat check; sample-before-spawn materializes before the spawn state and sample-after-spawn materializes before the sync state. The branch-contained nested single-spawn subsets use the same generated-top handoff model and gate the nested repeat check on same-body await_all or on single-pending same-body await_any; multiple nested spawns and do-while-spawn-pending remain fail-closed. |
| Reusable ISF libraries | shipped bounded surface | `(library NAME (exports (actor A)) (actor A ...))`, actor `(imports (library NAME as ALIAS))`, and `(use ALIAS.actor as INSTANCE (params ...) (bind ...))`. | Library use lowers to generated composition artifacts and report `library_uses[]` metadata. The shipped catalog includes `common.fifo.fifo`; parameter-driven shape elaboration and nested library imports remain backlog. |
| Schedule reports | shipped bounded surface | `--emit-schedule-json` and in-process `report(...)`. | Reports expose actor, transaction, storage, rule, drive, generated-composition, library-use, clock-domain, crossing, issue, schema-version, and public-contract metadata only through bounded documented keys. |
| Schedule report schema and storage roles | shipped bounded surface | Schedule JSON `schema_version: 1`, public `schedule_report_full_schema_stable`, advertised key/value families, and `inferred_storage[].kind`/`role` values. | The version-1 schedule JSON schema is stable through the public contract. Storage roles include dynamic waits, activation handoffs, rule-trigger sources, transaction ports/bindings, and temporal contract monitors. Raw parser actor hashes, private `LoweringIR` internals, raw assignment lists, and recursive child report dumps remain private. |
| Diagnostics and downstream issue reporting | shipped | Fail-closed parser/lowering diagnostics, strict-mode compatibility cuts, and `bin/fsmgen-issue-bundle`. | Unsupported public forms reject before misleading artifacts are emitted. Downstream consumers can provide a reproducible issue bundle without understanding `.fsm` or `.isf` internals. |

## Examples By Family

### CLI Entrypoints

```bash
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --strict --outdir /tmp/isf-build isf/spawn_parent.isf
./bin/fsmgen -l sv isf/apb_requester.isf
```

`--emit-schedule-json` reports the scheduled intent view and exits before HDL
generation. `--outdir` is the public path for multi-file lowering, including
generated-child and accepted multi-domain actors. Plain `.isf` HDL generation
lowers through scheduled `.fsm` first, then continues through the existing HDL
pipeline.

The I2C-like fixture is a bounded realistic fixture, not a full I2C protocol
compliance claim. It is file-backed in the `isf` regression tier for strict
schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, switch-branch repeats, read-data shifting, sampled write-data bit
selection from `data[7]`, and absence of an implicit `data_bit` input.

The burst-reader fixture is file-backed in the `isf` regression tier for
strict schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, dynamic repeat counter storage, watchdog and latency counter
roles, sampled aliases, and completion/timeout pulse fan-in.

The UART-like fixture is a bounded transmit example, not a full UART protocol
compliance claim. It is file-backed in the `isf` regression tier for strict
schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, sampled-byte LSB drive selection from `byte_data[0]`, known-width
`shift_right`, repeat counter storage, busy drive sequencing, and completion
pulse behavior.

The phase fixture is file-backed in the `isf` regression tier for transaction
`(phase ...)` pass-through state coverage, parser-validated phase body
metadata, strict schedule JSON parity, scheduled `.fsm` structure, plain and
strict HDL generation, and delayed completion pulse behavior. It does not
claim executable actor-level phase scheduling; actor-level phase/stage
metadata remains report-only.

The switch fixture is file-backed in the `isf` regression tier for sampled
selector capture, explicit switch branch dispatch, default fallthrough to
completion, named-drive branch starts, strict schedule JSON parity, scheduled
`.fsm` structure, plain and strict HDL generation, and delayed completion
pulse behavior. It does not widen the deferred nested child/await-sync branch
body surface.

The when fixture is file-backed in the `isf` regression tier for
transaction-local conditional body coverage: entry drive setup, two conditional
decision states, multi-step true-body drives, false-path fallthrough,
compatible named-drive start fan-in, strict schedule JSON parity, scheduled
`.fsm` structure, plain and strict HDL generation, and delayed completion
pulse behavior. It does not widen the deferred nested child/await-sync body
surface.

The generated-composition fixture is file-backed in the `isf` regression tier
for spawned generated-child composition coverage: generated top emission,
parent/child scheduled `.fsm` artifacts, start/done handoffs, named-drive
request/payload handoffs, public input fanout, `await_all` synchronization,
strict schedule JSON parity, strict `--outdir` file emission, and strict HDL
generation for the generated top, parent, and child artifacts. It is a bounded
generated-composition fixture, not an external protocol compliance claim.

The rule/resource fixture is file-backed in the `isf` regression tier for
resource arbitration coverage: a rule-over-transaction priority resolution, a
`rule_slot` resource with `priority` arbitration, high-priority rule
ownership, lower-priority rule gating, bounded `priority_resolutions[]` and
`resource_arbitration[]` report metadata, strict schedule JSON parity,
scheduled `.fsm` structure, plain and strict HDL generation, and delayed
completion pulse behavior. It does not widen the deferred backlog resource
kinds or arbiter families.

The stage/contract fixture is file-backed in the `isf` regression tier for a
sampled ready/valid stream handoff with a bounded eventual acknowledgement
contract: sampled payload forwarding, top-level ready/valid barrier metadata,
top-level bounded eventual contract metadata, temporal monitor storage roles,
SystemVerilog sticky-fail assertion projection, strict schedule JSON parity,
scheduled `.fsm` structure, plain and strict HDL generation, and delayed
completion pulse behavior. It does not widen nested stages, nested contracts,
stage-local compute, expression contracts, min/max windows, or broader
temporal operators.

The FIFO datapath fixture is file-backed in the `isf` regression tier for the
shipped actor-owned bank access surface: a depth-4 `data` bank scalarized into
`data_0` through `data_3`, pointer-guarded accepted pushes, pointer-guarded
accepted pops, bounded `bank_accesses[]` report metadata, strict schedule JSON
parity, scheduled `.fsm` structure, and plain plus strict HDL generation. It
does not claim general memory-array HDL emission, write-first collision
behavior, bypassing, or arbitrary-depth parameterized FIFOs.

The FIFO controller fixture is file-backed in the `isf` regression tier for
the shipped controller-only matrix: idle, push-only, pop-only, and simultaneous
push+pop occupancy updates; actor-maintained `full`/`empty`; 2-bit `wr_ptr` and
`rd_ptr` wrap; compatible same-value fan-in metadata; strict schedule JSON
parity; scheduled `.fsm` structure; and plain plus strict HDL generation. It
does not claim data-bank storage or `data_out` datapath transfer behavior.

The FIFO library fixture is file-backed in the `isf` regression tier for the
shipped fixed reusable FIFO path. `isf/fifo_library_use.isf` imports
`common.fifo.fifo`, binds instance `u_fifo`, emits the importing actor,
specialized child, and generated top scheduled `.fsm` artifacts, records fixed
parameter overrides and use-site bindings in `library_uses[]`, and reaches
plain plus strict generated-top HDL generation. It is fixed to
`DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and `OCC_WIDTH=3`; it does not claim
parameter-driven interface/storage elaboration, nested imports, standalone
exported transactions or drives, arbitrary-depth generated FIFOs,
memory-array backend emission, or automatic non-zero reset values.

### Actor, Interface, Storage, And Timing

```lisp
(actor apb_requester
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65536)
  (interface
    (input start)
    (input req_addr (width 32))
    (output done)
    (output PADDR (width 32)))
  (storage
    (var captured_addr (width 32))))
```

This is the ordinary single-clock shape. For multi-clock actors, use
`(clock-domains ...)` instead of mixing it with `(clock ...)`:

```lisp
(clock-domains
  (domain bus  (clock bus_clk) (reset bus_rst_n))
  (domain core (clock clk)     (reset rst_n) :default))
```

### Acknowledged Event CDC

```lisp
(crossings
  (event rx_done
    (from bus  rx_done_req)
    (to   core rx_done_pulse)
    (ready rx_done_ready)))
```

The source domain may request only while `rx_done_ready` is true. The
destination domain receives a pulse later, after the generated CDC child moves
the event safely across the domain boundary.

### Transaction Body

```lisp
(transaction apb_transfer
  (on start
    (sample req_addr as addr))
  (set PADDR addr)
  (drive setup)
  (await PREADY)
  (complete done)
  (latency (min 2) (max 16)))
```

The scheduled `.fsm` review artifact owns the exact cycle placement: samples
materialize at the accepted entry boundary, drive calls consume states, awaits
test the selected port, and completion pulses the authored done output.

### Transaction Ports And Bindings

```lisp
(transaction read_word
  (ports
    (input addr (width 32))
    (output data (width 32)))
  ...)

(do read_word
  (bind
    (input addr req_addr)
    (output data read_data)))

(rule launch_read ready
  (trigger read_word
    (bind
      (input addr (+ base_addr offset)))))
```

Input bindings accept scalar signals, numeric literals, exact-width literals,
and non-empty list expressions. `do` and `spawn` support input and output
bindings; rule `trigger` supports input bindings only. Successful schedule
reports expose bounded `transaction_port_bindings[]` entries rather than raw
binding internals.

### Stage And Contract

```lisp
(transaction stream_word
  (on start)
  (stage wait_ready
    (input ready)
    (output valid))
  (contract finish_seen
    (eventually done (within 8)))
  (complete done))
```

The shipped stage surface is a top-level ready/valid barrier. The shipped
contract surface is a top-level bounded eventual check. Broader stage-local
compute, nested stages, registered-valid/skid-buffer variants, expression
contract operands, min/max windows, and global implication contracts remain
backlog.

### Waits And Repeat Bodies

```lisp
(params
  (WAIT_PARAM 2))

(transaction pulse_train
  (on start)
  (repeat count
    (drive pulse 1)
    (wait WAIT_PARAM)
    (drive pulse 0)
    (update count_seen (+ count_seen 1)))
  (complete done))
```

The repeat body may use the shipped inline body clauses documented in
[Transactions](13b-transactions.md) and [Control Flow](13d-control-flow.md).
`WAIT_PARAM` is an actor parameter wait count: scalar actor parameter defaults
that resolve to non-negative integer literals lower through the same static
wait contract as literals and actor constants.
Generated or spawned nested child activation, cross-domain repeat-body `do`,
deeper branch repeat activation, loop-contained repeat activation, and nested
`stage` or `contract` clauses remain outside the shipped repeat-body subset.

### Types, Enums, And Aggregate Leaves

```lisp
(types
  (type mode_bits (bits 2))
  (type frame_t (record (mode (bits 2)) (valid bit))))
(enums
  (mode (IDLE 0) (BUSY 1)))
(storage
  (var frame (type frame_t)))

(transaction publish
  (on start)
  (set frame.mode mode.BUSY)
  (when frame.valid
    (set out_mode frame.mode)))
```

The shipped aggregate path is scalar-leaf based. `frame.mode` and
`frame.valid` are accepted because `frame` is declared actor-owned aggregate
storage and the paths resolve to scalar leaves.

Runtime expression divisor safety is fail-closed for literal zero and fixed
actor constants that resolve to zero:

```lisp
(constants (ZERO 0) (DEN 2))
(set out (/ numerator divisor))  ;; accepted: dynamic divisor, no proof yet
(set out (/ numerator 8'd2))     ;; accepted: nonzero literal divisor
(set out (/ numerator DEN))      ;; accepted: nonzero actor constant divisor
(set out (/ numerator 0))        ;; rejected before scheduled .fsm emission
(set out (/ numerator ZERO))     ;; rejected before scheduled .fsm emission
```

### Bank Store And Load

```lisp
(storage
  (bank data (width 8) (depth 4))
  (var wr_ptr (width 2))
  (var rd_ptr (width 2)))

(transaction fifo_step
  (on push)
  (store data wr_ptr data_in)
  (load data rd_ptr as data_out)
  (complete done))
```

The bank is scalarized in scheduled `.fsm` review text. Pointer-selected
access remains explicit through `store` and `load`; memory-array backend
emission is not a current support claim.

### Rules, Priority, And Resources

```lisp
(rule high write_req
  (set valid 1))

(rule low read_req
  (priority over high)
  (set valid 0))

(resources
  (resource rule_exec
    (kind rule_slot)
    (arbiter priority)
    (users high low)))
```

The shipped `rule_slot`/`priority` subset can gate a whole bound rule DT for
one active cycle. Other resource kinds are documented names, not supported
runtime arbitration behavior yet.

### Generated Children

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

The lowerer emits a scheduled parent `.fsm`, scheduled child `.fsm`, and a
generated top `.fsm`. The generated top applies static parameter overrides and
wires start/done handoffs.

### Reusable Library Use

```lisp
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
    (output full full)
    (output data_out data_out)))
```

The cataloged `common.fifo.fifo` actor is a shipped reusable ISF library
definition. Library imports are semantic roots that still lower to scheduled
`.fsm`; they are not textual includes.

### Schedule JSON And Manifest Discovery

```bash
./bin/fsmgen --emit-schedule-json isf/apb_requester.isf
./bin/fsmgen --capability-manifest
./bin/fsmgen --emit-capability-manifest
```

The schedule report is the machine-readable companion to the scheduled `.fsm`
review artifact. The capability manifest advertises the live ISF public
contract, including this book chapter through `live_document_paths`.

```json
{
  "schema_version": 1,
  "actor_params": [
    { "name": "WIDTH", "value": 8 }
  ],
  "actor_phases": [
    { "name": "capture", "body": [["note", "metadata"]] }
  ],
  "actor_stages": [],
  "inferred_storage": [
    {
      "name": "wait_count",
      "kind": "counter",
      "role": "dynamic_wait_counter",
      "width": 4
    },
    {
      "name": "done_fail",
      "kind": "register",
      "role": "temporal_contract_monitor"
    }
  ]
}
```

The manifest flag `schedule_report_full_schema_stable` is true for
`schema_version: 1`. Consumers should still prefer advertised keys, value
families, and explicit role fields over parsing generated signal names as
semantic API.

### Downstream Issue Bundles

```bash
./bin/fsmgen-issue-bundle \
  --case path/to/fsmgen-facing-artifact \
  --issue-id sf-0001 \
  --speforge-version "SPECFORGE_COMMIT" \
  --failure-class unknown \
  --expected "FSMGen should accept this generated artifact" \
  --observed "FSMGen rejects it" \
  -- --strict --check --json
```

Downstream tools do not need to decide whether the root cause is `.fsm`,
`.isf`, parser, lowering, HDL, or API-specific before filing. The bundle
captures the FSMGen-facing artifact, exact command, environment, observed
stdout/stderr/status, JSON probes, generated artifacts, and a rerunnable
`commands.sh` so the issue can be reproduced from the FSMGen repository root.

## Explicit Non-Claims

These are important because they prevent the matrix from implying support that
does not exist:

- Multi-bit CDC payloads, FIFO CDC, reset-as-event semantics, and direct
  cross-domain data access are not shipped.
- Cross-domain repeat-body `do`, generated or spawned nested activation
  beyond the documented top-level branch-contained generated do cases and
  top-level branch-contained single-spawn cases, broader outstanding-child
  semantics, deeper branch repeat activation, nested
  `while`, nested `until`, `stage`, `contract`, and cross-domain activation
  inside repeat bodies remain outside the shipped repeat-body subset.
  In short, cross-domain activation inside repeat bodies is not shipped.
- Dynamic division/modulo nonzero proof is not shipped. Literal-zero and
  actor-constant-zero divisors are rejected, but arbitrary runtime scalar
  divisors are emitted unchanged.
- Enum members are not writable targets, and enum members in expression
  operator position fail closed.
- Aggregate interface ports, transaction-local aggregate ports, aggregate
  banks, subaggregate updates, and whole-record/list truthiness remain backlog.
- Backlog resource kinds are registry names, not runtime arbitration support.
- Actor-level phase and stage metadata is report-only; it does not schedule
  actor-level runtime phases, barriers, generated `.fsm` states, or HDL
  behavior.
- Direct `(on ...)` activation-site `(params ...)` is unsupported; static
  specialization belongs to spawn, generated blocking `do`, and rule-trigger
  generated activation sites.
- Rule-trigger output bindings, snapshot-vs-live binding timing selection,
  richer binding reports, and broader static binding conflict diagnostics are
  not shipped.
- Nested stages, stage-local compute/action bodies, multiple ready/valid
  endpoints, registered-valid variants, and skid buffers are not shipped.
- Temporal contracts beyond the top-level bounded eventual subset, including
  global implication forms, dynamic bounds, expression operands, and multiple
  outstanding obligations, are not shipped.
- Raw parser actor hashes, private `LoweringIR` internals, raw assignment
  provenance lists, and recursive child report dumps are not public schedule
  JSON API.
- VHDL is recognized as a target family, but the full VHDL backend is not
  shipped.

When a future slice widens any row above, update the detailed chapter, this
matrix, the live spec, the downstream handoff, the public contract or manifest
metadata when applicable, focused tests, and the feature backlog in the same
task-scoped commit.
