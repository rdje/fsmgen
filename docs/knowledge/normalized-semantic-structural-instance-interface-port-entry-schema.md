---
id: normalized-semantic-structural-instance-interface-port-entry-schema
title: Normalized semantic structural RTL advertises instance interface-port entry schemas
answers:
  - "where are structural_rtl_ir instance interface port entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.instances interface_ports entries?"
  - "what is the normalized semantic structural instance interface port entry schema?"
date: 2026-06-05
status: current
tags: [normalized-semantic-json, structural-rtl-ir, instances, interface-ports, public-api]
evidence: perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded nested entry schema under
`semantic.forward_ir.structural_rtl_ir.instances[].interface_ports[]`.

The public key family reuses the structural port entry schema:
`direction`, `name`, `signed`, `type`, and `width`.

Nested instance `parameter_overrides[]` entries are now advertised separately
by `normalized-semantic-structural-instance-parameter-override-entry-schema`.
Nested instance `port_bindings[]` entries are now advertised separately by
`normalized-semantic-structural-instance-port-binding-entry-schema`.
