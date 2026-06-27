---
id: ial2-apb-public-surface-report-static-sync
title: APB public surface names shipped sideband-aware coverage
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.591?"
  - "did .591 change APB behavior?"
  - "what APB public surface cleanup happened after sideband strobes?"
  - "what comes after APB public surface cleanup?"
  - "why is APB alternate width readiness next?"
date: 2026-06-27
status: current
tags: [ial2, apb, sideband, strobe, pprot, pstrb, public-surface, manifest, task-tree]
evidence: docs/IAL2_APB_PUBLIC_SURFACE_REPORT_STATIC_SYNC.md; perl/FSM/Support/LanguageSurfaceSection.pm; t/297-capability-manifest.t; docs/IAL2_POST_APB_SIDEBAND_STROBE_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB prove -Iperl t/297-capability-manifest.t && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.591|IAL2-FEATURE-COMPLETENESS-FRONTIER\.592|sideband-aware APB requester-transfer source|APB alternate widths, APB PPROT access-control effects, APB back-to-back policy|APB alternate-width readiness' docs/IAL2_APB_PUBLIC_SURFACE_REPORT_STATIC_SYNC.md perl/FSM/Support/LanguageSurfaceSection.pm t/297-capability-manifest.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.591` synchronizes static public APB
language-surface wording after `.589` shipped bounded `PPROT`/`PSTRB`
sideband/strobe behavior.

The generic `.ppif` language-surface manifest now names the shipped
sideband-aware APB requester-transfer, multi-register completer, fixed
multi-register composition, and multi-peripheral composition `.ppif` sources.
It also records that `.apb` mirrors those sideband-aware `.ppif` sources
through support-accounted profile-alias fixtures.

`.591` removes the stale broad "APB sidebands" deferred wording from the
generic `.ppif` boundary. The remaining APB residues are APB alternate widths,
APB `PPROT` access-control effects, and APB back-to-back policy.

`.591` changes no parser behavior, generator behavior, source samples,
support-accounting identities, report schemas, schedule/check/semantic JSON
behavior, generated artifacts, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

The next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.592`, APB
alternate-width readiness audit, because address/data width policy determines
`PSTRB` width, byte-lane mapping, static validation, generated port widths, and
whether sideband-aware aliases can scale beyond the fixed 32-bit first slice.
