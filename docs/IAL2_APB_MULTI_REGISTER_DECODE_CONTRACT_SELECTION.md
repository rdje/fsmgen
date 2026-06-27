# IAL2 APB Multi-Register Decode Contract Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.580`

Date: 2026-06-27

## Summary

`.580` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.581`, direct bounded
implementation of APB multi-register completer decode for generated APB
completer and fixed-composition IAL2 surfaces. This selector changes no
behavior.

## Selected Source Syntax

The public source syntax reuses the existing `(storage ...)` block and accepts
one or more repeated `(register ...)` clauses:

```text
(storage
  (register reg0
    (address 0 width 32)
    (data reg0_data_q width 32 reset 0))
  (register reg1
    (address 4 width 32)
    (data reg1_data_q width 32 reset 0)))
```

No new register-map wrapper is selected for the first implementation. Existing
single-register sources remain valid and keep their existing generated behavior
and report shape.

## Selected First-Slice Rules

The first multi-register slice is intentionally bounded:

- Register order is source order.
- Register names must be unique ISF identifiers.
- Register data signal names must be unique and must not collide with APB bus,
  control, reset, or generated local names.
- Register addresses must be decimal non-negative integers, width 32,
  unique, and 4-byte aligned.
- Register data width remains 32 for every selected register.
- Register reset remains 0 for every selected register.
- Transfer policy remains `(read register)`, `(write register)`, and
  `(unmapped-address error)`.
- APB setup detection remains `(setup-detect (select 1) (enable 0))`.
- `wait_cycles` remains a 4-bit runtime input.

Byte lanes, per-register access permissions, side effects, non-zero reset
values, alternate data/address widths, range decode, arrays, and APB sideband
semantics remain future work.

## Selected Decode Behavior

Generated APB completers shall sample `PADDR`, `PWRITE`, `PWDATA`, and
`wait_cycles` during setup as they do today. After the runtime wait count:

- a write to a selected register address updates that register, asserts
  `PREADY`, drives `PRDATA` to 0, and keeps `PSLVERR` low;
- a read from a selected register address asserts `PREADY`, drives `PRDATA`
  from that register, and keeps `PSLVERR` low; and
- an unmapped address asserts `PREADY`, drives `PRDATA` to 0, and asserts
  `PSLVERR`.

Duplicate addresses are rejected, so no generated priority rule is exposed as
public behavior. Emission may still visit registers in source order for stable
generated text and deterministic tests.

## Selected Samples And Support Accounting

`.581` shall add these public samples:

```text
ppif/apb_completer_multi_register.ppif
ppif/apb_completer_multi_register.apb
ppif/apb_composition_multi_register.ppif
ppif/apb_composition_multi_register.apb
```

The selected fixed-composition samples should use the latest busy-plus-status
requester response shape so APB requester busy/status residues do not reappear
in the new composition fixtures.

Selected support identities:

```text
intent.ppif_apb_completer_multi_register
intent.apb_profile_alias_completer_multi_register
intent.ppif_apb_composition_multi_register
intent.apb_profile_alias_composition_multi_register
```

Existing one-register completer and composition samples remain unchanged.

## Selected Reports

Existing one-register reports remain unchanged:

```text
bindings.storage.register
transfer.register
```

Multi-register reports use additive list fields:

```text
bindings.storage.registers[]
transfer.registers[]
```

The list order is source order. Each register entry carries the selected
register name, address value/width, data signal name/width/reset, and generated
storage signal. Multi-register completer reports remove
`apb_multi_register_decode_deferred`; other APB residues remain. Multi-register
composition reports inherit the child completer register list, expose the
status-capable requester metadata, and remove the composition-level
`apb_multi_register_decode_deferred` residue. Existing one-register reports
keep their current residue and singular fields.

The report schema strings remain:

```text
fsmgen.ial2.protocol_intent.apb_completer.v1
fsmgen.ial2.protocol_intent.apb_composition.v1
```

The change is additive for new multi-register samples and preservation-only for
existing samples.

## Selected Diagnostics

`.581` shall add targeted diagnostics for:

- empty APB completer storage;
- duplicate register names;
- duplicate register data signal names;
- duplicate register addresses;
- unaligned register addresses;
- non-32-bit register address widths;
- non-32-bit register data widths; and
- non-zero register resets.

Existing diagnostics for unsupported clauses, missing required clauses,
profile mismatch, role mismatch, and transfer policy mismatch remain.

## Selected Generated Artifacts

Generated review artifacts and HDL module names remain stable:

```text
apb_completer.isf
apb_completer.fsm
apb_tb.fsm
apb_completer
apb_tb
```

Generated ISF and generated IAL0 may introduce per-register internal drive
names, but they must be deterministic, source-order stable, and covered by
focused tests. Existing one-register generated text is preserved.

## Validation Required For `.581`

The implementation slice must include:

- parser/generator syntax checks for touched modules and tests;
- focused APB prove tests for completer, composition, profile aliases, support
  accounting, and capability manifest;
- direct schedule/check/semantic/outdir probes for all four new
  multi-register samples;
- preservation probes for existing one-register completer and composition
  samples;
- diagnostics probes for duplicate names, duplicate addresses, unaligned
  addresses, bad widths, bad resets, and current deferral boundaries;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and behavior
  record updates; and
- doctrine closeout gates.

## Non-Goals

`.580` changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts,
schedule/check/semantic JSON, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior.

## Deferred Work

Multi-peripheral APB interconnect/topology, PPROT/PSTRB, byte lanes, register
side effects, access permissions, range decode, register arrays, alternate APB
widths, back-to-back transfer policy, status-only/status-enum/status-sticky
requester work, direct backend lowering, verification-output generation,
backend-language variants, AXI follow-on behavior, and VHDL remain deferred
outside `.580`.

## Rollback

Rollback is doc-only: revert this selector, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. `.579` remains a completed readiness audit and no APB behavior changes
are included in this selector.
