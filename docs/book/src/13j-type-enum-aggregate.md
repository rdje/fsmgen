# ISF Types, Enums, And Aggregates

This chapter is the review surface for the shipped `.isf` type, enum, and
aggregate subset. It describes what authors may write today, what the scheduled
`.fsm` review artifact preserves, and what still fails closed.

The important rule is that ISF does not own a separate type system. Local
`(types ...)` and `(enums ...)` declarations, package imports, scalar aliases,
enum members, and packed aggregate aliases reuse the same `.fsm` declaration
and package machinery that direct `.fsm` roots already use.

## Declarations And Imports

Actor-local declarations are written in the actor body. Schematic
shape (the actor body continues with `(interface ...)` and one or
more `(transaction ...)` clauses):

```text
(actor typed_actor
  (types
    (type byte (bits 8))
    (type frame_t (record (mode (bits 2)) (flag bit)))
    (type lanes_t (list bit (bits 2))))
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  ...)
```

Existing `.fsm` package roots can be imported by name:

```text
(actor package_typed_actor
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  ...)
```

The scheduled `.fsm` preserves these declarations as review artifacts:

```lisp
(+import shared)
(+types
  (type byte (bits 8))
  (type frame_t (record (mode (bits 2)) (flag bit))))
(+enums
  (mode (IDLE 0) (BUSY 1)))
```

Imported package roots are embedded into the scheduled `.fsm` output so CLI HDL
generation remains self-contained even when the lowerer uses a temporary
scheduled `.fsm` path.

## Scalar Type Aliases

Width-bearing declarations may use `(type NAME)` instead of `(width N)` when
`NAME` resolves to a scalar alias.

```lisp
(interface
  (input data (type byte))
  (output mode_out (type shared.mode_bits)))

(transaction tx
  (ports
    (input payload (type byte)))
  ...)

(storage
  (var scratch (type byte)))
```

`NAME` may be actor-local (`byte`) or package-qualified
(`shared.mode_bits`). `(width N)` and `(type NAME)` are mutually exclusive on
the same declaration. Unknown aliases fail before lowering.

## Aggregate Storage Carriers

Packed `list` and `record` aliases are accepted on actor-owned storage variables.
Packed records also support actor input ports, as described below.

```lisp
(storage
  (var frame (type frame_t))
  (var lanes (type shared.lanes_t)))
```

The scheduled `.fsm` keeps the authored alias in typed `+size` review entries,
and schedule reports expose the storage item with its packed `width`, authored
`type`, and resolved `type_kind` (`record` or `list`).

Packed record actor inputs are admitted with `(input NAME (type T))`, where
`T` is a local or package-qualified alias. Fields are live scalar reads in
supported transaction conditions, `set`/`update` RHS values, rules and drives.
Nested record members, list items and scalar slices use the existing packed
layout. The first authored member occupies the most significant bits.

```lisp
(actor record_input
 (types (type frame (record (flag bit) (data (signed (four_state (bits 5)))))))
 (interface (input start) (input packet (type frame))
  (output seen (width 5)) (output done))
 (storage (var held (type frame)))
 (transaction main
  (on start)
  (set held packet)
  (set seen packet.data)
  (complete done)))
```

The maintained example is [record_input.isf](../../../isf/record_input.isf).
Run `./bin/fsmgen --strict --check --json isf/record_input.isf` from the repository root.

That example uses a local alias to an imported record. Its companion
[record_input_types.fsm](../../../isf/record_input_types.fsm) declares the package:

```lisp
(?pkg:record_input_types
  (+types
    (type frame (record (flag bit) (data (signed (four_state (bits 5))))))))
```

The actor imports it and retains its local spelling:

```lisp
(imports (package record_input_types))
(types (type frame record_input_types.frame))
```

