---
id: ial2-ahb-local-source-reference-import-blocker
title: AHB subordinate source work is blocked on a local AHB/AHB-Lite reference artifact
answers:
  - "what blocked IAL2-FEATURE-COMPLETENESS-FRONTIER.705?"
  - "does the repo have an AHB/AHB-Lite source artifact?"
  - "what is needed to unblock AHB subordinate seed work?"
  - "why can't AHB source-fact extraction continue?"
  - "what comes after .705?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, source-reference, blocker, vendor, task-tree]
evidence: docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_REFERENCE_SEED_EVIDENCE_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md; docs/vendor; .cache/local-references; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: perl -we 'for my $f (qx(rg --files -uu docs/vendor .cache/local-references 2>/dev/null)) { die $f if $f =~ /(?:ahb|ahb-lite|ihi00(?:11|33))/i } print "no local AHB/AHB-Lite reference artifact in repo-local vendor/cache inputs\n";' && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.705|blocked|docs/vendor/arm/amba/ahb|source artifact' docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.705` is blocked. A repo-local search found
no acceptable AHB/AHB-Lite source reference artifact under tracked
`docs/vendor/` or the local `.cache/local-references/` mirror.

The tracked vendor inventory contains AXI, PSS, UVM, and SystemRDL references,
but no AHB/AHB-Lite reference. The local cache scan also found no path matching
AHB, AHB-Lite, or likely Arm document identifiers for AHB/AHB-Lite.

AHB subordinate source-fact extraction and lower-layer direct `.fsm`
subordinate seed contract selection cannot continue from requester-only code,
APB precedent, or non-authoritative summaries. They require a user-provided or
explicitly approved official AHB/AHB-Lite source artifact suitable for
tracking under `docs/vendor/arm/amba/ahb/`.

No source reference, source facts, seed, parser/generator behavior,
support-accounting, manifest, test behavior, generated artifact, HDL/runtime
behavior, direct backend, verification-output, backend-language variant, AXI,
APB, or VHDL behavior changed in `.705`.
