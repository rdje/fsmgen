---
id: vhdl-backend-validation-api-claim-evidence
title: Chapter 14l backend and API claims retain four executable evidence families
answers:
  - "how are Chapter 14l backend validation and API claims verified?"
  - "which tests prove VHDL generic maps and typed literal arithmetic lowering?"
  - "how is optional ABC mapping kept default off?"
  - "why do non-object MCP requests return -32600 Invalid Request?"
  - "are completed backend frontier task identifiers capability evidence?"
date: 2026-08-21
status: current
tags: [claim-verification, vhdl, backend, validation, mcp, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  docs/book/src/14l-backends-validation-and-apis.md;
  perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm;
  perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm;
  perl/FSM/Support/HDLExternalValidation.pm;
  perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm;
  t/386-hdl-generator-facade-target-language-boundary-audit.t;
  t/1420-vhdl-direct-backend-scaffold.t;
  t/313-hdl-external-validation-contract.t;
  t/1459-semantic-introspection-mcp-jsonrpc-batch-envelope-boundary.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh -- prove -Iperl
  t/386-hdl-generator-facade-target-language-boundary-audit.t
  t/1420-vhdl-direct-backend-scaffold.t
  t/313-hdl-external-validation-contract.t
  t/1459-semantic-introspection-mcp-jsonrpc-batch-envelope-boundary.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.14` reviews the exact 40 inventory
candidates on `docs/book/src/14l-backends-validation-and-apis.md`. Thirty-nine
state current behavior and use derived gates; the one-bit RLAST `.50 -> .51`
selection is immutable contract chronology and remains a reviewed structural
reference rather than an independent backend capability.

The structural VHDL emitter and facade oracle jointly prove the bounded
external-RTL, standalone-DT, generated-FSM, and APB/C4 generic-map families.
They check integer expressions, one- and multi-bit literals, packed values,
package resolution, ordering before the port map, absence of SystemVerilog
residue, and rejection of non-packed aggregate neighbors.

The direct VHDL converter derives widths and signedness from declarations.
Its direct and facade regressions check the selected packed ports, target-
width output literals, all signal/literal operand orders for arithmetic, and
positive, negative, scalar, signed, and non-signed forms. Wrong casts, raw
integer assignments, syntax leakage, and unsupported neighboring families are
explicit negative controls, so the historical frontier labels are navigation
around current executable behavior rather than its proof.

The external-validation adapter selects `synth -top` only for explicit
`abc_mapping => 1`, keeps ordinary calls on `synth -noabc -top`, and rejects
an opt-in request when ABC discovery is absent. Independently, the MCP adapter
rejects arrays and other non-object envelopes before dispatch and emits one
null-id `-32600 Invalid Request` response.
