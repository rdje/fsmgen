# IAL2 Post-APB Profile Sync Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.600`

Date: 2026-06-27

## Summary

`.600` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.601`, a no-behavior
readiness audit for APB sideband data16 `PPROT` policy effects after the APB
profile-alias public surface was synchronized.

The selector changes no parser behavior, generator behavior, source samples,
support-accounting catalog entries, validation behavior, generated artifacts,
report schemas, schedule/check JSON, semantic JSON, HDL/runtime behavior,
suffix acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.

## Evidence Read

After `.597`, selected sideband-aware 32-bit protection aliases carry
`protection_policy` metadata and use
`apb_additional_protection_policies_deferred`. After `.599`, the profile-alias
public documentation also names that shipped `.apb` surface.

The current remaining APB protection residue with the smallest immediate
surface mismatch is data16 policy effects:

```text
ppif/apb_completer_multi_register_sideband_data16.apb:
  apb_interconnect_multi_peripheral_decode_deferred
  apb_protection_policy_effects_deferred
  apb_remaining_widths_deferred
  apb_back_to_back_policy_deferred
  protection_policy: absent

ppif/apb_composition_multi_peripheral_sideband_data16.apb:
  apb_protection_policy_effects_deferred
  apb_remaining_widths_deferred
  apb_back_to_back_policy_deferred
  protection_policy: absent
```

The APB completer validator currently rejects `access-policy` unless the APB
data width is the selected 32-bit policy shape. The data16 completer and
composition paths already use the same sideband setup sampling, PPROT sample,
PSTRB byte-lane machinery, and denied/unmapped response substrate as the 32-bit
family, but the exact readiness and ownership need to be audited before any
behavior change.

That makes data16 PPROT policy effects the next narrow audit. Additional PPROT
predicate families, global/window/peripheral policies, interconnect-owned
enforcement, back-to-back transfer policy, additional APB topology behavior,
AXI/AHB return, direct backend, verification-output, backend-language variants,
and VHDL remain broader or later owners.

## Selection

`.601` shall audit readiness for sideband data16 APB PPROT policy effects. It
must read this selector, `.599` sync, `.598` selector, `.597` behavior, `.596`
contract, `.595` readiness audit, `.594` data16 behavior, `.589` sideband
behavior, APB profile/behavior docs, current APB reports/residue, PPIF parser,
APB completer/composition generators, RegressionCorpus, LanguageSurfaceSection,
focused APB tests, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge
Map, and relevant IAL2/backend/VHDL decisions.

The audit must decide whether the next exact owner should be data16 PPROT
policy contract selection, a lower-layer repair, a narrower public-surface
cleanup, or explicit deferral. It must settle implementation prerequisites,
report/residue expectations, diagnostics, validation, rollback, direct-backend
deferral, and VHDL deferral before any parser/generator/sample behavior change.

## Non-Goals

`.600` and `.601` do not implement data16 policy effects and do not change
parser behavior, generator behavior, source samples, support-accounting catalog
entries, validation behavior, generated artifacts, report schemas,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix acceptance,
direct backend lowering, verification-output generation, backend-language
variants, APB behavior, AXI behavior, AHB behavior, or VHDL behavior.

## Deferred Work

Data16 policy implementation, additional PPROT predicates,
global/window/peripheral policies, interconnect-owned enforcement,
back-to-back transfer policy, additional APB composition/interconnect behavior,
AXI/AHB return, direct backend lowering, verification-output generation,
backend-language variants, and VHDL remain deferred outside `.600`.

## Validation

The closeout validation for `.600` is documentation and focused-report based:

```bash
perl -MJSON::PP -we 'my $file=shift; my $json=qx(./bin/fsmgen --quiet --emit-schedule-json $file); die "fsmgen failed for $file\n" if $?; my $r=JSON::PP->new->decode($json); my @ids=map { $_->{id} // q{} } @{$r->{unsupported_residue} // []}; print "$file residue=" . join(q{,}, @ids) . " protection_policy=" . (exists($r->{protection_policy}) ? q{yes} : q{no}) . "\n";' ppif/apb_completer_multi_register_sideband_data16.apb
perl -MJSON::PP -we 'my $file=shift; my $json=qx(./bin/fsmgen --quiet --emit-schedule-json $file); die "fsmgen failed for $file\n" if $?; my $r=JSON::PP->new->decode($json); my @ids=map { $_->{id} // q{} } @{$r->{unsupported_residue} // []}; print "$file residue=" . join(q{,}, @ids) . " protection_policy=" . (exists($r->{protection_policy}) ? q{yes} : q{no}) . "\n";' ppif/apb_composition_multi_peripheral_sideband_data16.apb
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is doc-only: revert this selector, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.597` APB PPROT access-policy behavior and `.599` profile-alias
documentation sync remain unchanged.
