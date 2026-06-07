---
id: normalized-semantic-structural-net-entry-schema
title: Normalized semantic structural RTL advertises net entry schemas
answers:
  - "where are structural_rtl_ir nets entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.nets entries?"
  - "where are structural RTL net entry keys advertised?"
  - "what is the normalized semantic structural net entry schema?"
date: 2026-06-07
status: current
tags: [normalized-semantic-json, structural-rtl-ir, nets, public-api]
evidence: perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/Pipeline/DirectGenerationOrchestrator.pm; perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/1333-direct-structural-rtl-ir-projection.t; t/163-forward-structural-rtl-ir-surface.t; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/ARCHITECTURE-DEBT-FRONTIER.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded entry schema under `semantic.forward_ir.structural_rtl_ir.nets[]`.

The public key family covers structural net entries. Composition tops use this
surface for structural carrier nets. Direct roots also populate this surface
with declaration-only internal storage/helper nets projected from the backend
internal declaration plan. Those direct entries preserve width, signedness,
state-model, and declared-type metadata where available, but they do not claim
generated enable wires, direct instances, links, auxiliary assignments, or
assignment connectivity.

Payload/report contracts and the capability manifest inherit the net key list
through the normalized semantic contract helper chain.
