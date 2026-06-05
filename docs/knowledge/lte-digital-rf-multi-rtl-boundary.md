---
id: lte-digital-rf-multi-rtl-boundary
title: lte_digital_rf remains an expected failure at the multi-module ?rtl boundary
answers:
  - "why is lte_digital_rf not in external validation smoke?"
  - "what blocks fsm/lte_digital_rf.fsm?"
  - "is lte_digital_rf supported?"
  - "what is the lte_digital_rf ?rtl boundary?"
  - "should legacy multi-module ?rtl children be implemented?"
date: 2026-06-05
status: current
tags: [composition, rtlif, validation, regression-corpus]
evidence: fsm/lte_digital_rf.fsm; perl/FSM/Support/RegressionCorpus.pm; t/248-regression-corpus-accounting.t; t/249-regression-corpus-classified-behavior.t; t/300-check-json-regression-corpus.t; t/304-normalized-semantic-json-regression-corpus.t; docs/book/src/05-composition-basics.md; docs/book/src/10-errors-strict-mode-and-troubleshooting.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t
---

`fsm/lte_digital_rf.fsm` is not part of the external SystemVerilog validation
smoke. It is a historical composition sample whose first stable boundary is
the `?rtl:lte_dif_iosocket` child carrying 36 flat RTL module references.
FSMGen rejects that shape with `FSMGEN_COMPOSITION_RTL_CHILD_SOURCE_COUNT`, and
the regression corpus records the whole file as
`contract.lte_digital_rf_rtl_child_source_count` rather than reviving the
broader legacy multi-module `?rtl` dialect.
