---
id: ial2-ahb-profile-alias-readiness-audit
title: AHB profile-alias readiness selects .ahb contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.698 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.699?"
  - "is .ahb ready for implementation?"
  - "what comes after AHB requester PPIF behavior?"
  - "what comes after the AHB requester PPIF slice?"
date: 2026-06-29
status: current
tags: [ial2, ahb, profile-alias, readiness, task-tree]
evidence: docs/IAL2_AHB_PROFILE_ALIAS_READINESS_AUDIT.md; ppif/ahb_requester.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; bin/fsmgen; t/1473-ial2-ahb-requester.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.698|IAL2-FEATURE-COMPLETENESS-FRONTIER\.699|AHB \.ahb public profile-alias contract selection|source suffix.*\.ahb.*known IAL2 alias candidate|unsupported_first_slice_aliases|ahb_profile_alias_deferred|intent\.ppif_ahb_requester|must not accept \.ahb' docs/IAL2_AHB_PROFILE_ALIAS_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/Support/LanguageSurfaceSection.pm perl/FSM/Support/RegressionCorpus.pm t/1473-ial2-ahb-requester.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.698` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.699`, AHB `.ahb` public profile-alias
contract selection, as the next exact owner.

AHB is ready for `.ahb` contract selection, not implementation. The shipped
`ppif/ahb_requester.ppif` path already proves the bounded requester profile,
object vocabulary, generated `amba_requester.isf`, generated
`amba_requester.fsm`, HDL module `amba_requester`, report schema, support
accounting, and `.ahb` fail-closed boundary needed to define an alias contract.

`.699` must select source-path identity, explicit-profile policy, alias support
identity/source kind, manifest movement, diagnostics, validation, and residue.
It must not accept `.ahb` or change parser, generator, sample, manifest,
support-accounting, schedule/check/semantic JSON, HDL/runtime, backend,
verification-output, AXI, APB, broader AHB, direct-backend, or VHDL behavior.
