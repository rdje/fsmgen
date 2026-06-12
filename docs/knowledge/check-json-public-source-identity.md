---
id: check-json-public-source-identity
title: Check JSON preserves public source identity for lowered inputs
answers:
  - "does check JSON report the original .isf source path?"
  - "does check JSON report the original .ppif source path?"
  - "does check JSON match support accounting for .isf and .ppif samples?"
date: 2026-06-12
status: current
tags: [check-json, support-accounting, isf, ppif, public-api]
evidence: bin/fsmgen; perl/FSM/Support/RegressionCorpus.pm; t/301-check-json-supported-corpus.t; t/1436-ial2-ppif-parser-cli.t; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md; docs/tasks/CHECK-JSON-PUBLIC-SOURCE-IDENTITY.md
reverify: prove -Iperl t/301-check-json-supported-corpus.t t/1436-ial2-ppif-parser-cli.t
---

For successful public inputs that lower through generated `.fsm` temporaries,
check JSON reports the original resolved public source path. The shipped
`isf/apb_requester.isf` and `ppif/axi_aw_valid_ready.ppif` examples both keep
their `.isf`/`.ppif` path in `source.resolved_path` and have matched
support-accounting entries.
