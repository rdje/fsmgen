---
id: specforge-feature-intake-and-strict-port-question
title: SPECFORGE feature intentions, unknown-port validation defect and width/interface controls
answers:
  - "where is the response to SPECFORGE's six feature requests and strict-port question?"
  - "does accepting an unknown interface-port clause mean it is supported?"
  - "do actor width parameters currently resize HDL ports on override?"
  - "why does an undriven positive-width actor output disappear?"
date: 2026-09-26
status: current
tags: [specforge, isf, parameters, interface, verification, semantic-api, mcp]
evidence: docs/SPECFORGE_FEEDBACK_RESPONSE.md; docs/audits/specforge-feature-intake-20260926.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/replay-specforge-feature-intake.py .artifacts/specforge-intake-recheck-new
---

The tracked response is `docs/SPECFORGE_FEEDBACK_RESPONSE.md`, under
`2026-09-26: Configuration, Verification And Phase-Metadata Requests`.
It gives intended scope, required versus optional slices, dependencies and
execution order for all supplied packets. Parent `.33` in the semantic/API/MCP
tree owns the work. Intake `.33.1` does not implement those features.

At revision `a7bf398ac3c1008b996bf0a92bdd18c9464d9fda`, native strict checks
accept unknown `bogus-clause` and unsupported `present` port properties, and
emit the same HDL as the clause-free control except its date header.
`Parser::_parse_interface` ignores malformed option shapes and lacks a final
unknown-option rejection. This is a validation defect; `.33.2` owns refusal
through the shared parser and native/API/MCP surfaces.

The generic-width request is distinct from earlier derived widths (`.32.3`).
An actual HDL override to 64 leaves the default-32 source's WDATA at 32 bits;
the separately generated default-64 control has 64 bits. The width dependency
has already been resolved before emission. Generic preservation is owned by
`.33.3`; parameter legality and optional interfaces depend on it.

The optional-port packet's positive-width undriven AWMECID output is absent
from emitted HDL and realized semantics. A literal-width control also loses
it; a driven control preserves it. The FSM carries width but no output role,
so unused-signal inference omits it. `.33.9` owns repair without inventing a
drive value. The prior input-role repair does not cover outputs.

The audit retains exact caller texts and hashes, native reports, output-role
controls and an independent HDL width oracle. The replay driver uses retained
inputs, requires a fresh repository-relative same-volume destination, and
captures current outcomes rather than declaring changed behavior correct.
Choose another fresh destination for each replay. Caller-wide impact counts
were not independently measured; these bounded controls do not qualify a
whole caller corpus, future features or four-state knownness.
