---
id: isf-local-imported-type-dependencies
title: ISF local aliases resolve imported type dependencies through the shared resolver
answers:
  - "why did ISF local aliases to imported record types fail?"
  - "how are ISF local aliases and nested members using imported types qualified?"
date: 2026-10-01
status: current
tags: [isf, types, imports, record-ports]
evidence: perl/FSM/Adapter/ISF/Parser.pm; t/2014-isf-record-input-public-sources.t; t/2015-isf-local-imported-type-aliases.t; isf/record_input.isf; isf/record_input_types.fsm; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2014-isf-record-input-public-sources.t t/2015-isf-local-imported-type-aliases.t
---

ISF previously resolved actor-local types before loading package symbols. A
direct `(input packet (type shared.frame))` worked, while a local
`(types (type alias shared.frame))` failed before interface admission. The
ordering originated in 6dce0d9a34acaa813fa1ef1bbc791121674e074f; the independently
authored imported-local-alias source reproduces it at clean predecessor
d9a40e4913c9636b561c20ce542875e25377ca6c.

Package resolution now precedes local type resolution. Qualified imported type
facts seed the temporary signal manager consumed by the existing shared type
resolver. They do not become local declarations. Local forward aliases, imported
scalar/record aliases and nested imported members retain their resolved width,
signed/state properties and authored names. Undeclared namespaces and missing
types still refuse. Package roots remain embedded in scheduled carriers.

Actual parser/lowering, complete native/API/newline reports, literal recursive
types/ordered layouts and every-carrier strict replay provide re-derivation.
The pre-repair imported-alias failure, unknown dependency controls and equal
transport copies with planted layout/type corruption supply falsification.
Tracked producers, maintained corpus/package inputs, tests, this fact and Git
provide durability. Contextual public refusals and frontend closure are qualified under
SEM .60.4.3.2.3.6.2-.3; generated/domain/backend/native/consumer completion is
separately owned. This proof does not execute HDL or qualify external consumers.
