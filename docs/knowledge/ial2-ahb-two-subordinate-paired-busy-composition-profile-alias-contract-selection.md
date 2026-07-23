---
id: ial2-ahb-two-subordinate-paired-busy-composition-profile-alias-contract-selection
title: The two-subordinate paired AHB BUSY composition selects its matching .ahb alias
answers:
  - "what follows the generic two-subordinate paired AHB BUSY composition?"
  - "which task will add the two-subordinate paired AHB BUSY .ahb alias?"
  - "does the two-subordinate paired BUSY .ahb alias exist yet?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.802 select?"
  - "is the future two-subordinate paired AHB .ahb source another generator?"
  - "how will the two-subordinate paired AHB BUSY alias be support-accounted?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, composition, profile-alias, contract, selector]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t; t/1514-ial2-ahb-paired-busy-composition-profile-alias.t; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/; open my $fh, "<", "ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif" or die $!; my $source = <$fh>; my $r = FSM::Adapter::IAL2::PPIF->new()->parse_source($source, "ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb"); die "wrong child count\n" unless @{$r->{report}{children}} == 4; die "missing BUSY insertion\n" unless $r->{report}{children}[0]{busy_insertion}{before_beat} == 2; die "missing status park\n" unless $r->{report}{children}[2]{transfer}{seq_policy}{parks_on}[0] eq "busy"; die "missing control park\n" unless $r->{report}{children}[3]{transfer}{seq_policy}{parks_on}[0] eq "busy"; print "two-subordinate paired BUSY alias ready\n";'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.802` selects `.803`, direct data-only
implementation of
`ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb`
as a byte-identical mirror of the generic `.ppif` source shipped by `.801`.

The alias will support-account as
`intent.ahb_profile_alias_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park`
with coverage
`ial2_ahb_profile_alias_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
source kind `ial2_profile_alias`, module `ahb_tb`, child count 4, semantic root
`top`, and 314 protocol / 355 supported-smoke/strict targets.

An in-memory `.ahb`-label probe preserves the exact four IAL1/five IAL0
artifacts, requester `busy_insertion`, and both status/control
`parks_on=[busy]` policies. Existing suffix handling removes only aggregate,
requester, and both subordinate alias residue families plus alias-exposure
wording. No parser or generator change is selected: `.ppif` and `.ahb` are two
public entrypoints into the same architecture. t/1516 will own alias parity
and public surfaces; t/1515 remains the shared generated-HDL runtime proof.
