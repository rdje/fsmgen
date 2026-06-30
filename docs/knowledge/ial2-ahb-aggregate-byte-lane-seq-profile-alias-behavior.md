---
id: ial2-ahb-aggregate-byte-lane-seq-profile-alias-behavior
title: AHB aggregate byte-lane SEQ .ahb aliases shipped
answers:
  - "are matching AHB aggregate byte-lane SEQ .ahb aliases shipped?"
  - "does ppif/ahb_interconnect_byte_lane_seq.ahb exist yet?"
  - "does FSMGen ship ppif/ahb_interconnect_byte_lane_seq.ahb?"
  - "does FSMGen ship ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb?"
  - "what support accounting identifies AHB aggregate byte-lane SEQ .ahb aliases?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, byte-lane, seq, profile-alias]
evidence: docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane_seq.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb; ppif/ahb_interconnect_byte_lane_seq.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t; t/1488-ial2-ahb-interconnect-byte-lane-seq.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_seq.ahb && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_seq.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.760` ships
`ppif/ahb_interconnect_byte_lane_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb` as bounded public
AHB profile aliases over the generic aggregate byte-lane in-word `SEQ`
sources.

The aliases preserve explicit `(profile ahb)`, source object IDs, intent
names, generated `.isf` before generated `.fsm` review artifacts, HDL entry
module `ahb_tb`, `composition.byte_lane_propagation`,
`composition.seq_policy_propagation`, child `narrow_transfer_policy`, and
child `transfer.seq_policy`.

They support-account as
`intent.ahb_profile_alias_interconnect_byte_lane_seq` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_seq` with
source kind `ial2_profile_alias`.

Alias report trees remove aggregate/requester/subordinate profile-alias
residue and remove `.ahb alias exposure` wording from embedded byte-lane
`SEQ` child residue. Generic `.ppif` reports keep those source-surface
residues.
