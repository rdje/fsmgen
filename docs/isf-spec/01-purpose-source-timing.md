# Intent Scheduling Format (`.isf`) — Specification v0.6

Source material:
- [docs/INTENT_SCHEDULING_BRAINSTORM.md](../INTENT_SCHEDULING_BRAINSTORM.md)
- [docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](../ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
- [docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](../ISF_PUBLIC_INTERFACE_CONTRACT.md)
- [docs/book/src/13-intent-scheduling.md](../book/src/13-intent-scheduling.md)
- [docs/book/src/13h-lowering-reference.md](../book/src/13h-lowering-reference.md)
- [docs/book/src/13k-isf-feature-support-matrix.md](../book/src/13k-isf-feature-support-matrix.md)

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
ISF intentionally borrows familiar programming-language control-flow shape for
transaction authoring. Existing forms such as `when`, `repeat`, `wait`,
`while`, `until`, `do`, and spawned-child activation should still read
naturally to authors. That source shape does not change the hardware contract:
every shipped form must lower to explicit RTL intent with reviewable scheduled
`.fsm` states, decision points, counters, handshakes, or DTs.

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
The downstream integration handoff in
[docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](../ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
must be updated in the same slice as any downstream-visible syntax,
diagnostic, lowering, public facade, schedule-report, generated-artifact, or
deferral change. A mismatch between that handoff, this spec, the mdBook, the
public contract, tests, or code is a bug.

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
- The plain single-clock `file.isf` path is expected to reach generated HDL
  with clean stderr on success. Accepted multi-domain event-crossing actors
  lower through generated domain/top artifacts and now reach generated
  SystemVerilog/Verilog-family HDL containing the generated top plus concrete
  acknowledged-event CDC child modules for accepted crossings when each
  emitted domain artifact satisfies the current scheduled `.fsm` clock/reset
  HDL contract.
- `--strict` is accepted on the plain `file.isf` path and still routes through
  scheduled `.fsm` generation before HDL output.
- `--check --json` and `--check-json` preserve the machine-readable check
  contract for `.isf` inputs. Parser, lowering, schedule-report, and
  downstream semantic check failures exit nonzero with `success: false` JSON
  on stdout, keep stderr clean, and carry the normalized diagnostic text in
  `diagnostics[0].message`.
- If lowering produces multiple `.fsm` files, `--outdir DIR` writes every file
  there and the parent actor file is fed into the normal pipeline.
- The public `--outdir` path is expected to write scheduled `.fsm` file content
  matching the in-process lower-result `files` map.

The live downstream-consumer API contract for these CLI surfaces, the
`FSM::Adapter::ISF` / `FSM::Scheduler::ISF` in-process facades, and the bounded
schedule-report key families is
[docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](../ISF_PUBLIC_INTERFACE_CONTRACT.md). Its
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
Its `live_document_paths` metadata advertises the live spec, downstream
handoff, public contract, issue-reporting protocol, library catalog, every
Intent Scheduling mdBook chapter listed in `docs/book/src/SUMMARY.md`
including the book-facing shipped feature matrix, the canonical feature
backlog, and the book reference map. The ISF mdBook subset is audited against
the summary so newly added shipped-surface book chapters remain discoverable
through the manifest.
Its shareable-resource catalog metadata is audited as exact for current
arbiter names, resource kinds, shipped/backlog status, and meaning text.
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
widths normalized to `1`. Actor top-level interface `(width PARAM)` and
`(width CONST)` entries are accepted when the symbolic name is an actor-local
scalar parameter default, declared actor constant, or qualified imported
package scalar constant that resolves to a positive integer; the parser
handoff still exposes the resolved integer width.
It also advertises the transaction-entry shell: `transactions` is an array of
entries with scalar `name` and `clauses` array fields. Those shapes are
live-contract metadata for scheduler-consumable actors, not a freeze of the
full raw actor hash or the private transaction clause payloads.
The actor identity shape is also explicit: `actor_name` is a non-empty scalar
identifier preserved from the ISF actor root.
Current actor timing fields are explicit too: `clock` is a non-empty scalar.
For legacy single-clock actors, omitted timing clauses default to `clock =
clk`, `reset = { name: rst_n, kind: async, polarity: active_low }`, and
`watchdog = 65535` exactly `(2^16 - 1)`. With `(clock-domains ...)`,
`clock` and `reset` expose the selected default-domain timing, and `reset`
is null only when that default domain omits reset ownership.
Explicit actor-level watchdogs may use a positive decimal literal, a declared
actor constant, an actor-local scalar parameter default, or a qualified
imported package scalar constant that resolves to a positive integer. The
parser returns the resolved integer in the public `watchdog` scalar; the
authored declaration remains visible through `actor_constants[]`,
`actor_params[]`, or package/import metadata and embedded package
`+constants` entries.
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
For single-clock multi-file lowering, the current schedule report is
parent-scoped. Child scheduled `.fsm` text is exposed through the lower-result
`files` map rather than folded into the report. For multi-domain
clock-domain lowering, the schedule report describes the generated top at the
top level and exposes bounded domain/crossing metadata through
`clock_domains[]` and `crossings[]`.

## 3. Source Root

The public compile/report entry root is:

```lisp
(actor name
  actor_clause...)
```

The active parser accepts exactly one actor root from the Lispish source for
the compile/report entry actor and normalizes the Lispish nested-head shape
into canonical `(actor name ...)`. A source with multiple top-level
`(actor ...)` roots fails closed with a targeted diagnostic; sibling actor
roots are not ATL child type definitions until actor type resolution is
explicitly selected. Imported sources may additionally provide
`(library name ...)` roots as described in [3.1](#31-reusable-library-imports).
The shipped ATL actor type-resolution source is not a sibling actor root; it
is a library-qualified static instance type,
`(instance NAME of ALIAS.EXPORT)` or compact `(NAME : ALIAS.EXPORT)`, where
`ALIAS` is declared by the enclosing actor's library imports and `EXPORT`
names a library actor export. Those qualified spellings now resolve to
metadata only when the alias is an explicit import and the export exists.
Accepted qualified instances add
library/export provenance to their `actor_network.instances[]` report entry
and reserve deterministic child names. Lowering now emits the parent scheduled
`.fsm` plus those resolved child scheduled `.fsm` files. It still emits no
ATL top and performs no child wiring.
Accepted parser output preserves `name` as the public actor-shell
`actor_name`; nested or otherwise non-scalar actor names are rejected before
the parser returns an actor shell.

Supported actor clauses:
- `(clock name)`
- `(reset name)` or `(reset (name async active_low))`
- `(watchdog N)`
- `(interface ...)`
- actor-level `(params ...)` for reusable library actors
- actor-level `(constants (NAME value) ...)` for non-negative integer or
  enum-member compile-time constants
- actor-level `(imports ...)` and `(use ...)` for the first reusable library
  import-resolution slice
- actor-level `(drive ...)` definitions
- `(transaction name ...)`
- `(rule name condition action...)`
- `(rule name (when condition) action...)`
- `(resources ...)`
- `(priority ...)`

Actor-shell singleton clauses are not mergeable. At most one `(clock ...)`,
`(reset ...)`, `(watchdog ...)`, `(interface ...)`, `(params ...)`,
`(constants ...)`, `(imports ...)`, `(resources ...)`, and `(storage ...)`
clause may appear in an actor.
Duplicate singleton clauses are rejected before the parser returns an actor
shell instead of letting later clauses overwrite earlier public fields.

Actor constants:

```lisp
(constants
  (WAIT_ZERO 0)
  (WAIT_TWO 2)
  (WAIT_ONE 4'd1)
  (BUSY_WAIT mode.BUSY)
  (REMOTE_WAIT shared.mode.BUSY))
```

`(constants ...)` is the first shipped ISF constant/symbol surface. It is
actor-scoped, compile-time only, and currently accepts unique HDL-identifier
names with non-negative integer literal values or enum member references.
Decimal literals and exact-width integer literals are accepted through the
same shared integer literal support used elsewhere in FSMGen. Enum member
references use the existing `.fsm` spelling: local `mode.BUSY` or
package-qualified `shared.mode.BUSY` after `(imports (package shared))`.
The referenced member must resolve before lowering to a non-negative integer
literal. Constants are emitted into scheduled `.fsm` as `+constants`, appear
in schedule reports as `actor_constants[]` with the authored value token, and
are legal symbolic sources for actor parameter defaults, static `(wait NAME)`
counts, positive transaction latency min/max bounds, positive bounded
eventual temporal-contract windows, positive actor-level and await-local
watchdog limits, and the existing static activation-parameter override path.
Qualified imported package scalar constants are legal static transaction
latency min/max, temporal-contract window, and actor-level/await-local
watchdog-limit sources when they resolve to positive integer literals. Actor
parameter defaults may use declared actor constants by name or earlier
actor-local scalar parameter defaults by name as scalar defaults or as scalar
leaves inside compatible aggregate/list defaults; scheduled `.fsm` `+params`
and `actor_params[]` preserve the
authored token while the parser records the resolved literal internally for
scalar parameter consumers such as widths, depths, watchdogs, waits,
contracts, and repeat counts. Source order is the only actor-parameter
dependency model: forward references, self references, cycles, and non-scalar
actor parameters remain fail-closed. Actor-local scalar parameter defaults
that resolve to non-negative integer literals are legal static wait sources
and static transaction repeat count sources in the actor's own schedule; zero
repeat counts lower as transparent no-op regions when the body does not
contain child activation, while positive repeat counts still provide
counter-width evidence. Actor-local scalar parameter defaults that resolve to
positive integer literals are legal static transaction latency min/max
sources, bounded eventual temporal-contract window sources, and actor-level
and await-local watchdog limit sources. Qualified imported package scalar
constants are also accepted as static transaction repeat-count sources when
they resolve to non-negative integer literals. Same-transaction scalar parameter
defaults on generated child and direct/non-generated transactions are legal
static sources in the shipped transaction-local slots: port widths,
data-operation width evidence, repeat counts, wait counts, latency bounds,
bounded eventual contract windows, and top-level await-local watchdog limits.
Positive slots require a resolved positive integer; wait and repeat counts
allow a resolved non-negative integer. Transaction parameters outside those
same-transaction slots, runtime interface signals, arbitrary expressions, and
use-site activation overrides are not actor-parameter-default,
actor-level-watchdog-limit, or general static constants. Use-site overrides
that target generated child contract-window parameters are accepted only when
the override resolves to the same positive integer cycle count as the child
transaction parameter default; mismatched overrides fail closed instead of
respecializing the already-emitted temporal monitor. Use-site overrides that
target generated child static timing parameters used by repeat counts, wait
counts, latency bounds, or top-level await-local watchdog limits follow the
same default-resolved rule: same-value overrides are accepted, while
mismatched overrides fail closed until per-activation static timing
specialization is selected. Each sub-axis emits its own targeted diagnostic
(repeat-count, wait-count, latency-bound, watchdog-limit) so authors can
identify which deferred lane is blocking the override.
Actor constants and actor-local scalar parameter defaults are also accepted as
static default values for generated child transaction parameters; the lowerer
resolves those parent actor names to literal child `+params` and
generated-composition report values so generated child artifacts remain
self-contained.

ISF scalar type-alias references are shipped for width-bearing declarations.
Actor bodies may declare local `(types ...)` clauses whose payloads map
directly to `.fsm` `+types`, and may import existing `.fsm` package roots with
`(imports (package NAME) ...)`. A package import uses one
HDL-identifier-compatible package name, no alias, and no dotted package
namespace so lowered scheduled `.fsm` can preserve a matching `(+import NAME)`
review artifact. Imported package roots are embedded into the emitted
scheduled `.fsm` artifact so CLI HDL generation remains self-contained even
when `bin/fsmgen` uses a temporary lowered `.fsm` path.

Width-bearing actor interface ports, transaction-local ports, and actor-owned
storage entries may use `(type NAME)` for a scalar alias. They keep
`(width N)` or `(width PARAM)` for raw positive integer widths, and may use
`(width CONST)` when `CONST` is a declared actor constant that resolves to a
positive integer on actor interface ports, transaction-local ports,
actor-owned scalar storage variables, and actor-owned bank storage. Type and
width options are mutually exclusive. `PARAM` may name an actor-local scalar
parameter default that resolves to a positive integer on actor interface ports,
transaction-local ports, actor-owned scalar storage, and actor-owned bank
storage. Qualified imported package scalar constants may be used as
`(width PACKAGE.CONSTANT)` sources on actor interface ports,
transaction-local ports, actor-owned scalar storage, and actor-owned bank
storage when the constant resolves to a positive integer; actor-owned bank
storage also accepts `(depth PACKAGE.CONSTANT)` under the same scalar
positive-integer rule. Generated child and direct/non-generated
transaction-local ports may use `(width TX_PARAM)` when `TX_PARAM` names a
same-transaction scalar parameter default that resolves to a positive
integer. Explicit data-operation width evidence may use the
same qualified package scalar constants in `shift_left`/`shift_right`
`(width PACKAGE.CONSTANT)` options and `assemble`/`extract`
`(widths PACKAGE.CONSTANT ...)` entries, and may use same-transaction scalar
parameter defaults on generated child or direct/non-generated transactions as
`TX_PARAM` evidence when those defaults resolve to positive integers. Static
transaction wait counts may also use same-transaction scalar parameter
defaults or `(wait PACKAGE.CONSTANT)` when the parameter or imported package
constant resolves to a non-negative integer scalar. `NAME` may be
local, such as `byte`, or package-qualified, such as `shared.byte`.
Unknown aliases fail closed. Resolved `list` or `record` aliases are accepted
only on actor-owned storage variables, for example `(var frame (type
frame_t))` or `(var frame (type shared.frame_t))`; the alias must resolve to a
positive packed width through the existing `.fsm` `+types` machinery.
Aggregate aliases on actor interface ports, transaction-local ports, storage
banks, and other width-bearing declarations fail closed. Actor-local
`(enums ...)` declarations are accepted and preserved into scheduled `.fsm` as
`+enums`. Actor parameter defaults consume declared actor constants and earlier
scalar actor parameters by name for scalar defaults and scalar leaves inside
actor aggregate/list parameter defaults, preserving authored defaults while
recording resolved literals.
Enum members are consumed by actor constants, by actor scalar parameter
defaults or scalar leaves inside actor aggregate/list parameter defaults, by
generated child transaction scalar parameter defaults or scalar
leaves inside generated child transaction aggregate/list parameter defaults,
by scalar activation parameter overrides or scalar leaves inside activation
aggregate/list parameter overrides, by reusable-library use-site parameter
override scalar values or scalar leaves inside aggregate/list use-site
overrides, by direct transaction `set` RHS scalar values or scalar operands
inside transaction `set` RHS expressions, by scalar operands inside transaction
`when`/`while`/`until` condition expressions, by transaction `switch`
selectors or branch values, by standalone scalar transaction
`when`/`while`/`until` conditions, by scalar rule assignment RHS values or
scalar operands inside rule assignment RHS expressions, by scalar operands
inside rule guard expressions, by standalone scalar rule guards, by scalar drive body RHS values or scalar operands inside drive body RHS
expressions, by inline drive assignment RHS scalar values or scalar operands
inside inline drive RHS expressions, and by named drive-call scalar actual
values or scalar operands inside drive-call actual expressions in the current
ISF surface. Enum members in expression operator position,
transaction condition expression operator position, rule targets, rule
guard or rule assignment expression operator position, rule actions outside
trigger parameter overrides, drive targets, inline drive assignment RHS
expression operator position, drive body RHS expression operator position,
drive-call expression operator position, and typed aggregate carriers do not
consume enum member references yet.

The shipped aggregate carrier surface is anchored on actor-owned storage
variables: the generated `.fsm` preserves the authored aggregate alias in
`+size`, and the schedule report exposes the carrier as declared actor storage
with packed `width`, authored `type`, and resolved `type_kind` (`list` or
`record`). Scalar member/item reads such as `frame.flag` or `lanes[0]` are
accepted as the direct RHS token of transaction
`(set target aggregate_leaf)` clauses and as scalar operands inside
transaction `set` RHS expressions, for example
`(set mode_out (+ frame.mode mode_in))`. Scalar member/item writes such as
`(set frame.flag flag_in)` or `(set lanes[0] bit_in)` are accepted as direct
transaction `set` targets. Rule assignments may also read scalar aggregate
member/item leaves as direct scalar RHS values or scalar operands inside RHS
expressions, for example
`(rule expose ready (set mode_out frame.mode))` or the shorthand
`(rule expose ready (mode_out (^ lanes[1] pair_in)))`. Rule guard expressions
may read scalar aggregate member/item leaves as scalar operands, for example
`(rule expose (& ready frame.flag) (set fire 1))`. Standalone rule guards may
also read scalar aggregate member/item leaves directly, for example
`(rule expose frame.flag (set fire 1))`. Transaction
`when`/`while`/`until` conditions may read scalar aggregate member/item leaves
directly or as scalar operands inside condition expressions, for example
`(when frame.flag (set fire 1))` or
`(when (& ready frame.flag) (set fire 1))`. Direct aggregate condition leaves
lower through computed `.fsm` selector syntax such as `?(frame.flag)`.
Transaction `switch` selectors and branch scalar values may read scalar
aggregate member/item leaves, for example
`(switch frame.mode (1 (set seen 1)) (default (set seen 0)))` or
`(switch mode_in (frame.mode (set seen 1)) (default (set seen 0)))`.
Named drive body scalar RHS values and scalar operands inside RHS expressions
may read scalar aggregate
member/item leaves, for example `(drive publish (mode_out frame.mode))` or
`(drive publish (mode_out (+ frame.mode mode_in)))`. Named drive body targets
may write scalar aggregate member/item leaves on declared actor-owned aggregate
storage, for example `(drive capture (frame.mode mode_in))` or
`(drive capture (lanes[1] pair_in))`. Inline transaction drive assignment
scalar RHS values and scalar operands inside RHS expressions may also read
scalar aggregate member/item leaves, for example
`(drive inline_publish (mode_out frame.mode))` or
`(drive inline_publish (mode_out (+ frame.mode mode_in)))`. Inline transaction
drive assignment targets may write scalar aggregate member/item leaves, for
example `(drive inline_capture (frame.mode mode_in))` or
`(drive inline_capture (lanes[1] pair_in))`. These forms resolve against the
declared aggregate storage shape before lowering. Named drive-call scalar
actual values and scalar operands inside actual expressions may also read
scalar aggregate member/item leaves, for example `(drive publish frame.mode)`
or `(drive publish (+ frame.mode mode_in))`.
Aggregate paths outside
transaction `set` RHS values, direct transaction `set` targets, transaction
condition scalar values or expression operands, transaction `switch` selectors
or branch values, rule assignment targets, rule assignment RHS values or
expression operands, rule guard scalar values or expression operands, drive target tokens, drive
body RHS scalar values or expression operands, inline drive target tokens,
inline drive assignment RHS scalar values or operands, or drive-call actual
scalar values/expression operands,
aggregate paths in
expression operator position, subaggregate writes/operands, aggregate interface or
transaction ports, and aggregate storage banks remain deferred.
Existing ISF
aggregate support beyond this carrier plus direct scalar leaf read/write
context remains limited to compatible aggregate/list literal parameter values
and scalarized storage/bank lowering. Remaining enum work is limited to future
semantic contracts for target/lvalue positions, expression operator position,
non-static rule-action contexts outside the shipped trigger override surface,
and incompatible enum values. Remaining aggregate work is limited to future
semantic contracts for additional aggregate carriers, aggregate paths in
expression operator position, subaggregate operands or updates,
field/slice/update lowering beyond scalar leaves, broader shape inference, and
ambiguous partial-update behavior. Those items are not part of the closed
`ISF-TYPE-AGGREGATE-PARITY` shipped surface.

Runtime expression positions use the scheduled `.fsm` operator-first
expression surface. Division and modulo expressions now fail closed when any
divisor operand is a numeric/exact-width literal zero, an actor-level constant
that resolves to zero, an actor-local scalar parameter default that resolves
to zero, or a same-transaction scalar parameter default that resolves to zero
in the owning transaction, including nested expressions such as
`(+ mask (% numerator 8'd0))`, `(/ numerator ZERO_DIVISOR)`,
`(/ numerator ZERO_PARAM)`, or `(/ numerator ZERO_TX_PARAM)`. The guard
applies before scheduled `.fsm` emission across the shipped
expression-bearing surfaces:
transaction `set`/`update` RHS values, transaction wait-count expressions,
transaction conditions, activation input bindings, drive-call actual
expressions, inline and named drive RHS expressions, rule guards, rule
assignments, and actor-owned bank access index/value expressions. Nonzero
literal divisors, nonzero actor-constant divisors, nonzero actor-parameter
divisors, nonzero same-transaction parameter divisors, and dynamic scalar
divisors still lower unchanged. Same-transaction parameter names shadow
actor-level static names in the owning transaction expression context;
proving that every dynamic divisor or use-site-specialized parameter divisor
is nonzero remains deferred.

Additional actor clauses with mixed parser/scheduler behavior:
- actor-level `(phase name property...)`, structurally validated as a
  non-empty scalar name plus list-form body entries; duplicate actor phase
  names are rejected.
- actor-level `(stage name property...)`, structurally validated as a
  non-empty scalar name plus list-form body entries; duplicate actor stage
  names are rejected. Actor phase/stage metadata is parser-carried and
  schedule-report visible through `actor_phases[]` and `actor_stages[]`, but
  it still does not add generated `.fsm`, generated composition-top, or HDL
  behavior.
- actor-level `(observe NAME (role passive_monitor) (signals SIG...))`,
  structurally validated as a non-empty scalar observation name, required
  `passive_monitor` role, and non-empty source-ordered list of unique actor
  interface signals. The parser resolves each signal to input/output direction
  and scalar width, and schedule JSON exposes the metadata through
  `verification_observations[]`. The declaration is report-only: it does not
  add generated `.fsm`, generated composition-top, HDL, UVM, VHDL, scoreboard,
  coverage, or VIP behavior. Actor storage, transaction-local ports, dotted
  endpoints, child endpoints, expressions, unsupported roles, duplicate
  observation names, and multi-domain observation partitioning fail closed or
  remain deferred.
- `(resources ...)`, structurally validated as resource entries with
  `(arbiter priority|round_robin)` plus optional `(kind ...)` and
  `(users ...)`/`(members ...)`; `rule_slot`, `output_bundle`,
  `transaction_start`, and `storage_port` + `priority` rule-user resources
  are scheduler-enforced, and `rule_slot`, `output_bundle`,
  `transaction_start`, or `storage_port` + bounded `round_robin` rule-user
  resources are scheduler-enforced.
- actor-level `(priority lhs over rhs)`

Deprecated compatibility:
- `(handshake name (valid signal) (ready signal))`-style metadata is
  deprecated compatibility input. The parser validates a scalar name and
  exactly one scalar `valid` property plus one scalar `ready` property, rejects
  duplicate handshake names, then ignores the metadata. The current activation
  model is direct `(on port ...)` plus the scheduler-created `can_accept`
  signal. Legacy handshake metadata will not gain lowering semantics;
  malformed legacy forms point authors toward `(on ...)`, generated
  `can_accept`, or transaction `(stage ...)` for ready/valid barriers.

## 3.1 Reusable Library Imports

Reusable ISF libraries are source-intent roots for tested reusable design
descriptions. They are not textual includes. Imported definitions still lower
through scheduled `.fsm` review artifacts before any HDL backend sees them.
The shipped reusable-definition catalog lives in
[docs/ISF_LIBRARY_CATALOG.md](../ISF_LIBRARY_CATALOG.md). The machine-readable
ISF public contract advertises that path, the catalog entry key family, and
the current shipped definitions through `library_catalog_paths`,
`library_catalog_entry_keys`, and `shipped_library_definitions`.

The first shipped library root shape is:

```lisp
(library common.pulse
  (exports
    (actor pulse_actor))

  (actor pulse_actor
    ... reusable actor body ...))
```

The first shipped export kind is `actor`. Standalone `transaction` and `drive`
exports are still deferred because they need an owning actor, storage, reset,
interface, and conflict context before their runtime semantics are public.
Unsupported export kinds fail closed.

Actor roots import and use exported actors with actor-scoped clauses:

```lisp
(actor top
  (imports
    (library common.pulse as pulse_lib))

  (use pulse_lib.pulse_actor as rx
    (params
      (WIDTH 4))
    (bind
      (clock clk)
      (input trigger trigger)
      (output fired fired))))
```

Import aliases are explicit local namespaces. Without `as alias`, the dotted
library name is the namespace prefix, so `common.pulse.pulse_actor` remains
namespaced rather than unqualified. Duplicate aliases and duplicate use-site
instance names fail closed.

Reusable actor parameters are declared with one actor-level `(params ...)`
clause. Parameter names must be unique HDL identifiers and every parameter has
a default value:

```lisp
(actor pulse_actor
  (params
    (WIDTH 1))
  ...)
```

Use-site overrides are instance-local. Missing overrides use the exported
actor default. Unknown overrides, duplicate overrides, unsupported symbolic
values, and override shapes that do not match aggregate/list defaults fail
closed. Actor parameter defaults accept scalar decimal literals, exact-width
numeric literals in the shipped ISF parameter syntax, declared actor
constants, earlier scalar actor parameter defaults, scalar local or
package-qualified enum members, qualified imported package scalar constants,
and compatible aggregate/list literals whose leaves are numeric, exact-width,
declared actor constants, earlier scalar actor parameter defaults,
local/package enum member literals, or qualified imported package scalar
constants. Qualified package constants use `PACKAGE.CONSTANT`, must name a
scalar package `+constants` entry, and preserve the authored token in
scheduled `.fsm` `+params` and `actor_params[]` while recording resolved
literals internally. Unqualified package constants, package aggregate
constants, and package aggregate scalar-leaf paths remain fail-closed. Earlier
actor parameters are source-order dependencies only; forward, self, cyclic,
and non-scalar actor-parameter references fail closed. Generated child
transaction parameter defaults accept scalar decimal literals, exact-width
numeric literals, declared actor constants, actor-local scalar parameter
defaults, earlier scalar transaction parameter defaults, scalar local or
package-qualified enum members, qualified imported package scalar constants,
and compatible aggregate/list literals whose leaves are numeric, exact-width,
declared actor constants, actor-local scalar parameter defaults, earlier
scalar transaction parameter defaults, local/package enum member literals, or
qualified imported package scalar constants. Transaction-parameter
dependencies are source-order dependencies only; forward, self, cyclic, and
non-scalar transaction-parameter references fail closed.
Actor constants and actor scalar parameter defaults used by generated child
transaction defaults are literalized before child `.fsm` `+params`,
generated-composition child summaries, and default instance bindings are
published. Enum member defaults keep authored enum tokens because generated
child artifacts carry the matching enum declarations. Earlier scalar
transaction-parameter dependency tokens also keep authored tokens because the
names are declared in the same generated child artifact. Qualified package
constant defaults keep authored `PACKAGE.CONSTANT` tokens in generated child
`.fsm` `+params`, generated-composition child summaries, and default instance
bindings because generated child artifacts carry package imports and embedded
package roots; resolved scalar literals are recorded internally. Unknown
package constants, unqualified package constants, package aggregate constants,
and package aggregate member/item paths remain fail-closed. Scalar activation
parameter overrides and scalar leaves inside activation aggregate/list
parameter override values may use actor-local constants, actor-local scalar
parameter defaults, local or package-qualified enum members, and qualified
imported package scalar constants. Activation override package constants are
resolved to literal generated-top bindings and generated-composition report
values. Unknown package constants, unqualified package constants, package
aggregate constants, and package aggregate member/item paths remain
fail-closed in activation overrides.
Reusable-library use-site parameter overrides may use importing-actor
constants, importing-actor scalar parameter defaults, and local or
package-qualified enum members, and qualified imported package scalar constants
as scalar override values or as scalar leaves inside compatible aggregate/list
override values. Reusable-library use-site package constants resolve to literal
generated-top/generated-composition bindings and `library_uses[]` report
values. Unknown package constants, unqualified package constants, package
aggregate constants, and package aggregate member/item paths remain fail-closed
in reusable-library use-site overrides. Actor constants and earlier
scalar actor parameters used as actor parameter defaults resolve internally
before scalar actor-parameter consumers run while preserving the authored
token in scheduled `.fsm` and `actor_params[]`. Actor constants, actor scalar
parameters, enum members, and qualified package constants used by activation
sites resolve to literal values before generated-top emission. Actor constants,
actor scalar parameters, enum members, and qualified package constants used by
reusable-library use sites resolve to literal values before generated-top
emission and `library_uses[]` schedule-report publication where that report
surface exists. Qualified package scalar constants used by actor top-level
interface widths resolve to positive integer parser-handoff widths, scheduled
`.fsm` `+size` entries, schedule-report evidence, and HDL port ranges.
Qualified package scalar constants used by explicit data-operation width
evidence resolve to positive integer scheduler width facts that drive
scheduled `.fsm` shift positions, assemble/extract slice evidence, and
`inferred_storage[]` report widths.
Same-transaction scalar parameter defaults and qualified package scalar
constants used by static transaction wait counts resolve to non-negative
integer timing facts: zero counts remain transparent no-ops, and positive
counts emit fixed scheduled wait-state chains plus `transaction_waits[]`
entries. Transaction parameters shadow actor-level static names and remain
local lowering inputs; package entries preserve the authored qualified token
in `count_source`.
Qualified package scalar constants used by static transaction repeat counts
resolve to non-negative integer timing facts. Positive counts provide
counter-width evidence and preserve the authored qualified token in the
scheduled `.fsm` repeat-counter load. Zero counts lower as transparent no-op
regions with no counter, repeat init/check state, repeat-body state, or
`transaction_loops[]` entry. Plain `(do child)` and plain
`(spawn child as inst)` clauses in a statically zero repeat body are pruned
with the skipped body: they emit no local start/done handoff, generated child
scheduled `.fsm`, generated top, activation instance, or loop report entry.
If the target transaction is otherwise live or has an explicit actor-input
entry guard, that transaction remains available; only the statically skipped
activation is pruned. Syntactically valid parameterized, bound, or
domain-annotated static-zero child activations are pruned the same way; their
dead payload subclauses are shape-validated but are not validated against
child parameter, port, or domain declarations.
Schedule reports expose actor parameter defaults through `actor_params[]` entries with
each authored parameter `name` and JSON-safe default `value`, preserving
authored actor constant tokens such as `DEFAULT_WIDTH`, earlier actor
parameter tokens such as `BASE_W`, and enum tokens such as `mode.BUSY` or
`shared.mode.BUSY`. These entries describe static
specialization defaults;
they are not runtime ports and do not replace generated-composition parameter
binding reports for activation or library use sites.

Bindings are explicit. A reusable actor with a clock or reset must bind that
signal at the use site. Reset kind and polarity remain owned by the reusable
actor in this slice; the use site binds the parent reset signal but does not
change sync/async or polarity semantics. Every exported actor interface port
must be bound exactly once with matching direction and matching known width.
No implicit truncation, extension, or slicing is performed by the library
binder.

Resolution rules:

- Same-source `(library ...)` roots can be resolved by both `parse_file(...)`
  and `parse_source(...)`.
- `parse_file(...)` also resolves external library files from the importing
  source directory, each `FSMLIB` entry, and the current directory.
- For a dotted namespace such as `common.pulse`, both `common.pulse.isf` and
  `common/pulse.isf` are candidate file names under each root.
- `parse_source(...)` has no general external-file search root unless its
  source label is a real file path; use `parse_file(...)` for file-backed
  library resolution.

Lowering emits one specialized child scheduled `.fsm` artifact for each
resolved library actor use. The deterministic module and file basename are
`<importing_actor>__<instance>` and `<importing_actor>__<instance>.fsm`.
When a library actor use is present, lowering also emits a generated top
`<importing_actor>_top.fsm` that instantiates the importing actor and each
library child actor. Bound library inputs are linked from top inputs directly
to the library instance, and bound library outputs drive the corresponding top
outputs. Same-name clock/reset system bindings can be omitted at the use site
when the parent and child clock names match and the reset name/kind/polarity
matches; FSMGen records the inferred bindings in `library_uses[].bindings[]`
and uses the existing generated-composition system-port auto-wiring path.
When the library actor's authored clock or reset name differs from the
importing actor's parent signal, the generated top emits explicit Lisp-ish
composition links such as `(clk rx.lib_clk)` or `(rst_n rx.lib_rst_n)`. The
reusable actor still owns reset kind and polarity; the binding remaps only the
signal identity seen at the parent boundary. This is not multi-clock-domain
support. The current ISF scheduler still models one
clock domain for an actor/generated top; multi-clock, asynchronous, and
interacting clock-domain semantics remain unspecified and out of scope here.
Successful schedule reports expose a bounded top-level `library_uses` array
with `library`, `alias`, `export`, `kind`, `instance`, `module`,
`scheduled_fsm`, `parameters`, and `bindings`. Parameter summaries expose
`name`, `source`, and stringified `value`. Binding summaries expose `role`,
`library_name`, `parent_name`, and `width`; clock/reset bindings use JSON null
for `library_name`, and reset/clock width is `1`.

Current boundary: `ISF-LIBRARIES.5` resolves reusable actors, validates
parameters and bindings, emits child scheduled `.fsm` artifacts, wires library
actor instances into generated tops for same-name system ports, reaches
SystemVerilog generation for the covered generated-top path, reports bounded
provenance, records the real FIFO requirements, adds the first actor-owned
storage declaration surface, lets rule
guards be scalar or list expressions for direct FIFO fire predicates, and
accepts same-target rule writes when direct contradictory guard facts prove
that the writes cannot fire in the same cycle. A depth-4 FIFO-controller
matrix now lowers through scheduled `.fsm`, schedule JSON, and SystemVerilog
with actor-maintained pointer/occupancy/full/empty state. The first FIFO
datapath surface now implements `(store <bank-name> <index> <value>)` and
`(load <bank-name> <index> as <target>)` for actor-owned fixed-depth banks in rules and
supported transaction contexts. The first reusable FIFO library fixture is
now shipped as [isf/common/fifo.isf](../../isf/common/fifo.isf), exported as
`common.fifo.fifo`, with [isf/fifo_library_use.isf](../../isf/fifo_library_use.isf)
as the file-backed import/use fixture. That fixture reaches generated-top
SystemVerilog through the CLI and checks the specialized FIFO child parameter
bindings, scalarized data entries, pointer-gated accepted push/pop selectors,
and generated top wiring. The promoted fixture regression
[t/1321-isf-fifo-library-fixture-coverage.t](../../t/1321-isf-fifo-library-fixture-coverage.t)
also proves strict schedule JSON parity against the in-process report, strict
`--outdir` emission of the importer, specialized child, and generated top
`.fsm` artifacts, and both plain and strict generated-top HDL paths.
The public catalog/contract synchronization slice is shipped as
`ISF-LIBRARIES.5`: [docs/ISF_LIBRARY_CATALOG.md](../ISF_LIBRARY_CATALOG.md)
lists the shipped reusable definition with status, parameters, interface,
storage, semantics, tests, and limitations, and the machine-readable public
contract mirrors the bounded discovery metadata.

The first realistic ATL trigger-batch fixture is shipped as
[isf/atl_trigger_batch_pipeline.isf](../../isf/atl_trigger_batch_pipeline.isf).
It uses only the current static actor-network surface: three direct static
actor instances and one contiguous transaction-body trigger batch that targets
distinct actors. The fixture emits only `atl_trigger_batch_pipeline.fsm`,
reports `actor_network.instances[]`, `transaction_triggers[]`, and canonical
`association_schedules[]` with `kind: "temporary_trigger_batch"` and
`lifetime: "task_scoped"`. It also keeps `group_schedules[]` as a
schema-version-1 compatibility view with synthetic task-scoped
`run_trigger_batch` evidence. The fixture is backed by
[t/1324-isf-atl-fixture-coverage.t](../../t/1324-isf-atl-fixture-coverage.t)
for strict schedule JSON parity, scheduled `.fsm` structure, and plain plus
strict HDL generation. It deliberately does not declare a permanent
`(group ...)` association and does not claim peer events, endpoint data
movement, generated ATL child artifacts, generated ATL tops, group endpoints,
compact movement aliases, CDC, payloads, ready/backpressure, route mux/storage, or
trigger/data/event coupling.

The scalar ATL data-route fixture is shipped as
[isf/atl_data_route_pipeline.isf](../../isf/atl_data_route_pipeline.isf). It uses
two direct static actor instances, one named drive body, and one transaction
drive call:

```lisp
(drive feed_consumer
  (consumer.payload producer.payload))
```

The fixture emits only `atl_data_route_pipeline.fsm`, exposes the generated
parent handoff ports `producer_payload` and `consumer_payload`, and reports one
`actor_network.data_movements[]` entry with `route_lifetime:
"drive_call_cycle"` and `storage: "none"`. It keeps
`actor_network.association_schedules[]` and `group_schedules[]` empty because
this is a drive-activated data route, not a trigger-batch association. The
fixture is backed by
[t/1325-isf-atl-data-route-fixture-coverage.t](../../t/1325-isf-atl-data-route-fixture-coverage.t)
for strict schedule JSON parity, scheduled `.fsm` structure, and plain plus
strict HDL generation. It deliberately does not claim generated ATL child
artifacts, generated ATL tops, route mux/storage, peer events,
trigger/data coupling, wider payloads, fan-in/fan-out, CDC, ready/backpressure,
compact movement aliases, or permanent actor grouping.

The scalar ATL pin-ingress fixture is shipped as
[isf/atl_pin_ingress_pipeline.isf](../../isf/atl_pin_ingress_pipeline.isf). It
uses one direct static actor instance, one existing top-level input pin, one
named drive body, and one transaction drive call:

```lisp
(drive feed_consumer
  (consumer.payload pins.payload))
```

The fixture emits only `atl_pin_ingress_pipeline.fsm`, preserves `payload` as
the top-level input source, exposes the generated actor handoff output
`consumer_payload`, and reports one `actor_network.data_movements[]` entry
with `kind: "scalar_pin_to_actor_handoff"`, `source: "top_level_pin"`,
`sink: "external_handoff"`, `route_lifetime: "drive_call_cycle"`, and
`storage: "none"`. It keeps `actor_network.association_schedules[]` and
`group_schedules[]` empty because this is a drive-activated data route, not a
trigger-batch association. The fixture is backed by
[t/1326-isf-atl-pin-ingress-fixture-coverage.t](../../t/1326-isf-atl-pin-ingress-fixture-coverage.t)
for strict schedule JSON parity, scheduled `.fsm` structure, and plain plus
strict HDL generation. It deliberately does not claim generated ATL child
artifacts, generated ATL tops, actor-to-pin egress, bidirectional pin
movement, route mux/storage, peer events, trigger/data coupling, wider
payloads, fan-in/fan-out, CDC, ready/backpressure, compact movement aliases, or
permanent actor grouping.

The scalar ATL pin-egress fixture is shipped as
[isf/atl_pin_egress_pipeline.isf](../../isf/atl_pin_egress_pipeline.isf). It uses
one direct static actor instance, one existing top-level output pin, one named
drive body, and one transaction drive call:

```lisp
(drive publish_result
  (pins.result producer.payload))
```

The fixture emits only `atl_pin_egress_pipeline.fsm`, exposes the generated
actor source handoff input `producer_payload`, preserves `result` as the
top-level output sink, and reports one `actor_network.data_movements[]` entry
with `kind: "scalar_actor_to_pin_handoff"`, `source: "external_handoff"`,
`sink: "top_level_pin"`, `route_lifetime: "drive_call_cycle"`, and `storage:
"none"`. It keeps `actor_network.association_schedules[]` and
`group_schedules[]` empty because this is a drive-activated data route, not a
trigger-batch association. The fixture is backed by
[t/1327-isf-atl-pin-egress-fixture-coverage.t](../../t/1327-isf-atl-pin-egress-fixture-coverage.t)
for strict schedule JSON parity, scheduled `.fsm` structure, and plain plus
strict HDL generation. It deliberately does not claim generated ATL child
artifacts, generated ATL tops, bidirectional pin movement, route mux/storage,
peer events, trigger/data coupling, wider payloads, fan-in/fan-out, CDC,
ready/backpressure, compact movement aliases, or permanent actor grouping.

The ATL trigger-wait fixture is shipped as
[isf/atl_trigger_wait_pipeline.isf](../../isf/atl_trigger_wait_pipeline.isf). It
uses one direct static actor instance and one transaction that triggers the
actor, waits for its event, and completes:

```lisp
(transaction run
  (on start)
  (trigger worker.process)
  (await worker.done)
  (complete done))
```

The fixture emits only `atl_trigger_wait_pipeline.fsm`, exposes the generated
one-cycle parent trigger output `worker_process_start`, exposes the generated
parent event input `worker_done`, and reports one
`actor_network.transaction_triggers[]` entry plus one
`actor_network.event_waits[]` entry. It keeps
`actor_network.association_schedules[]`, `group_schedules[]`, `groups[]`, and
`data_movements[]` empty because this is a single-actor parent-handoff round
trip, not a temporary trigger batch or a data route. The fixture is backed by
[t/1328-isf-atl-trigger-wait-fixture-coverage.t](../../t/1328-isf-atl-trigger-wait-fixture-coverage.t)
for strict schedule JSON parity, scheduled `.fsm` structure, and plain plus
strict HDL generation. It deliberately does not claim temporary trigger-batch
plus event coupling, multiple waits or triggers, generated ATL child
artifacts, generated ATL tops, actor type resolution, HDL child wiring, event
payloads, data movement coupling, route mux/storage, fan-in/fan-out, CDC,
ready/backpressure, compact movement aliases, or permanent actor grouping.

The ATL trigger-batch wait fixture is shipped as
[isf/atl_trigger_batch_wait_pipeline.isf](../../isf/atl_trigger_batch_wait_pipeline.isf).
It uses three direct static actor instances, one contiguous same-cycle
temporary trigger batch, one following actor event wait, and one completion
pulse:

```lisp
(transaction run
  (on start)
  (trigger reader.capture)
  (trigger filter.process)
  (trigger writer.emit)
  (await writer.done)
  (complete done))
```

The fixture emits only `atl_trigger_batch_wait_pipeline.fsm`, exposes the
generated trigger outputs `reader_capture_start`, `filter_process_start`, and
`writer_emit_start`, exposes the generated event input `writer_done`, reports
per-target `actor_network.transaction_triggers[]`, one
`actor_network.association_schedules[]` entry with kind
`temporary_trigger_batch`, one schema-version-1
`actor_network.group_schedules[]` compatibility entry, and one
`actor_network.event_waits[]` entry. It keeps `actor_network.groups[]` and
`data_movements[]` empty because this is task-scoped parent-handoff
orchestration, not a permanent group or a data route. The fixture is backed by
[t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t](../../t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t)
for strict schedule JSON parity, scheduled `.fsm` structure including the
default await timeout state, and plain plus strict HDL generation. It
deliberately stays a single-wait fixture and does not claim hidden
actor-event fan-in, generated ATL child artifacts, generated ATL tops, actor
type resolution, HDL child wiring, event payloads, endpoint data movement
coupling, route mux/storage, CDC, ready/backpressure, compact movement aliases, or
permanent actor grouping.

The ATL trigger-batch multi-event wait fixture is shipped as
[isf/atl_trigger_batch_multi_wait_pipeline.isf](../../isf/atl_trigger_batch_multi_wait_pipeline.isf).
It uses the same parent-handoff surface, but preserves three authored
top-level transaction-body event waits as three sequential scheduled wait
states after the single temporary trigger-batch state:

```lisp
(transaction run
  (on start)
  (trigger reader.capture)
  (trigger filter.process)
  (trigger writer.emit)
  (await reader.done)
  (await filter.done)
  (await writer.done)
  (complete done))
```

The fixture emits only `atl_trigger_batch_multi_wait_pipeline.fsm`, exposes
the generated trigger outputs `reader_capture_start`,
`filter_process_start`, and `writer_emit_start`, exposes generated event
inputs `reader_done`, `filter_done`, and `writer_done`, reports three
source-ordered `actor_network.event_waits[]` entries, and keeps the same
task-scoped `association_schedules[]` plus compatibility `group_schedules[]`
metadata as the single-wait trigger-batch fixture. The scheduled parent FSM
uses one `run_atl_trigger_batch_1` state followed by `run_await_2`,
`run_await_3`, and `run_await_4`; each wait advances only when its matching
event handoff is observed, and the default await timeout state remains
present. This is explicit sequential waiting, not a hidden same-cycle event
join. The shipped subset requires all multi-event waits to be top-level,
contiguous, source ordered, after exactly one temporary trigger batch, and to
target distinct triggered actor instances with no ATL data movement in the
same transaction segment. Repeated waits, non-batch waits, interleaved parent
work, actor-event fan-in/fan-out joins, payload waits, generated child event
wiring, route coupling, CDC, ready/backpressure, and permanent actor grouping
remain fail-closed/deferred. Focused negative coverage in
[t/1322-isf-actor-network-static.t](../../t/1322-isf-actor-network-static.t)
keeps repeated actor waits outside the selected shape, and trigger-batch
repeated waits now name the missing event re-arm or per-event
generation/lifetime contract.

The ATL resolved-child fixture is shipped as
[isf/atl_resolved_child_pipeline.isf](../../isf/atl_resolved_child_pipeline.isf).
It uses one top-level actor, one same-source library actor export, one
library-qualified static actor instance, one parent trigger handoff, one
parent event wait, and one completion pulse:

```lisp
(actor atl_resolved_child_pipeline
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (transaction run
    (on start)
    (trigger worker.process)
    (await worker.done)
    (complete done)))
```

The fixture emits exactly `atl_resolved_child_pipeline.fsm`,
`atl_resolved_child_pipeline__worker.fsm`, and
`atl_resolved_child_pipeline_top.fsm`. The parent artifact still exposes
`worker_process_start` and `worker_done` as scheduled handoff ports, the
resolved child artifact keeps its authored `process_start` input and `done`
output, and the generated top makes those handoffs internal by wiring
`atl_resolved_child_pipeline.worker_process_start` to
`worker.process_start` and `worker.done` to
`atl_resolved_child_pipeline.worker_done`. The generated top exposes only the
top-level public pins plus clock/reset, instantiates the parent and resolved
child, wires `start` to the parent, and wires parent `done` to the top output.
Schedule JSON reports the resolved `worker` entry in
`actor_network.instances[]` with `type_resolution: library_actor_export`,
`library`, `alias`, `export`, `module`, and `scheduled_fsm`, plus one
`transaction_triggers[]` entry, one `event_waits[]` entry, and one
`actor_network.generated_tops[]` entry describing the top module/file,
parent/child modules, trigger parent/child ports, event parent/child ports,
clock, and reset. The fixture is backed by
[t/1330-isf-atl-resolved-child-fixture-coverage.t](../../t/1330-isf-atl-resolved-child-fixture-coverage.t)
for strict schedule JSON parity, strict `--outdir` top emission,
parent/child/top scheduled `.fsm` structure, and fail-closed diagnostics for
missing child transactions, non-scalar child activation, missing child event
outputs, and parent/child clock mismatches. It deliberately does not claim
multiple resolved children, trigger batches, ATL data movement coupled to
generated children, inferred payload or ready/backpressure bindings,
route mux/storage, actor-event fan-in, CDC, recursive actor networks, or
permanent actor grouping.

HDL promotion for this fixture is shipped: the source and report schema stay
unchanged, and focused coverage proves plain and strict CLI SystemVerilog
generation contains the generated ATL top, scheduled parent, resolved child,
and the selected internal trigger/event links. Broader generated ATL top
inference remains unshipped until a later task-tree leaf documents it here.

The resolved-child scalar pin-ingress fixture is shipped as
[isf/atl_resolved_child_pin_ingress_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_pipeline.isf).
It keeps the same one-child trigger/event top and adds one scalar
pin-ingress route: `(worker.payload pins.payload)` in a named drive body
activated by the same parent transaction. The generated top wires the real
top input pin to the parent, the parent generated handoff `worker_payload` to
the child scalar input `payload`, and the existing trigger/event links
unchanged. The child scheduled `.fsm` carries generated `+interface` role
metadata for the selected child input so HDL generation preserves `payload`
as a child module input. Schedule JSON keeps the route evidence in
`actor_network.data_movements[]` and the generated-top discovery evidence in
`actor_network.generated_tops[]`; no public report family is added.
[t/1330-isf-atl-resolved-child-fixture-coverage.t](../../t/1330-isf-atl-resolved-child-fixture-coverage.t)
covers strict schedule JSON parity, parent/child/top `.fsm` artifacts, plain
and strict HDL generation, and fail-closed missing child input diagnostics for
this fixture.

The resolved-child exact-width vector pin-ingress fixture is shipped as
[isf/atl_resolved_child_pin_ingress_vector_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_vector_pipeline.isf).
It keeps the same one-child trigger/event top and routes one top-level vector
input into one resolved child input with the existing drive-body syntax:
`(worker.payload pins.payload)`. Both the parent top-level input pin and the
resolved child input endpoint declare width 8 in the fixture. The parser keeps
the public route shape in `actor_network.data_movements[]` with
`kind: "vector_pin_to_actor_handoff"`, `width: 8`, and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
Lowering emits the parent handoff `worker_payload` at the exact endpoint
width, preserves the generated child `payload` input as an 8-bit child module
port, and wires the generated top from public top `payload` to the parent and
from parent `worker_payload` to child `payload`. A top-level input width that
does not exactly match the resolved child input width fails closed before
scheduled `.fsm` emission; FSMGen does not insert width adaptation,
truncation, extension, packing, slicing, route storage, route muxing, or a
payload protocol. Vector pin-ingress multi-route sets are shipped only in the
bounded same-child route-set form described next.

The resolved-child exact-width vector pin-ingress multi-route fixture is
shipped as
[isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf).
It keeps the same one-child trigger/event top and routes two vector top-level
input pins into two resolved child inputs with the existing drive-body syntax:
`(worker.payload pins.payload)` and `(worker.sideband pins.sideband)`. The
fixture proves route-local widths: `payload` is 8 bits and `sideband` is
4 bits, with matching resolved child input widths. Schedule JSON reports each
route as its own `actor_network.data_movements[]` entry with
`kind: "vector_pin_to_actor_handoff"` and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
The subset requires one resolved child, one parent transaction, one vector
`(child.endpoint pins.input_pin)` pair per drive body, one top-level drive
call per route, unique source pins, unique child input endpoints, and a
contiguous drive-call segment before the child trigger and event wait.
Mismatched route-local widths fail closed before scheduled `.fsm` emission.
Broader mixed scalar/vector route sets outside the bounded same-child
pin-ingress subset described next, width adaptation, route storage, muxing,
fan-in/fan-out, ready/backpressure, and payload protocols remain deferred.

The resolved-child mixed scalar/vector pin-ingress route-set fixture is shipped
as
[isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf).
It keeps the same one-child generated-top shape and routes one exact-width
vector top-level input plus one scalar top-level input into matching inputs on
the same resolved child. The fixture uses `(worker.payload pins.payload)` at
width 8 and `(worker.valid pins.valid)` at width 1. Both drive calls must stay
adjacent before the child trigger in the same parent transaction. Schedule JSON
reports each route independently in `actor_network.data_movements[]`: the
payload route uses `kind: "vector_pin_to_actor_handoff"` and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`,
while the valid route uses `kind: "scalar_pin_to_actor_handoff"` and
`width_source: "top_level_pin_scalar_one_bit"`. Mismatched vector route widths
still fail closed before scheduled `.fsm` emission. The subset does not add
width adaptation, route storage, muxing, fan-in/fan-out, ready/backpressure, or
payload protocols.

The bounded multi-route extension of that one-child pin-ingress shape is shipped
as
[isf/atl_resolved_child_pin_ingress_multi_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_multi_pipeline.isf).
It allows multiple scalar top-level input pins to feed multiple scalar inputs on
the same resolved child through adjacent argument-free drive calls before the
child trigger. The shipped fixture routes `(worker.payload pins.payload)` and
`(worker.sideband pins.sideband)`. Lowering emits separate drive-call states,
separate drive request signals, separate generated parent sink handoffs, child
`+interface` roles for both routed inputs, and generated-top wiring for both
top-level input-pin paths. Schedule JSON reports each route as a separate
`actor_network.data_movements[]` entry with
`kind: "scalar_pin_to_actor_handoff"`; it does not expose the private
generated-top `data_links`. The subset requires one resolved child, one parent
transaction, one scalar `(child.endpoint pins.input_pin)` pair per drive body,
one top-level drive call per route, unique source pins, unique child input
endpoints, and a contiguous drive-call segment before the child trigger and
event wait.

The resolved-child scalar pin-egress fixture is shipped as
[isf/atl_resolved_child_pin_egress_pipeline.isf](../../isf/atl_resolved_child_pin_egress_pipeline.isf).
It keeps the same one-child trigger/event top and adds one scalar
pin-egress route: `(pins.result worker.payload)` in a named drive body
called after the parent transaction triggers `worker.process` and awaits
`worker.done`. The generated top wires the child scalar output `payload` to
the parent generated handoff input `worker_payload`, wires parent `result` to
the top-level output `result`, and keeps the existing trigger/event links
unchanged. The child scheduled `.fsm` carries generated `+interface` role
metadata for the selected child output so HDL generation preserves `payload`
as a child module output. Schedule JSON keeps the route evidence in
`actor_network.data_movements[]` and generated-top discovery evidence in
`actor_network.generated_tops[]`; no public report family is added.
[t/1330-isf-atl-resolved-child-fixture-coverage.t](../../t/1330-isf-atl-resolved-child-fixture-coverage.t)
covers strict schedule JSON parity, parent/child/top `.fsm` artifacts, plain
and strict HDL generation, fail-closed missing child output diagnostics, and
fail-closed pre-event drive-order diagnostics for this fixture.

The resolved-child exact-width vector pin-egress fixture is shipped as
[isf/atl_resolved_child_pin_egress_vector_pipeline.isf](../../isf/atl_resolved_child_pin_egress_vector_pipeline.isf).
It keeps the same one-child trigger/event top and routes one resolved child
vector output to one top-level vector output with the existing drive-body
syntax: `(pins.result worker.payload)`. Both the resolved child output
endpoint and the parent top-level output pin declare width 8 in the fixture.
The parser keeps the public route shape in `actor_network.data_movements[]`
with `kind: "vector_actor_to_pin_handoff"`, `width: 8`, and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
Lowering emits the parent handoff `worker_payload` at the exact endpoint
width, preserves the generated child `payload` output as an 8-bit child module
port, and wires the generated top from child `payload` through parent
`worker_payload` to public top `result`. A resolved child output width that
does not exactly match the top-level output width fails closed before
scheduled `.fsm` emission; FSMGen does not insert width adaptation,
truncation, extension, packing, slicing, route storage, route muxing, or a
payload protocol. Vector pin-egress multi-route sets are shipped only in the
bounded same-child route-set form described next.

The resolved-child exact-width vector pin-egress multi-route fixture is
shipped as
[isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf](../../isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf).
It keeps the same one-child trigger/event top and routes two resolved child
vector outputs into two top-level vector output pins with the existing
drive-body syntax: `(pins.result worker.payload)` and
`(pins.status worker.status)`. The fixture proves route-local widths: the
payload-to-result route is 8 bits and the status-to-status route is 4 bits.
Schedule JSON reports each route as its own `actor_network.data_movements[]`
entry with
`kind: "vector_actor_to_pin_handoff"` and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
The subset requires one resolved child, one parent transaction, one vector
`(pins.output_pin child.endpoint)` pair per drive body, one top-level drive
call per route, unique child output endpoints, unique top-level output pins,
the child trigger before the event wait, and a contiguous drive-call segment
after the event wait. Mismatched route-local widths fail closed before
scheduled `.fsm` emission. Broader mixed scalar/vector route sets outside the
bounded same-child pin-egress subset described next, width adaptation, route
storage, muxing, fan-in/fan-out, ready/backpressure, and payload protocols
remain deferred.

The resolved-child mixed scalar/vector pin-egress route-set fixture is shipped
as
[isf/atl_resolved_child_pin_egress_mixed_pipeline.isf](../../isf/atl_resolved_child_pin_egress_mixed_pipeline.isf).
It keeps the same one-child generated-top shape and routes one exact-width
vector resolved child output plus one scalar resolved child output into
matching top-level output pins. The fixture uses
`(pins.result worker.payload)` at width 8 and `(pins.valid worker.valid)` at
width 1. Both drive calls must stay adjacent after the child event wait in the
same parent transaction. Schedule JSON reports each route independently in
`actor_network.data_movements[]`: the result route uses
`kind: "vector_actor_to_pin_handoff"` and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`,
while the valid route uses `kind: "scalar_actor_to_pin_handoff"` and
`width_source: "top_level_output_pin_scalar_one_bit"`. Mismatched vector route
widths still fail closed before scheduled `.fsm` emission. The subset does not
add width adaptation, route storage, muxing, fan-in/fan-out, ready/backpressure,
or payload protocols.

The bounded multi-route extension of that one-child pin-egress shape is shipped
as
[isf/atl_resolved_child_pin_egress_multi_pipeline.isf](../../isf/atl_resolved_child_pin_egress_multi_pipeline.isf).
It allows multiple scalar outputs from the same resolved child to feed multiple
scalar top-level output pins through adjacent argument-free drive calls after
the child event wait. The shipped fixture routes
`(pins.result worker.payload)` and `(pins.status worker.status)`. Lowering emits
separate drive-call states, separate drive request signals, separate generated
parent source handoffs, child `+interface` roles for both routed outputs, and
generated-top wiring for both top-level output-pin paths. Schedule JSON reports
each route as a separate `actor_network.data_movements[]` entry with
`kind: "scalar_actor_to_pin_handoff"`; it does not expose the private
generated-top `data_links`. The subset requires one resolved child, one parent
transaction, one scalar `(pins.output_pin child.endpoint)` pair per drive body,
one top-level drive call per route, unique child output endpoints, unique
top-level output pins, the child trigger before the event wait, and a
contiguous drive-call segment after the event wait.

Broader actor-to-actor generated-child routes, multi-child data wiring beyond
the selected two-child scalar route set, route mux/storage, CDC/reset remapping,
ready/backpressure, payload protocols, fan-in/fan-out, and permanent actor
grouping remain deferred.

The first positive two-child generated-top subset is shipped by
[isf/atl_two_child_pipeline.isf](../../isf/atl_two_child_pipeline.isf). The
parent declares resolved `reader` and `writer` children, triggers
`reader.capture`, awaits `reader.done`, triggers `writer.emit`, awaits
`writer.done`, and completes. Lowering emits parent, reader, writer, and
generated top `.fsm` artifacts. The generated top instantiates all three
modules, exposes only public parent pins plus clock/reset, wires
`reader_capture_start` to `reader.capture_start`, `reader.done` to
`reader_done`, `writer_emit_start` to `writer.emit_start`, and `writer.done`
to `writer_done`. Schedule JSON keeps the existing actor-network families and
uses `actor_network.generated_tops[].children[]` for the per-child generated
top wiring records.

The selected resolved-child trigger-batch generated-top subset is shipped by
[isf/atl_two_child_trigger_batch_pipeline.isf](../../isf/atl_two_child_trigger_batch_pipeline.isf).
The parent declares the same resolved `reader` and `writer` children, emits
contiguous `(trigger reader.capture)` and `(trigger writer.emit)` clauses in
one same-cycle temporary trigger batch, awaits `reader.done`, awaits
`writer.done`, and completes. Lowering emits parent, reader, writer, and
generated top `.fsm` artifacts. The parent pulses `reader_capture_start` and
`writer_emit_start` in one `run_atl_trigger_batch_1` state, then preserves
the waits as source-ordered sequential wait states. The generated top wires
both child start handoffs and both child event handoffs exactly like the
sequential two-child top. Schedule JSON preserves the individual
`actor_network.transaction_triggers[]` and `actor_network.event_waits[]`
records, preserves the task-scoped temporary association evidence in
`actor_network.association_schedules[]`, preserves the schema-version-1
compatibility view in `actor_network.group_schedules[]`, and reports one
generated top with `kind:
"resolved_children_trigger_batch_event_sequence"`. Static group declarations,
data movement coupled to the trigger batch, repeated child activations or
waits, non-source-ordered waits, nested waits/triggers, CDC, payload
protocols, ready/backpressure, route mux/storage, recursive actor networks,
and permanent actor grouping remain deferred for this generated-top family.

The first positive generated-child actor-to-actor data route through that
two-child top is shipped by
[isf/atl_two_child_data_pipeline.isf](../../isf/atl_two_child_data_pipeline.isf).
The source shape reuses the existing drive-body `(sink source)` order:

```lisp
(drive forward_payload
  (writer.payload reader.payload))
```

inside a parent transaction ordered as trigger `reader.capture`, await
`reader.done`, drive `forward_payload`, trigger `writer.emit`, await
`writer.done`, then complete. Lowering emits parent, reader, writer, and
generated top `.fsm` artifacts. The parent exposes `reader_payload` as the
generated source handoff input and `writer_payload` as the generated sink
handoff output; the parent drive body assigns `writer_payload` from
`reader_payload` only for the `forward_payload` drive-call cycle. The
generated top wires `reader.payload` to parent `reader_payload`, parent
`writer_payload` to `writer.payload`, and keeps trigger/event handoffs
internal. Schedule JSON reports the route through existing
`actor_network.data_movements[]` `scalar_actor_handoff` fields and discovers
the top through existing `actor_network.generated_tops[]` `children[]`
metadata. Route mux/storage, fan-in/fan-out, CDC/reset remapping,
ready/backpressure, payload protocols beyond exact-width handoff wiring,
repeated triggers, trigger-batch plus data movement coupling, groups,
recursive actor networks, and permanent actor grouping remain deferred.

The exact-width vector extension of that same two-child route shape is shipped
by
[isf/atl_two_child_vector_data_pipeline.isf](../../isf/atl_two_child_vector_data_pipeline.isf).
The source syntax is still the same `(writer.payload reader.payload)` drive
body pair and the same parent transaction ordering. FSMGen resolves the source
child output and sink child input widths from the generated children after
library-qualified actor type resolution. When both endpoints exist and declare
the same positive width, the parent source/sink handoff ports, child
`+interface` roles, generated top links, and generated HDL links use that
exact width. Schedule JSON keeps the same `actor_network.data_movements[]`
entry shape; vector routes report `kind: "vector_actor_handoff"`, `width`
equal to the child endpoint width, and
`width_source: "resolved_child_endpoint_exact_width"`. Scalar one-bit routes
continue to report `kind: "scalar_actor_handoff"` and
`width_source: "scalar_one_bit"`.

The bounded multi-route extension of that same two-child shape is shipped by
[isf/atl_two_child_multi_data_pipeline.isf](../../isf/atl_two_child_multi_data_pipeline.isf).
It allows more than one actor-to-actor route only when every route has the
same resolved source child, the same resolved sink child, the same parent
transaction, one direct endpoint pair, matching source/sink endpoint widths
for that route, and one argument-free top-level drive call. The transaction
must keep the contiguous order `trigger source`, `await source event`, all
route drive calls, `trigger sink`, and `await sink event`. The fixture routes
both `(writer.payload reader.payload)` and
`(writer.sideband reader.sideband)`. Lowering emits separate drive-call states,
separate drive request signals, separate source/sink parent handoffs, generated
child `+interface` roles for both reader outputs and both writer inputs, and
generated-top wiring for both paths. Schedule JSON reports both routes as
separate `actor_network.data_movements[]` entries; one-bit routes use
`kind: "scalar_actor_handoff"`, and exact-width vector routes use
`kind: "vector_actor_handoff"`. The public report still does not expose the
private generated-top `data_links`.

The shipped hardening around that positive route keeps the route unchanged
and adds focused fail-closed coverage around it. A generated-child
actor-to-actor route must prove the source endpoint is a scalar output on the
source child, the sink endpoint is a scalar input on the sink child, one
selected data-route drive body owns exactly one endpoint pair, and one
top-level transaction drive call activates that route. Fan-in/fan-out,
mux/storage, route endpoint expressions, CDC/reset remapping,
ready/backpressure, payload protocols, and permanent actor grouping remain
deferred.
The shipped width hardening now accepts exact-width generated-child
actor-to-actor routes when the source child output and sink child input
declare the same positive width. Mismatched source/sink widths fail closed
before scheduled `.fsm` emission. No packing, truncation, extension, slicing,
payload protocol, storage, or route muxing semantics are selected for
generated-child route endpoints.
The shipped clock/reset hardening keeps the same route in one parent
clock/reset policy. Source or sink children whose clock or reset signature
differs from the parent fail closed before FSMGen claims any CDC bridge,
reset remapping, generated-top system-port remapping, route mux/storage,
ready/backpressure, or payload protocol behavior.
The shipped self-route hardening keeps the same route between two distinct
resolved children. A route pair whose source and sink actor qualifiers name
the same child fails closed before FSMGen claims self-route, loopback,
child-internal bypass, storage, mux, fan-in/fan-out, ready/backpressure, or
payload protocol behavior.
The shipped repeated-trigger hardening keeps the route sequence to one
source-child trigger and one sink-child trigger. Extra triggers targeting
either route child fail closed before FSMGen claims repeated activation,
restart, pending-request merging, trigger fan-in/fan-out, or multi-activation
scheduling behavior.
The shipped repeated-wait hardening keeps the same route sequence to one
source-child event wait and one sink-child event wait. Extra waits targeting
either route child fail closed before FSMGen claims event fan-in/fan-out,
repeated wait sequencing, child replay, route-level wait storage, muxing,
ready/backpressure, or payload behavior.
The shipped same-parent-transaction hardening keeps the same route sequence
inside one parent transaction. Route clauses split across multiple parent
transactions fail closed before FSMGen claims route continuation, pending
handoff storage, transaction rendezvous, cross-transaction scheduling,
muxing, ready/backpressure, or payload behavior.
The shipped sink-trigger ordering hardening keeps the data drive call before
the sink child trigger. A sink trigger that appears before the drive call
fails closed before FSMGen claims speculative sink activation, delayed
payload delivery, route storage, muxing, ready/backpressure, or payload
protocol behavior.
The shipped sink-event-wait ordering hardening keeps the sink child event
wait after the sink child trigger. A wait on the sink child event before the
sink trigger fails closed before FSMGen claims pre-trigger acknowledgement,
sticky event sampling, event replay, route storage, muxing,
ready/backpressure, or payload protocol behavior.
The shipped source-event-wait ordering hardening keeps the source child
event wait after the source child trigger. A wait on the source child event
before the source trigger fails closed before FSMGen claims pre-trigger
acknowledgement, sticky event sampling, event replay, route storage, muxing,
ready/backpressure, or payload protocol behavior.
The shipped route-contiguity hardening keeps that same route as one
contiguous transaction-body segment. Interleaved parent clauses between the
source trigger, source event wait, data drive call, sink trigger, and sink
event wait fail closed before FSMGen claims interleaved parent work, local
side effects, pre/post route sampling, route continuation, pending handoff
storage, muxing, ready/backpressure, or payload protocol behavior.
The shipped route-isolation hardening keeps the contiguous route segment as
the only executable parent transaction-body work between the transaction
start condition and completion in this subset. Parent clauses before the
source trigger or after the sink event wait fail closed before FSMGen claims
pre-route setup, post-route sampling, local side effects, cleanup work, route
continuation, pending handoff storage, muxing, ready/backpressure, or payload
protocol behavior.
The shipped route-boundary cardinality hardening keeps that isolated route
bounded by exactly one simple `(on ...)` start condition and exactly one
simple `(complete ...)` completion pulse. Extra start or completion
boundaries remain fail-closed before FSMGen claims activation fan-in,
completion fan-out, start-condition arbitration, local setup/cleanup, route
continuation, pending handoff storage, muxing, ready/backpressure, or payload
protocol behavior.
The shipped boundary-simplicity hardening keeps those two route boundaries
body-free. `(on ...)` activation-body samples and `(complete ...)` extra
payload operands remain fail-closed before FSMGen claims activation-body
sampling, completion payload/fan-out, local setup/cleanup, route
continuation, pending handoff storage, muxing, ready/backpressure, or payload
protocol behavior.

A depth-1 element is not considered a FIFO for this library catalog; it is a
register/holding element and would hide the real storage and concurrency
requirements. The shipped reusable FIFO actor target is fixed-shape
`DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and `OCC_WIDTH=3`. Those parameters
are provenance and binding evidence in this fixture; actor top-level
interface widths may use actor-local scalar parameter defaults, declared actor
constants, or qualified imported package scalar constants that resolve to
positive integers, actor-owned scalar storage widths may use actor-local
scalar parameter defaults, declared actor constants, or qualified imported
package scalar constants that resolve to positive integers, actor-owned bank
widths may use actor-local scalar parameter defaults, declared actor
constants, or qualified imported package scalar constants that resolve to
positive integers, and bank depths may use actor-local scalar parameter
defaults, declared actor constants, or qualified imported package scalar
constants that resolve to positive integers. The actor has
actor-owned storage, read
and write pointers, occupancy state, actor-maintained flags, reset ownership,
and first-class handling of the four request cases every cycle: no request,
push without pop, pop without push, and push with pop. Push-only is accepted
when the FIFO is not full, pop-only
is accepted when the FIFO is not empty, simultaneous push+pop derives its
read-fire and write-fire predicates from the same pre-cycle
occupancy/full/empty snapshot, and idle preserves state. Depth 4 gives the
fixture concrete review points: 2-bit pointer wrap, occupancy values 0
through 4, and full/empty derivation.
`full` is maintained by the actor and is `1` exactly when occupancy is 4;
`empty` is maintained by the actor and is `1` exactly when occupancy is 0.
Transaction `(when condition body...)` remains ordered
control flow; it must not be used to pretend FIFO ports are concurrent when a
push and pop request arrive in the same cycle. The storage primitive needed
for that target is now available as actor-owned fixed storage:
`(var name (width N))` for pointer/occupancy state, with `(variable ...)` as
the verbose scalar-storage alias.
Hardware components modeled by ISF are persistent regions, not software
processes that die when work is done. Actors, transactions, DTs, and rules can
be inactive, but while the design is powered, clocked, and released from reset
their logic remains present. FIFO write and read behavior should therefore be
modeled as concurrently evaluable actor logic that interacts with shared
controller state. The write pointer names the entry selected for the next
accepted push; the read pointer names the entry selected for the next accepted
pop; for the first depth-4 target both pointers wrap from entry 3 back to
entry 0. The reusable FIFO fixture models the internal data bank through
`(bank data (width 8) (depth 4))`, `(store data wr_ptr data_in)`, and
`(load data rd_ptr as data_out)`.
Actor top-level interface widths may now use actor-local scalar parameter
defaults, declared actor constants, or qualified imported package scalar
constants that resolve to positive integers.
Actor-owned scalar storage widths may now use actor-local scalar parameter
defaults, declared actor constants, or qualified imported package scalar
constants that resolve to positive integers.
Actor-owned bank storage widths may now use actor-local scalar parameter
defaults, declared actor constants, or qualified imported package scalar
constants that resolve to positive integers.
Actor-owned bank storage depths may now use actor-local scalar parameter
defaults, declared actor constants, or qualified imported package scalar
constants that resolve to positive integers.
Use-site FIFO interface shape, use-site bank-depth
specialization, generated-top respecialization, arbitrary-depth
memory-backed FIFO generation beyond the first `DEPTH=4` fixture, automatic
non-zero reset values such as empty=1, standalone transaction/drive exports,
package/imported constants outside the shipped qualified actor parameter,
generated-child transaction parameter default, generated activation override,
reusable-library use-site override, actor interface width, and actor-owned
scalar storage width, actor-owned bank storage width, and actor-owned bank
storage depth scalar-constant
subsets, derived parameter expressions, and library actors that import other
libraries remain deferred.

## 4. Clock, Reset, Watchdog

```lisp
;; Implicit legacy single-clock defaults when the author omits the clauses:
(clock clk)
(reset (rst_n async active_low))
(watchdog 65535)

;; Explicit reset shorthand remains available:
(reset rst_n)
```

Reset rules:
- A legacy single-clock actor that omits `(clock ...)` defaults to clock
  signal `clk`.
- A legacy single-clock actor that omits `(reset ...)` defaults to asynchronous
  active-low reset signal `rst_n`.
- Any actor that omits `(watchdog ...)` defaults to watchdog limit `65535`,
  exactly `(2^16 - 1)`.
- Clock names must be scalar when a `(clock ...)` clause is present.
- `(clock ...)`, `(reset ...)`, and `(watchdog ...)` are actor-level
  singleton clauses; duplicates are rejected before actor-shell return.
- ISF currently supports one actor clock domain. A non-`clk` name is just an
  authored signal name for that single domain, not a second or interacting
  clock domain.
- Explicit flat `(reset name)` keeps the shipped synchronous reset shorthand.
- Names ending in `_n` or `_b` infer `active_low`; other names infer
  `active_high`.
- List form may include `async`, `active_low`, or `active_high`.
- Reset names must be scalar when a `(reset ...)` clause is present.
- Async resets lower to `.fsm` `(areset name)`.
- Sync resets lower to `.fsm` `(sreset name)`.

Multi-clock boundary:
- Legacy `(clock name)` ISF actors have one clock domain per actor/generated
  top.
- Library clock/reset bindings and generated-top system-port links are
  signal-name binding inside the one-domain library-binding model. They do
  not create a second clock domain and they do not model clock-domain crossing
  behavior.
- ISF now accepts parser metadata for named domains and builds an internal
  scheduler partition. Public `lower(...)` emits one domain scheduled `.fsm`
  artifact per declared domain plus a generated multi-domain top that wires
  explicit CDC child-interface artifacts for accepted event crossings.
  Schedule-report projection now exposes bounded domain and crossing metadata.
  Generated HDL for accepted event-crossing actors now emits the generated top
  and concrete acknowledged-event CDC child modules for accepted crossings on
  SystemVerilog/Verilog-family targets when each emitted domain artifact
  satisfies the current scheduled `.fsm` HDL contract. Clock-only no-reset
  domain artifacts are accepted by the direct backend; their generated CDC
  metadata records absent resets and the concrete CDC child omits absent reset
  ports.
- Direct reads or writes between domains are not accepted by implication. A
  shipped CDC primitive or protocol actor must provide specified runtime
  behavior, lowering, diagnostics, and report metadata before such crossings
  are legal.
- A `(crossings (activation child (from SRC) (to DEST)))` declaration is parsed,
  structurally validated (SRC/DEST declared and distinct; `child` a declared
  transaction), and lowers a blocking `(do child)` through CDC-synchronized
  activation start/done for the shipped bounded surface: transaction top level,
  any direct top-level body (`repeat`, `when`, `switch`, `while`, `until`), and a
  `repeat` nested directly in a top-level `when` body or top-level `switch`
  branch, and a nested `when` chain reached from one of those top-level branch
  bodies, including a `repeat` under that chain. Cross-domain activation without
  such a crossing continues to fail closed with the clock-domain-violation
  diagnostic; cross-domain `(spawn)`, declared-but-unused or misplaced activation
  crossings, nested switch bodies, repeat-contained branch bodies, and deeper
  cross-domain `(do)` placements remain fail-closed.
- Asynchronous reset trees are not DTs. FSMGen does not use ISF DT logic to
  build arbitrary asynchronous reset gating.

Selected source model and current implementation status:
- Named domains are actor-scoped. The parser now accepts the selected
  actor-level `(clock-domains ...)` block as metadata for the domain
  partitioning handoff:

```lisp
(clock-domains
  (domain core (clock clk) :default)
  (domain bus  (clock bus_clk)))
```

- Existing `(clock clk)` remains the shorthand for one implicit actor domain
  named `default`.
- Actor source must not mix `(clock ...)` with `(clock-domains ...)`, and must
  not mix actor-level `(reset ...)` with `(clock-domains ...)`.
- A multi-domain actor must declare unique domain names, scalar clock names,
  and exactly one default domain. A single-domain block has an implicit
  default.
- Interface ports, actor-owned storage entries, transactions, rules, and
  child instances may only reference actor-declared domain names through
  `(domain NAME)` annotations. Omitted domain references inherit the actor
  default domain when `(clock-domains ...)` is present.
- Domain annotations are accepted on interface ports, storage entries,
  transactions, rules, reusable `use` instances, and generated child
  activations:

```lisp
(interface
  (input start (domain core))
  (output bus_done (domain bus)))
(storage
  (var core_reg (width 1) (domain core)))
(transaction bus_tx
  (domain bus)
  ...)
(rule core_rule
  (domain core)
  ...)
(use lib.actor as rx
  (domain bus)
  (bind ...))
(spawn worker as w0
  (domain core))
```

- Drives do not own domains; they inherit the domain of their activation site.
  Reusing one drive body from multiple domains is rejected until a later
  feature defines safe cross-domain drive reuse.
- Transactions and rules are indivisible domain-owned regions. One
  transaction or rule may not be split across multiple domains.
- Interface-port or child-instance domain annotations are ownership metadata,
  not CDC primitives. They do not legalize direct cross-domain reads, writes,
  triggers, activations, or bindings.
- Malformed domain combinations fail closed: unknown domain references,
  duplicate domain names, duplicate or missing default domain markers in a
  multi-domain actor, duplicate clock names that pretend to be distinct
  domains, and any direct unowned crossing are rejected before lowering.
- Single-domain `(clock-domains ...)` sources can still lower through the
  existing single-clock scheduled `.fsm` path. Multi-domain sources build a
  validated internal domain partition, then public `lower(...)` returns
  domain-specific scheduled `.fsm` artifacts named
  `<actor>__domain_<domain>.fsm` and a generated `<actor>_top.fsm` top
  artifact.
- Schedule reports for multi-domain sources describe the generated top at the
  top level and expose each domain artifact through `clock_domains[]`; legal
  event crossings appear in `crossings[]`. The plain HDL path for accepted
  event-crossing actors emits the generated top and concrete acknowledged-event
  CDC child for SystemVerilog/Verilog-family targets when each emitted domain
  artifact satisfies the current scheduled `.fsm` HDL contract.

Selected reset ownership model and current implementation status:
- Existing actor-level `(clock clk)` plus optional actor-level `(reset ...)`
  remains the shipped shorthand for one implicit domain named `default`.
- An actor using `(clock-domains ...)` must put reset ownership inside each
  domain entry and must not also use actor-level `(reset ...)`:

```lisp
(clock-domains
  (domain core (clock clk)     (reset rst_n) :default)
  (domain bus  (clock bus_clk) (reset (bus_rst_n async active_low))))
```

- Each domain owns zero or one reset. A domain with no reset clause has no
  generated reset for its clocked state. Current lower/report/schedule-JSON
  paths preserve that absence; current direct scheduled `.fsm` HDL generation
  accepts the clock-only contract and emits reset-free sequential blocks for
  no-reset domain artifacts.
- Domain reset payloads reuse the shipped reset value rules: flat
  `(reset name)` is synchronous with inferred polarity; list forms may include
  `async`, `active_low`, or `active_high`; and reset names must be scalar.
- A synchronous reset is sampled only on the owning domain clock edge.
- An asynchronous reset is a direct external reset pin for the owning domain's
  clocked state. It is not a data signal, handshake, or CDC primitive.
- The same reset signal may be named by multiple domains only when
  synchronous/asynchronous kind and polarity match exactly. Such fanout
  describes one external reset pin reaching multiple domains; it does not
  synchronize data between them.
- Child reset bindings connect the child local-domain reset pin to a signal in
  the selected parent domain or to an explicitly shared external reset pin
  under the same kind/polarity rules.
- Malformed reset combinations fail closed: duplicate domain reset clauses,
  actor-level `(reset ...)` mixed with `(clock-domains ...)`, expression-valued
  reset names, conflicting reset reuse, DT-generated async reset gating, and
  treating reset assertion/deassertion as an ordinary cross-domain event.

Selected crossing primitive and current implementation status:
- The first legal cross-domain interaction is an acknowledged single-bit event
  channel. It carries no data payload:

```lisp
(crossings
  (event rx_done
    (from bus  rx_done_bus)
    (to   core rx_done_core)
    (ready rx_done_ready)))
```

- `(crossings ...)` is actor-scoped and references only domains declared in
  `(clock-domains ...)`.
- `(from DOMAIN SIGNAL)` names the source-domain event request signal.
- `(to DOMAIN SIGNAL)` names the generated destination-domain one-cycle event
  pulse.
- `(ready SIGNAL)` names the generated source-domain ready signal. Source
  logic may request a new event only when ready is true.
- Source and destination domains must be different declared domains.
- The primitive has at most one outstanding event. After an accepted source
  event, ready deasserts until an acknowledgement returns from the destination
  domain.
- The destination pulse occurs after synchronizer/acknowledgement latency. No
  same-cycle relationship is promised between source request and destination
  pulse.
- The generated top represents the primitive as an explicit CDC child
  interface with source clock/reset, destination clock/reset, request, ready,
  and pulse ports. Schedule reports expose the generated CDC instance/module
  names, endpoint domains/signals, single-outstanding acknowledgement policy,
  and no-payload policy. The generated HDL path recognizes the ISF-generated
  CDC metadata and emits a concrete acknowledged-event synchronizer child; it
  does not infer HDL for arbitrary external `?rtl` children. For no-reset
  domains, the generated `?rtlif` metadata records
  `SOURCE_RESET_PRESENT 0d0` and/or `DEST_RESET_PRESENT 0d0`; that metadata is
  public through lower/report review artifacts even though no-reset domain HDL
  remains fail-closed today.
- An actor may declare multiple independent event crossings. Each crossing
  gets its own deterministic CDC instance/module, top wiring, report entry,
  and generated child HDL. This does not add ordering, payload, or multi-event
  transaction semantics between crossings.
- Payload transfer, multi-bit data, level sampling, reset crossing, and
  FIFO-like storage remain outside this first primitive.
- Direct cross-domain reads, writes, triggers, activations, parent/child
  bindings, and reset assertion/deassertion events remain rejected unless a
  shipped crossing primitive or protocol actor owns that path.

Selected lowering artifact strategy and current implementation status:
- Current multi-domain lowering builds an internal domain partition that groups
  interface endpoints, storage, transactions, rules, reusable library uses, and
  generated child activations by declared domain. It rejects direct unowned
  cross-domain reads, writes, triggers, activations, bindings, and multi-domain
  drive reuse before emission.
- Current multi-domain artifact emission emits one domain-local scheduled
  `.fsm` artifact per declared domain, named
  `<actor>__domain_<domain>.fsm`.
- Each domain `.fsm` remains a normal single-clock scheduled module. Its
  `+system` clause uses only the domain clock and that domain's reset policy.
- A domain `.fsm` contains only domain-owned interface endpoints, storage,
  transactions, rules, child activations, generated helper signals, and
  generated event primitive endpoints for that domain.
- No domain `.fsm` directly references another domain's local state, generated
  helper, transaction, rule, or port.
- A generated top artifact named `<actor>_top.fsm` owns inter-module wiring.
  It instantiates domain modules and explicit CDC child interfaces through
  `?rtl`/`?rtlif` entries. It must not hide clocked behavior in top-level DT
  logic.
- The acknowledged event primitive emits an explicit generated CDC child
  interface with source clock/reset, destination clock/reset, request, ready,
  and pulse ports. It is not an ordinary single-domain `.fsm` state chain.
- Schedule-report metadata for domain artifacts and crossing artifacts is
  shipped. Multi-domain reports use the generated top as the top-level report
  scope, keep top-level `state_count` at zero, and put domain-local state
  counts plus artifact names under `clock_domains[]`. Plain HDL generation for
  accepted event-crossing actors emits the generated top and concrete
  acknowledged-event CDC child on SystemVerilog/Verilog-family targets when
  each emitted domain artifact satisfies the current scheduled `.fsm` HDL
  contract. No-reset event-crossing fixtures are supported for scheduled
  `.fsm` review artifacts, schedule reports, and generated HDL; their domain
  modules and generated CDC child omit absent reset ports.

Watchdog rules:
- `(watchdog N)` is the actor default for every `(await ...)`.
- `N` must be a positive integer literal, a declared actor constant, an
  actor-local scalar parameter default, or a qualified imported package scalar
  constant that resolves to a positive integer.
- `(await port (watchdog M))` overrides the default for that wait.
- Await-local `M` may use the same static source set as actor-level `N`. For
  top-level transaction awaits, `M` may also use a same-transaction scalar
  parameter default that resolves to a positive integer. Same-transaction
  parameters shadow actor-level static names in this value-domain slot and
  remain local lowering inputs.
  The current scheduled `.fsm` model has one watchdog counter per transaction,
  so one transaction must have a single effective watchdog limit; distinct
  per-await limits in the same transaction fail closed until per-await counter
  reset semantics are selected.
- Await states decrement an inferred watchdog counter and transition to a
  timeout state at zero.
