---
id: canonical-width-expression-capture
title: Opt-in width capture records actual prefix and infix evaluation structure and lookups
answers:
  - "where can canonical width evaluation capture actual selected bindings?"
  - "how do nested infix width payload lookups retain immediate identity?"
date: 2026-10-27
status: current
tags: [widths, source-capture, parameters, namespaces]
evidence: perl/FSM/WidthExpressionSupport.pm; t/2156-canonical-width-expression-capture.t; docs/audits/canonical-width-expression-capture-20261027.json.gz
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2156-canonical-width-expression-capture.t t/2128-shared-integer-width-evaluator.t t/2111-ial0-parameter-width-selection.t
---

capture_positive_width_expression returns detached width, binding and
observations records during the existing evaluator walk. Literal tokens,
authored prefix aliases, ordered operands and actual infix precedence survive.
Reference nodes join ordered observations by index and retain selected payload
expression structure, including nested lookups and repeated immediate roots.

Ordinary symbols use an actual static_symbol/parameter observation hook once;
explicit selectors use the existing declared-only parameter hook. Callback
payloads supply values, never equality-based namespace guesses. The record's
lookup field distinguishes those entrypoints. No lexical/target scope or
caller-provenance attestation is invented.

Ordinary APIs and payload callbacks remain unchanged. JSON-incompatible or
cyclic source/observation records, cyclic captured lookup chains, malformed
observations and canonical invalid widths refuse atomically. Transient state
restores on success/failure/retry; callback work stays outside the outer stack.
Held plain results retain neither evaluator nor callbacks. Exact ordinary
values/refusals/callback order/caller kinds match the predecessor; full raw
error traces remain retained with location-only comparison boundaries.

Direct parser/Core publication remains ISF-REDUCTION-DELIVERY.3.3.1.2.2. This
kernel alone activates no source grammar, public schema or symbolic HDL ranges.
