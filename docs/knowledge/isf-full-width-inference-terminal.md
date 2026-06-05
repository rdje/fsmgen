---
id: isf-full-width-inference-terminal
title: ISF multi-unknown data-operation width inference is intentionally fail-closed
answers:
  - "is full-width inference still closed?"
  - "can ISF infer two unknown assemble part widths?"
  - "can ISF infer two unknown extract field widths?"
  - "does multi-unknown width inference have a decidable subcase?"
  - "why does assemble with multiple unknown parts fail closed?"
  - "why does extract with multiple unknown fields fail closed?"
date: 2026-06-05
status: current
tags: [isf, data-operations, width-inference, fail-closed]
evidence: docs/tasks/ISF-FULL-WIDTH-INFERENCE.md; t/1385-isf-multi-unknown-width-fail-closed-terminal.t
reverify: prove -Iperl t/1385-isf-multi-unknown-width-fail-closed-terminal.t t/1344-isf-assemble-static-part-widths.t t/1101-isf-extract-slices.t
---

ISF has no decidable multi-unknown data-operation width inference case beyond
the shipped single-missing `assemble` part and single-missing `extract` field
inference. Two or more unknown widths with one total-width equation are
underdetermined, so the correct terminal remains fail-closed unless a future
task-tree owner introduces independent width evidence that reduces the case to
one unknown. The executable lock is `t/1385-isf-multi-unknown-width-fail-closed-terminal.t`.
