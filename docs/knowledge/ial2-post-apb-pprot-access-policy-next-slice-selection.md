---
id: ial2-post-apb-pprot-access-policy-next-slice-selection
title: APB profile-alias public-surface sync follows PPROT access policies
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.598?"
  - "what comes after APB PPROT access-policy behavior?"
  - "why is APB profile-alias cleanup next?"
  - "does .598 change APB behavior?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.599?"
date: 2026-06-27
status: current
tags: [ial2, apb, pprot, protection, profile-alias, selector, task-tree, public-surface]
evidence: docs/IAL2_POST_APB_PPROT_ACCESS_POLICY_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_PPROT_EFFECTS_CONTRACT_SELECTION.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/knowledge/ial2-apb-pprot-effects-behavior.md; ppif/apb_completer_multi_register_sideband_protection.apb; ppif/apb_composition_multi_register_sideband_protection.apb; ppif/apb_composition_multi_peripheral_sideband_protection.apb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: perl -MJSON::PP -we 'my $file=shift; my $json=qx(./bin/fsmgen --quiet --emit-schedule-json $file); die "fsmgen failed for $file\n" if $?; my $r=JSON::PP->new->decode($json); my @ids=map { $_->{id} // q{} } @{$r->{unsupported_residue} // []}; print "$file\n"; print "schema=$r->{schema}\n"; print "source=$r->{source_object}{id}\n"; print "residue=" . join(q{,}, @ids) . "\n"; print "protection_policy=" . (exists($r->{protection_policy}) ? q{yes} : q{no}) . "\n";' ppif/apb_completer_multi_register_sideband_protection.apb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.598|IAL2-FEATURE-COMPLETENESS-FRONTIER\.599|APB profile-alias|PPROT access-control effects remain deferred|apb_additional_protection_policies_deferred|apb_protection_policy_effects_deferred' docs/IAL2_POST_APB_PPROT_ACCESS_POLICY_NEXT_SLICE_SELECTION.md docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.598` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.599`, a no-behavior APB profile-alias and
public-surface synchronization owner after bounded APB `PPROT`
register-local access-policy behavior.

The selector follows `.597` because the code, corpus, tests, language surface,
and live reports already support the selected `.apb` protection aliases, but
`docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md` still has stale public-profile
wording. Its supported-sample lists include the protection aliases, while its
support-accounting and CLI example sections omit them, and its non-goals still
say `PPROT` access-control effects remain deferred.

Live report probes distinguish the shipped and deferred surfaces. Selected
32-bit protection aliases carry `protection_policy` metadata and
`apb_additional_protection_policies_deferred`. Sideband data16 aliases have no
`protection_policy` and still carry `apb_protection_policy_effects_deferred`,
because data16 policy effects remain future work.

`.599` must synchronize APB profile-alias/public documentation and continuity
layers without changing APB source acceptance, parser behavior, generator
behavior, source samples, support-accounting catalog entries, report schemas,
schedule/check/semantic JSON behavior except documentation wording, validation
behavior, generated artifacts, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, AHB
behavior, or VHDL behavior.
