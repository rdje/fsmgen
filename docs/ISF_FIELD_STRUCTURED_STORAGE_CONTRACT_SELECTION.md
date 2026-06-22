# ISF Field-Structured Storage Contract Selection

- Date: `2026-06-22`
- Owner: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1`
- Status: selected for first implementation slice

## Context

SPECFORGE requested a declarative ISF surface for static, named bit-field maps
on register/CSR-like storage words. Current ISF storage declarations carry
opaque scalar widths, optional scalar reset values, fixed-depth scalarized
banks, and selected aggregate storage carriers. Existing runtime field/data
operations (`set-field`, `when-field`, `extract`, `assemble`) describe
scheduled behavior and must not be used to preserve static register-table
metadata.

The current parser/lowerer/report path is narrow enough for a metadata-first
implementation:

- `FSM::Adapter::ISF::Parser::_parse_storage` owns actor storage syntax and
  width/reset validation.
- `_finalize_actor_storage_widths` resolves symbolic scalar storage widths
  before scheduler handoff.
- `FSM::Scheduler::ISF::LoweringIR::_declared_storage_for_ir` copies declared
  storage into the scheduler IR without changing generated behavior.
- `FSM::Scheduler::ISF::Emitter::JSON::_storage_summary` projects declared
  storage into `inferred_storage[]`.
- `FSM::Support::ISFPublicInterfaceContract` advertises the schedule-report
  storage key family and focused provenance tests.

## Selected First Slice

Implement metadata-only declarative fields for scalar actor-owned storage
variables:

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

The first slice changes no generated `.fsm`, HDL, scheduler behavior, or reset
derivation. The parent storage word remains the hardware object. Fields are
checked metadata exposed on the declared storage entry in `inferred_storage[]`.

## Accepted Syntax

- `(fields FIELD...)` is accepted only on scalar `(var ...)` / `(variable ...)`
  storage entries.
- A field form is `(field NAME (bits HI LO) OPTIONS...)`.
- `NAME` must be an HDL identifier and unique within the parent storage word.
- `HI` and `LO` must be non-negative integer literals with `HI >= LO`.
- Optional first-slice field options:
  - `(access TOKEN)`, where `TOKEN` is one of `ro`, `rw`, `wo`, `w1c`, `w0c`,
    `rc`, `rs`, `warl`, `wpri`, or `reserved`.
  - `(reset V)`, where `V` is a non-negative integer literal.
  - `(enum (NAME VALUE)...)`, where every enum name is an HDL identifier and
    every value is a non-negative integer literal.

## Validation

- Every field range must be inside the resolved parent scalar storage width.
- Field ranges may leave gaps; gaps are not inferred as named reserved fields.
- Overlapping field ranges fail closed.
- Field reset values must fit the field width.
- Field reset metadata is accepted only when the parent storage variable also
  carries `(reset PARENT)`, and each field reset must match the corresponding
  bit slice of `PARENT`. The first slice does not derive parent reset values
  from fields.
- Enum values must fit the field width; duplicate enum names or duplicate enum
  values within one field fail closed.
- `fields` on banks and typed aggregate storage carriers fail closed. Scalar
  type-alias storage can be reconsidered after the first width-literal path is
  stable.

## Report Shape

For a declared storage entry, `inferred_storage[]` may include optional
`fields` metadata:

```json
{
  "name": "control",
  "kind": "register",
  "role": "actor_storage",
  "width": 8,
  "fields": [
    {
      "name": "mode",
      "msb": 7,
      "lsb": 5,
      "width": 3,
      "access": "rw",
      "reset": 5,
      "enum": [
        { "name": "IDLE", "value": 0 },
        { "name": "RUN", "value": 5 }
      ]
    }
  ]
}
```

The top-level schedule-report key set remains additive-compatible. The
storage optional-key contract must add `fields`.

## Explicit Deferrals

- No generated field-level HDL, assertions, access-policy enforcement, WARL
  constraints, or register-model output.
- No parent reset derivation from a complete field map.
- No actor `(enums ...)` references from fields.
- No description/provenance text fields until string/token metadata policy is
  selected.
- No banks, aggregate storage carriers, packet/flit layouts, or transaction
  payload structures.

## Implementation Owner

`ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2` implements this first slice with
focused positive and fail-closed tests, public contract metadata, mdBook,
downstream docs, `docs/ISF_SPEC.md`, Knowledge Map, and commit-workflow
evidence.
