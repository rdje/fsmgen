---
id: normalized-semantic-public-source-identity
title: Normalized semantic JSON preserves public source identity for lowered inputs
answers:
  - "does normalized semantic JSON report the original .isf source path?"
  - "does normalized semantic JSON report the original .ppif source path?"
  - "does normalized semantic JSON match support accounting for .isf and .ppif samples?"
  - "what source_root_kind does semantic JSON use for lowered .isf and .ppif inputs?"
date: 2026-06-12
status: current
tags: [normalized-semantic-json, support-accounting, isf, ppif, public-api]
evidence: bin/fsmgen; perl/FSM/Support/RegressionCorpus.pm; t/303-normalized-semantic-json-supported-corpus.t; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md; docs/tasks/NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY.md
reverify: prove -Iperl t/303-normalized-semantic-json-supported-corpus.t
---

For successful public inputs that lower through generated `.fsm` temporaries,
normalized semantic JSON reports the original resolved public source path. The
shipped `isf/apb_requester.isf` and `ppif/axi_aw_valid_ready.ppif` examples
both keep their `.isf`/`.ppif` path in `source.resolved_path` and have matched
support-accounting entries.

The semantic payload still describes the generated `.fsm` root that enters the
semantic pipeline, so those lowered-input entries expect
`semantic.module.source_root_kind` and `semantic.forward_ir.intent_hir.source_root_kind`
to remain `fsm`.
