---
id: ial2-ahb-requester-exact-three-busy-event-profile-alias-contract-selection
title: Exact-three AHB requester BUSY selects a byte-identical .ahb profile alias
answers:
  - "will exact-three AHB requester BUSY have an .ahb alias?"
  - "what does IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.4 select?"
  - "is ahb_requester_busy_insert_three.ahb a separate generator?"
  - "how will the exact-three requester .ahb alias be support-accounted?"
  - "will the exact-three AHB alias be visible through semantic introspection and MCP?"
  - "does ppif/ahb_requester_busy_insert_three.ahb ship yet?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, busy, exact-three, profile-alias, semantics, mcp, contract]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_BEHAVIOR.md; ppif/ahb_requester_busy_insert_three.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; bin/fsmgen-mcp; t/1522-ial2-ahb-requester-two-busy-insert-profile-alias.t; t/1528-ial2-ahb-requester-three-busy-insert.t; docs/tasks/IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.md; docs/book/src/16c-ial2-ahb.md
reverify: perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/; open my $fh, "<", "ppif/ahb_requester_busy_insert_three.ppif" or die $!; my $r = FSM::Adapter::IAL2::PPIF->new()->parse_source(<$fh>, "ppif/ahb_requester_busy_insert_three.ahb"); my %x = map { $_->{id} => 1 } @{$r->{report}{unsupported_residue}}; die "wrong count\n" unless $r->{report}{busy_insertion}{beats} == 3; die "alias residue\n" if $x{ahb_profile_alias_deferred}; die "missing support residue\n" unless $x{ahb_requester_busy_insert_support}; print "exact-three alias ready\n";'
---

`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.4`
selects `ppif/ahb_requester_busy_insert_three.ahb` as a future byte-identical
profile alias of the shipped generic `.ppif` source. It reuses the same AHB
requester generator and IAL2 -> IAL1 -> IAL0 -> HDL route; it is not another
generator.

The selected support ID is
`intent.ahb_profile_alias_requester_busy_insert_three`, coverage is
`ial2_ahb_profile_alias_requester_busy_insert_three_pipeline_cli`, source kind
is `ial2_profile_alias`, module is `amba_requester_busy_insert_three`, and
semantic root is `fsm`. Existing `.ahb` handling preserves generated IAL1/IAL0
and numeric `busy_insertion.beats=3`, removing only
`ahb_profile_alias_deferred`.

The implementation must prove the alias through strict check, semantic JSON,
and the existing read-only MCP `fsmgen_semantic_introspect` tool without an
alias-specific API path. Focused t/1529 will own source/report/artifact/API
parity; assertion-enabled t/1528 remains the sole shared runtime proof. `.5`
now ships the selected alias; fact
`ial2-ahb-requester-exact-three-busy-event-profile-alias-behavior` owns the
current implementation result.
