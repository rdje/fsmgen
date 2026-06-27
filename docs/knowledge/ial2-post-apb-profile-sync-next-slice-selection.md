---
id: ial2-post-apb-profile-sync-next-slice-selection
title: APB data16 PPROT policy readiness follows profile sync
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.600?"
  - "what comes after APB profile-alias public sync?"
  - "which task owns APB data16 PPROT policy readiness?"
  - "why select APB data16 PPROT policy effects next?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.601?"
date: 2026-06-27
status: current
tags: [ial2, apb, pprot, protection, data16, selector, task-tree]
evidence: docs/IAL2_POST_APB_PROFILE_SYNC_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROFILE_ALIAS_PUBLIC_SURFACE_SYNC.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: perl -MJSON::PP -we 'my $file=shift; my $json=qx(./bin/fsmgen --quiet --emit-schedule-json $file); die "fsmgen failed for $file\n" if $?; my $r=JSON::PP->new->decode($json); my @ids=map { $_->{id} // q{} } @{$r->{unsupported_residue} // []}; print "$file residue=" . join(q{,}, @ids) . " protection_policy=" . (exists($r->{protection_policy}) ? q{yes} : q{no}) . "\n";' ppif/apb_completer_multi_register_sideband_data16.apb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.600|IAL2-FEATURE-COMPLETENESS-FRONTIER\.601|data16 PPROT policy|apb_protection_policy_effects_deferred|protection_policy' docs/IAL2_POST_APB_PROFILE_SYNC_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.600` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.601`, a no-behavior readiness audit for
sideband data16 APB `PPROT` policy effects.

The selector follows `.599` because the profile-alias public surface now
documents the shipped 32-bit protection aliases, leaving data16 policy effects
as the narrowest remaining APB protection mismatch. Data16 sideband aliases
still report `apb_protection_policy_effects_deferred` and no
`protection_policy`, while selected 32-bit protection aliases report
`protection_policy` plus `apb_additional_protection_policies_deferred`.

`.601` must audit parser/generator/report readiness and decide whether the
next owner should be data16 PPROT policy contract selection, lower-layer
repair, narrower public-surface cleanup, or explicit deferral. `.600` changes
no parser, generator, sample, support-catalog, report, JSON, HDL/runtime, APB,
AXI, AHB, backend, verification-output, backend-language, or VHDL behavior.
