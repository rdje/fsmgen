---
id: isf-record-binding-identity-roles
title: Activation identities remain separate from record binding values
answers:
  - "why did a generated scalar binding formal name refuse as an actor record read?"
  - "can a child scalar formal share an actor record input name?"
  - "does the binding identity repair admit record field actuals?"
date: 2026-10-01
status: current
tags: [isf, records, bindings, formals, domains, contexts]
evidence: perl/FSM/Support/ISFRecordPortContexts.pm; t/2023-isf-record-binding-identities.t; t/2021-isf-record-input-generated-refusals.t; docs/book/src/13j-type-enum-aggregate.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2023-isf-record-binding-identities.t t/2021-isf-record-input-generated-refusals.t t/1933-isf-caller-formal-binding-scope.t
---

The original record-context gate recursively scanned every token of transaction
spawn/do and rule trigger forms as unsupported values. A callee scalar formal
named packet was therefore mistaken for a same-named actor record input in the
caller. Calibrated actual scalar-only controls lower, while the same binding
with an unused actor record refuses before scheduling. The actual strict native
check independently reproduces that first cause. _unsupported is unchanged from
48da7b698141e13a6c57eddca810a641e0baae9c through predecessor
85b6fdfb460d93b632be9bfa3da880da83b9d3c8.

ISFRecordPortContexts now scans activation value positions. Target/instance
identities, callee formal names, static parameter keys and declared domain/timing
metadata retain their separate roles. Binding actuals and parameter values keep
the unsupported-record gate; malformed/unknown shapes retain conservative
scanning. Existing complete grammar, endpoint, width, timing, domain and writer
validators stay authoritative. Scalar member/type gates and published child
ports remain unchanged. No record root/leaf binding actual is newly admitted.

T2023 uses actual authored local/generated spawn/do/trigger controls, input/output
formal, target/instance and parameter/domain/timing collisions, actual record
refusals and complete caller purity. Module-admission hostile metadata probes
retain value refusals. T2021 adds an imported foreign actor record masked by an
explicitly bound scalar generated input, exact private handoff/top/child ports
and full native/API/newline products, plus actual record expression refusals.
A bare scalar slice binding atom is outside the existing signal/literal/list
grammar; the earlier pending slice-atom source was not a qualified admitted
witness. The corrected source binds a width-aligned bare scalar and selects the
child formal in its body.

Re-derivation uses actual authored native/public products and literal scoped
carrier/semantic ports. Falsification uses hostile record actuals/metadata,
independent literal widths/roles and the exact committed predecessor module's
identity RED with scalar/record-actual controls. Product/tests, this card/book,
the owning task and Git provide durability. Backend/native runtime, prior-product
closure and external consumer qualification remain separate work.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.2.2.
