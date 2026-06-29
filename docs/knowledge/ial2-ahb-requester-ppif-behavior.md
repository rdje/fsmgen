---
id: ial2-ahb-requester-ppif-behavior
title: AHB requester PPIF now ships bounded requester behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.697 implement?"
  - "does FSMGen accept ppif/ahb_requester.ppif?"
  - "does FSMGen support AHB PPIF now?"
  - "what AHB IAL2 source ships first?"
  - "what support accounting entry covers AHB requester PPIF?"
  - "does AHB PPIF lower directly to FSM?"
  - "is .ahb accepted after the AHB requester PPIF slice?"
date: 2026-06-29
status: current
tags: [ial2, ahb, ppif, protocol-intent, behavior, task-tree]
evidence: docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; ppif/ahb_requester.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1473-ial2-ahb-requester.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -v t/1473-ial2-ahb-requester.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.697|ppif/ahb_requester\.ppif|protocol_intent\.ahb_requester|fsmgen\.ial2\.protocol_intent\.ahb_requester\.v1|intent\.ppif_ahb_requester|source_kind.*ppif|source suffix.*\.ahb.*known IAL2 alias candidate|AhbRequester' docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md ppif/ahb_requester.ppif perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm perl/FSM/Support/RegressionCorpus.pm docs/book/src/16c-ial2-ahb.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.697` implements the first bounded AHB
requester IAL2 source: `ppif/ahb_requester.ppif`.

The source uses generic `.ppif`, `(profile ahb)`, and one
`(ahb-requester amba_requester ...)` object. It lowers through generated
`amba_requester.isf` before generated `amba_requester.fsm`; direct IAL2-to-IAL0
lowering remains forbidden. The HDL module is `amba_requester`.

The result kind/schema are `protocol_intent.ahb_requester` and
`fsmgen.ial2.protocol_intent.ahb_requester.v1`. Support accounting records
`intent.ppif_ahb_requester` with `source_kind` `ppif`.

The slice keeps `.ahb` unsupported. A `.ahb` copy fails closed with the known
IAL2 alias-candidate diagnostic. AHB completers/subordinates,
interconnect/decode, scoreboards, full AHB manager behavior beyond the bounded
requester, direct backend behavior, verification-output generation,
backend-language variants, and VHDL remain deferred.
