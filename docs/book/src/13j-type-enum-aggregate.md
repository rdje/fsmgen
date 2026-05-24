# ISF Types, Enums, And Aggregates

This chapter is the review surface for the shipped `.isf` type, enum, and
aggregate subset. It describes what authors may write today, what the scheduled
`.fsm` review artifact preserves, and what still fails closed.

The important rule is that ISF does not own a separate type system. Local
`(types ...)` and `(enums ...)` declarations, package imports, scalar aliases,
enum members, and packed aggregate aliases reuse the same `.fsm` declaration
and package machinery that direct `.fsm` roots already use.

## Declarations And Imports

Actor-local declarations are written in the actor body:

```lisp
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

```lisp
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

Packed `list` and `record` aliases are currently accepted only as actor-owned
storage variables.

```lisp
(storage
  (var frame (type frame_t))
  (var lanes (type shared.lanes_t)))
```

The scheduled `.fsm` keeps the authored alias in typed `+size` review entries,
and schedule reports expose the storage item with its packed `width`, authored
`type`, and resolved `type_kind` (`record` or `list`).

Aggregate interface ports, transaction-local ports, storage banks, and other
aggregate carriers are not shipped yet. They require separate ownership,
port-binding, and partial-update contracts.

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
| Actor aggregate/list parameter default leaf | `(params (MODES (mode.BUSY mode.IDLE)))` | Scalar enum leaves are preserved in compatible aggregate/list defaults. |
| Actor constant/parameter-backed aggregate/list parameter leaf | `(params (BASE_W 8) (LANES (LANE0 BASE_W)))` | Authored constant and earlier scalar actor parameter leaf tokens are preserved while resolved literals are available internally. |
| Generated child transaction scalar parameter default | `(transaction worker (params (BASE 8) (WIDTH BASE) (MODE mode.BUSY)) ...)` | Earlier scalar transaction parameter tokens and enum tokens are preserved in child `+params`; actor constants and actor scalar parameters used in this position are literalized before child/report publication. |
| Generated child transaction aggregate/list parameter default leaf | `(transaction worker (params (BASE 8) (LANES (BASE LANE0 BASE_W mode.IDLE))) ...)` | Child-local transaction parameter leaves and scalar enum leaves are preserved; scalar actor-static leaves are literalized. |
| Spawn, blocking `do`, and rule-trigger scalar parameter override | `(spawn worker as w0 (params (MODE mode.BUSY)))` | Resolved to a literal value in the generated top `?fsmc` parameter block and generated-composition report. |
| Activation aggregate/list override leaf | `(spawn worker as w0 (params (MODES (mode.BUSY mode.IDLE))))` | Scalar enum leaves resolve to literal aggregate/list override values. |
| Reusable-library use-site override | `(use lib.actor as u0 (params (MODE mode.BUSY)) ...)` or `(use lib.actor as u0 (params (MODE MODE_PARAM)) ...)` | Enum members, importing-actor constants, and importing-actor scalar parameter defaults resolve to literal generated-top bindings and `library_uses[]` report values. |
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
operands, subaggregate updates, whole-record/whole-list truthiness, aggregate
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
