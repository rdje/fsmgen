# IAL2 Post-APB PPROT Access-Policy Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.598`

Date: 2026-06-27

## Summary

`.598` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.599`, a no-behavior APB
profile-alias/public-surface synchronization owner after bounded APB `PPROT`
register-local access-policy behavior shipped.

The selector changes no parser behavior, generator behavior, source samples,
support-accounting catalog entries, validation behavior, generated artifacts,
schedule/check JSON, semantic JSON, HDL/runtime behavior, suffix acceptance,
direct backend lowering, verification-output generation, backend-language
variants, APB behavior, AXI behavior, AHB behavior, or VHDL behavior.

## Evidence Read

`.597` shipped selected sideband-aware 32-bit multi-register APB protection
behavior through:

```text
ppif/apb_completer_multi_register_sideband_protection.ppif
ppif/apb_completer_multi_register_sideband_protection.apb
ppif/apb_composition_multi_register_sideband_protection.ppif
ppif/apb_composition_multi_register_sideband_protection.apb
ppif/apb_composition_multi_peripheral_sideband_protection.ppif
ppif/apb_composition_multi_peripheral_sideband_protection.apb
```

The current parser, APB completer/composition generators, RegressionCorpus,
LanguageSurfaceSection, and focused APB tests show that the code/support surface
already recognizes those `.apb` protection aliases. Live report probes confirm
that selected protection aliases now carry `protection_policy` metadata and use
`apb_additional_protection_policies_deferred`:

```text
ppif/apb_completer_multi_register_sideband_protection.apb:
  apb_interconnect_multi_peripheral_decode_deferred
  apb_additional_protection_policies_deferred
  apb_alternate_widths_deferred
  apb_back_to_back_policy_deferred
  protection_policy: present

ppif/apb_composition_multi_peripheral_sideband_protection.apb:
  apb_additional_protection_policies_deferred
  apb_alternate_widths_deferred
  apb_back_to_back_policy_deferred
  protection_policy: present
