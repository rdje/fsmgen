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
date: 2026-07-23
status: current
tags: [ial2, ahb, subordinate, ppif, behavior]
evidence: docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; ppif/ahb_lite_subordinate.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; t/1475-ial2-ahb-subordinate.t; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -v t/1475-ial2-ahb-subordinate.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.715|ppif/ahb_lite_subordinate\.ppif|ahb-subordinate|ahb_lite_subordinate\.(isf|fsm)|fsmgen\.ial2\.protocol_intent\.ahb_subordinate\.v1|intent\.ppif_ahb_lite_subordinate|ial2_ppif_ahb_lite_subordinate_pipeline_cli|HREADYOUT' docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/16-ial2-protocol-platform-intent.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.715` implements the selected public IAL2
AHB subordinate `.ppif` behavior.

The public source is `ppif/ahb_lite_subordinate.ppif`. It uses `(profile ahb)`
and one `(ahb-subordinate ahb_lite_subordinate ...)` object. It lowers through
generated `ahb_lite_subordinate.isf` before generated
`ahb_lite_subordinate.fsm`, then emits HDL module `ahb_lite_subordinate`.

The report schema is `fsmgen.ial2.protocol_intent.ahb_subordinate.v1`.
Support accounting identifies the sample as
`intent.ppif_ahb_lite_subordinate` with coverage
`ial2_ppif_ahb_lite_subordinate_pipeline_cli` and `source_kind` `ppif`.

The current shipped behavior is the bounded AHB-Lite/common-AHB single-register
subordinate with one `ahb_phase_pending_q` accepted address/control bank. At
`HSEL && HREADY` for `NONSEQ`/`SEQ`, it captures HADDR, HTRANS, optional HBURST,
HWRITE, HSIZE, and wait_cycles, never HWDATA, and drives ready low before
another acceptance. It supports the selected word/byte-lane/SEQ/HBURST/BUSY
variants, width-safe counted waits, one-bit OKAY/ERROR `HRESP`, and two-cycle
ERROR. Generated outputs preserve `HREADYOUT=1`, `HRESP=0`, and `HRDATA=0`
reset/default metadata. t/1519 proves boundary-free active-phase retention and
final-ERROR active-capture versus IDLE cancel.

The matching subordinate `.ahb` aliases ship through later slices and enter the
same generator. General/deeper queues, multiple outstanding transfers, broader
manager/fabric behavior, and the transaction-layer horizon remain deferred.
