# Intent Scheduling Format (`.isf`) — Specification v0.6

Source material:
- [docs/INTENT_SCHEDULING_BRAINSTORM.md](INTENT_SCHEDULING_BRAINSTORM.md)
- [docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](ISF_PUBLIC_INTERFACE_CONTRACT.md)
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

## 1.1 Intent Abstraction Layers

FSMGen uses the following terminology when discussing intent levels:

- `.fsm` is **Intent Abstraction Layer 0** (`IAL0`). It is explicit
  cycle-authored hardware intent. It owns DT structure, assignment operators,
  state and non-state activation regions, mux-selection semantics, and exact
  runtime behavior. It is the semantic audit artifact produced before HDL.
- Current `.isf` is **Intent Abstraction Layer 1** (`IAL1`). It is scheduling
  intent above `.fsm`: transactions, rules, drives, samples, waits, repeats,
  transaction composition, spawned-child activation, and constraints lower into
  reviewable `IAL0` `.fsm`.

Additional layers are not assumed. A future `IAL2` should be introduced only
if it carries a real semantic level that is not merely nicer spelling for
existing ISF constructs. Plausible reasons include reusable protocol-level
intent objects, such as an authored APB read or AXI burst operation, or
platform/resource mapping decisions above individual transactions. Weak
reasons include aliases, macro wrappers, syntax sugar, or any form that lacks
a distinct runtime model. Every layer must preserve a clear lowering chain and
runtime semantics.

## 1.2 Construct Shipping Rule

An ISF construct is shipped only when its syntax, lowering, and runtime
semantics are all explicit. Parser acceptance alone is not support.

For every current or future construct, the public contract must answer:
- what source shape is accepted and what malformed shape fails closed;
- what scheduled `.fsm` artifact is emitted, or which targeted diagnostic is
  raised before emission;
- what the runtime behavior means in cycles, activation, storage, handshakes,
  conflicts, and completion;
- what schedule-report or review-artifact visibility downstream consumers can
  rely on; and
- what focused regression or fixture proves the behavior.

If one of those answers is not ready, the construct remains deferred, backlog,
or fail-closed compatibility input rather than a shipped ISF feature.

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
- The plain `file.isf` path is expected to reach generated HDL with clean
  stderr on success.
- `--strict` is accepted on the plain `file.isf` path and still routes through
  scheduled `.fsm` generation before HDL output.
- If lowering produces multiple `.fsm` files, `--outdir DIR` writes every file
  there and the parent actor file is fed into the normal pipeline.
- The public `--outdir` path is expected to write scheduled `.fsm` file content
  matching the in-process lower-result `files` map.

The live downstream-consumer API contract for these CLI surfaces, the
`FSM::Adapter::ISF` / `FSM::Scheduler::ISF` in-process facades, and the bounded
schedule-report key families is
[docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](ISF_PUBLIC_INTERFACE_CONTRACT.md). Its
machine-readable form is advertised through
`--capability-manifest -> embedding.isf_public_interface`. That contract must
evolve in the same slice as any implementation change that widens or changes
the public ISF surface; it is not a frozen API schema. Its identity/stability
metadata and
`public_top_level_presence_keys` list are audited as exact discovery data across
direct and manifest views. Its advertised entrypoint lists are also audited as
exact and duplicate-free across those views, and its ISF-specific CLI option
list is audited the same way. Its parser and scheduler method-name metadata is
also audited as exact and duplicate-free, as is its public constructor option
metadata. Its lower-result discovery metadata is audited as exact across direct
and manifest views too. Its schedule-report metadata fields and downstream
guidance list are audited as exact across the same views. Its `tested_by`
provenance metadata is also audited as an exact repo-local test list.
Its lower-result file sub-shape metadata is audited as exact for scheduled
`.fsm` basenames and scheduled text roots.
Its schedule-report transaction-ordering metadata is audited as exact for the
lexically sorted transaction list and emitted-order per-transaction states.
Its CLI success-shape metadata is audited as exact for the schedule JSON,
`--outdir`, and plain HDL-generation paths.
Its strict CLI success-shape metadata is audited as exact for accepted
`--strict file.isf` HDL generation.
Its in-process facade return-shape metadata is audited as exact for
`parse_file(...)`, `parse_source(...)`, `lower(...)`, and `report(...)`.

The public adapter and scheduler constructors require the exact
`FSM::Adapter::ISF` or `FSM::Scheduler::ISF` class invocant and currently
accept only the `debug` option. Malformed invocants, option lists, and
unsupported option names are rejected before object creation.
The public parser and scheduler facade methods require object receivers returned
by their corresponding `new(...)` constructors before private internals are
used. The public parser facade methods also validate their argument shape:
`parse_file(...)` requires one defined scalar path naming a readable `.isf`
file, and `parse_source(...)` requires defined scalar source text and source
label values.
The public scheduler facade methods validate the actor shell before lowering:
`lower(...)` and `report(...)` require one actor hash with scalar `actor_name`,
array `transactions`, and hash `interface` fields.
The machine-readable contract publishes that required handoff shell as
`actor_shell_required_keys`; other raw actor fields are still private parser
output.
It also publishes the shell value shapes: scalar `actor_name`, array
`transactions`, and hash `interface`.
The current bounded parser handoff also advertises the `interface` subshape:
`inputs` and `outputs` are arrays, and each public port entry has unique
non-empty scalar `name` plus positive integer `width`, with omitted source
widths normalized to `1`.
It also advertises the transaction-entry shell: `transactions` is an array of
entries with scalar `name` and `clauses` array fields. Those shapes are
live-contract metadata for scheduler-consumable actors, not a freeze of the
full raw actor hash or the private transaction clause payloads.
The actor identity shape is also explicit: `actor_name` is a non-empty scalar
identifier preserved from the ISF actor root.
Current actor timing fields are explicit too: `clock` is a non-empty scalar
when configured, `reset` is null when omitted or a hash with scalar `name`,
`kind`, and `polarity`, and `watchdog` is null when omitted or a positive
integer.
Current rule entries are advertised as a bounded shell: `rules` is an array of
entries with scalar `name`, optional `when`, and `actions` array fields. Rule
condition/action payload contents remain private scheduler input.
Current actor-level drive definitions are advertised as a bounded shell:
`drives` is a hash keyed by drive name, and each entry has `params` and `body`
array fields. Body entries are parser-validated scalar `(port value)` pairs;
detailed drive semantics remain private scheduler input.
The same contract publishes the public return containers: parser facades return
scheduler-consumable actor hash references, `lower(...)` returns a hash
reference with the advertised lower-result keys, and `report(...)` returns the
schedule-report JSON string.
The contract's facade-shape metadata for these receiver, argument, path, and
actor-shell boundaries is audited as exact across direct and manifest views.
Public facade boundary failures are advertised as bounded scalar diagnostics
before object creation, private parsing, or private lowering/reporting begins.
For multi-file lowering, the current schedule report is parent-scoped. Child
scheduled `.fsm` text is exposed through the lower-result `files` map rather
than folded into the report.

## 3. Source Root

The root form is:

```lisp
(actor name
  actor_clause...)
```

The active parser accepts one actor root from the Lispish source and normalizes
the Lispish nested-head shape into canonical `(actor name ...)`.
Accepted parser output preserves `name` as the public actor-shell
`actor_name`; nested or otherwise non-scalar actor names are rejected before the
parser returns an actor shell.

Supported actor clauses:
- `(clock name)`
- `(reset name)` or `(reset (name async active_low))`
- `(watchdog N)`
- `(interface ...)`
- actor-level `(drive ...)` definitions
- `(transaction name ...)`
- `(rule name condition action...)`
- `(rule name (when condition) action...)`
- `(resources ...)`
- `(priority ...)`

Actor-shell singleton clauses are not mergeable. At most one `(clock ...)`,
`(reset ...)`, `(watchdog ...)`, `(interface ...)`, and `(resources ...)`
clause may appear in an actor. Duplicate singleton clauses are rejected before
the parser returns an actor shell instead of letting later clauses overwrite
earlier public fields.

