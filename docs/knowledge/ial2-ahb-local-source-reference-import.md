---
id: ial2-ahb-local-source-reference-import
title: AHB/AHB-Lite source reference artifact is imported under docs/vendor
answers:
  - "does the repo have an AHB/AHB-Lite source artifact?"
  - "what resolved IAL2-FEATURE-COMPLETENESS-FRONTIER.705?"
  - "where is the imported AHB source reference?"
  - "what comes after .706?"
  - "what is needed before AHB subordinate seed selection now?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, source-reference, vendor, task-tree]
evidence: docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md; docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: test -f docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf && shasum -a 256 docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.706|IAL2-FEATURE-COMPLETENESS-FRONTIER\.707|IAL2-FEATURE-COMPLETENESS-FRONTIER\.708|docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification\.pdf|source-backed AHB/AHB-Lite subordinate fact|seed contract selection' docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.706` imported the user-approved official
Arm AMBA AHB Protocol Specification PDF under:

```text
docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf
```

The imported artifact has SHA-256:

```text
2ba2920e050e1d9f6a1b728dfef85e66eb400a3c29d774b086b7de71c768f724
```

`git check-ignore -v` produced no match for the imported path, so the PDF is
git-trackable.

This resolved the local source-reference artifact blocker recorded by `.705`.
The follow-on `.707` source-backed fact inventory has since been completed and
`.708` now owns lower-layer AHB subordinate seed contract selection.

The import did not itself extract source facts, select an AHB subordinate seed,
change parser/generator behavior, add tests, change generated artifacts, or
change HDL/runtime behavior.