Local aliases and nested members may reference declared imported types. Imports
resolve before local aliases; qualified names remain in their package namespace.
Forward local aliases also work. Missing types and undeclared packages refuse.
The scheduled carrier embeds the package root for independent strict replay.
T2014 qualifies accepted nested/imported/nearest-shadow public sources; T2015
qualifies scalar and nested imported dependencies. T2016 qualifies contextual
public refusals. T2017 qualifies the unchanged supplied SPECFORGE whole-copy and
field-guard sources, the exact earlier storage-only products and complete public
discovery. The supplied [whole-copy source](../../../docs/audits/specforge-aggregate-intake-20260930/record-port.isf)
uses a sixteen-bit input: subtype occupies bits 15 through 12, payload bits 11
through 0. Its [field guard](../../../docs/audits/specforge-aggregate-intake-20260930/record-port-field-guard.isf)
reads that same layout. Frontend source/report/replay qualification is complete;
generated/domain public closure, backend/native and consumer completion retain
separate owners.

Generated readers retain one typed packed input in their private interface.
Reused instances receive the live actor input independently; an unread inherited
input is omitted from the child while the authored top declaration remains.
An input-to-storage copy keeps the register and its reset in the actor or domain
owner. A sole generated writer supplies typed private write data and an explicit
enable to that owner. These carrier checks establish structure and strict replay;
native timing and reset behavior still require execution qualification.

The runnable [record_input_children.isf](../../../isf/record_input_children.isf)
imports the same package and reuses a reader in domain `io`:

```lisp
(transaction worker (domain io)
  (ports (output result (width 5)))
  (wait 2)
  (set result packet.data)
  (complete done))
(transaction main (domain io)
  (on start)
  (set held packet)
  (spawn worker as left (bind (output result seen)))
  (spawn worker as right (bind (output result again)))
  (await_all done)
  (complete done))
```

Run `./bin/fsmgen --strict --check --json isf/record_input_children.isf`.
Its explicit top exposes the declared inputs and outputs, plus each domain's
clock and declared reset. `unused` stays in clock-only domain `idle`; `packet`,
`held` and the readers belong to `io`. There is no implicit crossing or child
register copy. T2019 independently qualifies local/imported nested aliases,
reused readers, unused inputs and sole generated copies, including blocking
calls. Ordinary composition children now retain their source's embedded package
context through the normal frontend; external children still resolve packages
beside their own source. T2020 checks both boundaries.

Accepted generated/domain check, semantic and schedule queries are also
qualified through the native CLI, adapter API and actual newline MCP. The
complete products agree, including declared layouts and reset provenance.
Clock-only siblings retain an absent reset; each realized reader keeps its
owning clock and explicit reset contract. Contextual generated/domain refusal
and final prior-product closure remain separate qualification work.

The semantic report distinguishes authored declarations from realized wiring:

| Public location | Meaning |
| --- | --- |
| `source.interface_ports` | Authored record aliases, scalar leaf layout and declared domains. |
| `semantic.forward_ir.intent_hir.signal_analysis` | The composition top's physical vector pins. |
| `semantic.forward_ir.intent_hir.composition_children[].intent_hir.signal_analysis` | Each module's typed input/output declarations, including `declared_type_name` and the complete `declared_type_spec`. |
| `semantic.forward_ir.intent_hir.composition_children[].structural_rtl_ir.ports` | The corresponding typed structural ports. |
| Schedule `clock_domains[].interface_ports` | The declarations owned by each domain, including unused inputs. |

Join children using `instance_name`, `module_name` and `source_name`. Reused
readers have distinct instance identities and retain the same declared type.
Private write-data ports carry the target's complete record type. Their presence
does not add authored public pins or permit competing writers.

`packet` is one six-bit input; it does not become separate field pins.
`packet.flag` occupies bit 5 and `packet.data` bits 4 through 0. The copy into
`held` requires the same resolved recursive record type. Equivalent local or
imported aliases may have different spellings; equal packed width alone is
insufficient. Member names/order, nested shape, scalar kinds, signed properties
and declared state models must match. An unspecified state model stays
unspecified for this comparison. Existing storage-only copies keep their prior
contract.

