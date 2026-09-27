---
id: specforge-feature-intake-and-strict-port-question
title: SPECFORGE feature intentions, unknown-port validation defect and width/interface controls
answers:
  - "where is the response to SPECFORGE's six feature requests and strict-port question?"
  - "does accepting an unknown interface-port clause mean it is supported?"
  - "do actor width parameters currently resize HDL ports on override?"
  - "why does an undriven positive-width actor output disappear?"
  - "where is the SPECFORGE storage-register-access request owned?"
  - "why does read-only actor storage status appear as an HDL input?"
  - "why do generated transaction children duplicate or export actor storage?"
date: 2026-09-26
status: current
tags: [specforge, isf, parameters, interface, verification, semantic-api, mcp, storage, register-access]
evidence: t/1904-isf-generated-child-storage-reads.t; docs/audits/generated-child-storage-ownership-20260926.json; docs/decisions/0107-actor-storage-has-one-owner-across-generated-children.md; t/1903-isf-internal-storage-ownership.t; docs/audits/specforge-storage-register-access-intake-20260926.json; docs/SPECFORGE_FEEDBACK_RESPONSE.md; docs/audits/specforge-feature-intake-20260926.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/replay-specforge-feature-intake.py .artifacts/specforge-intake-recheck-new && scripts/run_with_ram_guard.sh -- python3 -B docs/audits/replay-specforge-feature-intake.py .artifacts/storage-access-recheck-new --storage-access
---

`docs/SPECFORGE_FEEDBACK_RESPONSE.md`, under `2026-09-26: Configuration, Verification And
Phase-Metadata Requests`, records required/optional scopes, dependencies and order for the supplied
packets. Parent `.33` owns them; intake `.33.1` implements none of those features.

At `a7bf398ac3c1008b996bf0a92bdd18c9464d9fda`, native strict checks accepted `bogus-clause` and
unsupported `present` port options and emitted the same HDL as the clause-free control except its
date header. `_parse_interface` ignored malformed shapes and lacked final unknown-option rejection.
`.33.2` repairs this defect through the shared parser/native/API/MCP boundary: T1898 rejects
unsupported/malformed options in default and strict modes, preserving valid metadata.

Generic widths differ from earlier derived widths (`.32.3`): overriding HDL to 64 left default-32
WDATA at 32, while separately generating default-64 gave 64. Width dependencies were resolved before
emission. `.33.3` owns preservation; parameter legality and optional interfaces depend on it.

The positive-width undriven AWMECID and literal control lost their output role; a driven control
kept it. The FSM retained width but no role/drive marker, so unused-signal inference omitted it.
`.33.9` now carries both directions through `+interface`; T1900 qualifies native/API/MCP inventories
and HDL declarations. `.35` repairs the separate reset-only metadata-without-assignment gap, with
T1901 runtime proof.

The storage-register-access packet is retained in
`docs/audits/specforge-storage-register-access-intake-20260926.json`. Intake `.37` confirms
word-access refusal; `.38.1` owns independent scalar metadata and `.38.2` optional banks. Immediate
`.39.2.1` repairs ordinary/domain storage using the `.39.1` internal-role carrier. T1903 checks the
retained controls, direct FSM replay, exact interfaces, complete native/API/MCP parity, typed/unused
storage, bank elements and independent reset/write/read/hold behavior. The audit keeps the original
input/reset defect for falsification. T1904 qualifies ordinary/single-domain scalar/bank live reads,
exact interfaces and repeat activation. T1911 qualifies aggregate shapes; T1916 qualifies
independent-domain live reads and reset isolation. T1917/T1918 qualify sole scalar child writes
including independent domains; broader writer qualification remains owned by .39.2.2.4.
Resolved reset widths reject overflow without
warnings. Explicit bindings and local state remain separate; decision `0107` owns shared semantics.

Audits retain exact caller bytes/hashes, native reports, output-role controls and the independent
HDL width oracle. Replay uses retained inputs and a fresh repository-relative same-volume
destination, capturing current outcomes without signing off changed behavior. Use a new destination
each time. Caller-wide impact counts were not independently measured; controls qualify neither the
whole caller corpus, future features nor four-state knownness.
