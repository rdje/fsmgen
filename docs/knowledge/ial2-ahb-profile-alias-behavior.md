---
id: ial2-ahb-profile-alias-behavior
title: AHB .ahb now ships as a bounded IAL2 profile alias
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.700 implement?"
  - "does FSMGen accept .ahb files now?"
  - "does FSMGen accept ppif/ahb_requester.ahb?"
  - "how does the .ahb IAL2 profile alias behave?"
  - "what support accounting entry covers the .ahb alias?"
  - "what profile does .ahb require?"
  - "does .ahb lower directly to .fsm?"
  - "which IAL2 profile-alias suffixes are currently supported?"
  - "which IAL2 aliases remain unsupported after .ahb shipped?"
date: 2026-06-29
status: current
tags: [ial2, ahb, ppif, profile-alias, behavior, task-tree]
evidence: docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; ppif/ahb_requester.ahb; ppif/ahb_requester.ppif; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; t/1474-ial2-ahb-profile-alias.t; t/1473-ial2-ahb-requester.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -v t/1474-ial2-ahb-profile-alias.t t/1473-ial2-ahb-requester.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.700|ppif/ahb_requester\.ahb|intent\.ahb_profile_alias_requester|ial2_ahb_profile_alias_requester_pipeline_cli|source_kind.*ial2_profile_alias|bounded public \.ahb|shipped_bounded_profile_alias|ahb_profile_alias_deferred' docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md docs/book/src/16c-ial2-ahb.md docs/book/src/16-ial2-protocol-platform-intent.md ppif/ahb_requester.ahb bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/Support/RegressionCorpus.pm perl/FSM/Support/LanguageSurfaceSection.pm t/1474-ial2-ahb-profile-alias.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t README.md ROADMAP_V2.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.700` implements the bounded AHB `.ahb`
profile-alias source `ppif/ahb_requester.ahb`.

The alias mirrors `ppif/ahb_requester.ppif`, requires explicit `(profile ahb)`,
and supports exactly one `(ahb-requester amba_requester ...)` object. It lowers
through generated `amba_requester.isf` before generated `amba_requester.fsm`;
direct IAL2-to-IAL0 lowering remains forbidden. The HDL module is
`amba_requester`.

Support accounting records `intent.ahb_profile_alias_requester` with coverage
`ial2_ahb_profile_alias_requester_pipeline_cli` and `source_kind`
`ial2_profile_alias`. The authored `.ahb` source path is preserved in check
JSON and semantic JSON.

The currently shipped IAL2 profile aliases are `.axi`, `.apb`, and `.ahb`.
`.chi`, `.ace`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` remain known
unsupported aliases. AHB completers/subordinates, interconnect/decode,
scoreboards, full AHB manager behavior beyond the bounded requester, direct
backend behavior, verification-output generation, backend-language variants,
and VHDL remain deferred.
