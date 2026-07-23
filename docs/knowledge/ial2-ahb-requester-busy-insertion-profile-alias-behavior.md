---
id: ial2-ahb-requester-busy-insertion-profile-alias-behavior
title: The AHB requester BUSY-insertion .ahb profile alias ships with behavior identical to the generic source
answers:
  - "does FSMGen ship ppif/ahb_requester_busy_insert.ahb?"
  - "how does the AHB requester BUSY-insertion .ahb alias behave?"
  - "what shipped in IAL2-FEATURE-COMPLETENESS-FRONTIER.790?"
  - "what support id covers the requester BUSY-insertion .ahb alias?"
  - "does the BUSY-insertion .ahb alias change generated HDL?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, busy, profile-alias, behavior]
evidence: ppif/ahb_requester_busy_insert.ahb; ppif/ahb_requester_busy_insert.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1512-ial2-ahb-requester-busy-insert-profile-alias.t; t/1498-ial2-ahb-requester-busy-insert.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: prove -Iperl t/1512-ial2-ahb-requester-busy-insert-profile-alias.t t/1498-ial2-ahb-requester-busy-insert.t && ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert.ahb
---

FSMGen ships `ppif/ahb_requester_busy_insert.ahb` as a byte-identical profile
alias of `ppif/ahb_requester_busy_insert.ppif`. Both lower through generated
`amba_requester_busy_insert.isf` and `.fsm`, then generate HDL module
`amba_requester_busy_insert` with the same single held BUSY presentation and
resumed `SEQ` behavior.

The alias support identity is
`intent.ahb_profile_alias_requester_busy_insert`, coverage
`ial2_ahb_profile_alias_requester_busy_insert_pipeline_cli`, source kind
`ial2_profile_alias`, semantic root `fsm`. Existing suffix handling removes
only `ahb_profile_alias_deferred`; `busy_insertion` and
`ahb_requester_busy_insert_support` remain unchanged. t/1512 proves alias
parity/CLI/artifacts/report/residue, while t/1498 retains generated-HDL runtime
proof. Current accounting is 310 protocol / 351 supported-smoke and strict.
