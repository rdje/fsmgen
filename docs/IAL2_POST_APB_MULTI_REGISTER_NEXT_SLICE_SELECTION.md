# IAL2 Post-APB Multi-Register Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.582`

Date: 2026-06-27

## Summary

`.582` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.583`, a no-behavior
readiness audit for APB multi-peripheral interconnect/decode.

The selector changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, schedule/check
JSON, semantic JSON, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior.

## Evidence Read

The `.581` implementation shipped additive APB multi-register completer decode
through these public samples:

```text
ppif/apb_completer_multi_register.ppif
ppif/apb_completer_multi_register.apb
ppif/apb_composition_multi_register.ppif
ppif/apb_composition_multi_register.apb
```

Multi-register completer and composition reports now remove
`apb_multi_register_decode_deferred` for the new multi-register samples while
preserving the older one-register sample report shape and residue.

Live schedule probes during `.582` confirmed the current APB residue:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif
```

The multi-register composition report still carries:

```text
apb_interconnect_multi_peripheral_decode_deferred
apb_protection_and_strobes_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

The requester report still carries its own APB topology residue:

```text
apb_multi_peripheral_decode_deferred
```

## Selection

`.583` shall audit APB multi-peripheral interconnect/decode readiness.

This is the next exact owner because APB now has:

- requester-transfer behavior through `.ppif` and `.apb`;
- completer behavior through `.ppif` and `.apb`;
- fixed requester/completer composition;
- requester busy/status outputs in fixed composition;
- completer multi-register decode in standalone and fixed-composition shapes.

The remaining APB topology gap is broader than register-local decode: the
public composition model still wires exactly one requester to exactly one
completer. Multi-peripheral interconnect/decode needs a readiness audit before
contract selection or implementation because it must settle source shape,
child/peripheral list semantics, address-map ownership, decode priority,
response muxing, diagnostics, report schema, sample/support-accounting scope,
and preservation of the existing fixed-composition samples.

## Why Not Sidebands Or Widths First

`PPROT`, `PSTRB`, byte lanes, APB4/APB5 sideband policy, alternate data/address
widths, and back-to-back transfer admission remain important, but they are not
the next owner. Multi-peripheral topology changes the APB composition contract
and report shape, while sideband/width/back-to-back work can remain local to a
single requester/completer path until the topology boundary is understood.

## Non-Goals

`.582` does not select implementation. `.583` is an audit, not a behavior
slice. It must not add multi-peripheral source syntax, parser acceptance,
generated interconnect logic, samples, support-accounting identities, report
schema changes, HDL behavior, direct backend lowering, verification-output
generation, backend-language variants, AXI behavior, or VHDL behavior.

## Deferred Work

Side effects, byte lanes, `PPROT`, `PSTRB`, APB4/APB5 sidebands, alternate APB
widths, back-to-back transfer admission, APB report cleanup outside the
selected topology audit, another protocol surface, direct backend lowering,
verification-output generation, backend-language variants, AXI follow-on
behavior, and VHDL remain deferred outside `.582`.

## Validation

The selector closeout validation is documentation and probe focused:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
scripts/check_docs_relative_paths.sh
mdbook build docs/book
git diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is doc-only: revert this selector, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.581` APB multi-register behavior remains unchanged.
