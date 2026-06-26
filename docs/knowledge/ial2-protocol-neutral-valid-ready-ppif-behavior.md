---
id: ial2-protocol-neutral-valid-ready-ppif-behavior
title: FSMGen ships a protocol-neutral valid-ready PPIF sample
answers:
  - "does FSMGen have a protocol-neutral Valid-Ready PPIF sample?"
  - "how do I run the valid-ready PPIF sample?"
  - "what is ppif/valid_ready_handshake.ppif?"
  - "what support-accounting id covers the neutral Valid-Ready PPIF sample?"
  - "does the neutral Valid-Ready PPIF sample use AXI channel families?"
date: 2026-06-26
status: current
tags: [ial2, ppif, protocol-platform, valid-ready, profile, sample, support-accounting]
evidence: docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_BEHAVIOR.md; ppif/valid_ready_handshake.ppif; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; docs/REGRESSION_CORPUS.md; t/1435-axi-ial2-valid-ready-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: prove -Iperl t/1435-axi-ial2-valid-ready-generator.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t && perl -Iperl -c t/1436-ial2-ppif-parser-cli.t && ./bin/fsmgen --emit-schedule-json ppif/valid_ready_handshake.ppif && ./bin/fsmgen --strict --check --json ppif/valid_ready_handshake.ppif && ./bin/fsmgen --strict --emit-semantic-json ppif/valid_ready_handshake.ppif
---

FSMGen ships `ppif/valid_ready_handshake.ppif` as the first
protocol-neutral/non-AXI Valid-Ready `.ppif` sample.

It uses `(profile valid-ready)`, logical channel `data_link`, role
`producer-to-consumer`, generated monitor `data_link_valid_ready_monitor`, and
support-accounting id `intent.ppif_valid_ready_handshake`. It does not use AXI
channel families.
