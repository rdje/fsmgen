---
id: shared-parameter-expression-binding
title: Canonical parameter binding is shared across explicit source scopes
answers:
  - "which helper binds observed parameter expressions across source scopes?"
  - "does shared parameter binding widen the composition scope contract?"
date: 2026-10-26
status: current
tags: [parameters, binding, lowering, scopes]
evidence: perl/FSM/ParameterBindingSupport.pm; perl/FSM/Composition/ParameterBindingSupport.pm; t/2144-shared-parameter-expression-binding.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2144-shared-parameter-expression-binding.t t/2121-composition-top-default-bindings.t t/2122-composition-top-instance-bindings.t
---

The shared helper consumes canonical evaluator trees, ordered observed declared
references, explicit direct-module or composition-top scope, and a transient
static resolver. It preserves immediate identities, aggregate suffixes and
source structure; equal numeric defaults never create bindings. Static
selections become detached canonical payloads, memoized within each call.

The composition wrapper still requires composition-top scope and its blessed
static-symbol object. Successful default and resolved instance products retain
their prior JSON kinds and values. Direct Core capture is a separate parser
consumer, described by the `direct-core-default-bindings` fact card. The shared
walk does not itself add public schema or general-default HDL support.
