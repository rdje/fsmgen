---
id: ial2-apb-interconnect-composition-contract-selection
title: APB composition contract selects explicit requester/completer aggregate
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.565 select?"
  - "what is the first APB composition IAL2 contract?"
  - "does APB composition use apb-interconnect or apb-composition?"
  - "does the first generated APB composition expose busy?"
  - "what comes after APB composition contract selection?"
date: 2026-06-26
status: current
tags: [ial2, apb, ppif, composition, interconnect, task-tree]
evidence: docs/IAL2_APB_INTERCONNECT_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_APB_INTERCONNECT_COMPOSITION_READINESS_AUDIT.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; ppif/apb_composition.ppif; ppif/apb_composition.apb; ppif/apb_completer.ppif; ppif/apb_completer.apb; ppif/apb_requester_transfer.ppif; fsm/apb_tb.fsm; fsm/apb_requester.fsm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.565|ppif/apb_composition\\.ppif|apb-composition|fsmgen\\.ial2\\.protocol_intent\\.apb_composition\\.v1|intent\\.ppif_apb_composition|apb_requester_busy_status_deferred|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.566' docs/IAL2_APB_INTERCONNECT_COMPOSITION_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.565` selects the first APB composition
contract and advances to `.566`, direct bounded APB `.ppif` composition
implementation.

The selected source is `ppif/apb_composition.ppif` with top-level intent
`apb_composition`. It uses explicit `(profile apb)`, one
`(apb-requester apb_requester ...)`, one `(apb-completer apb_completer ...)`,
and one `(apb-composition apb_tb ...)` that references the embedded endpoint
objects through child aliases `requester` and `completer`.

The selected report schema is
`fsmgen.ial2.protocol_intent.apb_composition.v1`; the selected support entry
is `intent.ppif_apb_composition` with coverage
`ial2_ppif_apb_composition_pipeline_cli`, source kind `ppif`, expected top
`apb_tb`, and expected child modules `apb_requester` and `apb_completer`.

The first generated composition does not expose requester `busy`, because the
shipped public APB requester `.ppif` response contract exposes `done`,
`last_error`, and `last_read_data` only. Busy/status output remains deferred as
`apb_requester_busy_status_deferred`.

`.565` selects `(apb-composition ...)`, not `(apb-interconnect ...)`, because
the first behavior is fixed one-requester/one-completer wiring and not
multi-peripheral address decode or routing. `.569` later exposes the shipped
completer and fixed composition through `.apb`. Multi-peripheral
interconnect/decode, multi-register decode, sidebands/strobes, alternate
widths, back-to-back policy, direct backend, verification-output generation,
backend-language variants, AXI, and VHDL remain deferred.
