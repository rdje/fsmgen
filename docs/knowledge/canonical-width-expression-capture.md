---
id: canonical-width-expression-capture
title: Opt-in width capture records actual prefix and infix evaluation structure and lookups
answers:
  - "where can canonical width evaluation capture actual selected bindings?"
  - "how do nested infix width payload lookups retain immediate identity?"
  - "how does direct declared-width resolution capture scope and actual lookup selection?"
  - "how are private Core declared-width bindings cloned and invalidated?"
  - "when are direct source width bindings published after validation?"
date: 2026-10-27
status: current
tags: [widths, source-capture, parameters, namespaces]
evidence: perl/FSM/Adapter/FSMGenFull.pm; t/2162-direct-source-width-binding-publication.t; docs/audits/source-width-publication-20261027.json.gz; perl/FSM/CoreAST.pm; perl/FSM/Adapter/FSMGenFull/SignalManager.pm; t/2161-core-declared-width-binding-lifecycle.t; docs/audits/core-width-binding-lifecycle-20261027.json.gz; perl/FSM/Adapter/FSMGenFull/Parser.pm; t/2160-direct-declared-width-capture.t; docs/audits/direct-declared-width-capture-20261027.json.gz; perl/FSM/WidthExpressionSupport.pm; t/2156-canonical-width-expression-capture.t; docs/audits/canonical-width-expression-capture-20261027.json.gz
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

Eligible primary/auxiliary source/Core publication and explicitly scoped late
sizing are implemented under ISF-REDUCTION-DELIVERY.3.3.1. Private requirements
retain separate declared and actual immediate copy origins; independent/opaque
combined shapes remain withheld. See direct-declared-width-consumers for the
current qualified replay/lifecycle boundaries. No source grammar, public schema
or symbolic HDL range is activated by this private publication.

Core Signal declared_width_binding now stores an explicit plain detached
envelope: captured scope/width/binding/observations plus actual declaration
signal/expression. Getter coherence checks the old declaration source, effective
width and absent declared type; physical names never supply origin. Failed
replacement clears the old binding. Registry effective-width refinement and
explicit source/type replacement invalidate private metadata, preserving old
max-width/numeric/source behavior; absent-type unchanged inference preserves it.
Explicit whole-registry clearing supports later failed source transactions.
Canonical graph semantics remain with actual producer/target proof, not this
holder. Normal source publication stages actual current requirement events;
coherent primary and auxiliary bindings share the same publisher. Reverify:
`prove -Iperl t/2161-core-declared-width-binding-lifecycle.t t/2160-direct-declared-width-capture.t t/2111-ial0-parameter-width-selection.t`.

Actual source capture uses the decoded original header scope. Static/type/define/
parameter environments resolve before +size; captured real Signal associations
publish only after all parser validation. Later facade failure clears them too.
Nonempty declarative environment replacement and failed direct size retries
invalidate snapshots; empty legacy no-ops preserve them. No source scope is
inferred for ordinary unscoped direct sizing. The explicit scoped entrypoint
validates original lexical scope and stages accepted late sizing atomically.
Actual assignment
objects receive bindings even when absent from module.signals. Selected complete
native check/semantic products are byte-identical, HDL differs only in Date,
and old source/default/numeric/caller JSON products conserve. Reverify:
`prove -Iperl t/2162-direct-source-width-binding-publication.t t/2161-core-declared-width-binding-lifecycle.t t/2160-direct-declared-width-capture.t t/2111-ial0-parameter-width-selection.t t/50-language-contract-size-section-boundary.t`.