Additional actor clauses with mixed parser/scheduler behavior:
- actor-level `(phase name property...)`, structurally validated as a
  non-empty scalar name plus list-form body entries; duplicate actor phase
  names are rejected.
- actor-level `(stage name property...)`, structurally validated as a
  non-empty scalar name plus list-form body entries; duplicate actor stage
  names are rejected. This metadata is parser-carried for downstream
  inspection only today; it is not copied into `LoweringIR`, schedule JSON,
  generated `.fsm`, generated composition tops, or HDL.
- `(resources ...)`, structurally validated as resource entries with
  `(arbiter priority|round_robin)` plus optional `(kind ...)` and
  `(users ...)`; `rule_slot` + `priority` resources are scheduler-enforced.
- actor-level `(priority lhs over rhs)`

Deprecated compatibility:
- `(handshake name (valid signal) (ready signal))` is structurally validated
  and then ignored. The current activation model is direct `(on port ...)`
  plus the scheduler-created `can_accept` signal.

## 4. Clock, Reset, Watchdog

```lisp
(clock clk)
(reset rst_n)
(reset (rst_n async active_low))
(watchdog 65536)
```

Reset rules:
- Clock names must be scalar when a `(clock ...)` clause is present.
- `(clock ...)`, `(reset ...)`, and `(watchdog ...)` are actor-level
  singleton clauses; duplicates are rejected before actor-shell return.
- Flat `(reset name)` defaults to synchronous reset.
- Names ending in `_n` or `_b` infer `active_low`; other names infer
  `active_high`.
- List form may include `async`, `active_low`, or `active_high`.
- Reset names must be scalar when a `(reset ...)` clause is present.
- Async resets lower to `.fsm` `(areset name)`.
- Sync resets lower to `.fsm` `(sreset name)`.

Watchdog rules:
- `(watchdog N)` is the actor default for every `(await ...)`.
- `N` must be a positive integer.
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
Accepted parser output exposes the interface handoff as `inputs` and `outputs`
arrays with unique non-empty scalar port `name` and positive integer `width`
entries. Malformed directions, duplicate names across either direction, nested
names, and non-positive or non-integer widths are rejected before the parser
returns an actor shell.
`(interface ...)` is an actor-level singleton clause; repeated interface blocks
are rejected instead of merged or overwritten.
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
- Accepted parser output exposes drives as a hash of shell entries keyed by
  unique non-empty drive name. Each entry contains `params` and `body` arrays.
  Duplicate drive names, nested or otherwise non-scalar drive names, duplicate
  parameter names, and nested or otherwise non-scalar parameter names are
  rejected before the parser returns an actor shell. Body entries are
  structurally validated as scalar `(port value)` pairs before parser return;
  richer body-expression semantics are not frozen as a public API by the
  actor-shell drive-shape metadata.
- Each drive definition becomes a non-state DT block named `-drive_name`.
- Each drive call becomes one scheduled state.
- The call asserts `drive_name_start`.
- Parameterized calls also assign one inferred parameter signal per formal,
  such as `scl_val`.
- Named drive calls use exact positional arity: a drive with `N` formal
  parameters requires exactly `N` actual values at every known drive call.
  Missing actuals and extra actuals fail closed during lowering instead of
  leaving parameter signals unbound or silently ignoring values.
- Hash-backed drive DT emission is deterministic: drive definitions are emitted
  lexically by drive name after transaction/rule-created DTs and any generated
  rule-trigger fan-in DTs.
- Drive DT assignments use flopped output assignment (`<-`) by default, so a
  drive call consumes one state and the driven port updates on the next clock.
- When a generated scheduled `.fsm` assignment targets a declared actor output,
  the LHS uses the normal `.fsm` output marker, such as `scl>`, `done>`, or
  `rdata>`, for all assignment families.
- DT selector logic is combinational. Assignment families decide the target
  behavior selected by that logic: `=` assignments drive combinational mux
  outputs, `<-` and `<=` assignments drive sequential/flopped targets, and
  `<1` assignments request one-cycle delayed pulses whether they appear in a
  state DT `(state_name ...)` or a non-state DT `(-name ...)`.
- The machine-readable ISF public contract advertises those operator families
  through `dt_assignment_operator_family_map`.
- Adjacent drive calls are not merged. To drive several ports in the same
  cycle, put those port-value pairs in one drive definition.

## 7. Transactions

```lisp
(transaction name
  clause...)
```

Accepted parser output exposes transactions as an array of shell entries with
unique non-empty scalar `name` and `clauses` array fields. Duplicate, nested,
empty, or otherwise non-scalar transaction names are rejected before the parser
returns an actor shell. Clause payload contents remain scheduler input and are
not frozen as a public API by the actor-shell transaction-shape metadata.

Current transaction clauses:
- `(on port body...)`
- `(when condition body...)`
- `(drive name args...)`
- `(await port)` and `(await port (watchdog N))`
- `(sample port as name)`
- `(repeat count body...)`
- `(switch signal (value body...)...)`, with optional `(default body...)` or
  `(_ body...)` fallback branch
- `(update var expr)`
- `(shift_left reg bit)`
- `(shift_right reg bit)`
- `(assemble part... as var)`
- `(extract word as field...)`
- `(extract word as field... (widths N...))`
- `(do transaction)`
- `(spawn transaction as instance)`
- `(await_all done_port)`
- `(await_any done_port)`
- `(complete port)`
- `(latency (min N) (max M))`

Unsupported transaction clause heads now fail closed during lowering instead
of being silently ignored. The same applies inside currently lowered body
contexts: `when` bodies, `switch` branches, and `repeat` bodies each have a
bounded supported subset matching the shipped lowerer. Deferred-but-recognized
`(contract ...)` and transaction `(stage ...)` clauses keep their more specific
diagnostics.

### 7.1 Activation

`(on port ...)` creates an entry/idle state guarded by scalar `port`.
The only supported inline body clauses inside `(on ...)` are
`(sample port as name)` forms; other activation-body forms fail closed during
lowering instead of being ignored.

The scheduler also creates `can_accept` and asserts it in entry states. This is
the current replacement for the old handshake-ready spelling. Deprecated
`(handshake name (valid signal) (ready signal))` metadata is compatibility-only:
the parser validates its shape, but the scheduler does not lower old handshake
semantics.

Samples inside `(on ...)` lower to guarded D-input assignments (`<=`) on the
entry transition.

`(when condition ...)` may be used as the first transaction clause as an
activation guard. It may also appear later as inline branching.

### 7.2 Sampling and Variables

```lisp
(sample req_addr as addr)
```

Current lowering:
- Sample clauses are structurally validated as exactly
  `(sample port as name)` with scalar `port` and scalar `name`. This applies
  both to standalone transaction-body samples and to samples nested directly in
  `(on ...)`.
- Samples lower to `.fsm` D-input assignments (`<=`).
- The `<=` operator is intentional: the sampled name denotes the D-input /
  next-value side in the state where the sample is emitted. Lowering samples
  with `<-` would make that name denote the previous Q/output value for
  same-state consumers, especially when a drive follows the samples and its
  parameter wiring consumes a sampled alias. That would force an extra state or
  risk stale data.
- Samples in `(on ...)` fire with the entry guard.
- Samples collected before a later drive/await are piggybacked onto that next
  scheduled state.
- Samples collected before a data operation materialize in a sample state
  before the data-operation state, so the data operation reads the captured
  value rather than the previous value.
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
- The await state tests the current `{transaction}_wd` Q value.
- The normal transition fires when the awaited port is true.
- A timeout transition fires when the watchdog counter is zero.
- A `>0` watchdog branch schedules the watchdog decrement for the next counter
  value. The zero test and decrement branch are same-cycle DT selector
  equations, not procedural statements. The `>0` guard also avoids describing
  a zero-watchdog decrement to all ones; timeout normally exits the await state,
  but the emitted next-value selection stays blocked at zero.
- Timeout states assign `done` with a one-cycle delayed pulse (`<1`) and
  `last_error` with a flopped output assignment (`<-`).

### 7.4 Completion

```lisp
(complete done)
```

