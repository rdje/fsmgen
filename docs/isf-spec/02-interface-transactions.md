
## 5. Interface

```lisp
(interface
  (input  name)
  (input  name (width N))
  (input  name (width PARAM))
  (input  name (width CONST))
  (output name)
  (output name (width N))
  (output name (width PARAM))
  (output name (width CONST))
  (output name (reset V))
  (output name (default V))
  (output name (width N) (reset V) (default V)))
```

Default width is `1`. Interface entries lower into `.fsm` `+size` entries.
Accepted parser output exposes the interface handoff as `inputs` and `outputs`
arrays with unique non-empty scalar port `name` and positive integer `width`
entries. `N` is a positive integer literal. `PARAM` may name an actor-local
scalar parameter default that resolves to a positive integer, including an enum
member reference that resolves to a positive integer; the parser lowers the
public `width` field to the resolved integer and keeps the authored parameter
visible through `actor_params[]`. `CONST` may name a declared actor constant
that resolves to a positive integer, including an enum-backed constant; the
parser lowers the public `width` field to the resolved integer and keeps the
authored constant visible through `actor_constants[]` and scheduled
`+constants`. Unknown symbolic width names, runtime interface signals,
zero-valued or non-scalar actor parameters, zero-valued actor constants,
arbitrary expressions, nested names, malformed directions, duplicate names
across either direction, and non-positive or non-integer literal widths are
rejected before the parser returns an actor shell.
`(interface ...)` is an actor-level singleton clause; repeated interface blocks
are rejected instead of merged or overwritten.
If an inferred scheduler storage name matches a declared interface port, the
declared port entry is kept and the inferred duplicate is suppressed.
Output ports are marked as public outputs by the `.fsm` emitter when assigned
from drive/rule output paths.

Output entries may carry `(reset V)` and `(default V)` metadata when `V` is a
non-negative integer literal that fits the resolved positive integer output
width. `(reset V)` lowers to generated `.fsm` `+size` reset metadata.
`(default V)` lowers to generated transaction idle/quiescent `<-` output
assignments, matching the generated drive output assignment family. Inputs,
type-referenced outputs, unresolved-width outputs, negative values,
malformed arity, and too-wide values fail closed.

### 5.1 Actor-Owned Storage

Actors may declare internal persistent state with a singleton `(storage ...)`
clause:

```lisp
(storage
  (var rd_ptr (width 2))
  (variable wr_ptr (width PTR_W))
  (var occupancy (width 3))
  (bank data (width DATA_W) (depth DEPTH)))
```

In this example scalar `PTR_W` may be declared in the same actor's
`(params ...)` or `(constants ...)` block with a value that resolves to a
positive integer. Bank width `DATA_W` may likewise be an actor scalar
parameter, actor constant, or qualified imported package scalar constant
resolving positive. Bank depth `DEPTH` may also be an actor scalar parameter,
actor constant, or qualified imported package scalar constant resolving
positive when a symbolic depth source is used.

The first shipped storage forms are:

- `(var name (width N|PARAM|CONST|PACKAGE.CONSTANT))`: an actor-owned
  internal scalar variable.
- `(variable name (width N|PARAM|CONST|PACKAGE.CONSTANT))`: verbose alias for
  `(var ...)`.
- `(bank name (width N|PARAM|CONST|PACKAGE.CONSTANT)
  (depth N|PARAM|CONST|PACKAGE.CONSTANT))`: a fixed-depth actor-owned
  storage bank.

Actor-owned scalar storage widths may be positive integer literals,
actor-local scalar parameter defaults, declared actor constants, or qualified
imported package scalar constants that resolve to positive integer literals.
The parser returns the resolved integer width, scheduled `.fsm` `+size` uses
that integer, schedule reports expose that integer as
`inferred_storage[].width`, and generated HDL uses the resolved range.
Authored actor constants remain visible through `actor_constants[]` and
scheduled `+constants`; imported package roots remain visible through
scheduled package imports and embedded package roots while the storage width
itself is published as the resolved integer. Unknown symbolic names, unknown
or unqualified package constants, package aggregate constants, package
aggregate scalar-leaf paths, ambiguous local-enum/package-constant spellings,
runtime interface signals, zero-valued or non-scalar actor parameters,
zero-valued actor constants, zero-valued package constants, and arbitrary
expressions fail closed. Type aliases remain spelled with `(type NAME)`, not
`(width NAME)`.

Storage bank widths may be positive integer literals, actor-local scalar
parameter defaults, declared actor constants, or qualified imported package
scalar constants that resolve to positive integer literals. Storage bank
depths may be positive integer literals, actor-local scalar parameter
defaults, declared actor constants, or qualified imported package scalar
constants that resolve to positive integer literals. The parser returns the
resolved integer width and depth; scheduled `.fsm`, schedule reports, bank
access metadata, and generated HDL see the same scalarized storage family
they would see for equivalent literal values.
Unknown symbolic names, unknown or unqualified package constants, package
aggregate constants, package aggregate scalar-leaf paths, ambiguous
local-enum/package-constant spellings, runtime interface signals, zero-valued
or non-scalar actor parameters, zero-valued actor constants, zero-valued
package constants, arbitrary storage dimension expressions, dynamic storage
depth, and memory-array backend emission remain deferred or fail closed.

Storage banks lower to deterministic scalar storage element names in the
scheduled `.fsm` review artifact. For example,
`(bank data (width 8) (depth 4))` declares `data_0`, `data_1`, `data_2`, and
`data_3`, each 8 bits wide. This scalarized lowering is intentional for the
first FIFO work: it lets the `DEPTH=4` fixture use four concrete storage
entries and reach the existing scalar signal/flop SystemVerilog backend before
generalized indexed storage syntax or memory-array emission is shipped.

Declared storage is internal actor state, not an interface port. A storage
signal must not collide with an interface port, actor clock/reset signal, or
generated scheduler signal such as `can_accept`. Missing width/depth options,
duplicate logical storage names, duplicate scalarized element names, and
duplicate `(storage ...)` clauses fail closed before scheduler handoff.

Lowering emits declared storage signals in scheduled `.fsm` `+size`. The
lowerer also carries their widths as normal width evidence so updates and data
operations can reuse the existing expression and mux paths. Schedule reports
include declared storage entries in `inferred_storage` with kind `register`,
role `actor_storage`, and positive integer `width`. Declared typed
actor-owned storage may also expose the authored `type` token and resolved
`type_kind` without exposing raw type-spec hashes. Used storage signals reach
SystemVerilog generation through the existing scalar assignment path.
The report `kind` is the generated storage class; authored scalar storage uses
the normalized scalar storage kind. `(state ...)` and `(register ...)` are not
accepted storage entry spellings.

### 5.1.1 Declarative Storage Fields

Scalar actor-owned storage variables may carry checked declarative field
metadata:

```lisp
(storage
  (var control (width 8) (reset 161)
    (fields
      (field mode   (bits 7 5) (access rw) (reset 5)
        (enum (IDLE 0) (RUN 5)))
      (field prio   (bits 4 2) (access rw))
      (field enable (bits 0 0) (access rw) (reset 1)
        (enum (OFF 0) (ON 1))))))
```

This is metadata on the parent storage word, not generated field-level RTL.
The scheduled `.fsm` and generated HDL remain byte-equivalent to an otherwise
identical opaque storage variable. Existing runtime field/data operations such
as `set-field`, `when-field`, `extract`, and `assemble` remain scheduled
behavior and are not static field-map declarations.

Field syntax is accepted only under scalar `(var ...)` / `(variable ...)`
entries that use `(width ...)`. Banks and typed storage entries reject
`(fields ...)` in this slice. Each field form is
`(field NAME (bits HI LO) OPTIONS...)`, where `NAME` is an HDL identifier,
`HI` and `LO` are non-negative integer literals, and `HI >= LO`. Field names
must be unique within the parent word. Field ranges may leave gaps; FSMGen
does not infer unnamed reserved fields. Ranges outside the resolved parent
width and overlapping ranges fail closed.

Optional field metadata:

- `(access TOKEN)`, where `TOKEN` is `ro`, `rw`, `wo`, `w1c`, `w0c`, `rc`,
  `rs`, `warl`, `wpri`, or `reserved`.
- `(reset V)`, where `V` is a non-negative integer literal that fits the
  field width. A field reset requires an explicit parent storage `(reset V)`
  and must match the corresponding parent reset bit slice; the first slice
  does not derive parent reset values from fields.
- `(enum (NAME VALUE)...)`, where member names are HDL identifiers, values
  are non-negative integer literals that fit the field width, and duplicate
  names or values within one field fail closed. References to actor
  `(enums ...)` remain deferred.

Schedule reports expose this as optional `inferred_storage[].fields` metadata
on the parent declared storage entry. Each field entry has `name`, `msb`,
`lsb`, `width`, and optional `access`, `reset`, and `enum` entries. No access
policy enforcement, generated assertions, register-model output, packet/flit
layout surface, aggregate-field layout, bank layout, or reset derivation is
promised by this first slice. The public fixture `isf/storage_fields.isf` is
support-accounted as `feature.isf_storage_field_metadata`; check JSON and
normalized semantic JSON report that matched source identity, while the field
map remains a schedule JSON payload.

### 5.2 Actor-Owned Bank Access

The first shipped source surface for actor-owned bank data access is explicit
action syntax:

```lisp
(store <bank-name> <index> <value>)
(load <bank-name> <index> as <target>)
```

Rules and supported transaction contexts accept these actions when
`<bank-name>` names a declared actor-owned `(bank ...)` storage entry. The
word `bank` in the grammar is a placeholder for an authored bank name; it is
not a literal token. An actor may declare multiple banks, and the second item
in each `store` or `load` selects which bank is accessed.
`store` is bank-only: it writes a selected entry of a declared bank. Scalar
actor-owned storage is written with the explicit setter `(set lhs expr)`.
Existing transaction `(update lhs expr)` remains supported as the older
transaction-local spelling, and ordinary rule assignments such as `(wr_ptr 1)`
remain supported shorthand. The setter word is shared, but the runtime region
is still owned by context: a rule `set` is actor-level concurrent logic guarded
by the rule's non-state DT enable, while transaction `set` is an ordered
transaction step that becomes part of the transaction state sequence. Rule
assignment direct scalar RHS values and scalar operands inside RHS expressions
may read scalar aggregate member/item leaves such as `frame.mode` or
`lanes[1]`; the parser resolves those paths against declared actor-owned
aggregate storage before lowering and preserves the authored path in the
guarded rule DT. Rule assignment targets may also write scalar aggregate
member/item leaves such as `frame.mode` or `lanes[1]`; subaggregate rule
targets remain deferred. Rule assignment direct scalar RHS values and scalar
operands inside RHS expressions may also use local enum members such as
`mode.BUSY` or package enum members such as `shared.mode.BUSY`; the parser
resolves those values before lowering and preserves the authored token in the
guarded rule DT. Scalar operands inside rule guard expressions may use enum
members or read scalar aggregate storage leaves such as `frame.flag`;
aggregate rule guard paths resolve against declared actor-owned aggregate
storage before lowering and preserve the authored path in the guarded rule DT
header. Standalone enum member rule guards and standalone scalar aggregate
storage leaf rule guards are shipped in shorthand and long-form `(when ...)`
rule syntax; they lower to non-state DT header guards such as `<mode.BUSY` and
`<frame.flag`. Aggregate paths in rule assignment RHS or rule guard expression
operator position, rule target enum members, enum members in rule guard or
rule assignment expression operator position, and subaggregate rule targets
remain deferred.

