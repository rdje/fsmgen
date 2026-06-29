---
id: ial2-ahb-subordinate-seed-prerequisite-selection
title: AHB subordinate seed contract needs source-backed reference evidence
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.703 select?"
  - "why did .703 not select the AHB subordinate seed contract?"
  - "does the repo have a local AHB vendor reference?"
  - "what comes after AHB subordinate seed readiness?"
  - "what must happen before the AHB subordinate seed contract?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, seed, prerequisite, reference, task-tree]
evidence: docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md; docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER.md; docs/IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md; docs/IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; fsm/amba_requester.fsm; ppif/ahb_requester.ppif; ppif/ahb_requester.ahb; docs/vendor; .cache/local-references; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json fsm/amba_requester.fsm && ./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.703|IAL2-FEATURE-COMPLETENESS-FRONTIER\.709|protocol\.ahb_lite_subordinate|Later status|lower-layer AHB subordinate seed' docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md docs/IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md docs/IAL2_AHB_SUBORDINATE_SEED_CONTRACT_SELECTION.md docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.703` does not select the lower-layer AHB
subordinate seed contract yet. It selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.704`,
an AHB subordinate source-reference and seed-evidence audit.

At `.703` time, the current repository evidence was requester-only:
`fsm/amba_requester.fsm`, `ppif/ahb_requester.ppif`, and
`ppif/ahb_requester.ahb`. The local `docs/vendor/` inventory contains AXI,
PSS, UVM, and SystemRDL references, but no AHB/AHB-Lite source reference.

Later status: `.706` imported the local AHB source reference, `.707` extracted
source-backed subordinate facts, `.708` selected the direct seed contract, and
`.709` shipped `fsm/ahb_lite_subordinate.fsm` as
`protocol.ahb_lite_subordinate`.

The seed contract needs source-backed evidence for subordinate signal roles,
transfer qualification, ready/response timing, read/write storage behavior,
reset/default outputs, and unsupported-transfer policy before a direct `.fsm`
seed can be selected.

The follow-on `.704` audit selected `.705`, AHB/AHB-Lite local source-reference
import prerequisite, because the source-backed evidence still is not available
locally.

Follow-on `.705` was later unblocked by the imported source artifact, and the
direct lower-layer seed now exists. IAL2 AHB completer/subordinate contract
selection, interconnect/decode, scoreboards, full-manager behavior, direct
backend, verification-output, backend-language variants, AXI, APB, and VHDL
remain future owners.
