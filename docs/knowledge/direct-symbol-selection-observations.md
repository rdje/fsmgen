---
id: direct-symbol-selection-observations
title: Direct payload resolution and selected-symbol observations share one branch selector
answers:
  - "how can direct width capture distinguish actual static versus parameter lookup?"
  - "does a direct parameter alias observation retain its immediate declaration?"
date: 2026-10-27
status: current
tags: [parameters, widths, namespaces, source-capture]
evidence: perl/FSM/Adapter/FSMGenFull/SignalManager.pm; t/2155-direct-symbol-selection-observations.t; docs/audits/direct-symbol-selections-20261027.json.gz
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2155-direct-symbol-selection-observations.t t/2111-ial0-parameter-width-selection.t
---

SignalManager.resolve_parameter_value_symbol_observation exposes the actual
selected branch as a detached static_symbol or parameter record. Each retains
token and value_payload; a parameter retains its immediate root and suffix.
ALIAS stays ALIAS even when its declaration default refers to W.

The old payload accessor delegates to the same selector, retaining aggregate,
constant, define, enum, exact parameter and parameter-path precedence and JSON
kinds. No eligible branch returns undef. A selected unusable static branch or
missing parameter leaf can retain an undef payload; source consumers must
check that value before admitting a resolved binding.

Actual same-name constant/parameter/type source, controlled legacy precedence,
path/root/copy controls and exact existing source/default/width/payload products
qualify this prerequisite. A held plain observation does not retain its otherwise
unreferenced SignalManager. This is not a global parser/resolver lifetime claim.
Scope, target provenance, declared-width capture and symbolic HDL activation
remain separately owned; this helper adds no public report schema.