`(store data wr_ptr data_in)` means: write `data_in` into the actor-owned bank
entry selected by `wr_ptr`. For a fixed-depth scalarized bank, lowering emits
one guarded update per bank entry. With depth 4, the scheduled `.fsm` review
artifact makes the selected entry visible through guards equivalent to
`wr_ptr == 0`, `wr_ptr == 1`, `wr_ptr == 2`, and `wr_ptr == 3` on `data_0`,
`data_1`, `data_2`, and `data_3`.

`(load data rd_ptr as data_out)` means: read the actor-owned bank entry
selected by `rd_ptr` into `data_out`. Lowering uses the same scalarized entry
family to build a mux-equivalent set of guarded assignments from `data_0`
through `data_3` into the target.

The first timing contract is read-before-write for same-cycle store and load
against the same bank. A load observes the current bank entry value from the
cycle snapshot. A store updates the selected bank entry for the following
cycle. If a later design needs write-first behavior, bypass behavior, or a
collision diagnostic, that must be an explicit future option or construct.

The first implementation requires:
- `bank` names a declared actor-owned `(bank ...)`;
- `index` is a scalar signal or literal token whose value domain is checked
  against the fixed bank depth where possible;
- `value` has bank-entry width or enough width evidence to reject mismatch
  before scheduled `.fsm` emission;
- `target` is a scalar storage or interface target with width compatible with
  the bank entry when width evidence is available;
- malformed arity, unknown banks, non-bank storage names, unsupported dynamic
  depth, width mismatch, and unsupported same-target conflicts fail closed with
  targeted diagnostics; and
- schedule reports expose bounded `bank_accesses` metadata so downstream
  consumers can see which owner accesses a generated storage bank, the
  selected index token, scalarized entries, width/depth, and the
  read-before-write same-cycle policy.

The checked-in fixture `isf/fifo_data_path.isf` is the file-backed forward
contract for this bank access surface. It proves a depth-4 bank whose
`accepted_push` rule stores through `wr_ptr` and whose `accepted_pop` rule
loads through `rd_ptr`, including strict schedule JSON parity, scheduled
`.fsm` structure, and plain plus strict HDL generation.

The sibling fixture `isf/fifo_controller.isf` is the file-backed forward
contract for the controller-only matrix. It proves idle, push-only, pop-only,
and simultaneous push+pop occupancy/full/empty behavior plus 2-bit pointer
wrap without claiming data-bank storage or `data_out` transfer behavior.

The reusable fixture `isf/fifo_library_use.isf` is the file-backed forward
contract for the fixed FIFO library-use path. It imports `common.fifo.fifo`,
binds instance `u_fifo`, emits the importing actor, specialized child, and
generated top scheduled `.fsm` files, records fixed parameter overrides and
use-site bindings in `library_uses[]`, and reaches plain plus strict generated
top SystemVerilog. This fixture is deliberately fixed to `DATA_WIDTH=8`,
`DEPTH=4`, `PTR_WIDTH=2`, and `OCC_WIDTH=3`; it does not claim use-site
parameter-driven FIFO interface shape, use-site bank-depth specialization,
generated-top
respecialization, nested library imports, standalone exported transactions or
drives, memory-array backend emission, or automatic non-zero reset values.

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
  structurally validated as `(port value)` pairs whose RHS is either a scalar
  value or a list expression before parser return. Scalar body RHS values and
  scalar operands inside body RHS expressions may use local enum members such
  as `mode.BUSY` or package enum members such as `shared.mode.BUSY`; the
  parser resolves those values before lowering and preserves the authored token
  in the generated drive DT. Scalar body RHS values and scalar operands inside
  body RHS expressions may also read scalar aggregate storage leaves such as
  `frame.mode` or `lanes[1]`; those paths resolve against declared actor-owned
  aggregate storage before lowering and preserve the authored token in the
  generated drive DT. Body RHS expressions recursively substitute drive formals
  with the generated drive payload signals before DT emission. Drive body RHS
  expression operator-position enum members or aggregate paths remain
  deferred. Body targets may also write scalar aggregate storage leaves such as
  `frame.mode` or `lanes[1]`; those targets resolve against declared
  actor-owned aggregate storage before lowering and preserve the authored
  token in the generated drive DT. Enum members as drive targets and
  subaggregate drive targets remain deferred.
- Each drive definition becomes a non-state DT block named `-drive_name`.
- Each drive call becomes one scheduled state.
- The call asserts `drive_name_start`.
- Parameterized calls also assign one inferred parameter signal per formal,
  such as `scl_val`.
- Named drive calls use exact positional arity: a drive with `N` formal
  parameters requires exactly `N` actual values at every known drive call.
  Missing actuals and extra actuals fail closed during lowering instead of
  leaving parameter signals unbound or silently ignoring values.
- Drive-call actuals may be scalar tokens or composed `.fsm` expression forms.
  Argument-level composition is part of the Lisp-like ISF surface, so a call
  such as `(drive mosi (& tx_byte[7] shift_enable))` lowers to a composed
  scheduled `.fsm` expression instead of requiring a temporary variable.
  Scalar drive-call actuals may use local enum members such as `mode.BUSY` or
  package enum members such as `shared.mode.BUSY`; the parser resolves those
  values before lowering and preserves the authored token in the generated
  parameter assignment. Scalar drive-call actuals may also read scalar
  aggregate storage leaves such as `frame.mode` or `lanes[1]`; those paths
  resolve against declared actor-owned aggregate storage before lowering and
  preserve the authored token in the generated parameter assignment.
  Drive-call actual expressions may also use local or package enum members as
  scalar operands, and scalar aggregate storage leaves as scalar operands.
  Aggregate paths and enum members in drive-call expression operator position
  remain deferred.
- Inline transaction drive assignments such as `(drive inline_mode (mode_out
  mode.BUSY))` may use local or package enum members as scalar RHS values. The
  parser resolves those values before lowering, and scheduled `.fsm` preserves
  the authored enum token in the generated state assignment. Inline drive RHS
  expressions may also use enum members as scalar operands. Inline drive
  scalar RHS values and scalar operands inside RHS expressions may read scalar
  aggregate storage leaves such as `frame.mode` or `lanes[1]`; those paths
  resolve against declared actor-owned aggregate storage before lowering and
  preserve the authored token or expression payload in the generated state
  assignment. Inline drive targets may also write scalar aggregate storage
  leaves such as `frame.mode` or `lanes[1]`; those targets resolve against
  declared actor-owned aggregate storage before lowering and preserve the
  authored token in the generated state assignment. Subaggregate inline drive
  targets, inline drive RHS expression operator-position enum members, and
  aggregate paths in inline drive RHS expression operator position remain
  deferred.
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
- Rule-owned `(pulse TARGET)` actions lower through that same `<1`
  delayed-pulse family and remain pulse-domain assignments, not flopped data
  writes.
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

Author-facing mental model: a transaction is task-like because it consumes
cycles and can own formal boundaries. Transaction `(ports ...)` declarations
act as formal data/control ports, and activation sites pass scalar, literal,
or list-expression runtime payloads through explicit `(bind ...)` blocks. The
compiler owns the lower-level handoff signals, mux selectors, and generated-top
bridge wiring. This is still static hardware, not a stack-allocated SV task
call: every activation lowers to scheduled `.fsm` states, persistent handoff
signals, and reviewable
assignments. Parameter overrides are narrower than port bindings: spawned child
transactions and blocking `do` generated child activations support
transaction-local `params` and per-instance `(params (NAME value) ...)`
overrides through the generated composition path, and those overrides
specialize static child instances. Transaction-local scalar parameter defaults
may use earlier scalar transaction parameter defaults, actor-local constants,
actor-local scalar parameter defaults, local enum members such as `mode.BUSY`,
or package enum members such as `shared.mode.BUSY`; compatible aggregate/list
defaults may use the same scalar leaf sources. Actor-static default leaves are
resolved to literal values before generated child `.fsm` `+params`,
generated-composition child parameter summaries, and default instance bindings
are published. Earlier transaction-parameter dependency tokens and enum member
defaults preserve the authored token in those review surfaces because the
generated child `.fsm` carries the needed declarations. Parameterized rule
triggers use the same static-specialization model: they specialize generated
child activation instances rather than mutate a shared transaction body.
Direct `(on ...)`
entry activation does not accept activation-site parameter overrides: it is the
transaction's own guard, not a separate caller-owned instance. Parameter
declarations on a directly entered transaction still apply as defaults for
that transaction definition; per-activation specialization requires a
generated activation form such as `spawn`, parameterized blocking `do`, or
parameterized rule `trigger`.

The activation-site parameter shape is the same explicit block already used by
spawned children. It is shipped for spawn, blocking `do`, and rule `trigger`:

```lisp
(do child
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)))

(trigger child
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)))
```

Those `params` values are static specialization values, not runtime payload
actuals. Runtime-varying data/control values must use transaction ports and
`(bind ...)`. A parameterized blocking `do` elaborates a generated child
activation instance and waits for that instance's `done` handoff. If two
activation sites override the same transaction parameter with different
values, the implementation must specialize distinct logical child instances or
cloned scheduled regions. It must not lower the parameter as a mutable runtime
signal shared by every activation of the transaction.

Actor-local constants, actor-local scalar parameter defaults, enum members,
and qualified imported package scalar constants are accepted as static
activation parameter override values. A constant, actor-scalar-parameter, or
`PACKAGE.CONSTANT` name may appear as a scalar override value, or as a scalar
leaf inside an aggregate/list override value, for generated activation forms
that already support `(params ...)`: spawn, parameterized blocking `do`, and
parameterized rule `trigger`. A local enum member such as `mode.BUSY` or
package enum member such as `shared.mode.BUSY` may appear as either a scalar
override value or a scalar leaf inside an aggregate/list override value. The
lowerer resolves constants, actor scalar parameters, enum members, and
qualified package scalar constants to literal values before generated-top
emission, so generated `?fsmc` parameter overrides remain self-contained.
Unqualified package constants, package aggregate constants, and package
member/item paths remain fail-closed. Reusable-library use-site parameter overrides
follow the same static value rule for scalar values and aggregate/list leaves:
numeric/exact-width literals, importing-actor constants, importing-actor
scalar parameter defaults, local/package enum members, and qualified imported
package scalar constants resolve before generated-top `?fsmc` emission and
`library_uses[]` report publication. Unqualified package constants, package
aggregate constants, and package member/item paths remain fail-closed.
Unknown names, unknown enum members, non-scalar actor parameters, transaction
parameters, runtime signals, and arbitrary expressions remain fail-closed.

The parameterized rule-trigger contract follows the same specialization rule.
It elaborates a generated child activation instance named
`{rule}_{transaction}_trigger_{ordinal}` for each lexical parameterized trigger
site, applies the overrides on that generated `?fsmc` instance, and preserves
the shipped rule-trigger pulse and input payload timing through generated
handoff DTs. Generated-child rule-trigger output bindings are supported for
scalar actor targets: the parent handoff DT reads the generated child output
port through the generated top and copies it to the bound actor signal only
under that trigger instance's done-observer signal. Direct/local transaction
rule-trigger output bindings remain rejected because a shared local target has
no rule-specific completion identity. Within one rule, generated trigger
output bindings may not target the same actor signal more than once; this
fails closed before scheduled `.fsm` emission because the source surface has
no rule-local output selection policy.

