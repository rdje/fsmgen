---
id: ial2-apb-back-to-back-behavior
title: APB back-to-back behavior ships selected depth-1 queued policy
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.607?"
  - "does APB back-to-back timing-policy behavior ship?"
  - "which APB back-to-back samples are supported?"
  - "how does the APB requester accepted signal work?"
date: 2026-06-28
status: current
tags: [ial2, apb, back-to-back, timing, behavior, task-tree]
evidence: docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md; ppif/apb_requester_transfer_status_back_to_back.ppif; ppif/apb_completer_back_to_back.ppif; ppif/apb_composition_status_back_to_back.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t
reverify: prove -Iperl t/1470-ial2-apb-profile-alias.t t/1471-ial2-apb-completer.t t/1472-ial2-apb-composition.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.607` ships the selected APB
back-to-back timing-policy behavior for exactly the status-observable
requester, one-register completer, and fixed one-requester/one-completer
composition sample family.

The supported sample paths are
`ppif/apb_requester_transfer_status_back_to_back.ppif/.apb`,
`ppif/apb_completer_back_to_back.ppif/.apb`, and
`ppif/apb_composition_status_back_to_back.ppif/.apb`.

The requester policy is depth-1 queued with overflow reject. `accepted` pulses
when `start` is sampled into either the active slot or the empty queued slot.
If the active transfer and queued slot are occupied, overflow does not pulse
`accepted` and does not overwrite the queued request. A queued transfer can
drive the next APB setup with `PSEL=1` and `PENABLE=0` without an inserted idle
bus cycle.

The completer policy is explicit adjacent setup admission on `PSEL &&
!PENABLE`. Fixed composition propagates compatible endpoint policies and
reports aggregate `back_to_back_policy` metadata.

`.609` later ships the selected 32-bit no-sideband two-peripheral
multi-peripheral status family. Multi-peripheral variants beyond that selected
family, sideband/data16/protection variants, deeper queues, alternate overflow
policies, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred.
