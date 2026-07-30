---
id: fsmgen-source-hir-two-route-promotion-audit
title: SourceHIR remains a private validated architecture boundary after two routes
answers:
  - "should SourceHIR be public after both lowering routes?"
  - "is another private SourceHIR fixture planned?"
  - "was SourceHIR retired or renamed after the IAL1 proof?"
  - "who owns a future public SourceHIR builder?"
  - "what concluded FSMGEN-HIR-ROADMAP-FRONTIER.8?"
date: 2026-07-30
status: current
tags: [source-hir, architecture, promotion, private, audit, ial1, ial2]
evidence: docs/FSMGEN_SOURCE_HIR_TWO_ROUTE_PROMOTION_AUDIT.md; docs/decisions/0031-source-hir-remains-a-private-validated-architecture-boundary.md; docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; docs/tasks/IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.md; perl/FSM/IR/SourceHIR.pm; perl/FSM/IR/SourceHIRBuilder.pm; perl/FSM/IR/SourceHIRPPIFRenderer.pm; perl/FSM/IR/SourceHIRISFRenderer.pm; t/1547-source-hir-valid-ready.t; t/1548-source-hir-phase-control.t
reverify: prove -Iperl t/1547-source-hir-valid-ready.t t/1548-source-hir-phase-control.t && rg -n 'SourceHIR|source_hir' bin/fsmgen perl/FSM/Support t/1547-source-hir-valid-ready.t t/1548-source-hir-phase-control.t
---

After two exact private route proofs, SourceHIR remains a private validated
architecture boundary. T1547 proves protocol/platform intent through canonical
PPIF/IAL2; t1548 proves concrete control through canonical ISF/IAL1. Both share
immutable closed objects, provenance/source-map rules, deterministic
validation/rendering, existing-parser re-entry, and exact downstream
equivalence without target-syntax or parser-AST storage.

The architecture is broad enough, so narrowing/renaming and retirement are
rejected. No third architecture-only private route is selected. Public
promotion is also rejected for now because all producers remain tests and no
supported language/package, public schema/serialization, versioning,
compatibility, diagnostics, or user workflow has been selected.

`IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` remains the owner of any future public
producer and projection. It is not activated by this audit.
