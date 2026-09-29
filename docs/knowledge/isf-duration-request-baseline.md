---
id: isf-duration-request-baseline
title: Physical-time durations require a new clock-rate and counter contract
answers:
  - "does ISF accept durations in milliseconds or microseconds?"
  - "does an ISF clock clause declare a frequency or period?"
  - "why does a large static wait expand into many states?"
  - "where is the SPECFORGE duration request baseline preserved?"
date: 2026-09-30
status: current
tags: [isf, duration, clock, frequency, wait, counter, specforge]
evidence: docs/audits/specforge-duration-intake-20260930/manifest.json; docs/audits/specforge-duration-intake-20260930/capture.t; docs/audits/specforge-duration-intake-20260930/verify.py; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; docs/book/src/13k-isf-feature-support-matrix.md
reverify: python3 -B docs/audits/specforge-duration-intake-20260930/verify.py
---

The preserved `sf-isf-duration-time-units` packet requests physical-time bounds,
a declared literal/parameter clock frequency or period, exact directed rounding,
source/conversion reports and counter-based duration lowering. Legal duration
ranges are optional. SEM `.60.1` owns required and optional dispositions;
intake does not implement the feature or select its illustrative syntax.

Current supplied wait/watchdog duration forms and the proposed frequency-bearing
clock fail. Parser `_parse_clock` accepts one name; LoweringIR `_wait_count_spec`
treats a list count as a runtime expression and refuses the `time` operator;
`_parse_await_wd` requires a scalar watchdog bound. `_ir_wait` builds a state
for each resolved static cycle. `_ir_dynamic_wait` already uses sampled-count
storage, with qualified entry and pending-sample semantics in
`isf-dynamic-wait-count-predicates.md`.

The audit retains complete native/API/newline outcomes and the actual baseline
carrier. The accepted cycle-parameter schedule matches SPECFORGE's supplied
schedule after excluding only the separately shipped reset-provenance field.
Its independently counted state chain has no wait counter. The requested
compatibility contract preserves that cycle-count baseline; efficient physical
duration lowering must not silently change existing report/state semantics.

The supplied large timeout and external corpus counts were not remeasured.
Only the bounded supplied baseline was exercised; no native HDL was executed.
The offline verifier checks immutable products and hostile controls. Its capture
script describes this dated baseline and may intentionally fail after duration
support ships; update this card when the public contract changes.
