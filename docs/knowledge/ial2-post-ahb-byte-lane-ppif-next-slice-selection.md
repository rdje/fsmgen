---
id: ial2-post-ahb-byte-lane-ppif-next-slice-selection
title: Post AHB byte-lane PPIF selector chooses matching AHB alias
answers:
  - "what follows AHB byte-lane PPIF behavior?"
  - "which task owns AHB byte-lane .ahb alias implementation?"
  - "what source path will add the AHB byte-lane subordinate profile alias?"
  - "is ppif/ahb_lite_subordinate_byte_lane.ahb selected?"
date: 2026-06-30
status: current
tags: [ial2, ahb, subordinate, byte-lane, narrow-transfer, profile-alias, task-tree]
evidence: docs/IAL2_POST_AHB_BYTE_LANE_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane.ppif; ppif/ahb_lite_subordinate.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; t/1482-ial2-ahb-subordinate-byte-lane.t; t/1477-ial2-ahb-subordinate-profile-alias.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: >-
  ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb && perl -Iperl -MFSM::Adapter::IAL2::PPIF -MJSON::PP=decode_json -E 'local $/; open my $fh, "<", "ppif/ahb_lite_subordinate_byte_lane.ppif" or die $!; my $src = <$fh>; my $r = FSM::Adapter::IAL2::PPIF->new->parse_source($src, "ppif/ahb_lite_subordinate_byte_lane.ahb"); my %res = map { $_->{id} => 1 } @{$r->{report}{unsupported_residue} || []}; die "missing narrow policy\n" unless $r->{report}{narrow_transfer_policy}; die "alias residue still present\n" if $res{ahb_subordinate_profile_alias_deferred};' && rg -n
  'IAL2-FEATURE-COMPLETENESS-FRONTIER\.738|IAL2-FEATURE-COMPLETENESS-FRONTIER\.739|ppif/ahb_lite_subordinate_byte_lane\.ahb|intent\.ahb_profile_alias_subordinate_byte_lane|ial2_ahb_profile_alias_subordinate_byte_lane_pipeline_cli' docs/IAL2_POST_AHB_BYTE_LANE_PPIF_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.738` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.739`, direct implementation of the
matching bounded public AHB byte-lane/narrow-transfer subordinate profile
alias: `ppif/ahb_lite_subordinate_byte_lane.ahb`.

The selected alias must mirror
`ppif/ahb_lite_subordinate_byte_lane.ppif`, keep explicit `(profile ahb)`,
preserve generated `ahb_lite_subordinate_byte_lane.isf` and
`ahb_lite_subordinate_byte_lane.fsm`, report `narrow_transfer_policy`, and
support-account as `intent.ahb_profile_alias_subordinate_byte_lane` with
source kind `ial2_profile_alias` and coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_pipeline_cli`.

The selector changes no behavior. At `.738` closeout, the generic byte-lane
`.ppif` source is supported, the word-only subordinate `.ahb` alias is
supported, and the byte-lane `.ahb` alias remains untracked until `.739`
implements it.
