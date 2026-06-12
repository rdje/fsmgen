---
id: normalized-semantic-structural-port-entry-schema
title: Normalized semantic structural RTL advertises port entry schemas
answers:
  - "where are structural_rtl_ir ports entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.ports entries?"
  - "what structural port keys are composition-only?"
  - "where are structural RTL port composition extension keys advertised?"
  - "where are structural RTL port target keys advertised?"
  - "where are structural RTL port source keys advertised?"
date: 2026-06-12
status: current
tags: [normalized-semantic-json, structural-rtl-ir, ports, public-api]
evidence: perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/1333-direct-structural-rtl-ir-projection.t; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded entry schemas under
`semantic.forward_ir.structural_rtl_ir.ports[]`.

The public key families cover structural port core entry keys, composition-top
port extension keys, direct-root input-port target extension/entry keys, and
direct-root output-port source extension/entry keys. Payload/report contracts
and the capability manifest inherit those lists through the normalized semantic
contract helper chain.

Direct input ports consumed by generated-enable assignment-record RHS ASTs may
carry a `targets[]` extension. Those entries reuse the generated-enable
assignment-record target endpoint shape: `kind`, `assignment_lhs`,
`assignment_kind`, `family`, and `role`.

Direct output ports whose names match bounded lowered output-drive families may
carry a `source` extension. That source summary is structural data, not rendered
HDL text, with keys `kind`, `signal_name`, `multiplexer_type`, `driver_count`,
`driver_blocks`, `rhs_values`, `driver_enable_signals`, and
`family_enable_signals`.
