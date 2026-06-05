---
id: normalized-semantic-structural-net-entry-schema
title: Normalized semantic structural RTL advertises net entry schemas
answers:
  - "where are structural_rtl_ir nets entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.nets entries?"
  - "where are structural RTL net entry keys advertised?"
  - "what is the normalized semantic structural net entry schema?"
date: 2026-06-05
status: current
tags: [normalized-semantic-json, structural-rtl-ir, nets, public-api]
evidence: perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded entry schema under `semantic.forward_ir.structural_rtl_ir.nets[]`.

The public key family covers structural net entries. Payload/report contracts
and the capability manifest inherit that list through the normalized semantic
contract helper chain.
