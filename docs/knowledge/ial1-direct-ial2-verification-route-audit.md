---
id: ial1-direct-ial2-verification-route-audit
title: Direct PPIF verification-output generation is not selected
answers:
  - "does FSMGen support direct ppif verification output?"
  - "should IAL2 feed verification generation directly?"
  - "what did IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6 decide?"
  - "how should future PPIF protocol verification facts reach verification output?"
  - "does --emit-verification-output accept .ppif?"
date: 2026-06-26
status: current
tags: [ial1, ial2, ppif, verification, task-tree]
evidence: docs/IAL1_DIRECT_IAL2_VERIFICATION_ROUTE_AUDIT.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/297-capability-manifest.t; t/1464-isf-verification-output-uvm-passive-monitor.t; t/1465-isf-verification-output-vhdl-observation-package.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL1_DIRECT_IAL2_VERIFICATION_ROUTE_AUDIT|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6|direct .ppif verification-output|direct IAL2-to-verification|direct IAL2 route|--emit-verification-output|vhdl-observation-package|uvm-passive-monitor|direct_ial2_to_ial0|verification-output CLI mode for .ppif|language_surface.file_surfaces' docs/IAL1_DIRECT_IAL2_VERIFICATION_ROUTE_AUDIT.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/ISF_PUBLIC_INTERFACE_CONTRACT.md docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/Support/LanguageSurfaceSection.pm t/297-capability-manifest.t t/1464-isf-verification-output-uvm-passive-monitor.t t/1465-isf-verification-output-vhdl-observation-package.t README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6` selected no direct
IAL2-to-verification generation route for the current verification-output
lane. FSMGen's shipped `--emit-verification-output` modes remain `.isf`-only,
and `.ppif` is intentionally not advertised with UVM or VHDL verification
output modes in the capability manifest language surface.

The selected future route for PPIF protocol-specific verification facts is to
lower or annotate the generated IAL1 `.isf` review artifact first, then reuse
the IAL1 verification-output path. A direct IAL2 verification-output route
requires a later exact owner that proves the required protocol facts cannot be
made reviewable in generated IAL1 without losing semantics.

This decision changes routing doctrine and documentation only. It does not
change parser behavior, PPIF lowering, verification-output artifacts,
manifests, support accounting, generated HDL, or CLI behavior.
