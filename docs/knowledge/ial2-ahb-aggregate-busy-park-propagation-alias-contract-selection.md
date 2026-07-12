---
id: ial2-ahb-aggregate-busy-park-propagation-alias-contract-selection
title: AHB aggregate BUSY-park .ahb alias contract selected (.783 -> .784)
answers:
  - "does FSMGen ship aggregate AHB BUSY-park .ahb profile aliases?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.783?"
  - "what will ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb be?"
  - "how are the aggregate BUSY-park .ahb aliases support-accounted?"
date: 2026-07-12
status: current
tags: [ial2, ahb, busy-park, aggregate, profile-alias, contract-selection]
evidence: docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_ALIAS_CONTRACT_SELECTION.md; ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: perl -Iperl -MFSM::Adapter::IAL2::PPIF -e 'my $s=do { local $/; open my $f, "<", "ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif"; <$f> }; my $r=FSM::Adapter::IAL2::PPIF->new()->parse_source($s, "ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb"); print $r->{report}{composition}{seq_policy_propagation}{subordinates}[0]{seq_policy}{parks_on}[0], "\n"'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.783` is a no-behavior contract selection: it
selects `.784`, the direct implementation of the matching bounded aggregate AHB
BUSY-park `.ahb` profile aliases
`ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb`,
mirroring the shipped generic aggregate BUSY-park `.ppif` sources from `.782`.

The selection is data-only: a reserved `.ahb`-label parse of each shipped
generic BUSY-park source already keeps the aggregate topology (child counts 3/4),
preserves each child `seq_policy.parks_on = [busy]` / BUSY-free `clears_on`, and
removes the top-level `ahb_aggregate_profile_alias_deferred` and embedded
`ahb_subordinate_profile_alias_deferred` residues through the existing
suffix-keyed suppression — no PPIF adapter or interconnect code change. `.784`
adds two tracked `.ahb` fixtures, support-accounts them as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park` (coverage
`ial2_ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park_pipeline_cli`,
child count 3) and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`
(child count 4), source kind `ial2_profile_alias`, module `ahb_tb`, and adds
focused `t/1497` plus catalog/language-surface/manifest/docs entries.

This follows the established AHB cadence `generic endpoint .ppif -> endpoint
.ahb -> generic aggregate .ppif -> aggregate .ahb`. Requester-side BUSY
insertion, halfword/word burst `SEQ`, wider/indefinite bursts,
multi-word/register-bank progression, optional AHB signals, broader AHB, backend
variants, AXI/APB, and VHDL remain deferred.