Direct `(on ...)` activation has no corresponding `(params ...)` source shape.
The only legal nested body clauses in `(on port body...)` are
`(sample port as name)` entries. A source such as
`(on start (params (WIDTH 16)))` is unsupported and fails closed with a
diagnostic that says direct `(on ...)` activation is an entry guard, not a
generated activation-site parameter override. It must not be interpreted as
either a runtime assignment or a static specialization site. Authors who need
runtime-varying values at entry should sample or read ports; authors who need
static specialization should move the reusable work behind a generated
activation site. The optional `(on SIGNAL as NAME)` activation label names the
entry state for checks only; it does not create a parameterizable activation
instance.

Current transaction clauses:
- `(on port body...)`
- `(when condition body...)`
- `(drive name args...)`
- `(await port)` and `(await port (watchdog N))`
- `(sample port as name)`
- `(wait N)` for an unconditional exact-cycle delay with a non-negative static
  literal, actor constant, actor scalar parameter default, bounded runtime
  scalar count, or bounded runtime expression count
- `(while cond body...)`
- `(until cond body...)`
- `(repeat count body...)`
- `(switch signal (value body...)...)`, with optional `(default body...)` or
  `(_ body...)` fallback branch
- `(set var expr)`
- `(update var expr)`
- `(shift_left reg bit)`
- `(shift_left reg bit (width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT))`
- `(shift_right reg bit)`
- `(shift_right reg bit (width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT))`
- `(assemble part... as var)`
- `(assemble part... as var (widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...))`
- `(extract word as field...)`
- `(extract word as field... (widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...))`
- `(do transaction [(domain NAME)] [(params (NAME value) ...)] [(bind ...)])`
- `(spawn transaction as instance [(domain NAME)] [(params (NAME value) ...)] [(bind ...)])`
- `(trigger transaction [(params (NAME value) ...)] [(bind ...)])`
- `(await_all done_port)`
- `(await_any done_port)`
- `(complete port)`
- `(latency (min N|PARAM|CONST|PACKAGE.CONSTANT)
  (max N|PARAM|CONST|PACKAGE.CONSTANT))`, where each bound is a positive
  decimal literal, actor constant, actor-local scalar parameter default, or
  qualified imported package scalar constant

Authored child instance labels in `spawn ... as`, reusable-library
`use ... as`, and ATL static instance declarations use the simple spelling
`[A-Za-z_][A-Za-z0-9_]*` and must be non-reserved across SystemVerilog and
VHDL-2008. SystemVerilog keyword matching is case-sensitive; VHDL matching is
case-insensitive. FSMGen rejects a reserved label at the nearest source
boundary rather than silently renaming it.

Unsupported transaction clause heads now fail closed during lowering instead
of being silently ignored. The same applies inside currently lowered body
contexts: `when` bodies, `switch` branches, and `repeat` bodies each have a
bounded supported subset matching the shipped lowerer. The deferred-but-recognized
transaction `(stage ...)` clause keeps its more specific diagnostic. The removed
`(contract ...)` clause is no longer recognized — it falls to the generic
unsupported-clause diagnostic (its bounded-eventually intent is now
`(assert (monitor (within signal cycles)))`).

### 7.1 Activation

`(on port ...)` creates an entry/idle state guarded by scalar `port`.
The only supported inline body clauses inside `(on ...)` are
`(sample port as name)` forms; other activation-body forms fail closed during
lowering instead of being ignored.
`(on ...)` does not accept `(params ...)` because it is not a separate
activation instance. Unsupported `(params ...)` body clauses get a targeted
diagnostic that names the entry-guard/generated-activation boundary.
Transaction-local `params` on the same transaction remain definition defaults,
not per-entry overrides.

The scheduler also creates `can_accept` and asserts it in entry states. This is
the current replacement for the old handshake-ready spelling. Deprecated
`(handshake name (valid signal) (ready signal))` metadata is compatibility-only:
the parser validates a scalar name, exactly one scalar `valid`, and exactly one
scalar `ready`, but the scheduler does not lower old handshake semantics. This
is an explicit compatibility policy, not an unfinished lowering path.

Samples inside `(on ...)` lower to guarded D-input assignments (`<=`) on the
entry transition.

`(when condition ...)` may be used as the first transaction clause as an
activation guard. It may also appear later as inline branching.
Transaction `when`, `while`, and `until` condition expressions may use local
enum members such as `mode.BUSY`, package enum members such as
`shared.mode.BUSY`, or scalar aggregate storage leaves such as `frame.flag` as
scalar operands. Scalar aggregate storage leaves and scalar local/package enum
members may also be used directly as standalone transaction conditions, for
example `(when frame.flag ...)`, `(while mode.BUSY ...)`, and
`(until shared.mode.BUSY ...)`. The parser resolves those operands before
lowering and preserves the authored condition expression, scalar aggregate
condition, or scalar enum member condition in the scheduled `.fsm`
computed-test selector. Non-HDL-identifier standalone conditions lower through
computed selector syntax such as `?(frame.flag)`, `?(mode.BUSY)`, or
`?(shared.mode.BUSY)`. Enum members or aggregate paths in transaction
condition expression operator position remain deferred.

### 7.1.1 Transaction Ports and Actor Pin Access

Transaction port declarations and activation-time bindings are now accepted.
Actor pin access is available through those bindings: actor inputs may be read,
actor outputs may be written, and actor output readback is rejected. Input
bindings may now be scalar signals, numeric/exact-width literals, or non-empty
list expressions. Bounded schedule-report binding provenance is shipped;
broader output binding shapes remain deferred follow-on work after
[docs/tasks/ISF-PORT-BINDING.md](../tasks/ISF-PORT-BINDING.md) and
[docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md](../tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md).

The public direction remains an ISF-level surface, not an author-facing escape
hatch to low-level `.fsm` handoff wiring. A transaction declares directional
data/control ports locally. Activation sites bind those ports to scalar actor
variables, actor-owned storage, or actor top-level pins with exact direction
and width checks. Authors should not manually create transaction payload wires,
bridge ports, generated-top handoff nets, or start-payload signals just to
connect transactions; the compiler lowers the ISF boundary into explicit
scheduled `.fsm` handoff assignments and reviewable generated-top wiring.

Shipped transaction declaration shape, assuming actor-level
`(params (DATA_W 32))`, `(constants (DATA_W 32))`, or imported package
constant `shared.DATA_W`:

```lisp
(transaction read_word
  (ports
    (input  addr (width 32))
    (output data (width DATA_W))
    (input  mask (width shared.DATA_W)))
  ...)
```

Each transaction may contain at most one `(ports ...)` clause. Each port entry
is `(input name)`, `(output name)`, `(input name (width N))`, or
`(output name (width N))`; `(width PARAM)`, `(width CONST)`, and
`(width PACKAGE.CONSTANT)` are also accepted when the source is an actor-local
scalar parameter default, declared actor constant, or qualified imported
package scalar constant that resolves to a positive integer. Generated child
and direct/non-generated transactions may also use a same-transaction scalar
parameter default with `(width TX_PARAM)` when that default resolves to a
positive integer. A later transaction parameter may reference an earlier
scalar transaction parameter default, and the transaction-local name resolves
before actor constants and actor parameters. `name` is a scalar HDL
identifier and `N` is a positive integer literal. Omitted width means 1.
Runtime interface signals, cross-transaction parameter names, unknown
symbolic names, unknown or unqualified package constants, package aggregate
constants, package aggregate scalar-leaf paths, ambiguous
local-enum/package-constant spellings, zero-valued or non-scalar actor or
transaction parameters, zero-valued actor constants, zero-valued package
constants, forward/self/cyclic transaction-parameter defaults, and arbitrary
expressions are rejected as port widths. Port names are unique across both
directions within the transaction. The parser returns the normalized
transaction-shell shape with resolved integer widths:

```lisp
ports = {
  inputs  => [ { name => "addr", width => 32 }, ... ],
  outputs => [ { name => "data", width => 32 }, ... ],
}
```

The `(ports ...)` declaration is not forwarded as a scheduler body clause. A
declaration by itself does not create behavior; behavior comes from transaction
states/rules that read or write the port and from activation sites that bind
the port.

Shipped activation binding shapes:

```lisp
(do read_word
  (bind
    (input addr req_addr)
    (output data read_data)))

(spawn read_word as r0
  (bind
    (input addr req_addr)
    (output data read_data)))

(trigger read_word
  (bind
    (input addr (+ base_addr offset))))
```

Transaction input bindings accept scalar actor-side signals,
numeric/exact-width literals, and non-empty list expressions. Scalar sources
and expression sources whose width is known by the lowerer are width-checked
against the transaction input port. Unknown expression widths continue into
the downstream `.fsm` expression validation and HDL generation path. Every
scalar signal reference that the lowerer can identify in an input-binding
expression must be a known readable actor input, declared actor-owned storage
signal, or known transaction variable in the caller's scope; actor output
readback is rejected. Division and modulo in input-binding expressions reject
literal-zero, actor-constant-zero, actor-parameter-zero, and
same-transaction-parameter-zero divisor operands before scheduled `.fsm`
emission. Transaction output bindings remain scalar-only because the
actor-side endpoint is the writable destination.

Transaction input bindings may include an explicit timing assertion as a
fourth entry:

```lisp
(bind
  (input addr req_addr (timing snapshot))
  (input live_data source (timing live)))
```

`snapshot` is accepted only on activation-region `do` inputs and rule-trigger
payload captures, where the source is already captured at the activation or
trigger boundary. `live` is accepted only on generated-top live handoff input
bindings, such as spawned generated-child inputs. A mismatched timing mode
fails closed; FSMGen does not add extra capture storage or continuous local
wiring to convert one timing mode into another in this slice. Output bindings
do not accept timing selection.

Local `(do ...)` bindings lower into the scheduled parent `.fsm` state that
starts and awaits the child transaction. Transaction input bindings are
emitted before the generated `child_start`; output bindings copy the child
output port to the bound actor signal under the generated `child_done` guard.
Parameterized/generated `(do ...)` bindings lower through explicit
generated-top handoff ports and a parent-owned `do_port_binding` DT. Input
bindings are same-cycle parent handoff assignments; output bindings copy the
generated child output under the generated instance's `done` guard.

`(spawn ...)` bindings lower through hidden generated-top handoff ports. Input
bindings create a hidden parent output handoff and a visible child input port;
output bindings create a hidden parent input handoff from the child output
port and a reviewable parent DT assignment to the bound actor signal. The
generated top wires those handoffs explicitly. Actor signals consumed by
explicit spawn input-binding expressions are not also same-name wired into the
child instance; the explicit handoff is the data path. Spawn output-binding
assignments are owned by the parent transaction for assignment provenance and
rule/transaction conflict analysis.

