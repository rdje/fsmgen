---
id: ial2-apb-sideband-strobe-behavior
title: APB sideband and strobe behavior ships PPROT/PSTRB propagation and byte-lane writes
answers:
  - "does .589 ship APB sideband strobe behavior?"
  - "does APB support PPROT and PSTRB now?"
  - "how does APB PSTRB write masking work?"
  - "what APB sideband samples are supported?"
  - "does APB PPROT enforce access control?"
  - "does APB sideband behavior change existing APB samples?"
date: 2026-06-27
status: current
tags: [ial2, apb, sideband, strobe, pprot, pstrb, byte-lane, behavior, task-tree]
evidence: >-
  docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_STROBE_CONTRACT_SELECTION.md; ppif/apb_requester_transfer_sideband.ppif; ppif/apb_requester_transfer_sideband.apb; ppif/apb_completer_multi_register_sideband.ppif; ppif/apb_completer_multi_register_sideband.apb; ppif/apb_composition_multi_register_sideband.ppif; ppif/apb_composition_multi_register_sideband.apb; ppif/apb_composition_multi_peripheral_sideband.ppif; ppif/apb_composition_multi_peripheral_sideband.apb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/REGRESSION_CORPUS.md; t/1470-ial2-apb-profile-alias.t;
  t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_sideband.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register_sideband.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register_sideband.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_sideband.ppif && prove -Iperl t/1470-ial2-apb-profile-alias.t t/1471-ial2-apb-completer.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.589` ships bounded APB `PPROT`/`PSTRB`
sideband/strobe behavior for sideband-aware requester, multi-register
completer, fixed multi-register composition, and multi-peripheral composition
`.ppif` and `.apb` samples.

Requester sources add `(protection req_prot width 3)` and `(write-strobe
req_wstrb width 4)` under `(request ...)`, plus bus-side `(protection PPROT
width 3)` and `(strobe PSTRB width 4)`. Requester lowering samples those
fields, drives `PPROT` from the sampled value, drives `PSTRB` from sampled
`req_wstrb` only for writes, and clears both sidebands in the terminal phase.

Completer lowering samples `PPROT` and `PSTRB` during APB setup. For mapped
writes, `PSTRB[0]` updates `PWDATA[7:0]`, `PSTRB[1]` updates
`PWDATA[15:8]`, `PSTRB[2]` updates `PWDATA[23:16]`, and `PSTRB[3]` updates
`PWDATA[31:24]`; unselected bytes preserve their previous register value.
Reads ignore `PSTRB`, and `PSTRB=0` is a successful no-byte write on a mapped
address.

Fixed composition wires `PPROT/PSTRB` from requester to completer.
Multi-peripheral composition propagates them through `apb_interconnect` to
each peripheral-side APB bus while preserving decoded `PSEL`, local address
translation, response muxing, and unmapped active-access `PSLVERR`.

`PPROT` is propagated and sampled, but protection access-control effects
remain deferred. Existing APB samples without sideband clauses remain
unchanged and keep the broad `apb_protection_and_strobes_deferred` residue;
sideband-aware reports instead use `apb_protection_policy_effects_deferred`.