Current lowering:
- `(complete port)` is structurally validated as exactly one scalar `port`
  target before scheduled `.fsm` emission.
- `(complete port)` creates a terminal state that returns the transaction to
  idle.
- The completion port assignment lowers to `(<1 (port 1))`, producing a
  one-cycle delayed pulse rather than a sticky flopped status bit.
- Protocol/output drive phases should not also drive the same completion
  signal with `<-`, because the `.fsm` backend rejects mixed pulse-delayed and
  non-pulse sequential operators on one LHS.

### 7.5 Latency

```lisp
(latency (min 1) (max 64))
```

Current lowering:
- Latency metadata accepts one or both `(min N)` and `(max N)` options.
- `N` must be a positive integer, each option may appear at most once, and
  `min` must be less than or equal to `max` when both are present.
- The scheduler creates a transaction cycle counter, an increment source, and
  latency error wiring without adding an authored transaction state.
- A valid explicit `max` bound drives the generated counter width and max
  violation check; omitted bounds use the scheduler defaults.

### 7.6 Repeat

```lisp
(repeat beats
  (await ready)
  (sample rdata as word))
```

Current lowering:
- Repeat clauses are structurally validated as `(repeat count body...)` with a
  scalar non-empty count and at least one body clause before counter emission.
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

The repeat count is a runtime counter load value, not an elaboration count.
Literal counts give statically reviewable loop bounds. Named counts may be
dynamic scalar signals when their width is known, but they make transaction
latency data-dependent and require a clear zero-count policy before the loop
can be treated as fully general. Future spawn-in-repeat support must preserve
the same rule: the loop reactivates a lexically named static child instance; it
does not create one child instance per iteration.

### 7.7 Inline Control Flow

`(when condition body...)` is structurally validated with one scalar or
list-form condition and at least one list-form body clause before branch
expansion. It creates one decision state plus body states. The true path enters
the body, and the false path skips to the first state after the whole `when`
body. Current body support includes drive, await, sample, complete, repeat,
update, shift/assemble/extract data operations, and nested `when`. Nested
repeats inside `when` bodies register the shared transaction counter width like
top-level and switch-nested repeats.

This transaction clause is distinct from the rule guard spelling
`(rule name (when condition) action...)`. In a rule, `(when condition)` is a
guard clause with no body of its own; it guards the rule actions that follow
it. The preferred rule shorthand is `(rule name condition action...)`, which
normalizes to the same public `when` field as the long guard spelling.

`(switch signal (value body...)...)` is structurally validated with one scalar
signal and one or more list-form branches before branch expansion. Each branch
must provide one scalar value and at least one list-form body clause. The
scheduler then creates one decision state with one branch per unique explicit
value. Duplicate explicit values are rejected. A switch may also contain one
fallback branch, spelled `(default body...)` or `(_ body...)`. Those spellings
are aliases and are rejected if both appear in the same switch. If no authored
fallback branch is present, the scheduler emits an implicit `.fsm`
`(default (-> next_state))` fallthrough branch to the first state after the
whole switch.

The generated `.fsm` default selector means "no explicit sibling branch
predicate matched." Downstream `.fsm` lowering expands it as the logical
negation of the OR of every explicit branch predicate, such as
`!(opcode == 0 || opcode == 1)` for a two-value switch. This preserves a real
else/default branch without asking ISF to synthesize that Boolean expression
itself, and it avoids the old invalid pattern of duplicating one explicit case
such as `=0` for fallthrough.

Current branch-body support includes drive, await, sample, repeat, update,
shift/assemble/extract data operations, and nested `when`. Branch bodies exit
to the first state after the whole switch, so multi-state branches and repeat
checks do not fall through into later branch bodies.

### 7.8 Data Manipulation

```lisp
(update var expr)
(shift_left reg bit)
(shift_right reg bit)
(shift_right reg bit (width N))
(assemble header payload crc as packet)
(extract packet as header payload crc)
(extract packet as header payload crc (widths 4 8 4))
```

Current lowering:
- `update` is structurally validated as `(update var expr)` with one scalar
  target `var` and one scalar or list expression payload. It emits one flopped
  assignment to `var`.
- `shift_left` is structurally validated as `(shift_left reg bit)` with scalar
  `reg` and scalar `bit`, then emits a left shift plus inserted bit.
- `shift_right` is structurally validated as
  `(shift_right reg bit [(width N)])` with scalar `reg` and scalar `bit`, then
  emits a right shift plus inserted bit. When the shifted signal has a known
  interface, sampled-source, assemble-inferred, or explicit `(width N)` width,
  the insert position uses that width. Unknown-width values now fail closed
  before scheduled `.fsm` emission instead of emitting a placeholder `WIDTH`
  expression. Explicit `(width N)` is an assertion: it may fill missing width
  evidence, but it must match any already-known width for the shifted register.
- `assemble` is structurally validated as `(assemble part... as target)` with
  one or more scalar parts and one scalar target, then emits a concat
  expression into the target variable. The private width map infers the target
  width as the sum of known part widths. When every part width is known and
  the target already has a known width, the sum must match the target width or
  lowering fails closed. Unknown part widths may still be accepted for the
  reviewable concat expression, but they are not used as width evidence.
- `extract` is structurally validated as
  `(extract word as field... [(widths N...)])` with one scalar source word and
  one or more scalar destination fields. It emits one extraction state. When
  the source word and destination fields have known widths, or when the clause
  supplies an ordered `(widths N...)` list matching the field count, fields are
  assigned exact descending slices. Unknown field widths fail closed instead
  of producing placeholder slice bounds. Explicit widths must be positive
  integers and must not conflict with already known field widths. When the
  source word width is known, the sum of field widths must match it.

Width evidence is transaction-local and private to lowering today. Interface
declarations seed it, sampled aliases inherit known source widths, explicit
`shift_right` and `extract` options add local evidence, and `assemble` can
infer target width from known parts. The evidence is collected from the whole
transaction clause tree before scheduled state emission, so it is not
source-order-sensitive. Schedule reports expose positive integer `width`
metadata for inferred scheduler counters and for register storage whose ISF
width evidence is known.

Planned width-evidence precedence for this tree is: actor interface
declaration, operation-local explicit option, sampled-alias propagation,
structural derivation from `assemble`/`extract`, then generated scheduler
storage for existing counter families. Explicit width options are author
assertions, not force-casts: they may fill unknown facts, but they must match
already-known facts for the same name. Once an operation family is migrated by
the data-width tree, that family must fail closed instead of emitting
`WIDTH`, `HIGH`, or `LOW` placeholders for accepted source.

The migrated data-operation families now follow that rule. `extract` accepts
only exact descending slices and fails when field widths are unknown, explicit
field widths conflict with known facts, or the sum of field widths disagrees
with a known source word width. `shift_right` uses a concrete insert position
from known or explicit width evidence and fails when width evidence is missing
or contradictory. `assemble` derives a target width only from fully known part
widths and rejects known target-width mismatches. `shift_left` does not need
separate width evidence for its insertion position.

## 8. Composition Between Transactions

### 8.1 Blocking Sequence

```lisp
(do child_transaction)
```

Current lowering:
- The parent emits an await-shaped state guarded by `child_transaction_done`.
- The child idle state is rewired to wait on `child_transaction_start`.
- `do` is structurally validated as `(do transaction)` with one scalar child
  transaction operand before child-target resolution.
- The `child_transaction` target must name a declared transaction in the same
  actor. Forward references are accepted; missing targets fail before
  scheduled `.fsm` emission.
- The rewired child idle state enters the first non-entry child state, so the
  child body does not need to begin with a drive state.
- The child's terminal state pulses `child_transaction_done` with `<1`, matching
  the completion-pulse contract and avoiding sticky done bits across repeated
  blocking calls.
- The parent `do` state asserts `child_transaction_start` directly.

### 8.2 Spawn

```lisp
(spawn child_worker as w0)
(await_all done)
```

Current lowering:
- Spawned transactions are emitted as separate child `.fsm` files.
- `spawn` is structurally validated as
  `(spawn transaction as instance [(params (NAME value) ...)])` with one
  scalar child transaction, one scalar instance name, and at most one validated
  parameter override block before spawned child collection.
