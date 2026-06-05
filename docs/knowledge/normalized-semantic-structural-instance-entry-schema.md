---
id: normalized-semantic-structural-instance-entry-schema
title: Normalized semantic structural RTL advertises instance shallow entry schemas
answers:
  - "where are structural_rtl_ir instances entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.instances entries?"
  - "what is the normalized semantic structural instance entry schema?"
  - "are structural_rtl_ir instance port bindings entry keys advertised?"
date: 2026-06-05
status: current
tags: [normalized-semantic-json, structural-rtl-ir, instances, public-api]
evidence: perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded shallow entry schema under
`semantic.forward_ir.structural_rtl_ir.instances[]`.

The public key family covers the instance shell keys:
`instance_name`, `interface_ports`, `kind`, `module_name`,
`parameter_overrides`, `port_bindings`, and `source_name`.

Nested instance `interface_ports[]` entries are now advertised separately by
`normalized-semantic-structural-instance-interface-port-entry-schema`.
Nested instance `parameter_overrides[]` and `port_bindings[]` entries are not
separately advertised yet; later exact task-tree owners must widen those nested
entry schemas deliberately.
