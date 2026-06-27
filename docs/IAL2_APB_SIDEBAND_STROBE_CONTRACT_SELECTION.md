# IAL2 APB Sideband/Strobe Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.588`

Date: 2026-06-27

## Summary

`.588` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.589`, direct bounded
implementation of APB `PPROT`/`PSTRB` sideband/strobe behavior for generated
APB IAL2 sources.

The selected contract changes no behavior in `.588`. It records the exact
public source syntax, report/support-accounting shape, diagnostics,
validation, and rollback boundary that `.589` must implement.

## Selected Source Syntax

The first sideband/strobe slice stays fixed to the existing 32-bit APB data
and address width. `PSTRB` width is therefore fixed at 4, one bit per byte
lane. `PPROT` width is fixed at 3.

Requester objects add explicit request-side bindings and bus-side bindings:

```lisp
(request
  (start start)
  (write req_write)
  (address req_addr width 32)
  (write-data req_wdata width 32)
  (protection req_prot width 3)
  (write-strobe req_wstrb width 4))
(bus
  (address PADDR width 32)
  (write PWRITE)
  (write-data PWDATA width 32)
  (protection PPROT width 3)
  (strobe PSTRB width 4)
  (select PSEL)
  (enable PENABLE)
  (ready PREADY)
  (read-data PRDATA width 32)
  (error PSLVERR))
```

Completer bus blocks add the same bus-side bindings:

```lisp
(bus
  (select PSEL)
  (enable PENABLE)
  (write PWRITE)
  (address PADDR width 32)
  (write-data PWDATA width 32)
  (protection PPROT width 3)
  (strobe PSTRB width 4)
  (ready PREADY)
  (read-data PRDATA width 32)
  (error PSLVERR))
```

Composition wiring adds the shared sideband bus signals:

```lisp
(wiring apb_bus
  (select PSEL)
  (enable PENABLE)
  (write PWRITE)
  (address PADDR width 32)
  (write-data PWDATA width 32)
  (protection PPROT width 3)
  (strobe PSTRB width 4)
  (ready PREADY)
  (read-data PRDATA width 32)
  (error PSLVERR))
```

The sideband/strobe clauses are additive sample variants. Existing APB samples
without `PPROT`/`PSTRB` stay valid and keep their current report shape and
residue.

## Selected Semantics

Requester behavior:

- samples `req_prot` and `req_wstrb` with the existing address/write/data
  request fields;
- drives `PPROT` from the sampled protection value in setup/access;
- drives `PSTRB` from sampled `req_wstrb` only for write transfers;
- drives `PSTRB` as zero for read transfers;
- deasserts `PPROT` and `PSTRB` to zero with the existing terminal phase.

Completer behavior:

- samples `PPROT` and `PSTRB` with `PADDR`, `PWRITE`, `PWDATA`, and
  `wait_cycles` during setup detection;
- applies `PSTRB` only to writes that hit a selected register;
- maps `PSTRB[0]` to `PWDATA[7:0]`, `PSTRB[1]` to `PWDATA[15:8]`,
  `PSTRB[2]` to `PWDATA[23:16]`, and `PSTRB[3]` to `PWDATA[31:24]`;
- preserves unselected register bytes;
- treats `PSTRB=4'b0000` as a successful no-byte write when the address hits a
  selected register;
- ignores `PSTRB` on reads;
- keeps unmapped-address `PSLVERR` behavior unchanged;
- samples and reports `PPROT` but does not attach access-control behavior in
  this first slice.

Composition behavior:

- fixed one-requester/one-completer composition wires `PPROT` and `PSTRB`
  between requester and completer;
- multi-peripheral composition forwards `PPROT` and `PSTRB` through the
  generated `apb_interconnect.isf`/`.fsm` to each peripheral-side bus, with
  existing decoded `PSEL` deciding which peripheral observes an active
  transfer;
- response mux and unmapped-address behavior stay unchanged.

## Selected Samples And Support

