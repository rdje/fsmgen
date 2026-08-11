---
id: ial2-ahb-interconnect-decode-behavior
title: AHB interconnect PPIF ships one requester and one subordinate
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.723 implement?"
  - "does FSMGen ship ppif/ahb_interconnect.ppif?"
  - "what is the public IAL2 AHB interconnect behavior?"
  - "what report schema and support accounting identify AHB interconnect PPIF?"
  - "does AHB interconnect PPIF lower through generated isf and fsm artifacts?"
  - "what composition child count should intent.ppif_ahb_interconnect report in check and semantic JSON?"
  - "is aggregate AHB .ahb alias shipped?"
date: 2026-07-29
status: current
tags: [ial2, ahb, interconnect, decode, ppif, behavior]
evidence: docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md; ppif/ahb_interconnect.ppif; ppif/ahb_interconnect.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; t/301-check-json-supported-corpus.t; t/303-normalized-semantic-json-supported-corpus.t; t/1478-ial2-ahb-interconnect.t; docs/tasks/GITHUB-PUSH-OUTCOME-ASSURANCE.md; docs/book/src/16c-ial2-ahb.md
reverify: >-
  prove -Iperl t/1478-ial2-ahb-interconnect.t t/1479-ial2-ahb-interconnect-profile-alias.t && ./bin/ci-regression full --no-book --hosted-corpus-shard 301:14/16 && ./bin/ci-regression full --no-book --hosted-corpus-shard 303:14/16 && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb && rg -n 'ppif/ahb_interconnect\.(ppif|ahb)|ahb_interconnect\.(isf|fsm)|ahb_tb\.fsm|fsmgen\.ial2\.protocol_intent\.ahb_interconnect\.v1|intent\.ppif_ahb_interconnect|intent\.ahb_profile_alias_interconnect|two-cycle unmapped' docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md docs/tasks/GITHUB-PUSH-OUTCOME-ASSURANCE.md docs/TASK_TREE.md
  README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md ppif/ahb_interconnect.ppif ppif/ahb_interconnect.ahb
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.723` implements the selected public IAL2
AHB interconnect/decode `.ppif` behavior.

The public source is `ppif/ahb_interconnect.ppif`. It uses `(profile ahb)`,
one `(ahb-requester amba_requester ...)`, one
`(ahb-subordinate ahb_lite_subordinate ...)`, and one
`(ahb-interconnect ahb_tb ...)` object. It lowers through generated
`amba_requester.isf`, `ahb_lite_subordinate.isf`, and `ahb_interconnect.isf`
before generated `amba_requester.fsm`, `ahb_lite_subordinate.fsm`,
`ahb_interconnect.fsm`, and aggregate `ahb_tb.fsm`, then emits HDL module
`ahb_tb`.

The report schema is `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`.
Support accounting identifies the sample as `intent.ppif_ahb_interconnect`
with coverage `ial2_ppif_ahb_interconnect_pipeline_cli` and `source_kind`
`ppif`.

Check and normalized semantic JSON report exactly three generated composition
children. RegressionCorpus owns both counts; t303 rejects a `top` row lacking an explicit semantic count or legacy exact instance count.

The shipped behavior is one requester, one subordinate, one static address
window at base 0 size 4, fixed `HGRANT=1`, decoded `HSEL_REGS`, local
`HADDR_REGS`, global `HREADY`, subordinate one-bit `HRESP_REGS` mapped to
requester two-bit `HRESP` OKAY/ERROR, and interconnect-owned two-cycle
unmapped active-transfer ERROR.

Generated IAL0 now makes the decode and response families mutually exclusive:
each window uses mapped-hit/not-hit `HSEL_*`/`HADDR_*`, while global response
outputs use retained-owner, first-cycle-unmapped, or
`!any_owner && !unmapped_address` ordinary-default modes. Direct-fabric t1530
passes with selector assertions enabled. The later generated-subordinate
repair now lets paired aggregates run with fabric and endpoint assertions
enabled.

Aggregate AHB `.ahb` alias behavior now ships separately as
`ppif/ahb_interconnect.ahb`, support-accounted as
`intent.ahb_profile_alias_interconnect`. The generic `.ppif` support identity
above remains unchanged.
