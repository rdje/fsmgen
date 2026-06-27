# IAL2 Post-APB Sideband/Strobe Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.590`

Date: 2026-06-27

## Summary

`.590` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.591`, a public-surface and
report-static cleanup owner after bounded APB `PPROT`/`PSTRB` behavior shipped.

The selector changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, schedule/check
JSON, semantic JSON, HDL/runtime behavior, suffix acceptance, direct backend
lowering, verification-output generation, backend-language variants, APB
behavior, AXI behavior, AHB behavior, or VHDL behavior.

## Evidence Read

`.589` shipped bounded APB sideband/strobe behavior through:

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

The current parser/generator/report code and focused APB tests show that
sideband-aware APB reports now remove the broad
`apb_protection_and_strobes_deferred` residue and retain narrower remaining
residue:

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

That evidence makes immediate APB alternate widths, `PPROT` access-control
effects, and back-to-back transfer policy real candidates. However,
`FSM::Support::LanguageSurfaceSection` still has stale `.ppif` manifest prose
that lists "APB sidebands" as deferred and omits the sideband-aware APB
`.ppif` coverage in its generic `.ppif` paragraph, even though the `.apb`
paragraph and behavior docs already describe sideband support. That is a
public-surface drift after `.589`, and the project doctrine requires roadmap,
codebase, reports, and mdBook-facing surfaces to stay aligned before deeper
feature widening.

The first post-sideband owner is therefore a bounded public-surface/report
static cleanup slice, not APB alternate widths or `PPROT` policy behavior.

## Selection

`.591` shall synchronize APB public-surface/report-static wording after `.589`.
It must read this selector, `.589` behavior, `.588` contract,
`FSM::Support::LanguageSurfaceSection`, APB reports/residue, RegressionCorpus,
focused APB/profile-alias/manifest tests, README, ROADMAP_V2, mdBook, task
tree, Memory, Knowledge Map, and relevant IAL2/backend/VHDL decisions.

The cleanup owner may update public/static wording and tests that cover that
wording, but it must not change APB source acceptance, parser semantics,
generator semantics, generated artifacts, report schemas, schedule/check/
semantic JSON behavior except corrected static manifest/report prose,
HDL/runtime behavior, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, AHB behavior, or VHDL behavior.

After that cleanup, the next selector can fairly compare APB alternate widths,
`PPROT` access-control effects, back-to-back transfer policy, additional APB
composition/interconnect behavior, AXI/AHB return, direct backend, and VHDL
work from an aligned public surface.

## Non-Goals

`.590` does not select implementation of APB alternate widths, `PPROT`
access-control effects, back-to-back requester admission, additional APB
composition/interconnect behavior, direct backend lowering, verification-output
generation, backend-language variants, AXI behavior, AHB behavior, or VHDL
behavior.

`.591` is also not a protocol-behavior slice. It must not accept new APB source
syntax, add new APB samples, add new support identities, modify generated
`PPROT`/`PSTRB` logic, widen APB widths, or alter generated HDL/runtime
behavior unless a later task-tree owner explicitly selects that work.

## Deferred Work

APB alternate address/data/strobe widths, `PPROT` access-control effects,
back-to-back transfer admission, multiple requesters, bus matrices, side
effects beyond byte-lane writes, direct IAL2-to-IAL0 lowering, direct backend
lowering, verification-output generation, backend-language variants, AXI
follow-on work, AHB follow-on work, and VHDL remain deferred outside `.590`.

## Validation

The closeout validation for `.590` is documentation and focused-report based:

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

The RAM-guarded batch form of the same four schedule probes stopped
immediately because the host-memory baseline was already above the default 88%
cutoff. No RAM-guard cutoff raise was used.

## Rollback

Rollback is doc-only: revert this selector, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.589` APB sideband/strobe behavior remains unchanged.
