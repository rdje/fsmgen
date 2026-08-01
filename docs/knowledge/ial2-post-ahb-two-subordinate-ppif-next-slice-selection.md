---
id: ial2-post-ahb-two-subordinate-ppif-next-slice-selection
title: Post AHB two-subordinate PPIF selector chooses matching AHB alias
answers:
  - "what follows AHB two-subordinate PPIF behavior?"
  - "which task owns AHB two-subordinate .ahb alias implementation?"
  - "what source path will add the AHB two-subordinate profile alias?"
  - "is ppif/ahb_interconnect_two_subordinate.ahb selected?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, decode, profile-alias, task-tree]
evidence: docs/IAL2_POST_AHB_TWO_SUBORDINATE_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_BEHAVIOR.md; ppif/ahb_interconnect_two_subordinate.ppif; ppif/ahb_interconnect.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; t/1480-ial2-ahb-interconnect-two-subordinate.t; t/1479-ial2-ahb-interconnect-profile-alias.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: >-
  ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb && perl -Iperl -MFSM::Adapter::IAL2::PPIF -E 'local $/; open my $fh, "<", "ppif/ahb_interconnect_two_subordinate.ppif" or die $!; my $src = <$fh>; my $ok = eval { FSM::Adapter::IAL2::PPIF->new->parse_source($src, "ppif/ahb_interconnect_two_subordinate.ahb"); 1 }; die "unexpected success\n" if $ok; print $@;' && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.731|IAL2-FEATURE-COMPLETENESS-FRONTIER\.732|ppif/ahb_interconnect_two_subordinate\.ahb|intent\.ahb_profile_alias_interconnect_two_subordinate|ial2_ahb_profile_alias_interconnect_two_subordinate_pipeline_cli|ahb_aggregate_profile_alias_deferred'
  docs/IAL2_POST_AHB_TWO_SUBORDINATE_PPIF_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.731` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.732`, direct implementation of the matching
bounded public AHB two-subordinate profile alias:
`ppif/ahb_interconnect_two_subordinate.ahb`.

The selected alias must mirror `ppif/ahb_interconnect_two_subordinate.ppif`,
keep explicit `(profile ahb)`, preserve the generated requester/status
subordinate/control subordinate/interconnect review artifacts and aggregate
`ahb_tb.fsm`, report topology
`one_requester_two_subordinate_static_window_interconnect`, and support-account
as `intent.ahb_profile_alias_interconnect_two_subordinate` with source kind
`ial2_profile_alias` and coverage
`ial2_ahb_profile_alias_interconnect_two_subordinate_pipeline_cli`.

The selector changes no behavior. At `.731` closeout, the generic
two-subordinate `.ppif` source is supported, the one-subordinate aggregate
`.ahb` alias is supported, and the two-subordinate `.ahb` alias still fails
closed until `.732` implements it.