```

The same probes show that data16 sideband aliases correctly keep the older
`apb_protection_policy_effects_deferred` residue and have no
`protection_policy`, because data16 policy effects remain deferred:

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

That makes APB back-to-back policy, additional PPROT policy families, data16
PPROT policy effects, additional APB composition/interconnect behavior, AXI/AHB
return, direct backend work, verification-output work, backend-language/VHDL
work, and public-surface cleanup real candidates. However,
`docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md` still has public-profile drift after
`.597`: the supported sample lists include protection aliases, but the
support-accounting and CLI example sections omit the protection alias entries,
and the non-goals section still says `PPROT` access-control effects remain
deferred. The code, reports, corpus, language surface, README, ROADMAP, and
mdBook now treat bounded 32-bit protection policy effects as shipped.

The next exact owner is therefore a public-surface synchronization slice before
any deeper APB behavior widening.

## Selection

`.599` shall synchronize the APB profile-alias/public surface after `.597`. It
must read this selector, `.597` behavior, `.596` contract, `.595` readiness
audit, `.594` data16 behavior, `.589` sideband behavior,
`docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md`, current APB reports/residue,
`FSM::Support::RegressionCorpus`, `FSM::Support::LanguageSurfaceSection`,
focused APB/profile-alias/manifest tests, README, ROADMAP_V2, mdBook, task
tree, Memory, Knowledge Map, and relevant IAL2/backend/VHDL decisions.

The cleanup owner may update APB profile-alias/public documentation, examples,
support-accounting prose, mdBook/README/ROADMAP summaries, Memory, task-tree
records, and Knowledge Map facts. It must not change APB source acceptance,
parser semantics, generator semantics, source samples, support-accounting
catalog entries, report schemas, schedule/check/semantic JSON behavior except
documentation wording, validation behavior, generated artifacts, HDL/runtime
behavior, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, AHB behavior, or VHDL behavior.

After `.599`, the next selector can compare APB back-to-back policy,
additional PPROT policy families, data16 PPROT policy effects, additional APB
composition/interconnect behavior, AXI/AHB return, direct backend,
verification-output, backend-language variants, and VHDL work from an aligned
public surface.

## Non-Goals

`.598` does not select implementation of APB back-to-back transfer policy,
additional PPROT predicates, global/window/peripheral policies,
interconnect-owned enforcement, data16 policy effects, additional APB
composition/interconnect behavior, direct backend lowering, verification-output
generation, backend-language variants, AXI behavior, AHB behavior, or VHDL
behavior.

`.599` is not a protocol-behavior slice. It must not accept new APB source
syntax, add new APB samples, add new support identities, modify generated APB
policy logic, widen APB widths, or alter generated HDL/runtime behavior unless
a later task-tree owner explicitly selects that work.

## Deferred Work

APB back-to-back transfer policy, additional PPROT policy families, data16
PPROT policy effects, additional APB composition/interconnect behavior,
multiple requesters, bus matrices, direct IAL2-to-IAL0 lowering, direct backend
lowering, verification-output generation, backend-language variants, AXI
follow-on work, AHB follow-on work, and VHDL remain deferred outside `.598`.

## Validation

The closeout validation for `.598` is documentation and focused-report based:

```bash
perl -MJSON::PP -we 'my $file=shift; my $json=qx(./bin/fsmgen --quiet --emit-schedule-json $file); die "fsmgen failed for $file\n" if $?; my $r=JSON::PP->new->decode($json); my @ids=map { $_->{id} // q{} } @{$r->{unsupported_residue} // []}; print "$file\n"; print "schema=$r->{schema}\n"; print "source=$r->{source_object}{id}\n"; print "residue=" . join(q{,}, @ids) . "\n"; print "protection_policy=" . (exists($r->{protection_policy}) ? q{yes} : q{no}) . "\n";' ppif/apb_completer_multi_register_sideband_protection.apb
perl -MJSON::PP -we 'my $file=shift; my $json=qx(./bin/fsmgen --quiet --emit-schedule-json $file); die "fsmgen failed for $file\n" if $?; my $r=JSON::PP->new->decode($json); my @ids=map { $_->{id} // q{} } @{$r->{unsupported_residue} // []}; print "$file\n"; print "schema=$r->{schema}\n"; print "source=$r->{source_object}{id}\n"; print "residue=" . join(q{,}, @ids) . "\n"; print "protection_policy=" . (exists($r->{protection_policy}) ? q{yes} : q{no}) . "\n";' ppif/apb_completer_multi_register_sideband_data16.apb
perl -MJSON::PP -we 'my $file=shift; my $json=qx(./bin/fsmgen --quiet --emit-schedule-json $file); die "fsmgen failed for $file\n" if $?; my $r=JSON::PP->new->decode($json); my @ids=map { $_->{id} // q{} } @{$r->{unsupported_residue} // []}; print "$file\n"; print "schema=$r->{schema}\n"; print "source=$r->{source_object}{id}\n"; print "residue=" . join(q{,}, @ids) . "\n"; print "protection_policy=" . (exists($r->{protection_policy}) ? q{yes} : q{no}) . "\n";' ppif/apb_composition_multi_peripheral_sideband_protection.apb
perl -MJSON::PP -we 'my $file=shift; my $json=qx(./bin/fsmgen --quiet --emit-schedule-json $file); die "fsmgen failed for $file\n" if $?; my $r=JSON::PP->new->decode($json); my @ids=map { $_->{id} // q{} } @{$r->{unsupported_residue} // []}; print "$file\n"; print "schema=$r->{schema}\n"; print "source=$r->{source_object}{id}\n"; print "residue=" . join(q{,}, @ids) . "\n"; print "protection_policy=" . (exists($r->{protection_policy}) ? q{yes} : q{no}) . "\n";' ppif/apb_composition_multi_peripheral_sideband_data16.apb
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is doc-only: revert this selector, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.597` APB PPROT access-policy behavior remains unchanged.