Use `(sample packet.data as captured)` in an already supported sample position
when a snapshot is needed. The private scalar alias retains the leaf width,
signed/state properties and existing capture timing. It adds no public port or
implicit reset. Alias collisions, shared transaction writers and invalid sample
paths refuse. Repeated captures by one owner preserve their existing rules.

Inputs cannot be assignment targets. Unknown members, out-of-range items,
subaggregate scalar operands, whole-record conditions/arithmetic and whole-record
sampling refuse. A nearest scalar formal or drive parameter masks an outer
record. A scalar drive parameter cannot read or write record members, even
while its width is unresolved, including member access after a scalar selector.
Bare scalar values and scalar slices keep their
existing width validation; enum/package names retain their namespace meaning. Named-domain
reads and copies require the declared owning domain or a supported crossing.
Generated child scalar outputs still require their published explicit bindings.
Strict width checks require width-aligned scalar assignments.

A static bit or slice of a named-drive scalar parameter follows that parameter,
including inside an expression. It does not read a same-named actor record.
The existing bare-parameter assignment supplies the parameter width; a selector
alone does not borrow a wider outer declaration. For example, `whole` establishes
the five-bit parameter below, while `seen` receives its low four bits:

```lisp
(actor scalar_drive_selectors
 (clock clk)
 (types (type frame (record (flag bit) (data (bits 5)))))
 (interface (input start) (input value (width 5)) (input packet (type frame))
  (output whole (width 5)) (output seen (width 4)) (output done))
 (drive (publish packet) (whole packet) (seen packet[3:0]))
 (transaction main (on start) (drive publish value) (complete done)))
```

The drive's `packet` is scalar and masks the actor's six-bit record. Its member
access such as `packet.data` still refuses. The same parameter identity applies
to an explicitly bound generated invocation and to the drive's owning domain.
Transaction locals retain their existing interface-name collision refusals.

A generated child's scalar formal can share an actor record input name. In a
binding, the formal name identifies the callee port; the actual value belongs
to the caller. The binding below sends `value` to the child's scalar `packet`:

```lisp
(actor scalar_record_binding
 (clock clk) (reset (rst_n async active_low))
 (types (type frame (record (flag bit) (data (bits 5)))))
 (interface (input start) (input value (width 3)) (input packet (type frame))
  (output observed (width 3)) (output done))
 (transaction worker (ports (input packet (width 3)) (output result (width 3)))
  (set result packet[2:0]) (complete done))
 (transaction main (on start)
  (spawn worker as job (bind (input packet value) (output result observed)))
  (await_all done) (complete done)))
```

The child keeps its scalar public port and selector. The actor record keeps its
own type, width and domain; no automatic record connection is added. Transaction
targets, instance labels and static parameter/domain/timing names also retain
their identity roles. Existing endpoint, width, timing and domain checks still
apply. This does not admit record input roots or field reads as binding actuals:
`(input packet actor_record)` and `(input packet (+ actor_record.data 0))` remain
refused. Bare slices are outside the existing signal/literal/list-expression
binding grammar; this repair does not introduce another binding form.

Rejected check and semantic queries retain their complete failure reports and
nullable diagnostic codes, without successful declarations or partial semantic
payloads. Schedule failure emits no schedule JSON. Its API and newline transport
retain the existing message-only error contract; the compiler diagnostic appears
in native stderr. None of these queries modifies the source or imported package.

Schedule preview reports scheduled intent before HDL realization. A later
composition wiring refusal, such as an unbound generated child output, can
therefore retain a complete schedule preview while strict check and semantic
queries refuse. Use those strict queries to qualify the realized composition;
a schedule preview alone does not prove its ports are connected.

