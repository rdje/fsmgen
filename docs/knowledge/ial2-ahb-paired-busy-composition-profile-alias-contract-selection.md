---
id: ial2-ahb-paired-busy-composition-profile-alias-contract-selection
title: The paired AHB BUSY composition selects its matching .ahb profile alias next
answers:
  - "what follows the generic paired AHB BUSY composition?"
  - "which task will add the paired AHB BUSY composition .ahb alias?"
  - "does the paired BUSY .ahb alias exist yet?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.795 select?"
  - "is the paired AHB .ahb source a separate generator?"
  - "how will the paired AHB BUSY alias be support-accounted?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, busy, composition, profile-alias, contract, selector]
evidence: >-
  docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_requester_busy_insert.ahb; ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t; t/1512-ial2-ahb-requester-busy-insert-profile-alias.t; t/1513-ial2-ahb-paired-busy-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md;
  docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'local $/; open my $fh, "<", "ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif" or die $!; my $r = FSM::Adapter::IAL2::PPIF->new()->parse_source(<$fh>, "ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb"); die "missing BUSY insertion\n" unless $r->{report}{children}[0]{busy_insertion}{before_beat} == 2; die "missing BUSY park\n" unless $r->{report}{children}[2]{transfer}{seq_policy}{parks_on}[0] eq "busy"; print "paired BUSY alias ready\n";'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.795` selects `.796`, direct data-only
implementation of
`ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb`
as a byte-identical profile-alias mirror of the generic `.ppif` source shipped
by `.794`.

The alias will support-account as
`intent.ahb_profile_alias_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park`
with coverage
`ial2_ahb_profile_alias_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park_pipeline_cli`,
source kind `ial2_profile_alias`, module `ahb_tb`, child count 3, and semantic
root `top`. It targets 312 protocol and 353 supported-smoke/strict entries.

An in-memory `.ahb`-label probe already preserves the exact requester,
subordinate, interconnect, top, IAL1/IAL0 artifacts, requester-child
`busy_insertion`, and subordinate `parks_on=[busy]`. Existing suffix handling
removes only aggregate/requester/subordinate alias residue. No parser or
generator change is selected: `.ppif` and `.ahb` are two public source surfaces
for the same generator architecture. t/1514 will own alias parity and public
CLI/report proof; t/1513 remains the shared generated-HDL runtime proof.

Two-subordinate paired behavior, broader BUSY/status/burst behavior, optional
signals, proposed audits, backends, AXI/APB, VHDL, and decision 0020 remain
deferred or inactive.