Rule `(trigger ...)` bindings support transaction input ports for local and
generated targets. Each triggering rule emits a distinct payload source signal
per bound input port, and the generated trigger fan-in DT routes that payload
into a local transaction port under the matching per-rule trigger source.
Parameterized/generated rule triggers additionally support scalar output
bindings: the generated trigger handoff DT copies the child output handoff to
the actor target when that generated trigger instance's done-observer signal
is high. Multiple rule payloads or output copies for the same port/target
therefore remain visible as guarded same-LHS assignments instead of being
silently merged. Multiple generated trigger output bindings in one rule may
not target the same actor signal, because the binding surface has no
rule-local output selection policy. Direct/local transaction rule-trigger
output bindings remain deferred because a shared local transaction target has
no rule-specific completion identity; their diagnostic names the missing
generated-child completion identity instead of implying all rule-trigger
output bindings are unsupported.

The same-cycle visibility rule for the shipped surface is: input payloads are
emitted in the same activation region as their start/trigger handoff, and
spawned child bindings are live handoff wiring through the generated top.
Explicit `(timing snapshot)` / `(timing live)` spelling documents and checks
that current timing class; behavior-changing timing conversion remains
deferred.

Actor top-level input pins are readable observations. ISF should not allow
transactions or rules to write actor inputs. Actor top-level output pins are
writable targets, but only through the same assignment, fan-in, priority,
resource, and runtime-conflict policies used for other driven LHS values.
Reading an actor output as a source value needs an explicit contract; until
that ships, authors should keep a variable for internal reuse and bind or
drive the output from that variable.

Rules that trigger transactions need a payload story as soon as transactions
have input ports. Multiple rules may trigger the same transaction in different
cycles, and sometimes in the same cycle. The implementation must not silently
merge two different payloads for the same transaction input. It must either
prove compatible fan-in, use explicit priority/resource arbitration, or emit
verification-only runtime conflict instrumentation according to the existing
conflict policy.

The shipped conflict coverage is now concrete for scalar bindings:
same-target rule/transaction conflicts involving spawned output bindings enter
the existing fail-closed rule/transaction path, while accepted spawn-output and
rule-trigger input fan-in reaches the SystemVerilog backend's verification-only
selector assertions.
Within a single activation bind block, multiple output bindings may not target
the same actor signal; this fails closed before broader assignment conflict
analysis because no intra-bind output selection policy is shipped.

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
  [t/1100-isf-sample-piggyback.t](../../t/1100-isf-sample-piggyback.t).
- The current implementation treats sampled names as inferred storage; richer
  wire-vs-register optimization is still future work.

### 7.3 Await and Timeout