Record outputs, root-list input ports, transaction-local aggregate ports,
aggregate banks and variants remain deferred. Output copies/member writes keep
their separately owned writer prerequisites. The compiler preserves typed
`+size`, explicit `+interface`, exact declaration metadata and private sample
carriers. Full generated/domain behavior, affected backend profiles, native HDL
execution and supplied consumer signoff remain separate qualification work.
See [0113](../../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md#authored-record-input-admission--2026-09-30)
and [declared interface metadata](13a-actor-interface.md#declared-interface-metadata).
Existing declaration-collision refusals still apply.

Single-member records and single-item lists also preserve their aggregate
identity. Nested forms and forward local aliases work in actor declarations
and survive the scheduled `.fsm` replay. For example:

```lisp
(actor single_payload
  (types
    (type payload_t (list (record (payload byte_t))))
    (type byte_t (bits 8)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input data (width 8))
    (output result (width 8)))
  (storage (var value (type payload_t) (reset 0)))
  (transaction main
    (on start)
    (set value data)
    (set result value)))
```

Here the storage keeps its nested list/record shape while whole-value transfers
use the packed representation. Empty aggregates, missing member types,
duplicate field names, unknown aliases, and dependency cycles fail during type
resolution. Generated transaction children in ordinary/single-domain actors
read these same owner-held values through typed internal connections; they do
not allocate private copies. Whole-value reads use the packed representation,
and scalar leaf reads retain their exact leaf width. For example:

```lisp
(actor aggregate_child_read
  (clock clk) (reset (rst_n async active_low))
  (types (type status_t (record (payload (bits 7)) (flag bit))))
  (interface (input start) (input data (width 8))
             (output observed (width 7)) (output done))
  (storage (var status (type status_t) (reset 0)))
  (transaction worker
    (ports (output result (width 7)))
    (wait 4) (set result status.payload) (complete done))
  (transaction parent
    (on start)
    (spawn worker as w0 (bind (output result observed)))
    (wait 1) (set status data)
    (await_all done) (complete done)))
```

The worker observes the owner's later payload value. The public ports stay
scalar; the generated child receives the aggregate root with its type intact.
See [Composition](13f-composition.md) for reset ownership, live-read timing and
the remaining domain/write boundaries.

## Enum Values

Enum members may be local, such as `mode.BUSY`, or package-qualified, such as
`shared.mode.BUSY`. The parser resolves them before lowering in static
specialization contexts and preserves authored tokens in review contexts where
the scheduled `.fsm` can carry them directly.

| Context | ISF example | Lowered/reported behavior |
| --- | --- | --- |
| Actor constant | `(constants (DEFAULT mode.BUSY))` | Preserved in `+constants`; resolved integer is available for static waits and existing static activation overrides. |
| Actor scalar parameter default | `(params (DEFAULT mode.BUSY))` | Preserved in actor `+params` and `actor_params[]`. |
| Actor constant-backed parameter default | `(params (WIDTH DEFAULT_WIDTH))` | Authored constant token is preserved in actor `+params` and `actor_params[]`; resolved literal is used internally by scalar parameter consumers such as widths and counts. |
| Actor parameter-backed parameter default | `(params (BASE_W 8) (WIDTH BASE_W))` | Earlier scalar actor parameter tokens are preserved in actor `+params` and `actor_params[]`; resolved literals are used internally by scalar parameter consumers. |
| Imported package constant-backed parameter default | `(params (WIDTH shared.DEFAULT_WIDTH))` | Qualified imported package scalar constant tokens are preserved in actor `+params` and `actor_params[]`; resolved scalar numeric or exact-width literals are used internally by scalar parameter consumers. |
| Imported package constant-backed interface width | `(interface (input data (width shared.DEFAULT_WIDTH)))` | Qualified imported package scalar constants resolve to integer parser-handoff widths, scheduled `.fsm` `+size` entries, schedule-report evidence, and HDL port ranges. |
| Imported package constant-backed scalar storage width | `(storage (var count (width shared.DEFAULT_WIDTH)))` | Qualified imported package scalar constants resolve to integer parser-handoff storage widths, scheduled `.fsm` `+size` entries, `inferred_storage[]` evidence, width evidence, and HDL register ranges. |
| Imported package constant-backed bank storage width | `(storage (bank data (width shared.DEFAULT_WIDTH) (depth 2)))` | Qualified imported package scalar constants resolve to integer parser-handoff bank widths, scalarized scheduled `.fsm` `+size` entries, `inferred_storage[]` and `bank_accesses[]` evidence, width evidence, and HDL register ranges. |
| Imported package constant-backed bank storage depth | `(storage (bank data (width 8) (depth shared.DEFAULT_DEPTH)))` | Qualified imported package scalar constants resolve to integer parser-handoff bank depths, deterministic scalarized storage families, scheduled `.fsm` `+size` entries, `inferred_storage[]` and `bank_accesses[]` depth/scalar-entry evidence, and HDL register declarations. |
| Actor aggregate/list parameter default leaf | `(params (MODES (mode.BUSY mode.IDLE)))` | Scalar enum leaves are preserved in compatible aggregate/list defaults. |
| Actor constant/parameter/package-backed aggregate/list parameter leaf | `(params (BASE_W 8) (LANES (LANE0 BASE_W shared.LANE1)))` | Authored actor constant, earlier scalar actor parameter, and qualified imported package scalar constant leaf tokens are preserved while resolved literals are available internally. |
| Generated child transaction scalar parameter default | `(transaction worker (params (BASE 8) (WIDTH BASE) (MODE mode.BUSY) (DATA_W shared.DEFAULT_WIDTH)) ...)` | Earlier scalar transaction parameter tokens, enum tokens, and qualified imported package scalar constant tokens are preserved in child `+params`; actor constants and actor scalar parameters used in this position are literalized before child/report publication. |
| Generated child transaction aggregate/list parameter default leaf | `(transaction worker (params (BASE 8) (LANES (BASE LANE0 BASE_W mode.IDLE shared.LANE1))) ...)` | Child-local transaction parameter leaves, scalar enum leaves, and qualified imported package scalar constant leaves are preserved; scalar actor-static leaves are literalized. |
| Spawn, blocking `do`, and rule-trigger scalar parameter override | `(spawn worker as w0 (params (MODE mode.BUSY)))` | Resolved to a literal value in the generated top `?fsmc` parameter block and generated-composition report. |
| Activation aggregate/list override leaf | `(spawn worker as w0 (params (MODES (mode.BUSY mode.IDLE))))` | Scalar enum leaves resolve to literal aggregate/list override values. |
| Package constant-backed activation override | `(spawn worker as w0 (params (WIDTH shared.DEFAULT_WIDTH)))` | Qualified imported package scalar constants and compatible aggregate/list leaves resolve to literal generated-top bindings and generated-composition report values. |
| Reusable-library use-site override | `(use lib.actor as u0 (params (MODE mode.BUSY)) ...)` or `(use lib.actor as u0 (params (MODE shared.DEFAULT_MODE)) ...)` | Enum members, importing-actor constants, importing-actor scalar parameter defaults, and qualified imported package scalar constants resolve to literal generated-top bindings and `library_uses[]` report values. |
| Transaction `set` RHS scalar value | `(set mode_out mode.BUSY)` | Authored token is preserved in the scheduled `.fsm` assignment. |
| Transaction `set` RHS expression operand | `(set mode_out (| mode_in mode.BUSY))` | Enum member is valid as a scalar operand; enum member in operator position fails closed. |
| Transaction condition expression operand | `(when (== mode_in mode.BUSY) (set fire 1))` | Enum member is valid as a scalar operand. |
| Standalone transaction `when`/`while`/`until` condition | `(when mode.BUSY (set fire 1))` | Dotted condition lowers through computed selector syntax such as `?(mode.BUSY)`. |
| Transaction `switch` selector | `(switch mode.BUSY (1 (set fire 1)))` | Dotted selector lowers through computed selector syntax. |
| Transaction `switch` branch value | `(switch mode_in (mode.BUSY (set fire 1)))` | Authored enum token is preserved as the branch scalar value. |
| Rule assignment RHS scalar value | `(rule r ready (set mode_out mode.BUSY))` | Authored token is preserved under the guarded rule DT. |
| Rule assignment RHS expression operand | `(rule r ready (set mode_out (^ mode_in mode.BUSY)))` | Enum member is valid as a scalar operand. |
| Rule guard expression operand | `(rule r (== mode_in mode.BUSY) (set fire 1))` | Enum member is valid as a scalar operand in the guard expression. |
| Standalone rule guard | `(rule r mode.BUSY (set fire 1))` | Guard lowers as a non-state DT header suffix such as `<mode.BUSY`. |
| Named drive body RHS scalar value | `(drive publish (mode_out mode.BUSY))` | Authored token is preserved in the generated drive DT assignment. |
| Named drive body RHS expression operand | `(drive publish (mode_out (^ mode_in mode.BUSY)))` | Enum member is valid as a scalar operand. |
| Inline drive RHS scalar value | `(drive publish (mode_out mode.BUSY))` in a transaction body | Authored token is preserved in the generated state assignment. |
| Inline drive RHS expression operand | `(drive publish (mode_out (^ mode_in mode.BUSY)))` in a transaction body | Enum member is valid as a scalar operand. |
| Named drive-call scalar actual | `(drive publish mode.BUSY)` | Authored token is preserved in the drive parameter assignment. |
| Named drive-call expression operand | `(drive publish (^ mode_in mode.BUSY))` | Enum member is valid as a scalar operand. |

Enum members in expression operator position remain rejected. Enum member
targets also remain rejected because enum members are constants, not writable
storage or output names. Unsupported enum references fail before scheduled
`.fsm` emission with diagnostics that name the unsupported context.

### Enum names are not type aliases

An `(enums (NAME ...))` declaration establishes only the enum member-value
family `NAME`. It does **not** also establish a scalar type alias named
`NAME`. Writing `(type NAME)` on a width-bearing interface port, transaction
port, or storage variable when only `(enums (NAME ...))` is declared fails
closed:

```text
(actor enum_not_a_type
  (enums (mode (IDLE 0) (BUSY 1)))
  (interface
    (input start)
    (output state_out (type mode))   ;; <-- ERROR: unknown type 'mode'
    (output done))
  ...)
```

> `Error: actor 'enum_not_a_type' interface port 'state_out' references
> unknown type 'mode'`

To use an enum name as a width-bearing type, **co-declare a backing scalar
type alias** `(types (type NAME (bits k)))` alongside `(enums (NAME ...))`.
Co-declaring the same `NAME` in both `(types ...)` and `(enums ...)` is
accepted and is the intended mechanism — they are distinct declaration roles
(the `(type)` provides the width alias used by `(type NAME)`; the `(enums)`
provides the member values used by `mode.BUSY`-style references), so this is
not a redeclaration conflict:

```lisp
(actor enum_with_type
  (clock clk)
  (reset rst_n)
  (types (type mode (bits 1)))
  (enums (mode (IDLE 0) (BUSY 1)))
  (interface
    (input start)
    (output state_out (type mode))
    (output done))
  (transaction tx
    (on start)
    (complete done)))
```

The backing `(bits k)` width is the author's assertion and is **not**
cross-validated against enum member magnitudes — `(type mode (bits 1))` is
accepted even with a member value that needs more bits. A downstream emitter
recovering a dense `0..N-1` enum should choose `k = ceil(log2(member_count))`.

Actor-local `(types ...)`, `(enums ...)`, and `(constants ...)` declarations
need **not** be referenced to be contract-valid: an unreferenced declaration
lowers cleanly and is preserved in the corresponding scheduled `.fsm` review
section.

## Aggregate Leaf Values

Aggregate member and item paths are valid only when the root is a declared
actor-owned aggregate storage variable and the path resolves to a scalar leaf.

```lisp
(storage
  (var frame (type frame_t))
  (var lanes (type lanes_t)))
```

Valid scalar leaves include record members such as `frame.flag` and list items
such as `lanes[1]`. Unknown record members,
out-of-range list indexes, malformed paths, and paths that resolve to a whole
record/list fail before lowering.

| Context | ISF example | Lowered/reported behavior |
| --- | --- | --- |
| Transaction `set` RHS scalar value | `(set mode_out frame.mode)` | Authored aggregate leaf is preserved in the scheduled assignment. |
| Transaction `set` RHS expression operand | `(set mode_out (+ frame.mode mode_in))` | Aggregate leaf is valid as a scalar operand. |
| Transaction `set` target | `(set frame.flag flag_in)` | Scalar aggregate leaf is a writable storage leaf target. |
| Standalone transaction `when`/`while`/`until` condition | `(when frame.flag (set fire 1))` | Direct aggregate condition lowers through computed selector syntax such as `?(frame.flag)`. |
| Transaction condition expression operand | `(when (& ready frame.flag) (set fire 1))` | Aggregate leaf is valid as a scalar operand. |
| Transaction `switch` selector | `(switch frame.mode (1 (set seen 1)))` | Selector lowers through computed selector syntax such as `?(frame.mode)`. |
| Transaction `switch` branch value | `(switch mode_in (frame.mode (set seen 1)))` | Aggregate leaf is valid as a scalar branch value. |
| Rule assignment RHS scalar value | `(rule expose ready (set mode_out frame.mode))` | Authored aggregate leaf is preserved under the guarded rule DT. |
| Rule assignment RHS expression operand | `(rule expose ready (set mode_out (+ frame.mode mode_in)))` | Aggregate leaf is valid as a scalar operand. |
| Rule assignment target | `(rule capture ready (set frame.mode mode_in))` | Scalar aggregate leaf is a writable rule target. |
| Rule guard expression operand | `(rule fire (& ready frame.flag) (set seen 1))` | Aggregate leaf is valid as a scalar guard operand. |
| Standalone rule guard | `(rule fire frame.flag (set seen 1))` | Guard lowers as a non-state DT header suffix such as `<frame.flag`. |
| Named drive body RHS scalar value | `(drive publish (mode_out frame.mode))` | Authored aggregate leaf is preserved in the drive DT assignment. |
| Named drive body RHS expression operand | `(drive publish (mode_out (+ frame.mode mode_in)))` | Aggregate leaf is valid as a scalar operand. |
| Named drive body target | `(drive capture (frame.mode mode_in))` | Scalar aggregate leaf is a writable drive target. |
| Inline drive RHS scalar value | `(drive publish (mode_out frame.mode))` in a transaction body | Authored aggregate leaf is preserved in the generated state assignment. |
| Inline drive RHS expression operand | `(drive publish (mode_out (+ frame.mode mode_in)))` in a transaction body | Aggregate leaf is valid as a scalar operand. |
| Inline drive target | `(drive capture (frame.mode mode_in))` in a transaction body | Scalar aggregate leaf is a writable inline-drive target. |
| Named drive-call scalar actual | `(drive publish frame.mode)` | Aggregate leaf is valid as a scalar drive actual. |
| Named drive-call expression operand | `(drive publish (+ frame.mode mode_in))` | Aggregate leaf is valid as a scalar operand. |

Aggregate paths in expression operator position remain rejected. Subaggregate
operands, subaggregate updates, whole-record/whole-list truthiness, record-output and root-list
interface ports, transaction-local aggregate ports, aggregate storage banks,
aggregate field/slice/update lowering beyond scalar leaves, and broader shape
inference remain backlog.

## Diagnostics

The parser resolves type aliases, enum members, and aggregate paths before
scheduled `.fsm` emission. That means these failures are reported in ISF space:

- Unknown local or package type aliases.
- `(width ...)` and `(type ...)` on the same declaration.
- Aggregate aliases on unsupported carriers.
- Unknown enum families or enum members.
- Enum references in unsupported contexts, including operator position or LHS
  target position.
- Unknown aggregate record members.
- Out-of-range aggregate list indexes.
- Aggregate paths that resolve to whole records or lists where a scalar leaf is
  required.
- Aggregate paths outside the shipped scalar leaf contexts listed above.

Strict HDL generation is part of the shipped contract for the listed forms.

When a form is accepted, the scheduled `.fsm` review artifact is the source of
truth for how the ISF syntax reached the backend.

## Aggregate Package Constants Fail Closed

A qualified imported package constant `pkg.NAME` works only when
`NAME` is a scalar entry. Aggregate or member paths
(`pkg.AGG.member`, `pkg.LIST.idx`, etc.) fail closed across every
shipped consumer with a `remains deferred` diagnostic naming the
consumer axis. The rejected source shape is a package whose
constant is an aggregate, paired with an actor that reaches into a
member path:

```text
;; in a sibling shared.fsm file:
(?pkg:shared
  (+constants
    (CONFIG ((lat 4) (depth 8)))))

;; in the actor:
(transaction worker
  (on start)
  (wait shared.CONFIG.lat)        ;; <-- aggregate/member path
  (complete done))
```

The validator emits
`Transaction 'worker': wait count package constant 'shared.CONFIG'
aggregate/member path 'shared.CONFIG.lat' remains deferred; wait
counts accept only qualified package scalar constants in this
slice`. The same `remains deferred` phrase fires from the matching
axis-specific helper for repeat counts, latency bounds, watchdog
limits, contract windows, data-operation widths, activation
parameter overrides, actor parameter defaults, and transaction
parameter defaults. The deferred lane is aggregate/member-path
resolution against the constant-symbol table; until it ships,
authors must pre-resolve the member to a scalar `pkg.CONSTANT` (for
example `(+constants (CONFIG_LAT 4))`) or use a same-transaction
constant or parameter default instead.

## Complete Accept-Path Examples

The chapter so far has shown schematic forms and table entries.
The actors below are self-contained, copy-pasteable fixtures that
each exercise one of the shipped type/enum/aggregate axes.

### Scalar type alias

```lisp
(actor type_alias_demo
  (types
    (type byte (bits 8)))
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input data (type byte))
    (output done))
  (transaction tx
    (on start
      (sample data as captured))
    (wait 2)
    (complete done)))
```

**Walkthrough.** `(types (type byte (bits 8)))` declares one
actor-local scalar alias `byte` resolving to an 8-bit value.
`(input data (type byte))` uses that alias in place of `(width 8)`,
which keeps the authored intent (`byte`) visible in the scheduled
`.fsm` `+size` review entries. The transaction samples the input
into local register `captured` at entry, waits two cycles, and
completes. The lowered FSM carries the alias as a typed `+size`
entry rather than a raw width.

### Local enum

```lisp
(actor enum_demo
  (enums
    (mode (IDLE 0) (BUSY 1) (DONE 2)))
  (constants
    (DEFAULT_STATE mode.IDLE))
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction tx
    (on start)
    (wait 4)
    (complete done)))
```

**Walkthrough.** `(enums (mode ...))` declares one enum family
`mode` with three members. Enum members are addressed dot-qualified
(`mode.IDLE`, `mode.BUSY`, `mode.DONE`). `(constants (DEFAULT_STATE
mode.IDLE))` uses the enum-member token as a constant value: the
authored `mode.IDLE` is preserved in the scheduled `.fsm`
`+constants` and `actor_constants[]` entries while the resolved
integer is available internally for static comparisons and waits.
The transaction itself is the minimal on/wait/complete skeleton —
the enum only contributes review metadata in this example.

### Aggregate storage carrier

```lisp
(actor aggregate_storage_demo
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (storage
    (var frame (type frame_t)))
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction tx
    (on start)
    (wait 2)
    (complete done)))
```

**Walkthrough.** `(type frame_t (record (mode (bits 2)) (flag
bit)))` declares a packed record alias with two members. `(storage
(var frame (type frame_t)))` declares one actor-owned scalar
storage `frame` whose width comes from the packed sum (`2 + 1 = 3`
bits). Aggregate carriers are accepted in actor-owned storage; they
are not yet accepted as interface or transaction ports. The
scheduled `.fsm` keeps the alias `frame_t` in typed `+size`
entries and the schedule report exposes the storage item with its
packed width, authored type, and resolved `type_kind` (`record`).
