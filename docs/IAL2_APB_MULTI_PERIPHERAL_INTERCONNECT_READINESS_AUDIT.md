# IAL2 APB Multi-Peripheral Interconnect/Decode Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.583`

Date: 2026-06-27

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.583` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.584`, APB multi-peripheral
interconnect/decode public contract selection.

Direct behavior implementation is not ready. The shipped APB surface can now
generate requester-transfer, completer, fixed one-requester/one-completer
composition, requester busy/status variants, and completer multi-register
decode. It still has no public contract for multiple APB completer peripherals,
address-map entries, decode ordering, request fanout, response muxing, or
multi-peripheral diagnostics.

The reusable-view decision is APB-specific: the next contract should select an
IAL2 APB topology/address-map source intent that lowers into a generated,
reusable APB IAL1 review artifact before generated IAL0 `.fsm` and HDL. The
audit does not select a standalone reusable IAL2 interconnect object and does
not select any cross-protocol implementation. Topology and address-map
configuration must be expressed through source-level parameter/generic-like
bindings at instantiation time, then materialized in the generated APB-specific
IAL1 review artifact.

AXI and AHB remain behind separate protocol-specific owners. APB, AXI, and AHB
have different signal sets and protocol contracts, so their multi-peripheral
interconnect/decode implementations cannot share logic.

No source syntax, parser behavior, generator behavior, samples,
support-accounting, validation behavior, schedule/check/semantic JSON behavior,
generated artifacts, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, AHB behavior, or VHDL behavior changed in this audit slice.

## Evidence Read

The audit read the `.582` selector, `.581` multi-register behavior, `.580`
multi-register contract, APB requester/completer/composition/profile-alias
behavior pages, current APB schedule reports and residue,
`ppif/apb_requester_transfer_status.ppif`,
`ppif/apb_completer_multi_register.ppif`,
`ppif/apb_composition_multi_register.ppif`,
`ppif/apb_composition_status.ppif`, the PPIF parser, `ApbRequesterTransfer`,
`ApbCompleter`, `ApbComposition`, `RegressionCorpus`,
`LanguageSurfaceSection`, focused APB tests, README, ROADMAP_V2, mdBook, task
tree, Memory, Knowledge Map, user input on reusable parameterized
interconnect/decode views, and relevant IAL2 decisions.

Live schedule probes confirmed the current APB residue boundary:

```text
ppif/apb_composition_multi_register.ppif
  schema: fsmgen.ial2.protocol_intent.apb_composition.v1
  mode: requester-completer-composition
  residue: apb_interconnect_multi_peripheral_decode_deferred,
           apb_protection_and_strobes_deferred,
           apb_alternate_widths_deferred,
           apb_back_to_back_policy_deferred
  child_instance_count: 2
  child roles: requester, completer

ppif/apb_composition_status.ppif
  schema: fsmgen.ial2.protocol_intent.apb_composition.v1
  mode: requester-completer-composition
  residue: apb_interconnect_multi_peripheral_decode_deferred,
           apb_multi_register_decode_deferred,
           apb_protection_and_strobes_deferred,
           apb_alternate_widths_deferred,
           apb_back_to_back_policy_deferred
  child_instance_count: 2
  child roles: requester, completer

ppif/apb_completer_multi_register.ppif
  schema: fsmgen.ial2.protocol_intent.apb_completer.v1
  mode: completer
  residue: apb_interconnect_multi_peripheral_decode_deferred,
           apb_protection_and_strobes_deferred,
           apb_alternate_widths_deferred,
           apb_back_to_back_policy_deferred

ppif/apb_requester_transfer_status.ppif
  schema: fsmgen.ial2.protocol_intent.apb_requester_transfer.v1
  mode: requester-transfer
  residue: apb_multi_peripheral_decode_deferred,
           apb_protection_and_strobes_deferred,
           apb_alternate_widths_deferred,
           apb_back_to_back_policy_deferred
```

## Current Boundary

The parser and public sample shape support exactly one APB requester object,
exactly one APB completer object, and exactly one APB composition object for
composition sources. The composition child block accepts a requester child and
a completer child; it has no peripheral list, no address-map block, no decode
priority field, no response-mux clause, and no instantiation-time topology
binding syntax.

`ApbComposition` currently generates two child artifacts and point-to-point APB
bus wiring:

```text
requester.PSEL    -> completer.PSEL
requester.PENABLE -> completer.PENABLE
requester.PWRITE  -> completer.PWRITE
requester.PADDR   -> completer.PADDR
requester.PWDATA  -> completer.PWDATA
completer.PREADY  -> requester.PREADY
completer.PRDATA  -> requester.PRDATA
completer.PSLVERR -> requester.PSLVERR
```

This is fixed requester/completer composition, not multi-peripheral APB decode.
The existing report schema records `child_instance_count => 2`, child modules
`apb_requester` and `apb_completer`, and
`apb_bus_wiring => explicit_requester_completer_point_to_point`. It does not
record selected peripheral windows, decoded `PSEL` outputs, response mux
priority, or unmapped-address routing.

## Readiness Gaps

`.584` must select the public source contract before implementation can begin:

- Source shape: whether multi-peripheral APB remains an expanded
  `(apb-composition ...)` form or introduces a narrower APB-specific clause
  inside that composition.
- Child/peripheral list: how one requester and N APB completers are named,
  referenced, ordered, and exposed in generated report fields.
- Address map: syntax for base/size or explicit ranges, alignment rules,
  uniqueness/overlap policy, address-width bounds, and whether register-local
  completer addresses compose under peripheral base addresses.
- Decode priority: deterministic source-order, explicit priority, or
  fail-closed no-overlap-only behavior.
- Response mux: selected `PREADY`, `PRDATA`, and `PSLVERR` mux behavior,
  unmapped-address response, idle/default response, and interaction with
  wait-state behavior.
- Diagnostics: duplicate child names, unknown child references, non-completer
  child references, empty peripheral maps, overlapping address windows,
  unaligned ranges, unsupported widths, duplicate exported signal names, and
  malformed parameter/generic-like bindings.
- Report schema: additive fields for peripherals, address maps, generated
  decode artifacts, decoded `PSEL` signals, response mux metadata, and
  preserved one-requester/one-completer report compatibility.
- Samples/support/tests: new `.ppif` and `.apb` multi-peripheral samples,
  support-accounting identities, parser diagnostics, schedule/check/semantic
  probes, generated review-artifact checks, and preservation probes for all
  current APB samples.
- Lowered reusable review artifact: an APB-specific generated IAL1 artifact
  should capture the parameterized topology/address map before generated IAL0
  `.fsm` and HDL, preserving the mandatory IAL2 -> IAL1 -> IAL0 -> HDL chain.

## Next Owner

`IAL2-FEATURE-COMPLETENESS-FRONTIER.584` should select the APB
multi-peripheral interconnect/decode public contract and still make no
behavior changes. It must choose the exact source vocabulary, parameter/
generic-like binding model, generated APB-specific IAL1 review artifact shape,
generated IAL0/HDL expectations, report schema, diagnostics, sample/support
scope, validation gates, mdBook/doc/fact updates, rollback boundary, and
preservation probes.

Direct implementation, parser widening, generator widening, sample additions,
support-accounting additions, report-schema behavior changes, and generated
artifact behavior changes remain forbidden until `.584` has selected the
contract and advanced to a separate implementation owner.

## Preservation And Deferral

The following behavior remains unchanged and must be preserved by `.584` and
any later implementation:

- existing requester-transfer `.ppif` and `.apb` samples;
- existing APB completer `.ppif` and `.apb` samples;
- existing fixed one-requester/one-completer composition `.ppif` and `.apb`
  samples;
- busy-capable and status-capable requester/composition samples;
- multi-register completer and status-capable composition samples;
- one-register report compatibility and multi-register `registers[]` report
  fields; and
- explicit APB residue for sidebands/strobes, alternate widths, and
  back-to-back policy.

Side effects, byte lanes/strobes, protection and sideband signals, alternate
APB widths, back-to-back transfer policy, direct backend lowering,
verification-output generation, backend-language variants, AXI follow-on,
AHB follow-on, and VHDL remain deferred outside `.583`.

Rollback for this audit is documentation-only: revert this audit record,
Knowledge Map fact, task-tree advancement, README/ROADMAP/mdBook sync, and
Memory update. No generated artifacts or runtime behavior are affected.

## Validation

The closeout validation for `.583` is documentation and continuity validation:

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
git --no-pager diff --check
scripts/check_doctrines.sh
```