```lisp
(await ready)
(await ready (watchdog 32))
(await ready (watchdog WD_LIMIT))
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
- Actor-level and await-local watchdog limits may use declared actor
  constants, actor-local scalar parameter defaults, or qualified imported
  package scalar constants that resolve to positive integers. Top-level
  await-local watchdog limits may additionally use same-transaction scalar
  parameter defaults that resolve to positive integers. The generated counter
  width and init value use the resolved integer. Same-transaction parameters
  shadow actor-level static names in top-level await-local watchdogs and
  remain local lowering inputs. Generated child activation overrides for a
  transaction parameter used by a top-level await-local watchdog are accepted
  only when the override resolves to the same positive integer value as the
  child default; mismatches fail closed because the child watchdog counter is
  generated from the default-resolved scheduled `.fsm`. Runtime signals,
  unknown symbols, unknown or unqualified package
  constants, aggregate package constants, package member/item paths, arbitrary
  expressions, zero-valued constants, zero-valued package constants,
  zero-valued or non-scalar actor/transaction parameters, and
  cross-transaction parameters fail closed.

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
- `N` must be a positive decimal integer literal, a declared actor constant
  whose resolved value is a positive integer, an actor-local scalar parameter
  default whose resolved value is a positive integer, a same-transaction
  scalar parameter default whose resolved value is a positive integer, or a
  qualified imported package scalar constant whose resolved value is a positive integer. Each
  option may appear at most once, and `min` must be less than or equal to
  `max` when both are present.
- Same-transaction scalar parameter defaults, actor constants, actor scalar
  parameter defaults, and qualified imported package scalar constants are
  resolved before the existing counter lowering path. The emitted `.fsm` guard
  and timeout checks contain the resolved integer, not a symbolic runtime
  reference. Same-transaction parameters shadow actor-level static names in
  this value-domain slot and remain local lowering inputs.
- Runtime interface signals, unknown symbolic names, unknown or unqualified
  package constants, aggregate package constants, package member/item paths,
  arbitrary expressions, zero-valued constants, zero-valued or non-scalar
  actor/transaction parameters, and cross-transaction parameters fail closed.
  Generated child activation overrides for a latency-bound transaction
  parameter are accepted only when the override resolves to the same positive
  integer as the child default; mismatches fail closed because per-activation
  latency counter specialization remains deferred.
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
- Repeat counter width is inferred for positive static and runtime counts.
  Positive decimal literal counts use the minimum width that can represent the
  loaded count; positive actor constants, actor scalar parameter defaults, and
  qualified package scalar constants use their resolved integer value as width
  evidence while preserving the authored load token; same-transaction scalar
  parameter defaults use their resolved positive integer value as width
  evidence and as the scheduled `.fsm` load value; known-width runtime scalar
  names use their known interface, storage, or sample-derived width. Unknown
  names, non-scalar actor/transaction parameters, cross-transaction
  parameters, malformed scalar tokens, and expression-valued counts fail
  closed before counter emission.
- Generated child activation overrides for a repeat-count transaction
  parameter are accepted only when the override resolves to the same positive
  integer as the child default; mismatches fail closed because per-activation
  repeat counter specialization remains deferred.
- Repeat counts that are statically known to be zero, either as literal zero
  or as an actor constant, actor scalar parameter, same-transaction scalar
  parameter, or package scalar constant resolving to zero, lower as
  transparent no-op regions with no counter, repeat init/check state,
  repeat-body state, or `transaction_loops[]` entry. `do` and `spawn` child
  activations inside such a body are pruned with no child/top artifacts when
  the target is not otherwise live; syntactically valid parameterized, bound,
  or domain-annotated activation subclauses are treated as dead payloads after
  shape validation.
- Known-width runtime scalar repeat counts split the repeat init edge:
  nonzero values enter the repeat body, while zero values bypass the body and
  repeat check to the state after the repeat region.
- Top-level repeats and switch-nested repeats register the shared transaction
  counter at the widest required width.
- The shipped repeat-body clause surface is named drive calls, `await`,
  `sample`, `update`, `set`, `shift_left`, `shift_right`, `assemble`,
  `extract`, actor-owned bank `store` and `load`, and shipped `wait` clauses.
  Top-level repeat bodies also accept local blocking `(do child)` when the
  child transaction remains local to the scheduled parent. The repeat-body
  `do` state asserts `child_start`, waits for the child's fresh `child_done`
  pulse, and only then reaches the repeat check back-edge. Repeats directly
  inside a top-level `when` body accept local `(do child)` when the child
  remains in the parent scheduled module, plain generated-child `(do child)`
  when the target child is already emitted as a generated child by another
  activation site, and generated blocking `(do child (params ...))` with
  static parameter overrides. In the local case, the child remains in the
  parent scheduled module. In the generated-child or parameterized generated
  case, the generated top emits one deterministic
  `{parent}_{child}_repeat_do_{ordinal}` instance for the lexical nested do
  site and applies parameter overrides once when present. All shipped
  when-contained forms keep samples around the nested do in source order, and
  the branch-owned repeat check is unreachable until the fresh local or
  generated child done pulse is observed. Repeats directly
  inside a top-level `switch` branch accept the same local, plain
  generated-child `(do child)`, and generated blocking
  `(do child (params ...))` forms with the same source-order sample timing,
  deterministic generated-instance naming, static parameter application once
  when present, and done-gated nested repeat check. When-contained and
  switch-contained generated nested `do` also accept `(bind ...)` when static
  `(params ...)` overrides are present; the generated top wires those
  input/output binding handoffs once for the lexical nested do site.
  When-contained and switch-contained generated nested `do` also accept
  `(domain NAME)` as declared same-domain metadata when static `(params ...)`
  overrides are present. A separate shipped subset accepts a plain local
  `(do child)` and a same-domain generated `(do child (params ...))` (with
  `(bind ...)`/`(domain NAME)` when static params are present) inside a
  `(repeat ...)` directly in a single `(while ...)`/`(until ...)` body; a
  generated `do` instantiates its child in the `_top` composition. A further
  shipped loop-plus-branch subset accepts a plain local `(do child)` inside a
  `(repeat ...)` reached through `while -> when -> repeat`; the `while` guard
  enters the nested `when`, the `when` guard enters `repeat_init`, the local
  `do` waits for the child transaction's fresh done pulse, and the repeat
  check returns to the `while` re-test after the repeat body drains. Generated
  `do`, `spawn`, cross-domain, `(bind ...)`, `(domain ...)`, `until -> when`,
  nested `switch`, and extra loop nesting in this loop-plus-branch family
  remain fail-closed. A further
  shipped subset accepts a plain local `(do child)` and a same-domain generated
  `(do child (params ...))` inside a `(repeat ...)` reached through deeper
  branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`); the generated
  `do` instantiates its child in the `_top`. A further shipped subset accepts
  the basic `(spawn child as inst)` + same-body `(await_all done)` (or
  single-pending `(await_any done)`) drain inside a loop-contained or
  deeper-nested repeat (lowering + composition parity with the top-level
  repeat-body spawn — the same pre-existing full-HDL composition-wiring
  limitation applies). A multi-pending `(await_any done)` followed by a later
  same-body `(await_all done)` drain is also supported in these contexts (as at
  top-level / when-body / switch-branch). Inside a loop-contained or
  deeper-nested repeat, an undrained spawn stays deferred
  (`loop-contained`/`deeper-nested repeat-body spawn requires same-body
  '(await_all done)' or single-pending '(await_any done)'`). A parent-body sync
  after the repeat exits is not a valid drain for repeat-body spawned children;
  it emits `repeat-body spawn cannot be drained by parent-body '(await_all
  done)' after the repeat exits; use same-body '(await_all done)' before the
  repeat check can loop` (with the authored sync form in the message). A
  multi-pending `(await_any done)` without a later `(await_all done)` remains
  fail-closed with a diagnostic that names the missing proof, for example
  `loop-contained repeat-body multi-pending await_any requires later same-body
  '(await_all done)' before the repeat check can loop`; top-level and
  deeper-nested forms use their matching context prefixes. A cross-domain
  generated `do` stays deferred (`cross-domain repeat-body do remains
  deferred`).
  A `while`- or body-first `until`-contained repeat may also keep one or more
  generated spawns pending across one plain local blocking `(do child)` when a
  later same-body `(await_all done)` drains the exact spawned-child set before
  repeat and the surrounding loop re-entry. The
  `while`- or `until`-contained single-pending variant may use post-`do`
  `(await_any done)` instead when the effect checker proves
  `await_any_single_pending_completes_outstanding_set` for that spawned
  instance. Multi-pending post-`do` `(await_any done)` is accepted as an
  observation point only when a later same-body `(await_all done)` drains the
  same pending generated children before repeat and loop re-entry; this rule
  has no public fanout cap. Generated `do` while spawned children are pending,
  missing later drains, cross-domain activation, and unrelated deeper placements
  remain fail-closed.
  Repeats directly inside a top-level
  `when` body also accept one or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites
  when the same nested repeat body reaches `(await_all done)` before the
  nested repeat check can loop. Repeats directly inside a top-level `switch`
  branch accept the same multiple generated-spawn plus same-body `await_all`
  subset. Both branch-contained paths may use single-pending
  `(await_any done)` directly when exactly one generated child is pending. Both
  branch-contained paths may also use multi-pending `(await_any done)` as an
  observation point when a later same-body `(await_all done)` drains the same
  outstanding generated children before the nested repeat check can loop.
  Those branch-contained nested spawns reuse the static generated-child
  handoff model and preserve source-order samples before the nested spawn or
  sync states. The top-level `when` body and top-level `switch` branch
  nested-repeat forms may also run a local plain `(do child)` while generated
  nested spawns remain pending either before or after a prior multi-pending
  `(await_any done)` observation, provided a later same-body `(await_all done)`
  drains every outstanding generated child before the nested repeat check can
  loop. That local do target remains in the parent scheduled module, waits for
  its own fresh local done pulse, and does not clear the generated-spawn done
  set. Those same branch-contained local-do forms may then start one or more
  additional generated nested spawns before the mandatory same-body
  `(await_all done)` drain, either when no multi-pending `await_any`
  observation is active before the later generated spawn or when the local
  `do` follows a prior multi-pending observation. The later spawn joins the
  same outstanding generated-spawn set; the local child's done pulse must be
  observed before the later spawn state can start, and the later `await_all`
  still drains both the pre-do and post-do generated spawns before nested
  repeat re-entry. In the prior-observation form, those branch-contained
  local-do paths may also run a second post-spawn multi-pending
  `(await_any done)` observation before the mandatory same-body
  `(await_all done)` drain. Both `await_any` observations leave the
  outstanding generated-spawn done set live, and the final `await_all` drains
  both pre-do and post-do generated spawns before nested repeat re-entry.
  That same local-do do-then-spawn shape may also run a post-spawn
  multi-pending `(await_any done)` observation before the final same-body
  `(await_all done)` drain when no prior multi-pending observation is active
  before the later spawn. The post-spawn observation does not clear the
  outstanding generated-spawn done set. The top-level
  `when` body and top-level `switch` branch
  nested-repeat subsets also accept a plain generated-child `(do child)` in
  that same pending-spawn interval when the target child is already emitted as
  a generated child by another activation site. The top-level `when` body and
  top-level `switch` branch forms may also place that plain generated-child
  `do` after a prior multi-pending `(await_any done)` observation, provided
  the later same-body `(await_all done)` drain still gates nested repeat
  re-entry. The generated do site owns one deterministic
  `{parent}_{child}_repeat_do_{ordinal}` instance, waits for that instance's
  fresh done handoff, and still leaves every pending generated-spawn done
  handoff live for the later same-body `(await_all done)` drain. That plain
  generated-child do may also be followed by one or more additional generated
  nested spawns before the mandatory same-body `(await_all done)` drain,
  either when no multi-pending `await_any` observation is active before the
  later spawn or when the generated-child `do` follows a prior multi-pending
  observation. The generated do instance's fresh done handoff gates the later
  spawn state, and the later `await_all` drains both pre-do and post-do
  generated spawns before nested repeat re-entry. In the prior-observation
  form, those branch-contained plain generated-child paths may also run a
  second post-spawn multi-pending `(await_any done)` observation before the
  mandatory same-body `(await_all done)` drain. Both `await_any` observations
  leave the outstanding generated-spawn done set live, and the final
  `await_all` drains both pre-do and post-do generated spawns before nested
  repeat re-entry. Top-level
  `when` body and top-level `switch` branch nested repeats also accept
  static-parameter generated `(do child (params ...))` in that same
  pending-spawn interval; the generated do site owns one deterministic
  instance, preserves static generated-top parameter binding, waits for its
  own fresh done handoff, and leaves every pending generated-spawn done
  handoff live for the later drain. The top-level `when` body and top-level
  `switch` branch forms may also place that static-parameter generated `do`
  after a prior multi-pending `(await_any done)` observation, provided the
  later same-body `(await_all done)` drain still gates nested repeat re-entry.
  Top-level `when` body and top-level `switch` branch nested repeats also
  accept static-parameter generated `(do child (params ...) (bind ...))` in
  that pending-spawn interval. The bound generated `do` may run before a
  post-do multi-pending `(await_any done)` observation or after a prior
  multi-pending `(await_any done)` observation, provided the later same-body
  `(await_all done)` drain still gates nested repeat re-entry. The generated
  do site wires generated-top input/output binding handoffs once, waits for
  its own fresh done handoff, and leaves every pending generated-spawn done
  handoff live for the later drain.
  Top-level `when` body and top-level `switch` branch nested repeats also
  accept static-parameter same-domain generated
  `(do child (params ...) [(bind ...)] (domain NAME))` in that pending
  interval; the domain annotation is declared same-domain ownership metadata
  only for the deterministic generated do instance, generated-composition and
  clock-domain summaries retain that ownership, and every pending
  generated-spawn done handoff remains live for the later same-body
  `(await_all done)` drain. The top-level `when` body and top-level `switch`
  branch same-domain subsets may also run after a prior multi-pending
  `(await_any done)` observation, still requiring that later same-body drain.
  Top-level `when` body nested repeat local `(do child)` may also be followed
  by post-do multi-pending `(await_any done)` as an observation point while
  generated nested spawns remain pending, provided the local child completes
  before that observation and a later same-body `(await_all done)` drains
  every pending generated spawn before nested repeat re-entry. Top-level
  `switch` branch nested repeat local `(do child)` supports the same post-do
  multi-pending `(await_any done)` observation and later-drain contract while
  generated nested spawns remain pending before the same-body `await_all`
  drain. Top-level `when` body nested repeat plain generated-child
  `(do child)` supports the same post-do multi-pending `(await_any done)`
  observation and later-drain contract while generated nested spawns remain
  pending before the same-body `await_all` drain; the generated-child do
  waits for its deterministic generated do instance's fresh done handoff.
  Top-level `switch` branch nested repeat plain generated-child `(do child)`
  supports the same post-do multi-pending `(await_any done)` observation and
  later-drain contract while generated nested spawns remain pending before
  the same-body `await_all` drain; the generated-child do waits for its
  deterministic generated do instance's fresh done handoff. When no prior
  multi-pending `await_any` observation is active before the later spawn,
  those plain generated-child do subsets may also start one or more later
  generated nested spawns, run a post-spawn multi-pending `(await_any done)`
  observation, and then use the mandatory same-body `await_all` to drain both
  pre-do and post-do generated spawns before nested repeat re-entry.
  Top-level `when` body and top-level `switch` branch nested repeat
  static-parameter generated
  `(do child (params ...))` support the same post-do multi-pending
  `(await_any done)` observation and later-drain contract while generated
  nested spawns remain pending before the same-body `await_all` drain; the
  generated do waits for its deterministic generated do instance's fresh done
  handoff and preserves static generated-top parameter binding. Those
  static-parameter generated-do subsets may also start one or more later
  generated nested spawns before the mandatory same-body `await_all`, either
  when no multi-pending `await_any` observation is active before the later
  spawn or after the generated do follows a prior multi-pending observation;
  the generated do instance's fresh done handoff gates the later spawn state
  and the final drain covers both pre-do and post-do generated spawns. Those
  same static-parameter generated-do do-then-spawn subsets may also run a
  post-spawn multi-pending `(await_any done)` observation before that final
  same-body `await_all` drain either when no prior multi-pending `await_any`
  observation is active before the later spawn or after the generated do
  follows a prior multi-pending observation; both observations leave all
  pre-do and post-do generated-spawn done handoffs live for the final drain.
  Top-level
  `when` body and top-level `switch` branch nested repeat static-parameter
  bound generated `(do child (params ...) (bind ...))` support the same
  post-do multi-pending observation and later-drain contract while also
  wiring the generated-top input/output binding handoffs for the generated do
  instance. Those bound generated-do subsets may also start one or more later
  generated nested spawns before the mandatory same-body `await_all`, either
  when no multi-pending `await_any` observation is active before the later
  spawn or after the generated do follows a prior multi-pending observation;
  the generated do instance's fresh done handoff gates the later spawn state,
  generated-top binding handoffs stay scoped to the do instance, and the final
  drain covers both pre-do and post-do generated spawns. In the
  prior-observation form, those same bound generated-do do-then-spawn subsets
  may also run a second post-spawn multi-pending `(await_any done)`
  observation before that final same-body `await_all` drain; both
  observations leave all pre-do and post-do generated-spawn done handoffs live
  for the final drain. Those same bound generated-do do-then-spawn subsets may
  also run a post-spawn multi-pending `(await_any done)` observation before
  that final same-body `await_all` drain when no prior multi-pending
  `await_any` observation is active before the later spawn; the observation
  leaves both pre-do and post-do generated-spawn done handoffs live. Top-level
  `when` body and top-level `switch`
  branch nested repeat
  static-parameter same-domain generated
  `(do child (params ...) [(bind ...)] (domain NAME))` support the same
  post-do multi-pending observation and later-drain contract while also
  retaining declared ownership metadata in generated-composition,
  domain-partition, and schedule-report clock-domain summaries. Those
  same-domain generated-do subsets may also start one or more later generated
  nested spawns before the mandatory same-body `await_all`, either when no
  multi-pending `await_any` observation is active before the later spawn or
  after the generated do follows a prior multi-pending observation. The
  generated do instance's fresh done handoff gates the later spawn state,
  declared ownership metadata remains scoped to the generated do instance,
  and the final drain covers both pre-do and post-do generated spawns. In the
  prior-observation form, those same same-domain generated-do do-then-spawn
  subsets may also run a second post-spawn multi-pending `(await_any done)`
  observation before that final same-body `await_all` drain; both
  observations leave all pre-do and post-do generated-spawn done handoffs
  live for the final drain, and declared ownership metadata stays scoped to
  the generated do instance. Those same-domain generated-do
  do-then-spawn subsets may also run a post-spawn multi-pending `(await_any
  done)` observation before that final same-body `await_all` drain when no
  prior multi-pending `await_any` observation is active before the later
  spawn; the observation leaves both pre-do and post-do generated-spawn done
  handoffs live while preserving declared ownership metadata. Deeper
  branch/loop nesting and cross-domain activation beyond the explicit
  activation-crossing surface remain fail-closed.
  Top-level
  repeat bodies also accept generated
  blocking `(do child)` when the target child is already emitted as a
  generated child by another activation site, and
  `(do child (params ...) [(bind ...)] [(domain NAME)])` with static
  parameter overrides, optional input/output port bindings, and optional
  declared same-domain ownership metadata. The generated top emits one
  generated do instance for the lexical do site, applies the parameter
  override once when present, wires binding handoff ports once when present,
  records same-domain ownership for generated composition and clock-domain
  report summaries when `(domain NAME)` is present, and the do state waits for
  that generated instance's fresh done pulse before the repeat check.
  Samples may appear before or after repeat-body `do`; pending samples before
  `do` materialize before the do state, while pending samples after `do`
  materialize after the do state's fresh done guard and before the repeat
  check. Cross-domain repeat-body `do` remains deferred. Top-level repeat
  bodies also
  accept the generated spawn subset:
  `(spawn child as instance [(params ...)] [(bind ...)] [(domain NAME)])`
  clauses followed by a same-body `(await_all done)` before the repeat check
  can loop. `(await_any done)` is also accepted in repeat bodies when exactly
  one repeat-body spawn is pending, making the re-entry proof equivalent to
  waiting for that one static child. When multiple repeat-body spawns are
  pending, `(await_any done)` is accepted only as an observation point before a
  later same-body `(await_all done)` drains the same outstanding spawned
  children before the repeat check. New repeat-body `spawn` or `do` clauses
  between that multi-pending `await_any` and its mandatory drain remain
  rejected. That subset reuses one static generated child instance per lexical
  spawn name; it does not create one child instance per repeat iteration.
  Parameter overrides specialize that static instance once in the generated
  top and use the same value/shape contract as top-level spawn. Input and
  output bindings reuse the top-level generated-child handoff contract:
  generated parent handoff ports are wired once in the generated top for the
  static instance, not recreated per iteration. Optional
  `(domain NAME)` annotations are declared same-domain ownership metadata only:
  they group the static child instance with the activation domain and do not
  imply CDC behavior or allow cross-domain activation. Samples may appear
  before or after repeat-body spawn as long as the same repeat body reaches
  same-body `await_all`, single-pending `await_any`, or multi-pending
  `await_any` followed by same-body `await_all` before the repeat check can
  loop. Pending samples materialize in an explicit sample state at their
  source-order timing point: before a later spawn state for sample-before-spawn
  ordering, or before the sync state for sample-after-spawn ordering.
  Cross-domain repeat-body `do`, generated or spawned nested activation beyond
  the documented top-level branch-contained generated do cases and shipped
  branch-contained spawn/local-do cases, broader
  outstanding-child semantics, `stage`, `contract`, deeper branch nesting,
  nested `while`, and nested `until` remain outside the shipped repeat-body
  subset.

