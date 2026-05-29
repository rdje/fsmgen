# Packages and Sharing

FSMGen now has a real semantic package lane through `?pkg:name`.

The goal is reuse without falling back to textual include or macro behavior.

## Why Packages Exist

Packages are for sharing:

- named scalar values
- named aggregate values
- enum families
- named type aliases

across multiple `.fsm` roots.

That makes shared intent explicit and keeps user-facing source cleaner.

## Package Shape

```lisp
(?pkg:shared
  (+constants
    (RESET_BYTE 8'hA5)
    (HEADER (1 4'hA))
  )
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1))
  )
  (+types
    (type byte (bits 8))
    (type frame_t (record (mode (bits 2)) (flag bit)))
  )
)
```

## Importing Packages

Use `+import` from direct roots or composition tops.

```lisp
(+import shared)
```

Imported names stay namespaced:

- `shared.RESET_BYTE`
- `shared.mode.BUSY`
- `shared.byte`
- `shared.HEADER`
- `shared.FRAME.flag`

`+import` brings the package namespace into scope; it does not flatten every
package member into the local namespace. That means authors write
`shared.RESET_BYTE`, not `RESET_BYTE`, even when `shared` is already imported.

This is deliberate. Namespaced access avoids implicit global symbol pollution,
keeps ownership obvious during review, prevents ambiguity when two imported
packages define the same member name, and lets diagnostics report the exact
package/member path that failed to resolve.

## Direct-Root Example

```text
(?fsm:uses_shared_values
  (+import shared)
  (+size
    (OUT shared.byte)
  )
  (idle
    (OUT = shared.RESET_BYTE)
  )
)
```

## Composition Example

```text
(?top:uses_shared_pkg
  (+import shared)
  (?ports:public_io
    packed_out>shared.frame_t
  )
  (?wiring:wiring
    /=shared.HEADER/packed_out/
  )
)
```

## Aggregate Values In Packages

Package constants can now be:

- scalar literals
- non-empty lists
- nested record/hash-like aggregates written as `(member value)` pairs

Scalar leaves such as:

- `shared.BYTES[1]`
- `shared.FRAME.flag`
- `shared.NEST.header.nibble`

are available on the live paths.

Whole aggregate roots such as `shared.HEADER`, `shared.TAIL`, and
`shared.FRAME` can also lower when every leaf resolves to one scalar literal.

## Declarative Scope

Package declarations now resolve declaratively rather than purely by order.

That means normal non-cyclic references can point forward or backward within
the same family, while explicit dependency cycles are rejected.

Package `+types` also participate in the same scalar width-symbol model as
direct roots: `(type byte_t (bits BYTE_W))` is accepted when `BYTE_W` is a
positive integer scalar package constant, and enum members such as
`width_e.NIBBLE` may be used the same way. Aggregate scalar leaves,
parameters, runtime signals, and arbitrary expressions are not type-width
symbols.

## Search And Resolution

Package roots may be:

- embedded in the same file
- or resolved from searchable external `.fsm` sources

Search follows the same general model as normal source resolution:

- repeated `--path DIR`
- `FSMLIB`
- local directory context

## What Packages Are Not

Packages are not:

- textual include files
- macro substitution
- implicit global scope
- import-order-dependent symbol pollution

That boundary is important. The package system is meant to be semantic and
explicit.

## Current Boundary

Today, packages are already useful for:

- shared values
- shared aggregate literals
- shared enums
- shared type aliases

Future work is still needed for:

- richer whole-aggregate typed flow
- broader inference-first package typing
- more public embedding/API guarantees around package metadata
