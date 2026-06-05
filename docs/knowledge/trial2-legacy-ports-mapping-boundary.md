---
id: trial2-legacy-ports-mapping-boundary
title: trial_2 remains an expected failure at the legacy ?ports mapping boundary
answers:
  - "why is trial_2 not in external validation smoke?"
  - "what blocks fsm/trial_2.fsm?"
  - "is trial_2 supported?"
  - "what is the trial_2 ?ports mapping boundary?"
  - "should legacy ?ports mapping directives be implemented?"
date: 2026-06-05
status: current
tags: [composition, validation, regression-corpus]
evidence: fsm/trial_2.fsm; perl/FSM/Support/RegressionCorpus.pm; t/249-regression-corpus-classified-behavior.t; t/300-check-json-regression-corpus.t; t/304-normalized-semantic-json-regression-corpus.t; docs/book/src/05-composition-basics.md; docs/book/src/10-errors-strict-mode-and-troubleshooting.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t
---

`fsm/trial_2.fsm` is not part of the external SystemVerilog validation smoke.
It is a historical composition sample whose first stable boundary is the legacy
`?ports` mapping directive `/data_o/{tasu_timestamp, tasu_pl_data}/` inside the
`lte_dif_tasu_fifo` `?ports` block. FSMGen rejects that shape with
`FSMGEN_COMPOSITION_PORT_DECLARATION_MODE`, and the regression corpus records
the whole file as `contract.trial_2_ports_mapping_directive` rather than
reviving the broader legacy composition dialect.