The repeat count is a runtime counter load value, not an elaboration count.
Positive literal counts give statically reviewable loop bounds. Actor
constants, actor scalar parameter defaults, and qualified imported package
scalar constants resolving to positive integers are static width evidence for
the repeat counter, but the scheduled `.fsm` still loads the authored count
token. Same-transaction scalar parameter repeat counts also provide static
width evidence when they resolve to positive integers, but the scheduled `.fsm`
loads the resolved integer because transaction parameters are local lowering
inputs. Static zero counts from literals, actor constants, actor scalar
parameters, same-transaction scalar parameters, or package scalar constants
lower as transparent no-op regions with no counter, repeat init/check state,
repeat-body state, or `transaction_loops[]` entry. Plain `do` and `spawn`
child activations inside statically zero repeat bodies are pruned with the
unreachable body when their targets are not otherwise live. Syntactically
valid parameterized, bound, or domain-annotated static-zero child activations
are pruned the same way after activation subclause shape validation. Named counts
may be dynamic scalar signals when their width is known; those known-width
runtime scalar counts skip the repeat body and repeat check when the runtime
value is zero.
Unknown count names, unqualified package constants, package aggregate
constants, package member/item paths, non-scalar actor parameters, non-scalar
transaction parameters, cross-transaction parameters, expression-valued counts,
package constants inside repeat-count expressions, and generated-top
respecialization fail closed or remain deferred outside the shipped repeat
count-source policy. Repeat-body local `do` and repeat-body spawn
support preserve the
same runtime-counter rule: the loop reactivates a local child only after its
fresh done pulse, or reactivates a lexically named static spawn child instance
after same-body `await_all`, or after same-body
`await_any` when exactly one child is pending, or for top-level repeat bodies
and documented branch-contained nested repeats after multi-pending `await_any`
followed by a same-body `await_all` drain; neither form creates one child
instance per iteration. In the documented top-level `when` body nested-repeat
local-do-while-spawn-pending subset, including the path where a multi-pending
`await_any` observation precedes the local do, a local child may complete
before that same-body `await_all` drain, but every generated spawn instance is
still not eligible for re-entry until the later drain observes its done
handoff.

### 7.6.1 Transaction Wait

```lisp
(wait 3)
(wait shared.WAIT_TWO)
```

`(wait N)` is the shipped unconditional transaction-local delay, distinct from
`(await cond)` and `(repeat count body...)`. It does not test an external
condition and it does not repeat a body. The shipped static count surface
accepts a non-negative integer literal, an actor constant name, an actor-local
scalar parameter name whose default resolves before lowering to a non-negative
integer literal, a same-transaction scalar parameter default that resolves to
a non-negative integer literal, or a qualified imported package scalar
constant that resolves to a non-negative integer literal. The runtime count
surface accepts a
known-width scalar count name or a known-width non-empty list expression in
contexts whose predecessor edge can be split safely.

Cycle semantics:
- `wait 0` means no delay. It emits no wait state, consumes no active
  transaction cycle, and advances directly to the following transaction clause.
- `wait 1` means the transaction occupies one generated wait region for one
  active clock cycle, then advances on the next state transition.
- `wait N` contributes exactly `N` active transaction cycles every time the
  clause executes.
- A wait inside a future loop contributes its full `N` cycles for each loop
  iteration that reaches it.
- The wait does not observe or consume an `(await ...)` watchdog. It is still
  ordinary transaction time and therefore counts toward transaction latency
  accounting or transaction-level monitors that count active transaction
  cycles.

The static lowering is a reviewable fixed scheduled-state chain for positive
static counts. `(wait N)` emits `N` generated `*_wait_*` states when `N > 0`;
each state advances unconditionally to the next wait state or to the following
transaction clause. `(wait 0)` emits no generated state and no
`transaction_waits[]` entry. A symbolic `(wait NAME)` first resolves `NAME`
through same-transaction parameter defaults, then through the actor constant
table, then through actor-local scalar parameter defaults, and then follows
the same rule. Same-transaction parameters therefore shadow actor-level static
names in this value-domain slot. A qualified `(wait PACKAGE.CONSTANT)`
resolves through the actor's imported package constant metadata and keeps the
authored qualified token in reports. No hidden wait counter is introduced for
this static literal/constant/parameter/package-constant surface. Pending
samples collected before a positive wait piggyback onto the first generated
wait state using the same sample-assignment behavior as drive/await
piggybacking. Pending samples collected before a zero wait are preserved and
materialize on the next state-producing clause. The wait surface is accepted
at the top level of a transaction body and inside the currently shipped inline
body contexts:
`when`, `switch`, `repeat`, `while`, and `until` bodies.

For the runtime surface, `(wait count_signal)` is accepted when `count_signal`
has a known unsigned width. `(wait (<op> ...))` is accepted when every signal
referenced by the non-empty list expression has known width and the
expression-width helper can derive a positive result width. Expression counts
use the same predecessor-edge snapshot contract as scalar counts. The
predecessor state gets two explicit outgoing edges: an effective count of zero
bypasses directly to the post-wait state, and a non-zero effective count
snapshots the current scalar or expression value into a generated wait counter
and enters one generated wait state. The wait state decrements that sampled
counter while active, exits when the sampled counter is `1`, and loops while
it is greater than `1`. A sampled runtime value of `K > 0` therefore consumes
exactly `K` active wait cycles, and later changes to the source scalar or
expression operands do not affect that wait occurrence.

Consecutive top-level runtime waits are supported by carrying the same
edge split through the wait chain. If the first runtime count is zero, the
activation edge immediately evaluates the next runtime wait's zero-bypass or
positive sampled-counter path. If the first wait is active, its final sampled
counter cycle (`counter == 1`) performs that same split for the next wait
without rereading the first count source and without adding an extra active
cycle. Pending samples before the first wait in a consecutive chain use the
same path-specific timing: positive first-count paths sample in the first
wait, zero first-count plus positive next-count paths enter a generated
sample-preserving clone of the next wait state, and all-zero paths materialize
the sample in a generated clone of the final sample-compatible successor.

Runtime waits are also supported after the shipped top-level predecessor
states whose advance condition is known to the scheduler. After `(await
ready)`, the ready edge splits into `ready && count != 0` and `ready && count
== 0` while the watchdog timeout edge remains intact. After `(stage ...)`, the
stage ready edge is split the same way while the valid output remains driven
by the stage state. After a top-level `repeat`, the repeat-check exit edge
`counter == 0` is split while the loop-back edge is preserved. After
`await_all`, the split is gated by the logical AND of all collected done
signals. After `await_any`, the split is gated by the logical OR of the
collected done signals. After transaction bank `load` or `store` states, the
unconditional advance edge is split while the guarded scalarized bank
assignments remain in the bank state. Loop decision states can also split a
runtime wait edge: a `while` true body-entry or back-edge, an `until` false
back-edge, and a loop-exit edge that falls through to a following runtime wait
can all load or bypass the generated counter while preserving the opposite
loop branch.
Loop-control decision states split the false fallthrough edge when
`(exit-when COND)` or `(continue-when COND)` is immediately followed by a
runtime wait: the true edge still exits or continues, and the false edge loads,
enters, or zero-bypasses the generated wait under `!COND`.

Runtime waits inside `when` bodies are supported when no pending sample must
cross the dynamic wait. The branch true edge is split into positive-count
counter load and zero-count bypass paths, and the false edge still skips the
whole `when` body. Runtime waits inside `repeat` bodies are supported in first
or later body position when no pending sample must cross the dynamic wait.
Generated dynamic wait counters are registered alongside the repeat counter.
When the repeat body starts with a runtime wait, the repeat check owns the
nonzero loop-back split: repeat-counter zero exits the loop, repeat-counter
nonzero plus positive wait count reloads the generated wait counter and enters
the wait, and repeat-counter nonzero plus zero wait count bypasses to the
following body state or sample-compatible clone. Runtime waits inside `switch`
branches are supported for the no-pending-sample subset. If the selected
switch case starts with a runtime wait, the switch state owns that case's
positive-count counter load/entry and zero-count bypass; other explicit cases
remain selectable, and implicit fallthrough lowers as the complement of all
explicit case-value predicates. Runtime waits inside `while` bodies are
supported for the no-pending-sample subset. If the body starts with a runtime
wait, both the entry decision true path and the loop-back true path split into
positive-count counter load/entry and zero-count bypass paths, while the false
path exits the loop. Runtime waits inside `until` bodies are also supported
for the no-pending-sample subset. The initial predecessor enters or bypasses
the first body wait, the `until` true path exits, and the false loop-back path
reloads or bypasses the runtime wait for the next iteration. Runtime waits
after pending samples remain rejected when the selected successor cannot carry
the sample without changing timing. Runtime waits after predecessor states whose
edge split is not implemented yet, malformed counts, and unknown-width runtime
count expressions remain rejected.

