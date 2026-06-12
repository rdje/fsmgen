---
id: normalized-semantic-structural-net-entry-schema
title: Normalized semantic structural RTL advertises net entry schemas
answers:
  - "where are structural_rtl_ir nets entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.nets entries?"
  - "where are structural RTL net entry keys advertised?"
  - "what is the normalized semantic structural net entry schema?"
date: 2026-06-12
status: current
tags: [normalized-semantic-json, structural-rtl-ir, nets, public-api]
evidence: perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/Pipeline/DirectGenerationOrchestrator.pm; perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/1333-direct-structural-rtl-ir-projection.t; t/163-forward-structural-rtl-ir-surface.t; t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.md; docs/tasks/R11-DIRECT-STRUCTURAL-WEN-EN-NETS.md; docs/tasks/R11-DIRECT-BACKEND-COORDINATION-FRONTIER.md; docs/tasks/ARCHITECTURE-DEBT-FRONTIER.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded entry schema under `semantic.forward_ir.structural_rtl_ir.nets[]`.

The public key family covers structural net entries. Composition tops use this
surface for structural carrier nets. Direct roots also populate this surface
with declaration-only internal storage/helper nets projected from the backend
internal declaration plan plus generated enable wires projected from the
already-prepared direct backend enable registries and assignment analysis.
Those direct entries preserve width, signedness, state-model, and declared-type
metadata where available, but their `source` remains null and `targets`
remains empty. Direct generated enable assignments live under
`assignment_records[]`, and the scalar rendered-line mirror remains under
`auxiliary_assignments[]`. Direct instances, links, net source/target
connectivity, and HDL rerouting through `StructuralRTLIR` remain outside this
net entry projection.

Payload/report contracts and the capability manifest inherit the net key list
through the normalized semantic contract helper chain.
