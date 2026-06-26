---
id: ppif-check-json-oversized-summary
title: Oversized PPIF manager-capacity check JSON uses a bounded source summary
answers:
  - "how was the t/301 PPIF manager-capacity check-json resource blocker resolved?"
  - "does oversized PPIF manager-capacity check JSON invoke HDL generation?"
  - "what check-json path handles depth-3 PPIF manager-capacity issue-order queue fixtures?"
  - "what verifies oversized PPIF check JSON no longer enters the HDL backend?"
date: 2026-06-26
status: current
tags: [check-json, ppif, ial2, resource-boundary, backend-portability]
evidence: bin/fsmgen; t/1466-ppif-check-json-oversized-summary.t; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/TASK_TREE.md
reverify: prove -Iperl t/1466-ppif-check-json-oversized-summary.t
---

Oversized PPIF manager-capacity sources whose generated IAL0 `.fsm` entry is
larger than the bounded check-summary threshold return successful check JSON
directly from the already-lowered PPIF result. The replacement path preserves
the public `.ppif` source identity, support-accounting match, module name,
state/signal/count result keys, and `generated_output.emitted == false` without
entering the HDL backend that caused the `t/301` resource blocker.

Normal HDL generation, semantic JSON, schedule JSON, generated review
artifacts, and smaller manager-capacity PPIF check-json sources still use their
existing paths. The focused regression is
`t/1466-ppif-check-json-oversized-summary.t`; it asserts the depth-3 dynamic
write same-ID issue-order queue fixture returns source-level summary counts
instead of backend-expanded counts.
