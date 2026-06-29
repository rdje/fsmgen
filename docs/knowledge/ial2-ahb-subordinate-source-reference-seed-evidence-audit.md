---
id: ial2-ahb-subordinate-source-reference-seed-evidence-audit
title: AHB subordinate seed evidence requires a local AHB/AHB-Lite reference import
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.704 select?"
  - "is AHB subordinate seed evidence source-backed?"
  - "what comes after AHB subordinate source-reference audit?"
  - "what must happen before AHB subordinate source-fact extraction?"
  - "why can't .704 select the AHB subordinate seed contract?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, source-reference, seed, evidence, vendor, task-tree]
evidence: docs/IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md; docs/IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md; docs/vendor; docs/tasks/AXI-SPEC-LOCAL-REFERENCE-IMPORT.md; docs/tasks/ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.md; docs/AXI_VALID_READY_INTENT_PROBE.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: perl -we 'for my $f (qx(rg --files -uu docs/vendor .cache/local-references 2>/dev/null)) { die $f if $f =~ /(?:ahb|ahb-lite|ihi00(?:11|33))/i } print "no local AHB/AHB-Lite reference artifact in repo-local vendor/cache inputs\n";' && perl -we 'for my $f (qx(rg --files fsm ppif perl/FSM/IAL2/ProtocolIntent t)) { die $f if $f =~ /ahb.*(?:completer|subordinate|slave)|(?:completer|subordinate|slave).*ahb/ } print "no AHB completer/subordinate fixture\n";' && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.704|IAL2-FEATURE-COMPLETENESS-FRONTIER\.705|blocked|source-reference import|docs/vendor/arm/amba/ahb' docs/IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.704` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.705`, an AHB/AHB-Lite local
source-reference import prerequisite.

The repo still has no local AHB/AHB-Lite source reference artifact under
`docs/vendor/`, and the shipped AHB evidence remains requester-only:
`fsm/amba_requester.fsm`, `ppif/ahb_requester.ppif`, and
`ppif/ahb_requester.ahb`.

AHB subordinate source-fact extraction and lower-layer direct `.fsm` seed
contract selection remain deferred. Follow-on `.705` recorded the precise
missing-artifact blocker: no approved/provided AHB/AHB-Lite source artifact
exists under tracked `docs/vendor/` or `.cache/local-references/`.

No source reference, seed, parser/generator behavior, support-accounting,
manifest, test behavior, generated artifact, HDL/runtime behavior, direct
backend, verification-output, backend-language variant, AXI, APB, or VHDL
behavior changed in `.704`.