`.589` shall add sideband-aware `.ppif` and `.apb` sample pairs for:

```text
ppif/apb_requester_transfer_sideband.ppif
ppif/apb_requester_transfer_sideband.apb
ppif/apb_completer_multi_register_sideband.ppif
ppif/apb_completer_multi_register_sideband.apb
ppif/apb_composition_multi_register_sideband.ppif
ppif/apb_composition_multi_register_sideband.apb
ppif/apb_composition_multi_peripheral_sideband.ppif
ppif/apb_composition_multi_peripheral_sideband.apb
```

The selected support-accounting identities mirror those filenames:

```text
intent.ppif_apb_requester_transfer_sideband
intent.apb_profile_alias_requester_transfer_sideband
intent.ppif_apb_completer_multi_register_sideband
intent.apb_profile_alias_completer_multi_register_sideband
intent.ppif_apb_composition_multi_register_sideband
intent.apb_profile_alias_composition_multi_register_sideband
intent.ppif_apb_composition_multi_peripheral_sideband
intent.apb_profile_alias_composition_multi_peripheral_sideband
```

## Reports And Residue

Sideband-aware requester reports must add request/bus sideband bindings and a
`strobe_policy` entry showing write-only `PSTRB` drive with read-zero behavior.

Sideband-aware completer reports must add bus sideband bindings,
`write_strobe`, `byte_lane_policy`, and sampled `protection` metadata.

Sideband-aware composition reports must add sideband propagation metadata for
fixed and multi-peripheral composition. Multi-peripheral interconnect child
reports must also list propagated `PPROT`/`PSTRB` peripheral-side signals.

Sideband-aware reports remove `apb_protection_and_strobes_deferred` and replace
it with the narrower `apb_protection_policy_effects_deferred`, because
protection bits are propagated and sampled but do not implement access-control
semantics in the first slice. `apb_alternate_widths_deferred` and
`apb_back_to_back_policy_deferred` remain.

Existing non-sideband APB samples keep `apb_protection_and_strobes_deferred`.

## Diagnostics

`.589` must reject:

- `PSTRB` widths other than 4;
- `PPROT` widths other than 3;
- request-side sideband fields without matching bus-side fields;
- bus-side sideband fields without required request-side fields for requester
  objects;
- fixed or multi-peripheral composition sideband wiring that does not match
  requester/completer/interconnect signal names and widths;
- sideband clauses in non-APB profiles;
- alternate APB widths in this sideband/strobe slice.

Diagnostics must remain distinct from unsupported object, suffix/profile
mismatch, malformed APB bus, duplicate clause, and unknown suffix diagnostics.

## Validation

The selected implementation owner must run focused syntax checks, direct
schedule/check/semantic/outdir probes for all new sample pairs, preservation
probes for existing APB samples, focused APB prove tests, regression-corpus and
capability-manifest checks, Knowledge Map generation/check, mdBook build,
docs path audit, memory architecture check, diff check, and doctrine gate.

Focused tests should include `t/1470-ial2-apb-profile-alias.t`,
`t/1471-ial2-apb-completer.t`, `t/1472-ial2-apb-composition.t`,
`t/248-regression-corpus-accounting.t`, and
`t/297-capability-manifest.t`.

## Non-Goals

`.588` and the selected `.589` implementation do not add alternate APB
address/data widths, runtime-selected strobe widths, APB protection access
control, side effects beyond byte-lane register writes, back-to-back transfer
admission, multiple requesters, bus matrices, scoreboards, queues, direct
IAL2-to-IAL0 lowering, direct backend lowering, verification-output
generation, backend-language variants, AXI interconnect, AHB interconnect, or
VHDL behavior.

## Rollback

Rollback of `.588` is doc-only: revert this contract, its fact card, task-tree
frontier updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge
Map changes. `.589` rollback, when implemented, must remove the sideband-aware
samples, parser/generator/report/support-accounting/test changes, and docs
while preserving all prior APB behavior.
