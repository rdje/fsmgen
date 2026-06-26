---
id: ial2-apb-ppif-composition-behavior
title: APB requester/completer composition is shipped as a PPIF source shape
answers:
  - "does FSMGen support an APB composition .ppif source?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.566 implement?"
  - "what APB composition PPIF behavior is shipped?"
  - "what report schema does APB composition use?"
  - "what support-accounting entry covers ppif/apb_composition.ppif?"
date: 2026-06-26
status: current
tags: [ial2, apb, ppif, composition, behavior, task-tree]
evidence: docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; ppif/apb_composition.ppif; ppif/apb_composition.apb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; t/1472-ial2-apb-composition.t; t/1470-ial2-apb-profile-alias.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --emit-schedule-json ppif/apb_composition.ppif && ./bin/fsmgen --strict --check --json ppif/apb_composition.ppif && ./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition.ppif && prove -Iperl t/1472-ial2-apb-composition.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.566` ships the first APB `.ppif`
requester/completer composition behavior. The public sample is
`ppif/apb_composition.ppif`, using `(profile apb)`, one `(apb-requester
apb_requester ...)`, one `(apb-completer apb_completer ...)`, and one explicit
`(apb-composition apb_tb ...)` object.

The APB composition `.ppif` source generates review artifacts
`apb_requester.isf`, `apb_completer.isf`, `apb_requester.fsm`,
`apb_completer.fsm`, and `apb_tb.fsm`. The selected HDL entry is
`apb_tb.fsm`, and the generated HDL contains modules `apb_tb`,
`apb_requester`, and `apb_completer`.

The IAL2 report schema is
`fsmgen.ial2.protocol_intent.apb_composition.v1`, and support accounting
matches `intent.ppif_apb_composition` with coverage
`ial2_ppif_apb_composition_pipeline_cli`, source kind `ppif`, expected top
`apb_tb`, expected child modules `apb_requester` and `apb_completer`, and
expected semantic source root kind `top`.

The shipped top exposes `clk`, `rst_n`, `start`, `req_write`, `req_addr`,
`req_wdata`, `wait_cycles`, `done`, `last_error`, and `last_read_data`.
Requester `busy` is not exposed. The fixed composition wires requester APB
outputs to the completer and completer APB responses back to the requester.

The later `IAL2-FEATURE-COMPLETENESS-FRONTIER.569` slice also exposes this
same bounded fixed composition through `ppif/apb_composition.apb`,
support-accounted as `intent.apb_profile_alias_composition`.

Requester busy/status exposure, multi-peripheral interconnect/decode,
multi-register decode, sidebands/strobes, alternate widths, back-to-back
policy, direct backend lowering, verification-output generation,
backend-language variants, AXI, and VHDL remain future owners.
