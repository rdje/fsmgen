---
id: ial2-ahb-interconnect-profile-alias-contract-selection
title: AHB interconnect .ahb contract selects aggregate alias implementation
answers:
  - "what AHB interconnect .ahb contract was selected?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.725 select?"
  - "what is the future AHB interconnect .ahb source path?"
  - "what support accounting will cover AHB interconnect .ahb?"
  - "which task owns AHB interconnect .ahb implementation?"
date: 2026-06-29
status: current
tags: [ial2, ahb, interconnect, decode, profile-alias, contract-selection, task-tree]
evidence: docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_POST_AHB_INTERCONNECT_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md; ppif/ahb_interconnect.ppif; ppif/ahb_interconnect.ahb; ppif/ahb_requester.ahb; ppif/ahb_lite_subordinate.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1478-ial2-ahb-interconnect.t; t/1479-ial2-ahb-interconnect-profile-alias.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: >-
  ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.725|IAL2-FEATURE-COMPLETENESS-FRONTIER\.726|ppif/ahb_interconnect\.ahb|intent\.ahb_profile_alias_interconnect|ial2_ahb_profile_alias_interconnect_pipeline_cli|source_kind.*ial2_profile_alias' docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_CONTRACT_SELECTION.md docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.725` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.726`, bounded implementation of public
AHB aggregate `.ahb` profile-alias exposure.

The selected alias path is `ppif/ahb_interconnect.ahb`, mirroring the
shipped generic aggregate source `ppif/ahb_interconnect.ppif`. The alias must
keep explicit `(profile ahb)`, one requester object, one subordinate object,
and one interconnect object.

The selected alias preserves generated `amba_requester.isf`,
`ahb_lite_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`. The report schema remains
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, and the HDL module remains
`ahb_tb`.

The selected support identity is `intent.ahb_profile_alias_interconnect`,
coverage key `ial2_ahb_profile_alias_interconnect_pipeline_cli`, source kind
`ial2_profile_alias`, and expected semantic source-root kind `top`.

`.726` shipped the selected implementation. Multi-subordinate decode,
multiple managers, bus matrices, optional signals, burst `SEQ`,
byte-lane/narrow-transfer behavior, direct backend, verification-output
generation, AXI/APB behavior, and VHDL remain future task-tree-owned work.
