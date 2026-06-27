# IAL2 APB Alternate-Width Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.592`

Date: 2026-06-27

## Summary

`.592` audits APB alternate-width readiness after the public APB
sideband/strobe surface was synchronized in `.591`. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.593`, public APB alternate-width contract
selection.

The audit changes no parser behavior, generator behavior, source samples,
support-accounting identities, validation behavior, generated artifacts,
report schemas, schedule/check JSON, semantic JSON, HDL/runtime behavior,
suffix acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.

## Evidence Read

Sideband-aware APB schedule reports still expose alternate widths as explicit
unsupported residue:

```text
ppif/apb_requester_transfer_sideband.ppif:
  apb_multi_peripheral_decode_deferred
  apb_protection_policy_effects_deferred
  apb_alternate_widths_deferred
  apb_back_to_back_policy_deferred

ppif/apb_completer_multi_register_sideband.ppif:
  apb_interconnect_multi_peripheral_decode_deferred
  apb_protection_policy_effects_deferred
  apb_alternate_widths_deferred
  apb_back_to_back_policy_deferred

ppif/apb_composition_multi_register_sideband.ppif:
  apb_interconnect_multi_peripheral_decode_deferred
  apb_protection_policy_effects_deferred
  apb_alternate_widths_deferred
  apb_back_to_back_policy_deferred

ppif/apb_composition_multi_peripheral_sideband.ppif:
  apb_protection_policy_effects_deferred
  apb_alternate_widths_deferred
  apb_back_to_back_policy_deferred
```

The public parser already preserves authored width tokens for APB width-bearing
clauses:

- requester request, response, and bus bindings use `(signal width N)`;
- completer control, bus, storage-address, and storage-data bindings use
  width-bearing clauses;
- composition wiring and address-map windows use width-bearing bus bindings
  and parameter/default clauses.

The behavior validators intentionally pin the current APB slice:

- requester request, response, and bus address/data widths are fixed at 32;
- requester `PPROT` is fixed at 3 and requester/write-side `PSTRB` at 4;
- completer bus, register address, and register data widths are fixed at 32;
- completer `wait_cycles` is fixed at 4;
- multi-register addresses must fit in 32 bits and stay 4-byte aligned;
- multi-peripheral address-map base/size parameters are fixed at width 32;
- composition buses require matching widths across requester, wiring,
  interconnect, and all peripheral completers.

Generated behavior also has hard-coded 32-bit/4-strobe assumptions today:

- requester lowering drives `PSTRB` with four copies of sampled `is_write`;
- completer lowering declares `strb_q` as width 4;
- completer byte-lane writes emit four 32-bit masks;
- multi-peripheral address-map reports and generated interconnect metadata
  publish address width 32.

The lower-layer generated IAL1/IAL0 substrate does not block contract
selection for a bounded static-width APB slice. Existing shipped surfaces
already support width-bearing ports, bitwise operations, concatenation,
`when-bit`, and masked read-modify-write expressions. The prerequisite is a
public APB width contract, not a lower-layer repair, as long as the first
implementation remains a bounded compile-time-width slice.

## Selection

`.593` shall select the public APB alternate-width contract before any behavior
change.

The contract selection must decide:

- whether the first alternate-width slice widens address, data, strobe, and
  wait-count controls together or splits them into smaller behavior owners;
- exact accepted APB address widths and whether address-map base/size
  parameter widths follow the bus address width;
- exact accepted APB write/read/register data widths;
- `PSTRB` derivation from data width, including byte-multiple requirements and
  fail-closed handling for non-byte-multiple data widths;
- whether `PPROT` remains fixed at width 3 in all alternate-width samples;
- wait-count width policy for completer and composition controls;
- register-address alignment and window-size alignment policy relative to the
  selected data width;
- requester, completer, fixed-composition, and multi-peripheral composition
  width compatibility rules;
- generated `apb_requester.isf`, `apb_completer.isf`, `apb_interconnect.isf`,
  `.fsm`, and HDL review-artifact expectations;
- report fields, residue migration, support-accounting identities, sample
  names, diagnostics, focused tests, validation gates, rollback, and the next
  implementation or prerequisite owner.

## Non-Goals

`.592` does not implement alternate APB widths. `.593` is also a contract
selection owner, not behavior work, unless it explicitly selects a later
implementation owner.

`.592` does not change APB source acceptance, parser validation, generator
logic, samples, support-accounting catalog, report schemas, generated review
artifacts, schedule/check/semantic JSON, HDL/runtime behavior, direct
backend lowering, verification-output generation, backend-language variants,
AXI behavior, AHB behavior, or VHDL behavior.

`PPROT` access-control effects, back-to-back transfer admission, multiple
requesters, bus matrices, side effects beyond byte-lane writes, direct
IAL2-to-IAL0 lowering, direct backend lowering, verification-output
generation, backend-language variants, AXI follow-on work, AHB follow-on work,
and VHDL remain deferred outside `.592`.

## Validation

The audit closeout validation is documentation and focused-report based:

```bash
perl -MJSON::PP -e 'for my $path (@ARGV) { open my $fh, q{-|}, qq{./bin/fsmgen}, qq{--quiet}, qq{--emit-schedule-json}, $path or die $!; local $/; my $json = <$fh>; close $fh or die qq{fsmgen failed for $path\n}; my $r = JSON::PP->new->decode($json); my @ids = map { $_->{id} } @{ $r->{unsupported_residue} || [] }; print "$path: ", join(",", @ids), "\n"; }' ppif/apb_requester_transfer_sideband.ppif ppif/apb_completer_multi_register_sideband.ppif ppif/apb_composition_multi_register_sideband.ppif ppif/apb_composition_multi_peripheral_sideband.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is doc-only: revert this audit, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.589` APB sideband/strobe behavior and `.591` public-surface
cleanup remain unchanged.
