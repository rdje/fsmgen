---
id: canonical-width-expression-capture
title: Opt-in width capture records actual prefix and infix evaluation structure and lookups
answers:
  - "where can canonical width evaluation capture actual selected bindings?"
  - "how do nested infix width payload lookups retain immediate identity?"
  - "how does direct declared-width resolution capture scope and actual lookup selection?"
  - "how are private Core declared-width bindings cloned and invalidated?"
date: 2026-10-27
status: current
tags: [widths, source-capture, parameters, namespaces]
evidence: perl/FSM/CoreAST.pm; perl/FSM/Adapter/FSMGenFull/SignalManager.pm; t/2161-core-declared-width-binding-lifecycle.t; docs/audits/core-width-binding-lifecycle-20261027.json.gz; perl/FSM/Adapter/FSMGenFull/Parser.pm; t/2160-direct-declared-width-capture.t; docs/audits/direct-declared-width-capture-20261027.json.gz; perl/FSM/WidthExpressionSupport.pm; t/2156-canonical-width-expression-capture.t; docs/audits/canonical-width-expression-capture-20261027.json.gz
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2160-direct-declared-width-capture.t t/2128-shared-integer-width-evaluator.t t/2111-ial0-parameter-width-selection.t
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

Direct Parser capture_declared_width_contract now accepts an explicit detached
{kind => direct_module, owner => source_name} scope. Literal/type branches keep
their exact ordinary contracts. Constant fast-path capture uses the actual
parsed scalar observation and exact decimal token without resolver/evaluator
replay; general expressions reuse the canonical capture and actual manager
observation/declared-only hooks. Only those branches add width_capture with
scope, width, binding and observations. Ordinary source/contracts and JSON kinds
conserve; failed retries and held-result parser release qualify.

Automatic source/Core publication remains
ISF-REDUCTION-DELIVERY.3.3.1.2.2.3. No source grammar, public schema or symbolic
HDL range is activated by this opt-in resolver.

Core Signal declared_width_binding now stores an explicit plain detached
envelope: captured scope/width/binding/observations plus actual declaration
signal/expression. Getter coherence checks the old declaration source, effective
width and absent declared type; physical names never supply origin. Failed
replacement clears the old binding. Registry effective-width refinement and
explicit source/type replacement invalidate private metadata, preserving old
max-width/numeric/source behavior; absent-type unchanged inference preserves it.
Explicit whole-registry clearing supports later failed source transactions.
Canonical graph semantics remain with actual producer/target proof, not this
holder. Normal parsing still publishes none; source activation and auxiliary
copies are .3.3.1.2.2.3.2/.3. Reverify:
`prove -Iperl t/2161-core-declared-width-binding-lifecycle.t t/2160-direct-declared-width-capture.t t/2111-ial0-parameter-width-selection.t`.
