---
id: ial2-ahb-aggregate-alias-nested-profile-residue-behavior
title: AHB aggregate .ahb aliases remove nested endpoint profile-residue
answers:
  - "do AHB aggregate .ahb alias child reports still carry endpoint profile alias residue?"
  - "which profile alias residue ids are removed from aggregate AHB .ahb reports?"
  - "do generic AHB aggregate PPIF reports still preserve child profile alias residue?"
  - "what changed in IAL2-FEATURE-COMPLETENESS-FRONTIER.748?"
  - "was the AHB aggregate alias nested residue cleanup report only?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, profile-alias, residue, behavior]
evidence: docs/IAL2_AHB_AGGREGATE_ALIAS_NESTED_PROFILE_RESIDUE_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_ALIAS_NESTED_PROFILE_RESIDUE_CONTRACT_SELECTION.md; perl/FSM/Adapter/IAL2/PPIF.pm; t/1479-ial2-ahb-interconnect-profile-alias.t; t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t; t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.748|ahb_profile_alias_deferred|ahb_subordinate_profile_alias_deferred|ahb_aggregate_profile_alias_deferred|nested endpoint profile' docs/IAL2_AHB_AGGREGATE_ALIAS_NESTED_PROFILE_RESIDUE_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.748` ships a report-only cleanup for
aggregate AHB `.ahb` aliases.

Aggregate `.ahb` report trees now remove `ahb_aggregate_profile_alias_deferred`,
`ahb_profile_alias_deferred`, and `ahb_subordinate_profile_alias_deferred`
recursively. The cleanup covers the word-only and byte-lane one-subordinate
and two-subordinate aggregate `.ahb` aliases.

Generic aggregate `.ppif` reports still keep those source-surface residues.
No parser behavior, generated artifacts, support accounting, or HDL/runtime
behavior changed.
