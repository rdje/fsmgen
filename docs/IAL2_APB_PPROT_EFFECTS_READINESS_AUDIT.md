# IAL2 APB PPROT Effects Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.595`

Date: 2026-06-27

## Summary

`.595` audits APB `PPROT` access-control effects readiness after
sideband-aware APB data16 behavior shipped. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.596`, public APB `PPROT`
access-control effects contract selection, before any behavior change.

The audit changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, schedule/check
JSON, semantic JSON, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Current Surface

The shipped sideband-aware APB requester, completer, fixed composition, and
multi-peripheral composition samples already carry `PPROT` as a 3-bit signal:

- requester sources sample `(protection req_prot width 3)` and drive
  bus-side `(protection PPROT width 3)`;
- completer sources sample bus-side `(protection PPROT width 3)` during APB
  setup detection;
- fixed composition wires requester `PPROT` directly to the completer;
- multi-peripheral composition forwards `PPROT` through generated
  `apb_interconnect.isf`/`.fsm` to each peripheral-side bus;
- sideband-aware data16 variants preserve the same `PPROT` width and
  propagation while changing only data/strobe width.

The generated behavior currently treats `PPROT` as propagated metadata only.
No shipped APB source has public policy vocabulary for privileged,
secure/non-secure, instruction/data, read/write, address-window, register, or
peripheral-local access control.

## Current Reports And Residue

Sideband-aware APB reports use:

```text
apb_protection_policy_effects_deferred
```

That residue is intentionally narrower than the older broad
`apb_protection_and_strobes_deferred`: `PPROT` and `PSTRB` transport is
implemented, while `PPROT` policy effects remain unimplemented.

After `.594`, selected data16 reports also use
`apb_remaining_widths_deferred` for future APB width families. The remaining
APB behavior residues are therefore separable:

- `PPROT` access-control effects;
- back-to-back transfer policy;
- APB address widths other than 32;
- wait-count widths other than 4;
- data widths beyond the selected sideband-aware 16/32-bit boundary.

## Readiness Findings

The implementation substrate is ready for public contract selection:

- APB generated sources already lower through generated `.isf` before
  generated `.fsm`.
- Requester, completer, fixed composition, and multi-peripheral composition
  generators already know whether a source is sideband-aware.
- Completer lowering already samples `PPROT` into local state during setup,
  which is the natural point for deciding the access result for the selected
  APB transfer.
- Existing generated IAL1/IAL0 supports fixed-width ports, constants,
  comparisons, bit tests, boolean expressions, and conditional actions needed
  for bounded static policy checks.
- Multi-peripheral composition already preserves decoded select, local address
  translation, response muxing, and unmapped active-access `PSLVERR`; a future
  policy contract can decide whether policy checks live only in completers or
  also in interconnect/window decode.

No lower-layer repair is selected before public contract selection.

## Selection

`.596` shall select the public APB `PPROT` access-control effects contract.

The contract selection must decide:

- exact public source vocabulary for protection policies;
- whether the first policy applies globally to a completer, per register, per
  address window, per peripheral, or only to a single bounded sample family;
- whether policy checks affect reads, writes, or both;
- how denied accesses drive `PREADY`, `PRDATA`, `PSLVERR`, requester `done`,
  `error`, `read_data`, and status-capable `status`;
- whether denied writes are side-effect-free, including when `PSTRB` selects
  one or more byte lanes;
- how `PSTRB=0` mapped writes interact with protection denial;
- how fixed and multi-peripheral composition propagate or aggregate denial;
- report fields, `unsupported_residue` migration, support-accounting
  identities, diagnostics, samples, focused tests, mdBook examples, validation
  gates, and rollback.

The likely first implementation owner after `.596` should stay bounded to
sideband-aware APB completer and composition behavior. Requester transport
already propagates `PPROT`; requester-observable effects should follow from
the completer/interconnect response.

## Non-Goals

`.595` does not select implementation. `.596` is a contract-selection owner,
not behavior work.

This audit does not add policy vocabulary, parser acceptance, sample files,
support identities, generated behavior, report schema fields, runtime policy
effects, direct IAL2-to-IAL0 lowering, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

Back-to-back transfer policy, APB address widths other than 32, wait-count
widths other than 4, data widths beyond the selected sideband-aware 16/32-bit
boundary, multiple requesters, bus matrices, scoreboards, queues, AXI
follow-on, AHB follow-on, and VHDL remain deferred.

## Validation

The audit closeout validation is documentation and static-surface focused:

```bash
rg -n 'apb_protection_policy_effects_deferred|PPROT|protection access-control' \
  perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm \
  perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm \
  perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm \
  docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md \
  docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
scripts/check_doctrines.sh
```

## Rollback

Rollback of `.595` removes this audit record, its Knowledge Map fact card, and
the README/ROADMAP/mdBook/task-tree/memory updates that select `.596`. Because
`.595` is documentation-only, `.594` sideband-aware APB data16 behavior remains
unchanged.
