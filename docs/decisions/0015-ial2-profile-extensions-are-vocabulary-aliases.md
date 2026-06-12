# 0015 — IAL2 profile extensions are vocabulary aliases

- Date: 2026-06-12
- Type: architecture
- Status: accepted
- Refines: `docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md`

## Context

Decision `0014` established that IAL2 must remain protocol/platform-generic
and must lower through IAL1 before IAL0. It also treated protocol-specific
file extensions such as `.axi` as out of bounds.

The user then clarified an important nuance: IAL2 will likely have different
vocabularies for each protocol and chip-spec domain. That means protocol
profile extensions such as `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
`.smbus`, `.i2s`, and similar names might be useful if they are treated as
profile entrypoints over IAL2, not as separate semantic layers.

## Decision

IAL2 remains one architectural layer.

Generic protocol/platform containers such as `.pif`, `.ppi`, or `.ppif`
remain valid candidates for the broad IAL2 file surface.

Protocol-specific extensions may also be accepted later as vocabulary/profile
aliases. For example, a future `.axi` file can be equivalent to a generic IAL2
file that declares an AXI vocabulary/profile inside the file.

Protocol-specific extensions are not separate language layers, do not get
special direct-lowering privileges, and must not fragment the compiler
architecture.

The mandatory lowering chain remains:

```text
IAL2 -> IAL1 / .isf -> IAL0 / .fsm -> HDL
```

Direct IAL2-to-IAL0 lowering remains forbidden for generic IAL2 files and
for any future protocol-profile extension.

## Consequences

- Decision `0014` remains correct about generic IAL2 containers and layered
  lowering, but its blanket rejection of protocol-specific extensions is
  refined.
- Future IAL2 design may support both forms:
  - a generic file that declares a protocol/platform vocabulary internally,
  - and profile-specific file extensions that imply that vocabulary.
- Profile extensions must be documented as aliases/profiles over the same IAL2
  model.
- Profile extensions must emit the same reports, source anchors, residue, and
  reviewable IAL1 as generic IAL2 input.
- Any future profile-extension implementation requires its own exact task-tree
  owner.
