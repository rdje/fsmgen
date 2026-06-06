---
id: normalized-semantic-structural-instance-parameter-override-entry-schema
title: Normalized semantic structural RTL advertises instance parameter-override entry schemas
answers:
  - "where are structural_rtl_ir instance parameter override entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.instances parameter_overrides entries?"
  - "what is the normalized semantic structural instance parameter override entry schema?"
  - "are structural_rtl_ir instance parameter overrides entry keys advertised?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, structural-rtl-ir, instances, parameter-overrides, public-api]
evidence: perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/06-composition-advanced.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded nested entry schema under
`semantic.forward_ir.structural_rtl_ir.instances[].parameter_overrides[]`.

The public core key family covers `name`, `origin_kind`, `raw_value_ast`,
`value_kind`, `value_payload`, and `value_text`. A raw-value extension key
family covers optional `raw_value` metadata when a single authored token is
preserved. A value-metadata extension key family covers optional
`declaration_default_value_kind`, `declaration_default_value_width`,
`value_type_spec`, and `value_width` metadata when the resolver can report the
resolved value shape and child/interface declaration validation can report the
matched declaration default shape.

Nested instance `port_bindings[]` entries are advertised separately by
`normalized-semantic-structural-instance-port-binding-entry-schema`.
