# IAL2 APB Profile-Alias Public-Surface Sync

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.599`

Date: 2026-06-27

## Summary

`.599` synchronizes APB profile-alias public documentation after `.597` shipped
bounded APB `PPROT` register-local access-policy behavior.

The sync changes no parser behavior, generator behavior, source samples,
support-accounting catalog entries, validation behavior, generated artifacts,
report schemas, schedule/check JSON, semantic JSON, HDL/runtime behavior,
suffix acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.

## Public Surface Aligned

`docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md` now matches the support-accounted
`.apb` surface after `.597`:

- task-tree ownership includes `.599`;
- the supported `.apb` and mirrored `.ppif` lists order protection aliases with
  the live RegressionCorpus and LanguageSurfaceSection surface;
- the Lowering and Reports section states that protection aliases emit
  `protection_policy` and `apb_additional_protection_policies_deferred`, while
  sideband data16 aliases keep `apb_protection_policy_effects_deferred`;
- support-accounting prose includes the three selected protection alias
  entries for completer, fixed composition, and multi-peripheral composition;
- schedule/check/semantic CLI examples include protection aliases;
- diagnostics mention that unsupported access-policy placements remain
  fail-closed; and
- non-goals now defer data16 policy effects, additional predicates,
  global/window/peripheral policies, interconnect-owned enforcement, and
  back-to-back policy instead of saying all `PPROT` access-control effects are
  deferred.

## Still Deferred

Data16 protection-policy effects, additional `PPROT` predicates,
global/window/peripheral policies, interconnect-owned enforcement, APB
back-to-back transfer policy, additional APB topology behavior, AXI/AHB return,
direct backend lowering, verification-output generation, backend-language
variants, and VHDL remain deferred.

## Next Owner

`.600` is the next no-behavior selector. It must choose the next
roadmap-aligned APB/IAL2 owner after the profile-alias/public surface is
aligned.

## Validation

The `.599` closeout validation is documentation and public-surface based:

```bash
perl -MJSON::PP -we 'my $file=shift; my $json=qx(./bin/fsmgen --quiet --emit-schedule-json $file); die "fsmgen failed for $file\n" if $?; my $r=JSON::PP->new->decode($json); print "$file protection_policy=" . (exists($r->{protection_policy}) ? q{yes} : q{no}) . "\n";' ppif/apb_completer_multi_register_sideband_protection.apb
perl -MJSON::PP -we 'my $file=shift; my $json=qx(./bin/fsmgen --quiet --emit-schedule-json $file); die "fsmgen failed for $file\n" if $?; my $r=JSON::PP->new->decode($json); print "$file protection_policy=" . (exists($r->{protection_policy}) ? q{yes} : q{no}) . "\n";' ppif/apb_composition_multi_peripheral_sideband_protection.apb
prove -Iperl t/1470-ial2-apb-profile-alias.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is doc-only: revert this sync note, the profile-alias behavior doc
wording, the fact card, task-tree frontier updates, README, ROADMAP_V2, mdBook,
Memory, and generated Knowledge Map changes. The `.597` APB PPROT
access-policy behavior remains unchanged.
