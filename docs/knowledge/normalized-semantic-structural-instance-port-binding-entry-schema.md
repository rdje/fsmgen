---
id: normalized-semantic-structural-instance-port-binding-entry-schema
title: Normalized semantic structural RTL advertises instance port-binding entry schemas
answers:
  - "where are structural_rtl_ir instance port binding entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.instances port_bindings entries?"
  - "what is the normalized semantic structural instance port binding entry schema?"
  - "are structural_rtl_ir instance port bindings entry keys advertised?"
  - "are structural_rtl_ir instance parameter overrides entry keys advertised?"
date: 2026-06-05
status: current
tags: [normalized-semantic-json, structural-rtl-ir, instances, port-bindings, public-api]
evidence: perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded nested entry schema under
`semantic.forward_ir.structural_rtl_ir.instances[].port_bindings[]`.

The public core key family covers `connection_expr`, `port_name`, and
`signal_name`. A separate typed-extension key family covers optional
`connection_type_spec` metadata when the structural binding preserves a typed
actual contract.

Nested instance `parameter_overrides[]` entries are still not separately
advertised; a later exact task-tree owner must widen that nested entry schema
deliberately.
