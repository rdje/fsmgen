---
id: ial2-ahb-subordinate-seed-behavior
title: AHB Lite subordinate direct seed ships as protocol.ahb_lite_subordinate
answers:
  - "does FSMGen have an AHB subordinate seed?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.709 ship?"
  - "what is protocol.ahb_lite_subordinate?"
  - "what comes after .709?"
  - "what AHB subordinate direct fixture is supported?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, ahb-lite, direct-fsm, support-accounting]
evidence: docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md; fsm/ahb_lite_subordinate.fsm; perl/FSM/Support/RegressionCorpus.pm; t/248-regression-corpus-accounting.t; docs/IAL2_AHB_SUBORDINATE_SEED_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/16c-ial2-ahb.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm && rg -n 'protocol\.ahb_lite_subordinate|ahb_lite_subordinate|three hundred eight|IAL2-FEATURE-COMPLETENESS-FRONTIER\.709|IAL2-FEATURE-COMPLETENESS-FRONTIER\.710' perl/FSM/Support/RegressionCorpus.pm t/248-regression-corpus-accounting.t docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/16-ial2-protocol-platform-intent.md
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

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.710`, a
no-behavior readiness audit for IAL2 AHB completer/subordinate source work now
that the lower-layer direct seed exists.
