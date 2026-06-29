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
evidence: docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md; docs/IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md; docs/IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; fsm/amba_requester.fsm; ppif/ahb_requester.ppif; ppif/ahb_requester.ahb; docs/vendor; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg --files docs/vendor && perl -we 'for my $f (qx(rg --files docs/vendor)) { die $f if $f =~ /(?:ahb|ahb-lite|ihi00(?:11|33))/i } print "no local AHB vendor reference\n";' && ./bin/fsmgen --quiet --strict --check --json fsm/amba_requester.fsm && perl -we 'for my $f (qx(rg --files fsm ppif perl/FSM/IAL2/ProtocolIntent t)) { die $f if $f =~ /ahb.*(?:completer|subordinate|slave)|(?:completer|subordinate|slave).*ahb/ } print "no AHB completer/subordinate fixture\n";' && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.703|IAL2-FEATURE-COMPLETENESS-FRONTIER\.704|source-reference|lower-layer AHB subordinate seed' docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.703` does not select the lower-layer AHB
subordinate seed contract yet. It selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.704`,
an AHB subordinate source-reference and seed-evidence audit.

The current repository evidence is requester-only:
`fsm/amba_requester.fsm`, `ppif/ahb_requester.ppif`, and
`ppif/ahb_requester.ahb`. The local `docs/vendor/` inventory contains AXI,
PSS, UVM, and SystemRDL references, but no AHB/AHB-Lite source reference.

The seed contract needs source-backed evidence for subordinate signal roles,
transfer qualification, ready/response timing, read/write storage behavior,
reset/default outputs, and unsupported-transfer policy before a direct `.fsm`
seed can be selected.

AHB IAL2 completer/subordinate contract selection, interconnect/decode,
scoreboards, full-manager behavior, direct backend, verification-output,
backend-language variants, AXI, APB, and VHDL remain future owners.
