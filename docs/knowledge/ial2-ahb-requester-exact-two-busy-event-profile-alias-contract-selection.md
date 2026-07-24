---
id: ial2-ahb-requester-exact-two-busy-event-profile-alias-contract-selection
title: Exact-two AHB requester BUSY selects a byte-identical .ahb profile alias
answers:
  - "will exact-two AHB requester BUSY have an .ahb alias?"
  - "what does IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.6 select?"
  - "is ahb_requester_busy_insert_two.ahb a separate generator?"
  - "how will the exact-two requester .ahb alias be support-accounted?"
  - "will the exact-two AHB alias be visible through semantic introspection and MCP?"
  - "does ppif/ahb_requester_busy_insert_two.ahb ship yet?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, busy, exact-two, profile-alias, semantics, mcp, contract]
evidence: docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_requester_busy_insert_two.ppif; ppif/ahb_requester_busy_insert.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; bin/fsmgen-mcp; t/1512-ial2-ahb-requester-busy-insert-profile-alias.t; t/1521-ial2-ahb-requester-two-busy-insert.t; docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md; docs/book/src/16c-ial2-ahb.md
reverify: perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/; open my $fh, "<", "ppif/ahb_requester_busy_insert_two.ppif" or die $!; my $r = FSM::Adapter::IAL2::PPIF->new()->parse_source(<$fh>, "ppif/ahb_requester_busy_insert_two.ahb"); my %x = map { $_->{id} => 1 } @{$r->{report}{unsupported_residue}}; die "wrong count\n" unless $r->{report}{busy_insertion}{beats} == 2; die "alias residue\n" if $x{ahb_profile_alias_deferred}; die "missing support residue\n" unless $x{ahb_requester_busy_insert_support}; print "exact-two alias ready\n";'
---

`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.6` selects
`ppif/ahb_requester_busy_insert_two.ahb` as a future byte-identical profile
alias of the shipped generic `.ppif` source. It reuses the same AHB requester
generator and IAL2 -> IAL1 -> IAL0 -> HDL route; it is not another generator.

The selected support ID is
`intent.ahb_profile_alias_requester_busy_insert_two`, coverage is
`ial2_ahb_profile_alias_requester_busy_insert_two_pipeline_cli`, source kind is
`ial2_profile_alias`, module is `amba_requester_busy_insert_two`, and semantic
root is `fsm`. Existing `.ahb` handling preserves generated IAL1/IAL0 and
numeric `busy_insertion.beats=2`, removing only
`ahb_profile_alias_deferred`.

The implementation must prove the alias through strict check, semantic JSON,
and the existing read-only MCP `fsmgen_semantic_introspect` tool without an
alias-specific API path. Focused t/1522 will own source/report/artifact/API
parity; assertion-enabled t/1521 remains the shared runtime proof. The alias
does not ship until `.7` implements and support-accounts it.
