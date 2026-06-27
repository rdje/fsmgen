---
id: ial2-apb-back-to-back-contract-selection
title: APB back-to-back contract selects explicit queued timing policy
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.606?"
  - "what APB back-to-back source syntax is selected?"
  - "does APB back-to-back policy require accepted?"
  - "what is the first APB back-to-back sample family?"
  - "what comes after APB back-to-back contract selection?"
date: 2026-06-28
status: current
tags: [ial2, apb, back-to-back, timing, contract, task-tree]
evidence: docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_BACK_TO_BACK_READINESS_AUDIT.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.606|IAL2-FEATURE-COMPLETENESS-FRONTIER\.607|timing-policy|back-to-back queued|queue-depth 1|overflow reject|setup-admission adjacent|accepted|apb_requester_transfer_status_back_to_back|apb_composition_status_back_to_back' docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.606` selects the public APB
back-to-back transfer policy contract without changing behavior.

The selected requester syntax is an explicit `(timing-policy ...)` clause under
the existing APB requester `(transfer ...)` block:
`(back-to-back queued)`, `(queue-depth 1)`, and `(overflow reject)`. The
selected requester response surface requires `(accepted NAME)`, `(busy NAME)`,
and `(status NAME width 2)` so accepted queued requests and overflow rejection
are observable. The selected completer syntax adds `(timing-policy
(setup-admission adjacent))` under the existing APB completer transfer block.

The first implementation owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.607`, bounded to requester, completer, and
fixed one-requester/one-completer composition samples:
`apb_requester_transfer_status_back_to_back`,
`apb_completer_back_to_back`, and `apb_composition_status_back_to_back`, each
with `.ppif` and `.apb` profile-alias coverage. Multi-peripheral,
sideband/data16/protection, deeper queues, alternate overflow policies, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain deferred.
