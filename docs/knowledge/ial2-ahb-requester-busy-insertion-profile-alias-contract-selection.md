---
id: ial2-ahb-requester-busy-insertion-profile-alias-contract-selection
title: AHB requester BUSY-insertion follow-on selects the matching .ahb profile alias
answers:
  - "what follows the AHB requester BUSY-insertion .ppif behavior?"
  - "which task will add the AHB requester BUSY-insertion .ahb alias?"
  - "does ppif/ahb_requester_busy_insert.ahb exist yet?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.789 select?"
  - "how will the requester BUSY-insertion .ahb alias be support-accounted?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, busy, profile-alias, contract, selector]
evidence: docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_BEHAVIOR.md; ppif/ahb_requester_busy_insert.ppif; ppif/ahb_requester_busy_insert.ahb; ppif/ahb_requester.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1474-ial2-ahb-profile-alias.t; t/1498-ial2-ahb-requester-busy-insert.t; t/1512-ial2-ahb-requester-busy-insert-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/; open my $fh, "<", "ppif/ahb_requester_busy_insert.ppif" or die $!; my $r = FSM::Adapter::IAL2::PPIF->new()->parse_source(<$fh>, "ppif/ahb_requester_busy_insert.ahb"); my %x = map { $_->{id} => 1 } @{$r->{report}{unsupported_residue}}; die "alias residue\n" if $x{ahb_profile_alias_deferred}; die "missing BUSY support\n" unless $x{ahb_requester_busy_insert_support}; print "requester BUSY alias ready\n";'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.789` selects `.790`, direct
implementation of `ppif/ahb_requester_busy_insert.ahb` as a byte-identical
profile-alias mirror of the shipped generic
`ppif/ahb_requester_busy_insert.ppif` source.

The alias will support-account as
`intent.ahb_profile_alias_requester_busy_insert` with coverage
`ial2_ahb_profile_alias_requester_busy_insert_pipeline_cli`, source kind
`ial2_profile_alias`, module `amba_requester_busy_insert`, and semantic root
`fsm`. Existing `.ahb` parsing already preserves the BUSY report/artifacts and
removes only `ahb_profile_alias_deferred`; no adapter or generator change is
needed.

`.790` is data-only and now ships the alias fixture,
support/language/capability/test entries, behavior/public docs, and closeout
evidence. Fact `ial2-ahb-requester-busy-insertion-profile-alias-behavior` owns
the shipped result. Paired composition,
broader BUSY policies, runtime insertion, local bus-BUSY status, larger burst
progression, optional signals, backend variants, AXI/APB, and VHDL remain
deferred. Decision 0020 remains proposed/inactive.