- The spawned transaction target must name a declared transaction in the same
  actor. Forward references are accepted; missing targets fail before
  scheduled `.fsm` emission.
- Each spawned child exposes `start` as an input and `done` as an output. Named
  drive calls inside a spawned child expose drive handoff outputs such as
  `<drive>_start` and `<drive>_<param>` instead of directly exporting the
  actor output driven by that drive body.
- The parent exposes per-instance `instance_start` outputs and
  `instance_done` inputs for generated-top wiring. Each spawn state asserts
  its matching `instance_start` signal.
- `await_all` and `await_any` are structurally validated as
  `(await_all done_port)` and `(await_any done_port)` with one scalar done-port
  operand before sync-state emission.
- `await_all` waits for all collected spawned done ports using one scheduled
  transition suffix guarded by their logical AND, for example
  `(-> parent_done <(& w0_done w1_done w2_done))`.
- `await_any` emits one guard per collected spawned done port and advances when
  any one of them fires.
Focused regressions cover both synchronization forms.

Top-level generated-child instantiation is now shipped for the covered
spawned-child fixture set. Spawn parameter declaration, validation, scheduled
child `+params` emission, per-instance override preservation, and generated-top
application now all flow through the normal composition pipeline. The public
contract is:

- Multi-file spawn actors expose an explicit generated `?top` source over the
  scheduled parent module and spawned child modules.
- The scheduled parent module keeps the actor name. The generated top uses a
  distinct deterministic name, initially `<actor_name>_top`.
- The generated top re-exports the actor public interface. Per-instance
  `instance_start`/`instance_done` handoff signals are internal top wiring, not
  public top ports.
- The scheduled parent exposes `instance_start` as an output port and
  `instance_done` as an input port for each spawned instance. Each spawned
  child exposes `start` as an input and `done` as an output.
- The generated top wires `parent.instance_start` to `instance.start`,
  `instance.done` to `parent.instance_done`, and child named-drive handoff
  outputs to parent per-instance handoff inputs.
- A spawned child returns to its `start`-guarded idle state after completion and
  must not re-enter the body until the next start pulse.
- Spawn instance names are actor-local identities and must be unique. Multiple
  instances of one child transaction share the same child module with distinct
  instance names.
- Spawn parameter overrides are emitted on the generated `?fsmc` instance
  through the existing composition `(params ...)` override surface.

`spawn` is static HDL composition plus runtime activation. The generated child
instance exists for the lifetime of the generated top. Executing the spawn site
asserts the instance start path; completion only returns that same instance to
idle. Reaching the same lexical spawn again, including through future
spawn-in-repeat support, reuses the same physical instance. The scheduler must
reject or sequence any path that could start a still-busy child before its
fresh done pulse is observed.

Parameterized spawn uses one optional nested `params` block after the instance
name:

```lisp
(transaction child_worker
  (params
    (WIDTH 8)
    (LANES (8'h00 8'h00)))
  ...)

(transaction parent_main
  (spawn child_worker as w0
    (params
      (WIDTH 16)
      (LANES (8'hA5 8'h3C)))))
```

The shipped parameter-binding surface is spawn-only; `(do child)` remains
unparameterized. Child transaction parameter declarations must use unique
HDL-identifier-compatible names. Spawn overrides must use unique names declared
by the child transaction; missing overrides use child defaults. Scalar numeric
and exact-width literal overrides are width-flexible. Aggregate/list defaults
require compatible aggregate/list override shape. Symbolic top constants are
not accepted until ISF has an explicit constant/symbol surface. Malformed
forms, duplicate instance names, duplicate parameters, unknown targets, unknown
override names, unsupported value shapes, parameter declarations on
non-spawned transactions, and parameter blocks on `(do child)` fail before
misleading scheduled artifacts are emitted. The scheduled child `.fsm` carries
the child transaction defaults in a direct `+params` block, and the parent
lowerer IR preserves each spawn instance's override list. The generated top
emits those overrides as `?fsmc` instance `(params ...)` blocks, so the
existing composition pipeline applies them to the spawned child instances.

### 8.3 Generated Composition Schedule Report Projection

The accepted schedule-report projection for generated ISF composition is a
top-level `generated_composition` field. Successful reports keep the ordinary
transaction, storage, and DT summaries parent-scoped, while this field exposes
bounded generated-top discovery metadata for spawned-child composition.

For actors without a generated composition top, `generated_composition` is
`null`. For spawned-child actors, the field is an object with these bounded
keys:
- `kind`: currently `spawn_generated_top`.
- `top_module`: generated top module name, initially `<actor>_top`.
- `top_fsm`: generated top `.fsm` basename, initially `<actor>_top.fsm`.
- `parent`: object with `module` and `scheduled_fsm` for the scheduled parent.
- `children`: array of spawned child module summaries. Each child entry exposes
  `transaction`, `module`, `scheduled_fsm`, and `parameters`; parameter entries
  expose `name` and stringified `default`.
- `instances`: array of spawned instance summaries. Each instance entry exposes
  `instance`, `child`, `start`, `done`, `parameter_bindings`, and
  `drive_handoffs`.

Instance `start` and `done` entries expose the parent and child port names used
by the generated top. `parameter_bindings` entries expose `name`, `source`
(`default` or `override`), and stringified `value`. `drive_handoffs` entries
expose one named drive, its request link, and one payload entry per drive
parameter with `parameter`, `child_port`, `parent_port`, and `width`.

This projection is deliberately bounded. It does not expose raw LoweringIR
records, raw composition parser objects, raw `?toplink` arrays, assignment
provenance, or private port-inference internals. It is live contract metadata
that evolves with FSMGen, not a frozen full schedule-report schema.

### 8.4 Generated Composition Diagnostics

Generated composition diagnostics must be targeted before scheduled artifacts
or generated tops become misleading. Diagnostics in this family should name the
transaction, spawn instance, child transaction, parameter, or generated handoff
that failed. The current accepted diagnostic families cover malformed spawn
syntax, unknown child targets, duplicate instance names, parent actor naming
conflicts, malformed or duplicate parameter declarations/overrides, unknown
override names, aggregate/scalar shape mismatches, parameter declarations on
non-spawned transactions, parameterized `(do child)`, and generated handoff
port-name conflicts.

If an actor interface already declares a port name reserved for a generated
handoff, lowering fails before the generated top is emitted. Spawn start/done
conflicts name the transaction and spawn instance. Named-drive request
conflicts also name the drive. Named-drive payload conflicts name the drive and
payload parameter. This keeps generated-composition failures source-local
instead of letting them fall through as later composition-pipeline fallout.

## 9. Rules

```lisp
(rule always_ready ready
  (valid 1)
  (trigger main_transfer))
```

The long guard spelling remains accepted for compatibility and clarity:

```lisp
(rule always_ready
  (when ready)
  (valid 1)
  (trigger main_transfer))
```

Current lowering:
- Accepted parser output exposes rules as an array of shell entries with
  unique non-empty scalar `name`, optional `when`, and `actions` array fields.
  Duplicate, nested, empty, or otherwise non-scalar rule names are rejected
  before the parser returns an actor shell. Condition and action payload
  contents remain scheduler input and are not frozen as a public API by the
  actor-shell rule-shape metadata.
- Rule actions are structurally validated before the actor shell is returned.
  Supported action shapes are `(port expr)`, `(trigger transaction)`, and
  `(priority over other_rule)`. The assignment shape keeps `port` scalar and
  allows `expr` to use the same scalar-or-list `.fsm` RHS expression domain
  as transaction `(update var expr)`.
- `(trigger transaction)` targets must name a declared transaction in the same
  actor. Forward references are accepted because the parser validates trigger
  targets after the full actor body is collected; missing targets fail before
  an actor shell is returned.
- Each rule emits one non-state DT block.
- A scalar condition immediately after the rule name is the preferred shorthand
  guard. Long-form `(when condition)` supplies the same guard. The parser
  normalizes both spellings to the same public `when` field. The shipped guard
  form is a single port/signal condition. Rule-local `(when condition)` is not
  the transaction control-flow form; it has no body and guards the rule actions
  that follow it.
