---
id: ial2-post-ahb-interconnect-ppif-next-slice-selection
title: After AHB interconnect PPIF, select aggregate .ahb alias contract
answers:
  - "what comes after AHB interconnect PPIF shipment?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.724 select?"
  - "is aggregate AHB interconnect .ahb next?"
  - "why not multi-subordinate AHB decode after .723?"
  - "which task owns AHB interconnect .ahb contract selection?"
date: 2026-06-29
status: current
tags: [ial2, ahb, interconnect, decode, profile-alias, selector, task-tree]
evidence: docs/IAL2_POST_AHB_INTERCONNECT_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md; ppif/ahb_interconnect.ppif; ppif/ahb_requester.ahb; ppif/ahb_lite_subordinate.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1478-ial2-ahb-interconnect.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ppif && perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/ = undef; open my $fh, "<", "ppif/ahb_interconnect.ppif" or die $!; my $src = <$fh>; my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($src, "ahb_interconnect.ahb"); 1 }; print $ok ? "unexpected success\n" : $@;' && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.724|IAL2-FEATURE-COMPLETENESS-FRONTIER\.725|ahb_aggregate_profile_alias_deferred|ppif/ahb_interconnect\.ahb|intent\.ahb_profile_alias_interconnect' docs/IAL2_POST_AHB_INTERCONNECT_PPIF_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.724` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.725`, AHB aggregate `.ahb`
profile-alias contract selection.

The shipped aggregate AHB behavior remains `ppif/ahb_interconnect.ppif` from
`.723`: one requester, one subordinate, one static address window, generated
requester/subordinate/interconnect `.isf` and `.fsm` review artifacts,
aggregate `ahb_tb.fsm`, HDL module `ahb_tb`, report schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, and support accounting
`intent.ppif_ahb_interconnect`.

The aggregate `.ahb` alias is currently rejected, and the shipped interconnect
report keeps `ahb_aggregate_profile_alias_deferred`. `.725` must select the
exact future alias contract before behavior changes, likely
`ppif/ahb_interconnect.ahb`, `intent.ahb_profile_alias_interconnect`,
`source_kind ial2_profile_alias`, and coverage
`ial2_ahb_profile_alias_interconnect_pipeline_cli`.

Multi-subordinate decode, multiple managers, bus matrices, optional signals,
burst `SEQ`, byte-lane/narrow-transfer behavior, direct backend,
verification-output generation, AXI/APB behavior, and VHDL remain future
task-tree-owned work.
