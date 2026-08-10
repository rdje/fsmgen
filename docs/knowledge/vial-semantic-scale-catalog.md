---
id: vial-semantic-scale-catalog
title: VIAL semantic scale uses canonical source, scoped IDs, and earliest caps
answers:
  - "how are VIAL architecture semantic scale workloads generated?"
  - "does VIAL semantic scale forge SemanticIR?"
  - "how are VIAL expectation handle and fiber semantic IDs scoped?"
  - "why does the VIAL literal repeat qualification candidate reject early?"
  - "how do I run the exact VIAL semantic catalog proof?"
date: 2026-08-10
status: current
tags: [vial, semantic-ir, scalability, semantic-id, limits, verification]
evidence: >-
  docs/decisions/0058-vial-action-local-semantic-ids-follow-language-scope.md;
  docs/decisions/0059-vial-literal-repeat-scale-is-currently-dominated-by-expanded-actions.md;
  perl/FSM/VIAL/ArchitectureScaleSemanticCatalog.pm;
  perl/FSM/VIAL/SemanticBuilder.pm;
  t/1550-vial-semantic-ir.t;
  t/1601-vial-architecture-scale-semantic-catalog.t;
  docs/book/src/16d-hial-vial-verification-architecture.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
reverify: >-
  prove -Iperl t/1550-vial-semantic-ir.t
  t/1601-vial-architecture-scale-semantic-catalog.t &&
  FSMGEN_VIAL_SCALE_EXACT=1 scripts/run_with_ram_guard.sh --
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t
---

`FSM::VIAL::ArchitectureScaleSemanticCatalog` constructs all 14 selected
semantic axes and five levels as ordinary typed `.vial` sources. It accepts no
IR input: the shipped parser and semantic builder alone produce
`VIALSemanticIR`. Reusable evaluations prove counts, IDs, spans, reference/type
closure, authored order, independent reports, formatting, byte boundaries,
diagnostics, and cleanup without making a capacity claim.

Decision `0058` scopes handles and expectations by their named scenario.
Fibers also retain the structural path of their unnamed parallel scope. The
checked AHB reference therefore has 53 globally unambiguous named IDs even
when expectation names repeat across scenarios.

Decision `0059` records one current limit interaction. Repeat 65,535 with one
body action reaches the 65,536 expanded-action cap; repeat 65,536 rejects
there. The selected 262,144 qualification and 1,000,000 boundary consequently
remain earlier-cap rejections until `.17.4` decides limit policy. The 4,096
gate succeeds, and 1,000,001 rejects at the repeat-count validator.