- `(port expr)` actions lower as flopped assignments inside the guarded
  non-state DT. They keep the existing `<-` rule data-assignment family and
  do not introduce combinational or D-input-named rule action operators.
- Same-target rule data writes now receive a best-effort compile-time conflict
  check before scheduled `.fsm` text is treated as valid. Two rules that drive
  the same target to incompatible values fail closed with
  `isf_conflicting_rule_writes`; compatible same-target/same-value rule writes
  remain accepted. Rule/drive overlap is tracked internally as
  `isf_unproven_rule_drive_overlap` with `proof_status => not_doable` because
  that compile-time proof is not doable in the current analysis.
- Rule-local `(priority over other_rule)` and actor-level
  `(priority high over low)` can resolve same-target rule/rule data conflicts
  when the priority graph selects one winner for that target. The lowerer
  suppresses the lower-priority rule assignment with the inverse of the
  higher-priority rule condition. Priority cycles fail closed with
  `isf_priority_cycle_conflict`; incomparable rules still fail closed through
  the ordinary conflict diagnostic.
- Actor-level rule-over-transaction priority can resolve the covered
  same-target data case when the rule assignment and transaction-state
  assignment use the same timing operator. The lowerer keeps the winning rule
  assignment in its guarded non-state DT and adds the inverse active rule
  condition to the transaction-state assignment. Unordered rule/transaction
  conflicts fail closed with `isf_conflicting_rule_transaction_writes`.
  Priority cycles still fail with `isf_priority_cycle_conflict`. If the
  transaction is declared higher priority than the rule, lowering fails with
  `isf_priority_transaction_winner_unsupported` because the scheduled `.fsm`
  review artifact does not yet expose state-active predicates that can safely
  guard non-state rule DT assignments.
- Generated SystemVerilog includes verification-only selector assertions for
  analyzed muxes after ISF lowers through scheduled `.fsm`. Same-value
  `LHS`/`VAL` source selectors and whole-`LHS` value selectors are checked
  with `$onehot0` under `` `ifndef SYNTHESIS``; Verilog emission stays free of
  SystemVerilog assertions. The checks are derived from backend assignment
  analysis, so they cover internal generated muxes such as `next_state` as
  well as ISF-authored data targets. Standalone DT roots keep their existing
  standalone-DT multi-drive assertions rather than receiving duplicate
  selector blocks.
- `(trigger transaction)` lowers as a `<1` one-cycle delayed pulse inside the
  guarded non-state DT to a generated per-rule/per-transaction source named
  `rule_transaction`, so a rule trigger is a pulse rather than a sticky
  flopped request bit.
- If multiple rules trigger the same transaction, the scheduled `.fsm` exposes
  each rule source separately and emits one generated combinational fan-in DT
  per target transaction. That DT drives `transaction_start` from the OR of the
  rule sources without adding another cycle.
- Scheduled `.fsm` emission writes the rule guard as the non-state DT header
  DTE, for example:

```lisp
(-always_ready <ready
  (<- (valid> 1))
  (<1 (always_ready_main_transfer 1))
)

(-main_transfer_trigger_fanin
  (= (main_transfer_start always_ready_main_transfer))
)
```

Multi-rule fan-in example:

```lisp
(-r0 <a
  (<1 (r0_work 1))
)

(-r1 <b
  (<1 (r1_work 1))
)

