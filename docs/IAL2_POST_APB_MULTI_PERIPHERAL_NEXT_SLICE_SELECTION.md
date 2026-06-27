# IAL2 Post-APB Multi-Peripheral Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.586`

Date: 2026-06-27

## Summary

`.586` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.587`, a no-behavior
readiness audit for APB sidebands, strobes, and byte-lane semantics.

The selector changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, schedule/check
JSON, semantic JSON, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Evidence Read

`.585` shipped bounded APB multi-peripheral interconnect/decode through:

```text
ppif/apb_composition_multi_peripheral.ppif
ppif/apb_composition_multi_peripheral.apb
```

The new behavior removed the selected multi-peripheral composition gap by
generating `apb_interconnect.isf`, `apb_interconnect.fsm`, endpoint artifacts,
and `apb_tb.fsm`. The generated interconnect decodes static address windows,
fans out selected `PSEL`, translates local `PADDR`, muxes selected
`PREADY`/`PRDATA`/`PSLVERR`, and returns `PSLVERR` for active unmapped
accesses.

Live schedule probes during `.586` checked the current APB report payloads:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif
```

Those probes showed no live APB residue entries in the checked reports after
the `.585` behavior. A report-cleanup-only slice is therefore not the next
useful owner.

The public language-surface boundary still explicitly defers APB sidebands,
alternate widths, back-to-back policy, direct IAL2-to-IAL0 lowering, direct
backend lowering, verification-output generation, backend-language variants,
and VHDL. The remaining APB feature gap closest to the shipped 32-bit
requester/completer/composition path is sideband/strobe/byte-lane semantics:
`PPROT`, `PSTRB`, byte-enable write behavior, sideband propagation through
fixed and multi-peripheral composition, diagnostics, report fields, samples,
support-accounting, and preservation of existing APB sources.

## Selection

`.587` shall audit APB sidebands/strobes/byte-lane readiness.

The audit must decide whether the next exact owner should be:

- public contract selection for a bounded APB sideband/strobe source shape;
- a lower-layer generated-IAL1 or APB FSM prerequisite;
- parser/static-validation/report readiness work;
- an alternate-width prerequisite before `PSTRB` or byte-lane behavior;
- APB composition/interconnect propagation readiness work; or
- explicit deferral behind a better-supported successor.

This is selected before alternate APB widths, back-to-back transfer admission,
multiple requesters/bus matrices, APB VHDL/C4 parity, AXI/AHB interconnect
readiness, direct backend lowering, and verification-output generation because
the shipped APB path now has enough requester, completer, register decode, and
composition topology coverage to audit local sideband/strobe semantics without
first widening unrelated protocol topology.

## Non-Goals

`.586` does not select implementation. `.587` is an audit, not a behavior
slice. It must not add APB sideband syntax, `PPROT`, `PSTRB`, byte-lane
updates, alternate widths, generated logic, samples, support-accounting
identities, report schema changes, HDL behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, AHB
behavior, or VHDL behavior unless a later owned contract/implementation leaf
selects that work.

## Deferred Work

Alternate APB address/data widths, back-to-back transfer admission, multiple
requesters, bus matrices, scoreboards, queues, side effects beyond the audited
sideband/strobe boundary, direct IAL2-to-IAL0 lowering, direct backend
lowering, verification-output generation, backend-language variants, AXI
interconnect, AHB interconnect, and VHDL remain deferred outside `.586`.

## Validation

The selector closeout validation is documentation and probe focused:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
mdbook build docs/book
git diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is doc-only: revert this selector, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.585` APB multi-peripheral interconnect/decode behavior remains
unchanged.