Pending samples before top-level runtime waits are supported for the first
path-specific sample-materialization subset when the following state can carry
the zero-count sample without changing timing, such as a drive call, an await,
static wait state, completion state, independent scalar `set`/`update` state,
independent shift state, independent `assemble` state, or independent
`extract` state, or independent bank `load` state that neither reads nor
overwrites a pending sample alias, independent bank `store` state that neither
reads nor overwrites a pending sample alias, top-level ready/valid `stage`
state that neither reads nor overwrites a pending sample alias, or top-level
bounded-eventual `contract` arm state that neither reads nor overwrites a
pending sample alias, or top-level `await_all`/`await_any` sync state whose
collected done ports do not reference a pending sample alias, or top-level
`spawn` state whose generated start handoff does not overwrite a pending
sample alias, or a top-level transaction `(phase ...)` pass-through state.
The positive-count path matches positive static waits by
materializing samples in the first active wait state.
For counts greater than one, a second generated wait-loop state consumes the
remaining sampled counter value without repeating the sample. The zero-count
path matches `wait 0` by materializing samples in a specialized clone of the
next state-producing clause, so no hidden sample-only cycle is added and the
original following state does not double-sample after a positive wait.
Completion zero-count clones preserve the same delayed-pulse assignment and
return-to-idle transition as the original completion state.
Independent setter zero-count clones preserve the original scalar setter and
advance to the same successor as the original setter state. Setters that read
or overwrite a pending sample alias remain fail-closed because the zero-count
clone would otherwise sample and consume that alias in one state.
Independent shift zero-count clones preserve the original shift assignment and
advance to the same successor as the original shift state. Shifts that read or
overwrite a pending sample alias remain fail-closed for the same reason.
Independent assemble zero-count clones preserve the original concat assignment
and advance to the same successor as the original assemble state. Assemble
states that read a pending sample alias as a part or overwrite one as the
target remain fail-closed for the same reason.
Independent extract zero-count clones preserve the original slice assignments
and advance to the same successor as the original extract state. Extract
states that read a pending sample alias as the source word or overwrite one as
a destination field remain fail-closed for the same reason.
Independent bank-load zero-count clones preserve the original guarded
scalarized load assignments and advance to the same successor as the original
bank-load state. Bank loads that read a pending sample alias as the index or
scalarized entry, or overwrite one as the load target, remain fail-closed for
the same reason.
Independent bank-store zero-count clones preserve the original guarded
scalarized store assignments and advance to the same successor as the original
bank-store state. Bank stores that read a pending sample alias as the index or
stored value, or overwrite one as a scalarized bank entry, remain fail-closed
for the same reason.
Await-all and await-any zero-count clones preserve the original collected
done-port synchronization behavior and advance to the same successor as the
original sync state. Sync states whose collected done ports read a pending
sample alias remain fail-closed for the same reason.
Spawn zero-count clones preserve the original generated child start handoff
and advance to the same successor as the original spawn state. Spawn states
whose generated start handoff overwrites a pending sample alias remain
fail-closed for the same reason. Blocking `do` remains separate because it
also owns input/output bindings and a completion guard.
Transaction phase zero-count clones preserve the original pass-through
transition and advance to the same successor as the original transaction
`(phase ...)` state. This rule applies only to scheduler-created transaction
phase marker states, which have no assignments or guards; actor-level phase
metadata remains report-only and unrelated to runtime zero-count sample
materialization.
Ready/valid stage zero-count clones preserve the original `valid` assignment
and ready-gated transition, then advance to the same successor as the original
stage state when `ready` is true. Stage states that read a pending sample
alias as the ready input or overwrite one as the valid output remain
fail-closed for the same reason.
Bounded-eventual contract zero-count clones preserve the original one-cycle
arm request and advance to the same successor as the original contract arm
state. Contract monitor DTs remain the owners of pending, age, and fail
storage. Contract arm states that would read or overwrite a pending sample
alias remain fail-closed for the same reason.
Loop decision zero-count clones preserve the original repeat check decrement
or while/until condition decision. Repeat check assignments and loop
conditions that read or overwrite a pending sample alias remain fail-closed
for the same reason.
Top-level runtime waits whose zero-count successor cannot yet carry pending
samples without changing timing fail closed. Consecutive top-level runtime
wait chains carry pending samples across zero-count wait links when the final
zero-count successor is sample-compatible; the original downstream wait state
remains unsampled for paths that already materialized the sample. The same
path-specific materialization is also supported inside `when` bodies and
`switch` branches
when the selected zero-count successor can carry the pending samples. The
false path of `when`, other explicit switch cases, and implicit switch
fallthrough remain unchanged. `repeat`, `while`, and `until` bodies use the
same materialization when the zero-count body successor can carry pending
samples. Repeat loop-back/exit behavior, `while` false exits, and `until` true
exits remain unchanged. Completion states, independent scalar setter states,
independent shift states, independent assemble states, and independent extract
states, plus independent bank-load and bank-store states, are
sample-compatible selected successors in the shipped `when`-body and
`switch`-branch subset; top-level await-all/await-any sync states,
spawn states, transaction phase pass-through states, ready/valid stage states,
and bounded-eventual contract arm states are also sample-compatible for
top-level waits when their synchronization, start-handoff, ready/valid, or arm
signals do not touch pending sample aliases; transaction phase pass-through
states carry no assignments or guards. Repeat, while, and until loop
decision/check states are sample-compatible when their assignments and loop
conditions do not touch pending sample aliases. Runtime waits whose selected zero-count successor
cannot yet carry pending samples without changing timing fail closed.

Diagnostics:
- `(wait)` and `(wait N extra)` are malformed arity.
- Negative literals, non-integer literals, unknown symbolic names,
  non-scalar or non-integer actor or transaction parameter defaults,
  cross-transaction parameter names, unknown package constants, unqualified
  package constants, package aggregate constants, package member/item paths,
  package constants inside
  wait-count expressions, unknown-width dynamic scalar names, malformed or
  unknown-width dynamic expressions, and unsupported dynamic wait contexts
  fail closed.
- Waits outside transaction body contexts are invalid.

Successful schedule reports expose a bounded `transaction_waits[]` summary
rather than raw lowering internals. Each entry contains `transaction`,
`cycles`, `count_kind`, `count_source`, `entry_state`, `exit_state`,
`counter_signal`, and `counter_width`. Only positive static waits and accepted
runtime waits create entries. Static waits report `count_kind` as
`static`, `cycles` as the resolved positive integer, `count_source` as the
literal, actor constant name, actor parameter name, or qualified package
constant token, and
`counter_signal`/`counter_width` as JSON null. Runtime scalar waits report
`count_kind` as `runtime_scalar`; runtime expression waits report
`count_kind` as `runtime_expression` and keep the
normalized expression text in `count_source`. Both runtime forms keep `cycles`
as JSON null and expose the generated counter name/width through
`counter_signal` and `counter_width`.

### 7.7 Inline Control Flow

`(when condition body...)` is structurally validated with one scalar or
list-form condition and at least one list-form body clause before branch
expansion. It creates one decision state plus body states. The true path enters
the body, and the false path skips to the first state after the whole `when`
body. Current body support includes drive, await, sample, wait, complete,
repeat, update, shift/assemble/extract data operations, and nested `when`. Nested
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
value. The selector may be a signal, local/package enum member, or scalar
aggregate storage leaf, and branch values may use local/package enum members or
scalar aggregate storage leaves such as `frame.mode` and `lanes[1]`; aggregate
switch selectors and branch values are resolved against declared actor-owned
aggregate storage before lowering. Enum or aggregate switch selectors that are
not HDL identifiers lower through computed `.fsm` selector syntax such as
`?(mode.BUSY)`, `?(shared.mode.BUSY)`, `?(frame.mode)`, or `?(lanes[1])`,
because direct `.fsm` plain test selectors are reserved for
HDL-identifier-compatible signal names. Subaggregate selectors or branch values
remain deferred. Duplicate explicit values are rejected. A switch may also contain
one fallback branch, spelled `(default body...)` or `(_ body...)`. Those
spellings are aliases and are rejected if both appear in the same switch. If
no authored fallback branch is present, the scheduler emits an implicit `.fsm`
`(default (-> next_state))` fallthrough branch to the first state after the
whole switch.

The generated `.fsm` default selector means "no explicit sibling branch
predicate matched." Downstream `.fsm` lowering expands it as the logical
negation of the OR of every explicit branch predicate, such as
`!(opcode == 0 || opcode == 1)` for a two-value switch. This preserves a real
else/default branch without asking ISF to synthesize that Boolean expression
itself, and it avoids the old invalid pattern of duplicating one explicit case
such as `=0` for fallthrough.

Current branch-body support includes drive, await, sample, wait, repeat,
update, shift/assemble/extract data operations, and nested `when`. Branch
bodies exit to the first state after the whole switch, so multi-state branches
and repeat checks do not fall through into later branch bodies.

### 7.7.1 Transaction Loops

```lisp
(while (! done)
  (drive poll)
  (await ready))

(until done
  (drive step)
  (wait 1))
```

`(while cond body...)` is a shipped pre-test transaction loop. The scheduler
emits explicit generated decision states that sample `cond` once before each
possible iteration. The entry decision makes zero iterations possible: if the
sampled condition is true, control enters the body; if it is false, control
exits to the transaction clause after the whole loop. After a body iteration,
a back-edge decision samples the same condition before choosing either another
iteration or loop exit.

`(until cond body...)` is a shipped body-first transaction loop. Control enters
the body once before the first condition sample. After the body, the scheduler
emits a generated decision state that samples `cond` once. If the sampled
condition is true, control exits. If it is false, control loops back to the
body. One or more iterations are therefore required. A pre-test "run while not
done" loop should be written as `(while (! done) body...)`, not by overloading
`until`.

Loop conditions use the same scalar or list-expression condition surface as
transaction `(when ...)` and rule guards. The condition is sampled only in the
generated decision state. It is not a continuous guard over every state inside
a multi-cycle body; once the body starts, body states run according to their
own scheduled control flow until they reach the loop check or exit path.

For a bare `while`/`until` condition whose width is known and greater than one,
truth means **nonzero**, not exactly one. Lowering makes that rule explicit in
the review artifact: for example, a three-bit `(while count ...)` condition is
emitted as `?(!= count 3'd0)` at both the entry and back-edge decisions. A
one-bit bare condition keeps the compact `?flag` form, and authored expression
conditions keep their expression shape. `transaction_loops[].condition`
continues to report the authored condition rather than this width-derived
internal normalization.