(-work_trigger_fanin
  (= (work_start (| r0_work r1_work)))
)
```

- Inline `(priority over other_rule)` is structurally validated by the parser,
  and `other_rule` must name a declared rule in the same actor. Forward
  references are accepted because the target check runs after the full actor
  body is collected. For same-target rule/rule data conflicts, lowering uses
  this edge as target-local priority metadata.

Separate `(priority lhs over rhs)` declarations are structurally validated by
the parser, and both `lhs` and `rhs` must name declared transactions or rules
in the same actor. Forward references are accepted. Actor-level priority
metadata is enforced for same-target rule/rule data conflicts when both
targets are rules, for priority-arbitrated `rule_slot` resources when the
endpoints are bound rules of the same resource, and for the lowerable
rule-over-transaction same-target data case. Transaction-over-rule priority,
transaction/transaction priority beyond ordinary state mutual exclusion, and
broader resource arbitration remain deferred.

`(resources ...)` entries are structurally validated as resource entries with
non-empty scalar names, an `(arbiter priority|round_robin)` subclause, and
optional `(kind ...)` and `(users ...)` subclauses. Duplicate resource names,
duplicate resource subclauses, duplicate users, malformed kinds, malformed
users, and unknown `rule_slot` users are rejected before scheduled `.fsm`
emission. `(resources ...)` is an actor-level singleton clause, so repeated
resources blocks are rejected instead of merged or overwritten. Resource
semantics use a growable catalog of shareable resource kinds. The resource name
is the author-defined instance handle; the kind says what is being shared; the
`arbiter` says how requesters are selected. The table below is the current
public registry of things ISF can name as shareable resources. It deliberately
starts small and grows only when a kind has a clear lowering path, runtime
semantics, diagnostics, report surface, and regression coverage.

Current shareable resource registry:

| Kind | Status | Meaning |
| --- | --- | --- |
| `rule_slot` | shipped for `priority` arbitration | A one-cycle mutual-exclusion slot for rule users. A grant enables the whole bound rule DT for that cycle. |
| `output_bundle` | backlog | A group of actor outputs or LHS targets that must have one owner for a cycle. |
| `interface_bundle` | backlog | A protocol-facing interface or bus bundle, such as an APB-like signal group. |
| `named_drive` | backlog | A reusable actor `(drive ...)` body or drive-call path that multiple users may request. |
| `transaction_start` | backlog | The start/request fan-in for one transaction. |
| `child_instance` | backlog | A spawned child instance that must not be re-entered while busy. |
| `storage_port` | backlog | A shared state, register, memory, or storage-port access path. |

Backlog names are parser-recognized catalog entries, not shipped runtime
behavior. A backlog kind with bound users must fail closed until its lowering
path, runtime semantics, diagnostics, report surface, and regression coverage
ship.

The shipped resource-arbitration implementation covers priority-arbitrated
`rule_slot` users. The source shape keeps binding centralized under
`(resources ...)` by extending a resource entry with `(kind rule_slot)` and
`(users rule_a rule_b ...)` subclauses. For that covered case, each bound rule
requests the resource when its normalized rule guard is true. Rule-local
`(priority over other_rule)` and actor-level `(priority lhs over rhs)` edges
choose the active winner when the endpoints are bound rules of the same
resource. The generated grant gates the whole lowered rule DT DTE, while
existing same-target priority suppression remains assignment-local. Cycles,
incomplete ordering among potentially simultaneous bound users,
ambiguous future user namespaces, unsupported resource kinds, and
`round_robin` resources with bound users fail closed. Transaction users,
named-drive users, output-target users, child-instance users, storage-port
users, multi-capacity resources, and transaction-lifetime hold/release
semantics remain deferred.

Actor-level `(phase name property...)` and `(stage name property...)` metadata
is structurally validated by the parser and carried in the actor shell for
downstream consumers, but the scheduler does not enforce actor-level phase or
stage semantics yet. That actor-level metadata is not copied into `LoweringIR`,
schedule JSON, generated `.fsm`, generated composition tops, or HDL today.
Transaction-level `(phase name property...)` remains the
current pass-through state marker lowering. Transaction-level
`(stage name (input ready_signal) (output valid_signal))` is the first shipped
stage-lowering subset. It is supported only as a top-level transaction clause,
with `ready_signal` bound to an actor input and `valid_signal` bound to an
actor output. It lowers to one transaction state that drives
`valid_signal = 1` while the state is active and advances only when
`ready_signal` is true in that same cycle. Pending samples immediately before
the stage materialize before the stage so a stall does not resample every
cycle. Nested stages, stage-local `(latency ...)`, `(compute ...)`, arbitrary
stage body actions, multiple ready/valid endpoints, registered-valid variants,
and skid-buffer behavior remain fail-closed/deferred. Schedule reports expose
shipped transaction stages through `transaction_stages` entries containing the
authored transaction and stage names, `kind = ready_valid_barrier`, generated
state name, ready input, and valid output.

Transaction-level `(contract name (eventually signal (within cycles)))` is the
first shipped temporal-contract subset. It is supported only as a top-level
transaction clause, with a unique contract name per transaction, `signal` bound
to a scalar actor interface input or output, and `cycles` as a positive integer
literal. Reaching the clause emits one arm state. The checked window starts on
the next cycle and lasts for the `cycles` bound. The generated scheduled `.fsm`
artifact contains the arm state plus an always-on monitor DT with pending, age,
and sticky-fail storage. Actor reset clears the monitor storage. Seeing
`signal` while pending clears the obligation; window expiry or re-arming the
same contract while pending sets the sticky fail bit. Schedule-report
`dt_blocks` classify the generated monitor as `temporal_contract_monitor`, and
`inferred_storage` reports pending/fail as registers and age as a counter.
Schedule reports also expose shipped contracts through `temporal_contracts`
entries containing the authored transaction and contract names, `kind =
bounded_eventually`, trigger state, observed signal, cycle bound, pending,
counter, and fail signal names, overlap policy, reset policy, and assertion
projection status. Raw monitor equations and backend assertion text are not
schedule-report payloads. SystemVerilog assertion text under `` `ifndef
SYNTHESIS`` remains deferred; the scheduled monitor is already the source of
truth. Historical/free-form contract bodies, global `always` implication
forms, min/max windows, dynamic bounds, same-cycle checks, nested contracts,
expression operands, and multiple outstanding obligations remain
fail-closed/deferred.

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
  "transaction_stages": [],
  "temporal_contracts": [],
  "dt_blocks": [],
  "generated_composition": null,
  "compatible_fanin_groups": [],
  "priority_resolutions": [],
  "resource_arbitration": [],
  "compile_issues": []
}
```

This is a machine-readable schedule report generated from the same lowering IR
as `.fsm` output. It now has a bounded public key-family contract through
`embedding.isf_public_interface`, but it is not a frozen full schema. Current
scalar source values such as `watchdog` are preserved as parser-carried strings
in the JSON report. Assigned scheduler counters using the generated `*_wd`,
`*_cc`, and `*_cnt` naming families are reported as `kind: counter` with the
width inferred by `LoweringIR`. Transaction summaries include the generated
state families used by the current scheduler, including control-flow and
data-operation states. DT block summaries follow deterministic lowering order:
transaction/rule-created DTs first in construction order, generated
rule-trigger fan-in DTs by transaction name, then hash-backed drive DTs
lexically by drive name.

The capability-manifest ISF public contract exposes the same policy through
`scheduled_fsm_dt_ordering` and `schedule_report_dt_ordering`.
Those ordering fields are audited as exact paired metadata across direct and
manifest views.
Each `dt_blocks` entry's `assignments` value is a non-negative count of
assignment forms in the matching scheduled `.fsm` DT block, not an assignment
payload list. The capability-manifest ISF public contract advertises this shape
through `schedule_report_dt_assignments_shape`.
Each `dt_blocks` entry's `kind` value is currently `drive`,
`latency_counter`, `rule`, `rule_trigger_fanin`, or
`temporal_contract_monitor`. The capability-manifest ISF public contract
advertises this value family through `schedule_report_dt_kind_values`.
Each `inferred_storage` entry's `kind` value is currently `counter` or
`register`; optional `width` values are positive integer bit widths when
present and currently appear on inferred scheduler counters. The
capability-manifest ISF public contract advertises this through
`schedule_report_storage_kind_values` and `schedule_report_storage_width_shape`.
Each `transactions` entry's `states` value is an emitted-order array of
scheduled state names belonging to that transaction, and `count` is a
non-negative integer equal to that array length. The capability-manifest ISF
public contract advertises this through
`schedule_report_transaction_states_shape` and
`schedule_report_transaction_count_shape`.
The `transactions` array is sorted lexically by transaction name, and each
transaction's `states` array keeps scheduled `.fsm` state emission order. The
capability-manifest ISF public contract advertises this through
`schedule_report_transaction_ordering`.
The `transaction_stages` array reports the shipped ready/valid stage subset.
Each entry has `transaction`, authored stage `name`, `kind =
ready_valid_barrier`, generated `state`, `ready` input, and `valid` output.
The capability-manifest ISF public contract advertises the keys and kind
values through `schedule_report_transaction_stage_keys` and
`schedule_report_transaction_stage_kind_values`.
The `temporal_contracts` array reports the shipped bounded eventual contract
subset. Each entry has `transaction`, authored contract `name`, `kind =
bounded_eventually`, `trigger`, observed `signal`, `within_cycles`,
`pending_signal`, `counter_signal`, `fail_signal`, `overlap_policy`,
`reset_policy`, and `assertion_projection`. The current `overlap_policy` is
`fail`, and the current assertion projection value is `none`; monitor logic
exists in scheduled `.fsm`, but no backend assertion text is emitted yet. The
capability-manifest ISF public contract advertises the keys, kind values,
overlap values, assertion-projection values, and reset-policy shape through the
matching `schedule_report_temporal_contract_*` metadata fields.
The reset summary's `kind` value is currently `async` or `sync`, and its
`polarity` value is currently `active_high` or `active_low`. The
capability-manifest ISF public contract advertises those value families through
`schedule_report_reset_kind_values` and
`schedule_report_reset_polarity_values`.
Configured reset summaries are hashes with the advertised reset keys; omitted
resets are reported as JSON null. The capability-manifest ISF public contract
advertises this through `schedule_report_reset_shape`.
The top-level `inputs` and `outputs` values count interface ports by direction,
and `port_count` equals their sum. `state_count` counts scheduled `.fsm` state
blocks in the current parent report scope. The capability-manifest ISF public
contract advertises this through `schedule_report_interface_count_shape` and
`schedule_report_state_count_shape`.
The top-level `source` and `scheduled_fsm` values are actor-derived `.isf` and
`.fsm` basenames for the current parent report scope, `clock` is the actor
clock signal name, and `watchdog` is a scalar limit when configured or null when
omitted. The capability-manifest ISF public contract advertises this through
`schedule_report_source_shape`, `schedule_report_scheduled_fsm_shape`,
`schedule_report_clock_shape`, and `schedule_report_watchdog_shape`.
Successful reports keep `compile_issues` present as an array. Reports with no
nonfatal compile issues keep it empty; the capability-manifest ISF public
contract advertises that no-issue success shape through
`schedule_report_compile_issues_success_shape`.
Nonfatal conflict issues are projected into `compile_issues` as bounded objects
with stable `code`, `severity`, `target`, `domain`, `proof_status`,
human-readable `reason`, and capped `sources` summaries. The important current
proof status is `not_doable`, used when the scheduler is explicitly flagging
that a compile-time proof is NOT doable for a case such as rule/drive overlap.
The public contract advertises the bounded issue keys, source-summary keys,
severity values, and proof-status values. Fail-closed conflicts still produce
targeted diagnostics instead of successful schedule reports.
Rejected conflict diagnostics are regression-covered for both in-process
scheduler calls and the CLI schedule-report path. They name the stable code,
target, reason, conflicting owners, source kinds, operators, and values, and
the CLI path does not emit successful schedule JSON for rejected conflicts.
Accepted compatible fan-in metadata is emitted as a top-level
`compatible_fanin_groups` array. Each group is bounded to classifier `kind`,
`domain`, target/value facts, and source summaries; raw
`assignment_provenance`, activation proof context, assignment indexes, and
priority-suppression bookkeeping remain private `LoweringIR` internals.
The public projection reports request and pulse fan-in through their
domain-specific group kinds instead of duplicating them as generic
`same_target_value` groups.
Successful priority/resource decisions are emitted as top-level
`priority_resolutions` and `resource_arbitration` arrays. A
`priority_resolutions` entry records the target plus bounded winner/loser owner
names and owner kinds for target-local suppression. A `resource_arbitration`
entry records an enforced resource's name, kind, arbiter, bound rule user, and
the higher-priority rule users that can suppress that user's grant. These
entries describe the static lowering decision; they are not per-cycle runtime
grant traces.
The CLI `--emit-schedule-json` entrypoint is expected to emit the same report as
the in-process scheduler on stdout and keep stderr clean on success.
For multi-file lowerings, that report currently describes the parent scheduled
module only.

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
- [t/1108-isf-schedule-json-transaction-states.t](../t/1108-isf-schedule-json-transaction-states.t)
- [t/1109-isf-await-all-sync.t](../t/1109-isf-await-all-sync.t)
- [t/1110-isf-do-child-entry-rewire.t](../t/1110-isf-do-child-entry-rewire.t)
- [t/1111-isf-sample-before-data-ops.t](../t/1111-isf-sample-before-data-ops.t)
- [t/1112-isf-public-interface-contract.t](../t/1112-isf-public-interface-contract.t)
- [t/1113-isf-public-interface-contract-json-roundtrip-audit.t](../t/1113-isf-public-interface-contract-json-roundtrip-audit.t)
- [t/1114-isf-public-interface-contract-defensive-copy-audit.t](../t/1114-isf-public-interface-contract-defensive-copy-audit.t)
- [t/1115-isf-public-interface-cli-manifest-audit.t](../t/1115-isf-public-interface-cli-manifest-audit.t)
- [t/1116-isf-public-schedule-report-key-family-audit.t](../t/1116-isf-public-schedule-report-key-family-audit.t)
- [t/1117-isf-public-lower-result-files-audit.t](../t/1117-isf-public-lower-result-files-audit.t)
- [t/1118-isf-public-parse-source-facade-audit.t](../t/1118-isf-public-parse-source-facade-audit.t)
- [t/1119-isf-deterministic-dt-block-order.t](../t/1119-isf-deterministic-dt-block-order.t)
- [t/1120-isf-public-live-document-path-audit.t](../t/1120-isf-public-live-document-path-audit.t)
- [t/1121-isf-public-cli-schedule-report-audit.t](../t/1121-isf-public-cli-schedule-report-audit.t)
- [t/1122-isf-public-cli-outdir-lowering-audit.t](../t/1122-isf-public-cli-outdir-lowering-audit.t)
- [t/1123-isf-public-cli-hdl-generation-audit.t](../t/1123-isf-public-cli-hdl-generation-audit.t)
- [t/1124-isf-public-cli-strict-mode-audit.t](../t/1124-isf-public-cli-strict-mode-audit.t)
- [t/1125-isf-public-constructor-boundary-audit.t](../t/1125-isf-public-constructor-boundary-audit.t)
- [t/1126-isf-public-parser-method-boundary-audit.t](../t/1126-isf-public-parser-method-boundary-audit.t)
- [t/1127-isf-public-scheduler-method-boundary-audit.t](../t/1127-isf-public-scheduler-method-boundary-audit.t)
- [t/1128-isf-public-multifile-schedule-report-audit.t](../t/1128-isf-public-multifile-schedule-report-audit.t)
- [t/1129-isf-public-actor-shell-contract-audit.t](../t/1129-isf-public-actor-shell-contract-audit.t)
- [t/1130-isf-public-compile-issues-success-audit.t](../t/1130-isf-public-compile-issues-success-audit.t)
- [t/1131-isf-public-top-level-discovery-audit.t](../t/1131-isf-public-top-level-discovery-audit.t)
- [t/1132-isf-public-method-receiver-boundary-audit.t](../t/1132-isf-public-method-receiver-boundary-audit.t)
- [t/1133-isf-public-constructor-receiver-boundary-audit.t](../t/1133-isf-public-constructor-receiver-boundary-audit.t)
- [t/1134-isf-public-parse-file-path-boundary-audit.t](../t/1134-isf-public-parse-file-path-boundary-audit.t)
- [t/1135-isf-public-entrypoint-metadata-audit.t](../t/1135-isf-public-entrypoint-metadata-audit.t)
- [t/1136-isf-public-cli-option-metadata-audit.t](../t/1136-isf-public-cli-option-metadata-audit.t)
- [t/1137-isf-public-method-name-metadata-audit.t](../t/1137-isf-public-method-name-metadata-audit.t)
- [t/1138-isf-public-constructor-option-metadata-audit.t](../t/1138-isf-public-constructor-option-metadata-audit.t)
- [t/1139-isf-public-lower-result-metadata-audit.t](../t/1139-isf-public-lower-result-metadata-audit.t)
- [t/1140-isf-public-schedule-report-metadata-audit.t](../t/1140-isf-public-schedule-report-metadata-audit.t)
- [t/1141-isf-public-identity-flags-metadata-audit.t](../t/1141-isf-public-identity-flags-metadata-audit.t)
- [t/1142-isf-public-guidance-metadata-audit.t](../t/1142-isf-public-guidance-metadata-audit.t)
- [t/1143-isf-public-facade-shape-metadata-audit.t](../t/1143-isf-public-facade-shape-metadata-audit.t)
- [t/1144-isf-public-tested-by-metadata-audit.t](../t/1144-isf-public-tested-by-metadata-audit.t)
- [t/1145-isf-public-scheduled-fsm-metadata-audit.t](../t/1145-isf-public-scheduled-fsm-metadata-audit.t)
- [t/1146-isf-public-dt-assignment-metadata-audit.t](../t/1146-isf-public-dt-assignment-metadata-audit.t)
- [t/1147-isf-public-report-dt-assignment-count-audit.t](../t/1147-isf-public-report-dt-assignment-count-audit.t)
- [t/1148-isf-public-storage-metadata-audit.t](../t/1148-isf-public-storage-metadata-audit.t)
- [t/1149-isf-public-transaction-metadata-audit.t](../t/1149-isf-public-transaction-metadata-audit.t)
- [t/1150-isf-public-reset-metadata-audit.t](../t/1150-isf-public-reset-metadata-audit.t)
- [t/1151-isf-public-report-count-metadata-audit.t](../t/1151-isf-public-report-count-metadata-audit.t)
- [t/1152-isf-public-report-scalar-metadata-audit.t](../t/1152-isf-public-report-scalar-metadata-audit.t)
- [t/1153-isf-public-cli-success-metadata-audit.t](../t/1153-isf-public-cli-success-metadata-audit.t)
- [t/1154-isf-public-facade-return-metadata-audit.t](../t/1154-isf-public-facade-return-metadata-audit.t)
- [t/1155-isf-public-cli-strict-success-metadata-audit.t](../t/1155-isf-public-cli-strict-success-metadata-audit.t)
- [t/1156-isf-public-lower-result-file-shape-audit.t](../t/1156-isf-public-lower-result-file-shape-audit.t)
- [t/1157-isf-public-report-transaction-ordering-audit.t](../t/1157-isf-public-report-transaction-ordering-audit.t)
- [t/1158-isf-public-report-dt-kind-metadata-audit.t](../t/1158-isf-public-report-dt-kind-metadata-audit.t)
- [t/1159-isf-public-report-reset-shape-metadata-audit.t](../t/1159-isf-public-report-reset-shape-metadata-audit.t)
- [t/1160-isf-public-actor-shell-value-shape-audit.t](../t/1160-isf-public-actor-shell-value-shape-audit.t)
- [t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t](../t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t)
- [t/1162-isf-public-actor-shell-interface-shape-audit.t](../t/1162-isf-public-actor-shell-interface-shape-audit.t)
- [t/1163-isf-public-actor-shell-transaction-shape-audit.t](../t/1163-isf-public-actor-shell-transaction-shape-audit.t)
- [t/1164-isf-public-actor-shell-actor-name-shape-audit.t](../t/1164-isf-public-actor-shell-actor-name-shape-audit.t)
- [t/1165-isf-public-actor-shell-timing-shape-audit.t](../t/1165-isf-public-actor-shell-timing-shape-audit.t)
- [t/1166-isf-public-actor-shell-rule-shape-audit.t](../t/1166-isf-public-actor-shell-rule-shape-audit.t)
- [t/1167-isf-public-actor-shell-drive-shape-audit.t](../t/1167-isf-public-actor-shell-drive-shape-audit.t)
- [t/1168-isf-rule-guard-factoring.t](../t/1168-isf-rule-guard-factoring.t)
- [t/1169-isf-rule-shorthand-guard.t](../t/1169-isf-rule-shorthand-guard.t)
- [t/1171-isf-rule-trigger-fanin.t](../t/1171-isf-rule-trigger-fanin.t)
- [t/1172-isf-rule-trigger-fanin-schedule-report.t](../t/1172-isf-rule-trigger-fanin-schedule-report.t)
- [t/1173-isf-shift-right-explicit-width.t](../t/1173-isf-shift-right-explicit-width.t)
- [t/1174-isf-extract-explicit-widths.t](../t/1174-isf-extract-explicit-widths.t)
- [t/1175-isf-contract-fail-closed.t](../t/1175-isf-contract-fail-closed.t)
- [t/1176-isf-resource-priority-boundary.t](../t/1176-isf-resource-priority-boundary.t)
- [t/1177-isf-do-child-done-pulse.t](../t/1177-isf-do-child-done-pulse.t)
- [t/1178-isf-handshake-compatibility-boundary.t](../t/1178-isf-handshake-compatibility-boundary.t)
- [t/1179-isf-phase-stage-boundary.t](../t/1179-isf-phase-stage-boundary.t)
- [t/1180-isf-unsupported-transaction-clause-boundary.t](../t/1180-isf-unsupported-transaction-clause-boundary.t)
- [t/1181-isf-rule-action-boundary.t](../t/1181-isf-rule-action-boundary.t)
- [t/1182-isf-rule-trigger-target-boundary.t](../t/1182-isf-rule-trigger-target-boundary.t)
- [t/1184-isf-child-transaction-target-boundary.t](../t/1184-isf-child-transaction-target-boundary.t)
- [t/1185-isf-transaction-name-boundary.t](../t/1185-isf-transaction-name-boundary.t)
- [t/1186-isf-rule-name-boundary.t](../t/1186-isf-rule-name-boundary.t)
- [t/1187-isf-drive-name-boundary.t](../t/1187-isf-drive-name-boundary.t)
- [t/1188-isf-interface-port-boundary.t](../t/1188-isf-interface-port-boundary.t)
- [t/1189-isf-drive-parameter-boundary.t](../t/1189-isf-drive-parameter-boundary.t)
- [t/1190-isf-rule-priority-target-boundary.t](../t/1190-isf-rule-priority-target-boundary.t)
- [t/1191-isf-actor-priority-target-boundary.t](../t/1191-isf-actor-priority-target-boundary.t)
- [t/1192-isf-singleton-actor-clause-boundary.t](../t/1192-isf-singleton-actor-clause-boundary.t)
- [t/1193-isf-drive-call-arity-boundary.t](../t/1193-isf-drive-call-arity-boundary.t)
- [t/1194-isf-drive-body-boundary.t](../t/1194-isf-drive-body-boundary.t)
- [t/1195-isf-sample-clause-boundary.t](../t/1195-isf-sample-clause-boundary.t)
- [t/1196-isf-complete-clause-boundary.t](../t/1196-isf-complete-clause-boundary.t)
- [t/1197-isf-latency-clause-boundary.t](../t/1197-isf-latency-clause-boundary.t)
- [t/1198-isf-update-clause-boundary.t](../t/1198-isf-update-clause-boundary.t)
- [t/1199-isf-shift-clause-boundary.t](../t/1199-isf-shift-clause-boundary.t)
- [t/1200-isf-assemble-clause-boundary.t](../t/1200-isf-assemble-clause-boundary.t)
- [t/1201-isf-extract-clause-boundary.t](../t/1201-isf-extract-clause-boundary.t)
- [t/1202-isf-repeat-clause-boundary.t](../t/1202-isf-repeat-clause-boundary.t)
- [t/1203-isf-await-sync-clause-boundary.t](../t/1203-isf-await-sync-clause-boundary.t)
- [t/1204-isf-child-composition-clause-boundary.t](../t/1204-isf-child-composition-clause-boundary.t)
- [t/1205-isf-switch-clause-boundary.t](../t/1205-isf-switch-clause-boundary.t)
- [t/1206-isf-when-clause-boundary.t](../t/1206-isf-when-clause-boundary.t)
- [t/1209-isf-static-conflict-detection.t](../t/1209-isf-static-conflict-detection.t)
- [t/1210-isf-priority-conflict-resolution.t](../t/1210-isf-priority-conflict-resolution.t)
- [t/1211-isf-runtime-selector-conflict-instrumentation.t](../t/1211-isf-runtime-selector-conflict-instrumentation.t)
- [t/1212-isf-schedule-report-compile-issues-projection.t](../t/1212-isf-schedule-report-compile-issues-projection.t)
- [t/1213-isf-schedule-report-compatible-fanin-projection.t](../t/1213-isf-schedule-report-compatible-fanin-projection.t)
- [t/1214-isf-rejected-conflict-diagnostics.t](../t/1214-isf-rejected-conflict-diagnostics.t)
- [t/1215-isf-spawn-parameter-binding.t](../t/1215-isf-spawn-parameter-binding.t)
- [t/1216-isf-generated-composition-top.t](../t/1216-isf-generated-composition-top.t)
- [t/1217-isf-generated-composition-schedule-report.t](../t/1217-isf-generated-composition-schedule-report.t)
- [t/1218-isf-rule-slot-resource-arbitration.t](../t/1218-isf-rule-slot-resource-arbitration.t)
- [t/1219-isf-rule-transaction-priority.t](../t/1219-isf-rule-transaction-priority.t)
- [t/1220-isf-arbitration-schedule-report.t](../t/1220-isf-arbitration-schedule-report.t)
- [t/1221-isf-rule-expression-assignment.t](../t/1221-isf-rule-expression-assignment.t)
- [t/1222-isf-rule-expression-conflict-report.t](../t/1222-isf-rule-expression-conflict-report.t)
- [t/1223-isf-stage-lowering.t](../t/1223-isf-stage-lowering.t)
- [t/1224-isf-contract-lowering.t](../t/1224-isf-contract-lowering.t)
- [t/1225-isf-stage-contract-schedule-report.t](../t/1225-isf-stage-contract-schedule-report.t)

## 12. Explicitly Deferred

- Old `(handshake ...)` semantics beyond validated ignored compatibility
  parsing.
- The removed `(assign ...)` action keyword; authored transaction uses fail
  closed as unsupported transaction clauses.
- Broader generated-child top instantiation surfaces beyond the covered ISF
  spawn pattern. The current generated top covers scheduled parent/child
  wiring, start/done handoff, named-drive handoff, and spawn parameter
  overrides for the shipped fixture set.
- Enforced resource arbitration beyond the shipped priority-arbitrated
  `rule_slot` case: `round_robin`, `output_bundle`, `interface_bundle`,
  `named_drive`, `transaction_start`, `child_instance`, `storage_port`,
  multi-capacity resources, dynamic resource names, and transaction lifetime
  ownership remain deferred.
- Priority resolution beyond the currently shipped same-target rule/rule
  data-conflict case, rule-over-transaction data-conflict case, and
  resource-level bound-rule grant case.
- Expression-valued rule guards and alternate rule assignment operators.
- Transaction `(stage ...)` forms beyond the shipped top-level ready/valid
  barrier: nested stages, stage-local latency/compute bodies, multiple
  endpoints, registered-valid variants, and skid buffers remain deferred.
- Temporal `(contract ...)` forms beyond the shipped top-level bounded
  eventual subset.
- Rich storage-class optimization in schedule reports.
- Broad aggregate/record width inference beyond the explicitly documented ISF
  data-operation evidence model.
- Treating the schedule JSON as a fully frozen public schema beyond the bounded
  key families advertised by `embedding.isf_public_interface`.
