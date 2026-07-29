---
id: ial2-ahb-requester-exact-four-busy-event-profile-alias-contract-selection
title: Exact-four AHB requester BUSY selects a byte-identical .ahb profile alias
answers:
  - "will exact-four AHB requester BUSY have an .ahb alias?"
  - "what does exact-four alias selector .4 choose?"
  - "is ahb_requester_busy_insert_four.ahb a separate generator?"
  - "how will the exact-four requester alias be support-accounted?"
  - "will the exact-four alias support semantic introspection and MCP?"
  - "does ppif/ahb_requester_busy_insert_four.ahb ship yet?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-four, profile-alias, semantics, mcp, contract]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_BEHAVIOR.md; ppif/ahb_requester_busy_insert_four.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1529-ial2-ahb-requester-three-busy-insert-profile-alias.t; t/1535-ial2-ahb-requester-four-busy-insert.t; docs/tasks/IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.md; docs/book/src/16c-ial2-ahb.md
reverify: perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'open my $fh, "<", "ppif/ahb_requester_busy_insert_four.ppif" or die $!; my $text=join("", <$fh>); my $r=FSM::Adapter::IAL2::PPIF->new()->parse_source($text, "ppif/ahb_requester_busy_insert_four.ahb"); my %x=map { $_->{id} => 1 } @{$r->{report}{unsupported_residue}}; die "wrong count\n" unless $r->{report}{busy_insertion}{beats} == 4; die "wrong width\n" unless $r->{generated_ial1}{text} =~ /ahb_busy_remaining_q \(width 3\)/; die "alias residue\n" if $x{ahb_profile_alias_deferred}; die "missing support residue\n" unless $x{ahb_requester_busy_insert_support}; print "exact-four alias ready\n";'
---

Selector `.4` chooses `ppif/ahb_requester_busy_insert_four.ahb` as a future
byte-identical profile alias of the shipped generic source. It reuses the same
AHB requester generator and IAL2 -> IAL1 -> IAL0 -> HDL route.

The selected support ID is
`intent.ahb_profile_alias_requester_busy_insert_four`, coverage is
`ial2_ahb_profile_alias_requester_busy_insert_four_pipeline_cli`, source kind
is `ial2_profile_alias`, module is `amba_requester_busy_insert_four`, and
semantic root is `fsm`. Existing `.ahb` handling preserves width-three IAL1,
IAL0, and numeric `busy_insertion.beats=4`, removing only
`ahb_profile_alias_deferred`.

Focused t1536 will own alias parity without a second simulation; assertion-
enabled t1535 remains the shared exact-four runtime. Implementation projects
328 protocol / 369 supported+strict / 52 AHB paths split 26 `.ppif` / 26
`.ahb`. The alias does not ship in contract selection; proposed `.5` owns it.
