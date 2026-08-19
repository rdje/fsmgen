---
id: xial-native-development-framework
title: The xIAL framework is a no-HDL development ecosystem around the IASIM kernel
answers:
  - "what does xIAL mean?"
  - "what is the xIAL native development framework?"
  - "is IASIM only a simulator command?"
  - "can all design and verification work happen at xIAL level?"
  - "what ecosystem should surround IASIM?"
  - "how does the xIAL framework relate to IASIM?"
  - "does xIAL intent signoff replace physical design signoff?"
  - "is HDL export optional in the xIAL framework?"
  - "how is xIAL to HDL export signed off?"
  - "must published xIAL HDL meet HDL standards?"
date: 2026-08-10
status: current
tags: [hial, vial, xial, iasim, architecture, signoff, task-tree]
evidence: >-
  docs/tasks/XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.md;
  docs/tasks/IASIM-EXECUTABLE-REFERENCE-SEMANTICS.md;
  docs/TASK_TREE.md;
  ROADMAP_V2.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  scripts/check_task_tree_integrity.pl &&
  rg -n 'complete native framework|xIAL|HIAL IP|VIAL VIP|functional/intent signoff'
  docs/tasks/XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.md
---

`XIAL-NATIVE-DEVELOPMENT-FRAMEWORK` broadens the product direction from an
engine into a complete ecosystem. Here `xIAL` means HIAL or VIAL (`x = H` or
`x = V`), not another language tier. The primary no-HDL loop is author and
compose HIAL plus VIAL, elaborate/check, execute in IASIM, inspect/debug,
measure and close coverage, regress, then issue a scoped native xIAL signoff
manifest. IASIM stays the small independently qualified semantic kernel; a
stable session/query API keeps rich framework policy and clients from changing
execution meaning.

The surrounding framework owns reproducible workspaces and incremental builds,
authoring/introspection, reusable versioned HIAL IP and VIAL VIP/packages,
interactive sessions, typed semantic traces, causal debug and time travel,
verification services, regression/triage, coverage closure and waivers,
visualization, automation/extensions, scale/recovery, and signoff governance.
CLI, TUI, IDE, web, and automation clients share one typed service truth.
Generated HDL and external tools remain unnecessary for operating the native
inner loop, but supported HDL export is not an optional product-quality
obligation. Every advertised
publishable xIAL-to-HDL profile must name exact language/methodology revisions
and pass professional source/packaging, source-map, LRM conformance, lint/
warning, parse/compile/elaboration/runtime, IASIM differential, multi-tool
portability, and applicable synthesis/equivalence gates with a reproducible
conformance manifest. HDL still does not define xIAL meaning. Native xIAL
functional/intent signoff also does not silently claim synthesis, timing,
CDC/RDC, DFT, physical implementation, analog, or silicon signoff; those keep
separate explicit evidence layers.

Related: [[iasim-executable-reference-semantics]],
[[hial-vial-verification-fixture-architecture]].
