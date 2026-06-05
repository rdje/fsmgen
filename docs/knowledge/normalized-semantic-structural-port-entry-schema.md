---
id: normalized-semantic-structural-port-entry-schema
title: Normalized semantic structural RTL advertises port entry schemas
answers:
  - "where are structural_rtl_ir ports entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.ports entries?"
  - "what structural port keys are composition-only?"
  - "where are structural RTL port composition extension keys advertised?"
date: 2026-06-05
status: current
tags: [normalized-semantic-json, structural-rtl-ir, ports, public-api]
evidence: perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded entry schemas under
`semantic.forward_ir.structural_rtl_ir.ports[]`.

The public key families cover structural port core entry keys and composition
top port extension keys. Payload/report contracts and the capability manifest
inherit those lists through the normalized semantic contract helper chain.
