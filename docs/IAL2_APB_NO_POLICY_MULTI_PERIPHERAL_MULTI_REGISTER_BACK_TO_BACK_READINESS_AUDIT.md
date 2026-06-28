# IAL2 APB No-Policy Multi-Peripheral Multi-Register Back-To-Back Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.640`
- Date: `2026-06-28`
- Status: selected
- Scope: APB no-policy multi-peripheral multi-register back-to-back timing
  readiness

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.640` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.641`, public contract selection for the
bounded 32-bit sideband-aware no-policy multi-peripheral multi-register
back-to-back timing family.

This audit changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Evidence

Current fixed-composition timing support already covers the no-policy
multi-register endpoint shapes:

- `ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif`
  reports aggregate `back_to_back_policy` over a selected 32-bit sideband
  requester and a two-register no-policy sideband completer with `reg0` at
  byte address `0` and `reg1` at byte address `4`.
- `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif`
  reports aggregate `back_to_back_policy` over a selected sideband data16
  requester and a two-register no-policy sideband data16 completer with
  `reg0` at byte address `0` and `reg1` at byte address `2`.

Current multi-peripheral timing support covers no-policy one-register
peripherals and selected protected two-register status/control peripherals:

- `ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif`
  is 32-bit sideband-aware, two-peripheral, and no-policy, but each
  peripheral has one storage register.
- `ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif`
  is 32-bit sideband-aware and two-register per peripheral, but the storage
  shape is the selected protected status/control family.

In-memory timing candidates confirmed the current validator boundary:

- A 32-bit sideband no-policy multi-peripheral candidate with two registers
  per peripheral fails with the current diagnostic requiring one-register
  peripheral storage or the selected protected status/control storage shape.
- A sideband data16 no-policy multi-peripheral candidate with two registers
  per peripheral fails with the current diagnostic requiring the selected
  sideband data16 protection status/control storage shape.

## Selection

`.641` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.641`: select the public APB
sideband-aware no-policy multi-peripheral multi-register back-to-back
timing-policy contract before implementation.

The selected contract-selection scope is intentionally 32-bit first:

- one requester;
- two peripheral completers;
- APB address/data/register width `32`;
- `PPROT width 3`;
- `PSTRB width 4`;
- no register-local `access-policy` clauses;
- each peripheral has exactly the selected no-policy two-register shape with
  `reg0` at byte address `0` and `reg1` at byte address `4`;
- requester timing is the selected depth-1 queued `accepted/busy/status`
  contract with overflow `reject`;
- every peripheral completer uses adjacent setup admission;
- interconnect decode remains propagation-only and active-access-only for
  unmapped accesses.

`.641` must settle exact public source names, address-map/window requirements,
report/residue movement, support-accounting identities, diagnostics,
validation, rollback, docs, and whether direct implementation can follow.

## Why Not Direct Implementation

The next behavior would introduce a new public multi-peripheral source shape:
no-policy two-register peripheral storage under the multi-peripheral
composition. That source shape is not currently present as a `.ppif` or
`.apb` fixture. A contract-selection slice should settle the public names,
window sizing, register shape, report contract, support identities, and
diagnostics before implementation changes any parser/generator/sample/test or
HDL behavior.

## Deferred Boundaries

The following remain deferred behind future exact owners:

- sideband data16 no-policy multi-peripheral multi-register timing;
- data16-protection generalization beyond the selected status/control family;
- generalized register names, counts, address widths, and wait-count widths;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- broader protection-policy families;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Validation

This audit is documentation-only. Closeout validation is:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
scripts/check_doctrines.sh
git --no-pager diff --check
```

## Rollback

Rollback removes this audit document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, sample, support-accounting, schedule/check/semantic
JSON, generated-artifact, HDL/runtime, suffix, direct-backend,
verification-output, backend-language, APB, AXI, AHB, or VHDL behavior is
changed by this audit.
