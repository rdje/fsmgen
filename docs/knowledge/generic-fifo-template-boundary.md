---
id: generic-fifo-template-boundary
title: generic_fifo remains an expected failure at the legacy template boundary
answers:
  - "why is generic_fifo not in external validation smoke?"
  - "what blocks fsm/generic_fifo.fsm?"
  - "is generic_fifo supported?"
  - "what is the generic_fifo ?define boundary?"
  - "should legacy ?define or ?& template macros be implemented?"
date: 2026-06-05
status: current
tags: [language-contract, templates, validation, regression-corpus]
evidence: fsm/generic_fifo.fsm; perl/FSM/Support/RegressionCorpus.pm; t/248-regression-corpus-accounting.t; t/249-regression-corpus-classified-behavior.t; t/300-check-json-regression-corpus.t; t/304-normalized-semantic-json-regression-corpus.t; docs/book/src/10-errors-strict-mode-and-troubleshooting.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t t/41-language-contract-top-level-source-kind-boundary.t
---

`fsm/generic_fifo.fsm` is not part of the external SystemVerilog validation
smoke. It is a historical template sample whose first stable boundary is the
unsupported top-level `?define:generic_fifo` source root. FSMGen rejects that
shape with `FSMGEN_LANGUAGE_UNSUPPORTED_TOP_LEVEL_SOURCE`, and the regression
corpus records the whole file as `contract.generic_fifo_define_template_source`
rather than reviving the broader legacy template dialect that also includes
`?&generic_fifo` macro instantiations, bracket placeholders, and `?repeat`
forms.
