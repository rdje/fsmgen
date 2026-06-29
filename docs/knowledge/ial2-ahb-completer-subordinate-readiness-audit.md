---
id: ial2-ahb-completer-subordinate-readiness-audit
title: AHB completer/subordinate readiness requires a lower-layer seed contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.702 select?"
  - "is AHB completer/subordinate ready for IAL2 contract selection?"
  - "does FSMGen have an AHB subordinate fixture?"
  - "why not select AHB interconnect after requester .ahb?"
  - "what comes after AHB completer/subordinate readiness?"
date: 2026-06-29
status: current
tags: [ial2, ahb, completer, subordinate, readiness, lower-layer, task-tree]
evidence: docs/IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md; docs/IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; fsm/amba_requester.fsm; ppif/ahb_requester.ppif; ppif/ahb_requester.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json fsm/amba_requester.fsm && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb && perl -we 'for my $f (qx(rg --files fsm ppif perl/FSM/IAL2/ProtocolIntent t)) { die $f if $f =~ /ahb.*(?:completer|subordinate|slave)|(?:completer|subordinate|slave).*ahb/ } print "no AHB completer/subordinate fixture\n";' && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.702|IAL2-FEATURE-COMPLETENESS-FRONTIER\.705|ahb_completer_subordinate_deferred|ahb_interconnect_decode_deferred|source-reference import' docs/IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md docs/IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md MEMORY.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.702` finds AHB
completer/subordinate IAL2 work not ready for public IAL2 contract selection.
It selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.703`, lower-layer AHB
subordinate seed contract selection.

The current AHB evidence is requester-only: direct `fsm/amba_requester.fsm`,
generic IAL2 `ppif/ahb_requester.ppif`, and profile alias
`ppif/ahb_requester.ahb`. A repository scan finds no shipped AHB completer,
subordinate, or slave fixture/generator.

The missing lower-layer seed blocks IAL2 contract selection because the first
subordinate must choose signal families, ready/response timing, read/write
storage behavior, transfer qualification, reset/default outputs, and
unsupported-transfer policy before source vocabulary and generated artifacts
are promised.

AHB interconnect/decode is later because it needs at least one selected
subordinate endpoint first. Full manager behavior, scoreboards, direct
backend, verification-output, backend-language variants, AXI, APB, and VHDL
remain future owners.

The follow-on `.703` selector found no local AHB/AHB-Lite source reference
under `docs/vendor/` and selected `.704`, AHB subordinate source-reference and
seed-evidence audit, before lower-layer seed contract selection. `.704` then
selected `.705`, AHB/AHB-Lite local source-reference import prerequisite,
because no local source artifact or curated subordinate evidence inventory
exists yet.
