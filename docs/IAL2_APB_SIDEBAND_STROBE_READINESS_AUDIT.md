# IAL2 APB Sideband/Strobe Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.587`

Date: 2026-06-27

## Summary

`.587` audits APB sidebands, strobes, and byte-lane readiness after bounded
APB multi-peripheral interconnect/decode shipped. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.588`, public contract selection for a
bounded APB sideband/strobe source shape.

The audit changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, schedule/check
JSON, semantic JSON, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Correction From `.586`

During `.587`, the schedule-report probe was tightened to the actual public
field name, `unsupported_residue`. The earlier `.586` selector wording that
described the checked APB reports as having no APB residue entries was too
narrow because it inspected only a non-existent `residue` field.

The correct live evidence is:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif
```

Top-level multi-peripheral composition now removes the top-level
multi-peripheral decode residue, but it still reports:

```text
apb_protection_and_strobes_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

The older endpoint and fixed-composition samples intentionally retain their
own narrower topology residues, and all checked APB surfaces still report
`apb_protection_and_strobes_deferred`.

## Current Surface

The shipped APB IAL2 bus blocks currently include the core APB signals only:

```text
PSEL
PENABLE
PWRITE
PADDR[31:0]
PWDATA[31:0]
PREADY
PRDATA[31:0]
PSLVERR
```

There is no accepted source syntax for `PPROT`, `PSTRB`, byte-enable policy, or
APB4/APB5 sideband behavior. The public parser fails closed if sideband clauses
are authored today:

```text
(strobe PSTRB width 4)      -> unsupported clause '(strobe ...)'
(protection PPROT width 3)  -> unsupported clause '(protection ...)'
```

The APB requester, completer, fixed-composition, and multi-peripheral
composition generators all enforce 32-bit address/write-data/read-data widths
in the current APB slices. Their reports explicitly keep
`apb_protection_and_strobes_deferred`, `apb_alternate_widths_deferred`, and
`apb_back_to_back_policy_deferred`.

## Lowering Readiness

The generated-IAL1/IAL0 path already has enough expression and assignment
surface to select a public sideband/strobe contract before implementation:

- APB generated sources already lower through generated `.isf` before
  generated `.fsm`.
- IAL1/IAL0 support fixed-width ports, bitwise `&`, `|`, and `^`, shifts,
  concatenation, and masked field update desugaring.
- Existing tests cover bit operations, `set-field`, concatenation, and APB
  generated requester/completer/composition lowering.
- The current parser rejects unselected sideband clauses instead of silently
  accepting or ignoring them.

That is enough for contract selection. Implementation is still blocked until a
contract settles the exact public syntax and byte-lane semantics.

## Selection

`.588` shall select the public APB sideband/strobe contract.

The contract selection must decide:

- whether the first bounded slice includes both `PPROT` and `PSTRB`, or splits
  protection from byte strobes;
- exact source syntax under requester, completer, and composition bus blocks;
- whether sideband clauses are optional or require new sample variants;
- fixed 32-bit first-slice policy and `PSTRB` width 4 derivation, while keeping
  alternate APB widths deferred;
- write-byte enable semantics for completer register updates;
- propagation through fixed one-requester/one-completer composition and
  multi-peripheral interconnect/decode composition;
- generated `apb_requester.isf`, `apb_completer.isf`, `apb_interconnect.isf`,
  and `.fsm` review-artifact expectations;
- report fields, `unsupported_residue` migration, support-accounting
  identities, capability-manifest wording, diagnostics, tests, mdBook examples,
  validation gates, and rollback.

## Non-Goals

`.587` does not select implementation. `.588` is a contract-selection owner,
not behavior work. The next implementation owner must be selected only after
`.588` settles the public contract.

Alternate APB address/data widths, back-to-back transfer admission, multiple
requesters, bus matrices, scoreboards, queues, direct IAL2-to-IAL0 lowering,
direct backend lowering, verification-output generation, backend-language
variants, AXI interconnect, AHB interconnect, and VHDL remain deferred outside
`.587`.

## Validation

The audit closeout validation is documentation and probe focused:

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

Temporary `/tmp` mutations of APB requester, completer, and multi-peripheral
composition sources also confirmed that unselected `(strobe ...)` and
`(protection ...)` bus clauses fail closed with unsupported-clause diagnostics.

## Rollback

Rollback is doc-only: revert this audit, its fact card, the `.586` correction,
task-tree frontier updates, README, ROADMAP_V2, mdBook, Memory, and generated
Knowledge Map changes. The `.585` APB multi-peripheral interconnect/decode
behavior remains unchanged.
