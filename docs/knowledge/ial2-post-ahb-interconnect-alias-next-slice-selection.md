---
id: ial2-post-ahb-interconnect-alias-next-slice-selection
title: After AHB interconnect .ahb, audit multi-subordinate decode readiness
answers:
  - "what comes after AHB interconnect .ahb shipment?"
  - "which task owns the next AHB follow-on after ppif/ahb_interconnect.ahb?"
  - "is multi-subordinate AHB decode next?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.727 select?"
date: 2026-06-29
status: current
tags: [ial2, ahb, interconnect, decode, task-tree, selection]
evidence: docs/IAL2_POST_AHB_INTERCONNECT_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect.ahb; ppif/ahb_interconnect.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1479-ial2-ahb-interconnect-profile-alias.t; t/1478-ial2-ahb-interconnect.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: >-
  ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb && perl -Iperl -MFSM::Adapter::IAL2::PPIF -E 'local $/; open my $fh, "<", "ppif/ahb_interconnect.ahb" or die $!; my $src=<$fh>; $src =~ s/\(subordinate regs ahb_lite_subordinate\)/\(subordinate regs ahb_lite_subordinate\)\n      \(subordinate regs2 ahb_lite_subordinate\)/; my $ok=eval { FSM::Adapter::IAL2::PPIF->new->parse_source($src, "multi_subordinate_candidate.ahb"); 1 }; die "unexpected success\n" if $ok; print $@;' && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.727|IAL2-FEATURE-COMPLETENESS-FRONTIER\.728|ahb_multi_subordinate_decode_deferred|multi-subordinate AHB interconnect/decode|ppif/ahb_interconnect\.ahb' docs/IAL2_POST_AHB_INTERCONNECT_ALIAS_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
  docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.727` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.728`, a no-behavior readiness audit for
bounded multi-subordinate AHB interconnect/decode.

The reason is that `.726` ships the aggregate `.ahb` alias and removes only
`ahb_aggregate_profile_alias_deferred`; the first remaining aggregate
interconnect residue is `ahb_multi_subordinate_decode_deferred`.

`.728` should audit the parser and generator assumptions around exactly one
subordinate child and one static address window, compare APB multi-peripheral
interconnect/decode precedent only as evidence, and select the next exact
contract or prerequisite before any behavior change.
