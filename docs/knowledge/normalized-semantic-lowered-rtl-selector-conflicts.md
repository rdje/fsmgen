---
id: normalized-semantic-lowered-rtl-selector-conflicts
title: Normalized semantic lowered RTL advertises selector-conflict metadata
answers:
  - "where are lowered RTL selector conflict keys advertised?"
  - "does normalized semantic JSON expose selector_conflict_targets?"
  - "what contract owns semantic.forward_ir.lowered_rtl_ir.selector_conflict_targets?"
  - "are selector_conflict_target_count and selector_conflict_targets public semantic JSON keys?"
date: 2026-06-05
status: current
tags: [normalized-semantic-json, lowered-rtl-ir, public-api]
evidence: perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; perl/FSM/Support/NormalizedSemanticReport.pm; t/340-normalized-semantic-lowered-rtl-ir-contract.t; t/311-normalized-semantic-report-contract.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/297-capability-manifest.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/340-normalized-semantic-lowered-rtl-ir-contract.t t/311-normalized-semantic-report-contract.t t/354-normalized-semantic-child-runtime-contract-audit.t t/297-capability-manifest.t
---

`semantic.forward_ir.lowered_rtl_ir.selector_conflict_target_count` and
`semantic.forward_ir.lowered_rtl_ir.selector_conflict_targets` are advertised
through `FSM::Support::NormalizedSemanticLoweredRTLIRContract`.

The payload/report contracts and capability manifest inherit that lowered-RTL
key family through the normalized semantic contract helpers. The nested
`selector_conflict_targets` entry contents remain bounded at the current
object-shell level unless a later task widens that entry schema deliberately.
