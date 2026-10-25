---
id: ial2-ahb-subordinate-ppif-behavior
title: AHB subordinate PPIF behavior ships through generated IAL1 and IAL0
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.715 implement?"
  - "does FSMGen ship ppif/ahb_lite_subordinate.ppif?"
  - "what is the public IAL2 AHB subordinate behavior?"
  - "what report schema and support accounting identify AHB subordinate PPIF?"
  - "does AHB subordinate PPIF lower through generated isf and fsm artifacts?"
  - "is AHB subordinate exposed through .ahb yet?"
  - "how is AHB bridge metadata invariance checked?"
date: 2026-10-25
status: current
tags: [ial2, ahb, subordinate, ppif, behavior]
evidence: docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; ppif/ahb_lite_subordinate.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; t/1475-ial2-ahb-subordinate.t; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1475-ial2-ahb-subordinate.t t/1903-isf-internal-storage-ownership.t t/1983-isf-interface-port-metadata.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.715|ppif/ahb_lite_subordinate\.ppif|ahb-subordinate|ahb_lite_subordinate\.(isf|fsm)|fsmgen\.ial2\.protocol_intent\.ahb_subordinate\.v1|intent\.ppif_ahb_lite_subordinate|ial2_ppif_ahb_lite_subordinate_pipeline_cli|HREADYOUT' docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/16-ial2-protocol-platform-intent.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.715` ships
`ppif/ahb_lite_subordinate.ppif`: `(profile ahb)`, one
`(ahb-subordinate ahb_lite_subordinate ...)`, generated
`ahb_lite_subordinate.isf` then `ahb_lite_subordinate.fsm`, HDL module
`ahb_lite_subordinate`. Schema: `fsmgen.ial2.protocol_intent.ahb_subordinate.v1`.
Support: `intent.ppif_ahb_lite_subordinate`, coverage
`ial2_ppif_ahb_lite_subordinate_pipeline_cli`, `source_kind=ppif`.

This bounded AHB-Lite/common-AHB single-register subordinate has one
`ahb_phase_pending_q` address/control bank. At `HSEL && HREADY` for
`NONSEQ`/`SEQ`, it captures HADDR, HTRANS, optional HBURST, HWRITE, HSIZE,
and wait_cycles, never HWDATA; ready drops before another acceptance.
Variants: word/byte-lane/SEQ/HBURST/BUSY; width-safe waits; one-bit HRESP
OKAY/ERROR, two-cycle ERROR; reset/default HREADYOUT=1, HRESP=0, HRDATA=0. t/1519 proves boundary-free active retention and final-ERROR
active-capture versus IDLE cancel. Later `.ahb` aliases use this generator.
Deeper/general queues, multiple outstanding transfers, broader manager/fabric
behavior and the transaction-layer horizon remain deferred.

T1475 compares current generated IAL0 bytes with/without only the generated
verification-bridge annotation; a changed output reset must change the bytes.
July's checksum predates explicit port/storage `+interface`; diagnosis:
PUBLICATION-REGRESSION-REPAIRS.14, with no parser/runtime fault.