The shipped `while`/`until` loop source position is top-level inside a
transaction body. `while`/`until` loop bodies accept the current inline body
subset: named drive calls, `await`, `sample`, `complete`, `repeat`, `update`,
`set`, shift/assemble/extract data operations, actor-owned bank `store`/`load`,
nested `when`, and shipped `(wait N)` clauses. They continue to reject `do`,
`spawn`, `await_all`, `await_any`, `stage`, `contract`, loops nested inside loop
bodies, and loops nested under `when`/`switch`/`repeat` until re-entry, child
lifetime, and report semantics are specified for those combinations.
Top-level repeat-body local `(do child)`, top-level when-body nested repeat
local, plain generated-child `(do child)`, or static-parameter generated
`(do child (params ...))` with optional `(bind ...)` handoffs and optional
declared same-domain `(domain NAME)` metadata, top-level
switch-branch nested repeat local, plain generated-child `(do child)`, or
static-parameter generated
`(do child (params ...))` with optional `(bind ...)` handoffs and optional
declared same-domain `(domain NAME)` metadata, top-level when-body and
switch-branch nested repeat generated spawns with same-body `await_all`,
single-pending same-body `await_any` when exactly one generated child is
pending, or multi-pending same-body `await_any` followed by a mandatory
same-body `await_all` drain, top-level when-body nested repeat local
`(do child)` or plain generated-child `(do child)` while generated nested
spawns are pending before or after a prior multi-pending `await_any`
observation, or static-parameter generated
`(do child (params ...))` while generated nested spawns are pending before or
after a prior multi-pending `await_any` observation, or
static-parameter generated `(do child (params ...) (bind ...))` while
generated nested spawns are pending, or static-parameter same-domain generated
`(do child (params ...) [(bind ...)] (domain NAME))` while generated nested
spawns are pending, before a later same-body `await_all` drain, top-level
switch-branch nested repeat local `(do child)` or plain generated-child
`(do child)` while generated nested spawns are pending before or after a prior
multi-pending `await_any` observation, or static-parameter generated
`(do child (params ...))` while generated nested spawns are pending before or
after a prior multi-pending `await_any` observation, or
static-parameter generated `(do child (params ...) (bind ...))` while
generated nested spawns are pending, or static-parameter same-domain
generated `(do child (params ...) [(bind ...)] (domain NAME))` while
generated nested spawns are pending, or top-level when-body static-parameter
same-domain generated `(do child (params ...) [(bind ...)] (domain NAME))`
after a prior multi-pending `await_any` observation while generated nested
spawns are pending, or top-level switch-branch static-parameter same-domain
generated `(do child (params ...) [(bind ...)] (domain NAME))` after a prior
multi-pending `await_any` observation while generated nested spawns are
pending, before a later same-body `await_all` drain,
repeat-body
generated blocking `(do child)` for
already generated child targets, `(do child (params ...) [(bind ...)]
[(domain NAME)])`, and repeat-body spawn followed by same-body `await_all`,
single-pending same-body `await_any`, or multi-pending same-body `await_any`
followed by a same-body `await_all` drain are the only shipped loop-body
child-activation subsets, and they apply only to `repeat` bodies.
Repeat-body spawn may carry the same static `(params ...)` overrides and
`(bind ...)` port handoffs as top-level spawn; those overrides and handoff
ports specialize the single lexical child instance and are not per-iteration
runtime values or per-iteration hardware. Repeat-body generated `do` may be
selected either by an already generated child target or by static
`(params ...)` overrides; when it has `(bind ...)` input/output handoffs and
same-domain `(domain NAME)` ownership metadata, those handoff ports and domain
summaries specialize the single lexical generated do instance and are not
per-iteration runtime values or per-iteration hardware. Samples around
repeat-body `do` materialize at their source-order timing point before the do
state or after the do state's done guard and before the repeat check. Generated-do
domain metadata still rejects cross-domain activation and unsupported nested
placement; explicit activation crossings own only the bounded blocking `(do child)`
surface documented in the multi-domain section.

Dynamic loops are ordinary persistent hardware schedule regions, not software
processes that appear or die. They may run for data-dependent or unbounded
cycle counts. They do not create an implicit timeout. Existing actor watchdog,
transaction latency, and temporal-contract mechanisms must remain explicit and
must count loop-body cycles according to their own documented active-cycle
semantics.

Malformed loop diagnostics:
- Missing condition, missing body, empty/non-list body forms, or extra
  structural wrapper forms must fail before misleading scheduled artifacts are
  emitted.
- Unsupported body clause heads must name the unsupported construct and the
  loop kind.
- Conditions must use the same scalar/list-expression condition contract as
  other ISF guards.

Successful schedule reports expose a bounded `transaction_loops[]` summary
rather than raw lowering internals. Each entry contains `transaction`, `kind`,
`condition`, `entry_state`, `decision_states`, `body_start`, `body_states`,
`exit_state`, and `body_clause_count`.
The `condition` value is the normalized condition text used in the scheduled
`.fsm` review artifact, not a raw parser node.

### 7.8 Data Manipulation

```lisp
(set var expr)
(update var expr)
(shift_left reg bit)
(shift_left reg bit (width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT))
(shift_right reg bit)
(shift_right reg bit (width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT))
(assemble header payload crc as packet)
(assemble header payload crc as packet (widths TX_HEADER_W HEADER_W PACKAGE.CRC_W))
(extract packet as header payload crc)
(extract packet as header payload crc (widths TX_HEADER_W 8 PACKAGE.CRC_W))
```

Current lowering:
- `set` is the canonical explicit scalar setter. It is structurally validated
  as `(set var expr)` with one scalar target `var` and one scalar or list
  expression payload. In a transaction it emits one ordered flopped assignment
  state to `var`.
- `update` remains supported as the older transaction-local spelling for the
  same flopped transaction update behavior.
- `shift_left` is structurally validated as
  `(shift_left reg bit [(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)])` with scalar
  `reg` and scalar `bit`, then emits a left shift plus inserted bit. The
  optional `(width ...)` is width evidence for the shifted register. It may be
  a positive integer literal, same-transaction scalar parameter default on a
  generated child or direct/non-generated transaction, actor-local scalar
  parameter default, declared actor constant, or qualified imported package
  scalar constant that resolves to a positive integer. It may fill missing
  transaction-local width evidence for
  later data operations and report metadata, but it must match any
  already-known width for the same register. Plain
  `(shift_left reg bit)` remains accepted without width evidence because the
  emitted left-shift expression does not need an insertion-position width.
- `shift_right` is structurally validated as
  `(shift_right reg bit [(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)])` with
  scalar `reg` and scalar `bit`, then emits a right shift plus inserted bit.
  When the shifted
  signal has a known interface, sampled-source, assemble-inferred, or explicit
  `(width ...)` value, the insert position uses that width. Unknown-width
  values now fail closed before scheduled `.fsm` emission instead of emitting
  a placeholder `WIDTH` expression. Explicit `(width ...)` is an assertion:
  it may fill missing width evidence, but it must match any already-known
  width for the shifted register.
- `assemble` is structurally validated as
  `(assemble part... as target [(widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...)])`
  with one or more scalar parts and one scalar target, then emits a concat
  expression into the target variable. An optional trailing `(widths ...)`
  list supplies ordered part-width evidence and must have one entry per part.
  Each explicit width entry may be a positive integer literal,
  same-transaction scalar parameter default on a generated child or
  direct/non-generated transaction, actor-local scalar parameter default,
  declared actor constant, or qualified imported package scalar constant that
  resolves to a positive integer. Mixed literal and accepted symbolic entries
  are allowed. The private width map infers the
  target width as the sum of known or explicit part widths. If
  exactly one part width is missing and the target width plus every sibling
  part width is known, the missing part width is inferred as the positive
  remainder. Explicit or inferred part widths become transaction-local
  evidence for later data operations in the same transaction. When every part
  width is known and the target already has a known width, the sum must match
  the target width or lowering fails closed. Two or more unknown part widths
  may still be accepted for the reviewable concat expression, but they are not
  used as width evidence unless the `(widths ...)` option makes them known.
- `extract` is structurally validated as
  `(extract word as field... [(widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...)])`
  with one scalar source word and one or more scalar destination fields. It
  emits one extraction state. When the source word and destination fields have
  known widths, or when the clause supplies an ordered `(widths ...)` list
  matching the field count, fields are assigned exact descending slices. Each
  explicit width entry may be a positive integer literal,
  same-transaction scalar parameter default on a generated child or
  direct/non-generated transaction, actor-local scalar parameter default,
  declared actor constant, or qualified imported package scalar constant that
  resolves to a positive integer. Mixed literal and accepted symbolic entries
  are allowed. If exactly one
  destination field width is missing and the source word width plus every
  sibling field width is known, the missing field width is inferred as the
  positive remainder. The inferred width becomes transaction-local evidence
  for later data operations in the same transaction. Two or more unknown field
  widths remain ambiguous and fail closed instead of producing placeholder
  slice bounds. Explicit widths must be positive and must not conflict with
  already known field widths.
  When the source word width is known, the sum of field widths must match it;
  a zero or negative inferred remainder fails closed.

The emitted shift expressions use the normal `.fsm` expression surface. Raw
`<<` and `>>`, plus `shl` and `shr` aliases, are accepted as binary operators
through SystemVerilog generation, so accepted ISF shift source is not merely a
schedule-text feature. Width alignment still matters at the surrounding
assignment boundary: a 1-bit drive actual should select a 1-bit expression such
as `tx_byte[7]` rather than relying on implicit truncation from an 8-bit word.

Width evidence is transaction-local and private to lowering today. Interface
declarations seed it, sampled aliases inherit known source widths, explicit
`shift_left`, `shift_right`, `assemble`, and `extract` options add local
evidence, and `assemble` can infer target width from known parts. Explicit
data-operation width options accept positive integer literals, actor-local
scalar parameter defaults, declared actor constants, qualified imported
package scalar constants, or same-transaction scalar parameter defaults on
generated child or direct/non-generated transactions that resolve to positive
integers. Accepted package constants must be imported, qualified as
`PACKAGE.CONSTANT`, and scalar package `+constants` entries. Accepted
transaction parameters are resolved from the transaction definition's default
before scheduled `.fsm` emission. Activation-site overrides on `spawn`,
generated blocking `do`, or rule `trigger` that target a generated child
parameter used by a data-op width are accepted only when they resolve to
the same value as the child transaction parameter default; mismatched
overrides fail closed with a targeted diagnostic, and full
override-specialized data-op width lowering remains backlog. Unqualified package constants, unknown package
constants, package aggregate constants, package member/item paths, ambiguous
local-enum/package-constant spellings, unrelated or cross-transaction
parameters, runtime signals, unknown names, arbitrary expressions, zero
values, non-scalar values, use-site overrides, activation-site override
specialization, and generated-top
respecialization are not data-operation width evidence. The
evidence is collected from the whole transaction clause tree before scheduled
state emission, so it is not source-order-sensitive. Schedule reports expose
positive integer `width` metadata for inferred scheduler counters and for
register storage whose ISF width evidence is known. They also expose optional
`role` metadata when the lowerer has stable scheduler evidence for the storage
purpose, such as sampled aliases, extracted fields, ordinary data registers,
completion pulses, watchdog/latency/repeat counters, and named-drive
request/payload storage.

Planned width-evidence precedence for this tree is: actor interface
declaration, operation-local explicit option, sampled-alias propagation,
structural derivation from `assemble`/`extract`, then generated scheduler
storage for existing counter families. Explicit width options are author
assertions, not force-casts: they may fill unknown facts, but they must match
already-known facts for the same name. Once an operation family is migrated by
the data-width tree, that family must fail closed instead of emitting
`WIDTH`, `HIGH`, or `LOW` placeholders for accepted source.

The migrated data-operation families now follow that rule. `extract` accepts
only exact descending slices, including the single-missing-field case where a
known source width and known sibling widths prove one positive remainder. It
fails when field widths are still ambiguous, explicit field widths conflict
with known facts, the inferred remainder is not positive, or the sum of field
widths disagrees with a known source word width. `shift_right` uses a concrete
insert position from known or explicit width evidence and fails when width
evidence is missing or contradictory. `shift_left` accepts the same optional
`(width ...)` evidence shape, rejects contradictory explicit widths, and keeps
plain widthless shifting accepted because no insertion-position width is
needed. `assemble` accepts an optional
`(widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...)` evidence list for ordered part
widths, derives a target width from fully known or explicit part widths, can
infer exactly one missing part width from a known target and known siblings,
and rejects known target-width mismatches,
contradictory explicit part widths, or non-positive inferred remainders.
