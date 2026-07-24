---
id: ial2-ahb-subordinate-seed-behavior
title: AHB Lite subordinate direct seed ships as protocol.ahb_lite_subordinate
answers:
  - "does FSMGen have an AHB subordinate seed?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.709 ship?"
  - "what is protocol.ahb_lite_subordinate?"
  - "what comes after .709?"
  - "what AHB subordinate direct fixture is supported?"
  - "does the direct AHB subordinate seed retain an active phase accepted on completion?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, ahb-lite, direct-fsm, support-accounting]
evidence: docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md; fsm/ahb_lite_subordinate.fsm; perl/FSM/Support/RegressionCorpus.pm; t/248-regression-corpus-accounting.t; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; docs/IAL2_AHB_SUBORDINATE_SEED_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; docs/TASK_TREE.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/16c-ial2-ahb.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm && prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.709` ships a lower-layer direct AHB
subordinate seed:

```text
fsm/ahb_lite_subordinate.fsm
module: ahb_lite_subordinate
support accounting: protocol.ahb_lite_subordinate
```

The seed is a bounded AHB-Lite/common-AHB single-register subordinate. It uses
`HSEL`, `HADDR`, `HTRANS`, `HWRITE`, `HSIZE`, `HREADY`, `HWDATA`,
fixture-local `wait_cycles`, `HREADYOUT`, one-bit `HRESP`, and `HRDATA`.

The direct fixture accepts selected `NONSEQ` word reads/writes to
`32'h00000000`, ignores `IDLE` and `BUSY` with zero-wait OKAY, supports bounded
data-phase wait states through `wait_cycles`, and reports unsupported `SEQ`,
unsupported sizes, and unmapped addresses through the source-backed two-cycle
ERROR response.

Current limitation: t/1520 proves that the direct seed drops a selected active
phase accepted on a successful or final-ERROR completion edge because only
`IDLE` samples address/control. Each case has two bus acceptances but one
internal capture/completion. This seed is distinct from the generated IAL2
family repaired by `.3`. `.6` proved the `.5` no-bank realization unsafe
because next-phase capture changes current register-input mux predicates, then
restored the failed attempt. `.7` selects Q-named `<-` loads for the existing
four-state registers without a pending bank/relaunch; `.8` later implements it.

The selected next owner was `IAL2-FEATURE-COMPLETENESS-FRONTIER.710`, a
no-behavior readiness audit for IAL2 AHB completer/subordinate source work.
`.710` selected `.711`, public IAL2 AHB subordinate/completer contract
selection, before any parser/generator/source behavior changes.

Later `.711` selected the future public source
`ppif/ahb_lite_subordinate.ppif` and `.712`, a no-behavior generated-substrate
audit before implementation.
