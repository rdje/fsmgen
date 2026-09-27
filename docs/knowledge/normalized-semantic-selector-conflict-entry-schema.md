---
id: normalized-semantic-selector-conflict-entry-schema
title: Normalized semantic lowered RTL advertises selector-conflict entry schemas
answers:
  - "where are selector_conflict_targets entry keys advertised?"
  - "what keys are in semantic.forward_ir.lowered_rtl_ir.selector_conflict_targets entries?"
  - "what keys are in selector_conflict_targets rhs_enable_families entries?"
  - "where are selector conflict assertion metadata keys advertised?"
date: 2026-09-28
status: current
tags: [normalized-semantic-json, lowered-rtl-ir, selector-conflicts, public-api]
evidence: perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/340-normalized-semantic-lowered-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/340-normalized-semantic-lowered-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticLoweredRTLIRContract` advertises the bounded
entry schemas under
`semantic.forward_ir.lowered_rtl_ir.selector_conflict_targets[]`.

The public key families cover selector target entries, nested
`rhs_enable_families[]` entries, multi-value assertion metadata, and same-value
assertion metadata. Payload/report contracts and the capability manifest
inherit those lists through the normalized semantic contract helper chain.

Decision 0111 distinguishes selector policy values while retaining these key
families. The legacy same_value_assertion descriptor uses kind compatible_fanin
for OR-coalesced same-RHS source enables, which may be active together. It does
not imply an emitted source-exclusivity check. multi_value_assertion retains
kind onehot0; explicit onehot0 metadata still emits its obligation. Compatible
family entries remain discoverable under selector_conflict_targets for report
compatibility. Standalone-DT and shared-composition assertion policies are
separate and unchanged. T1211/T340 and full native/API/newline/carrier checks
qualify metadata/emission. SEM .32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.3 now completes
observed positive execution on both HDL targets and an actual different-value
assertion rejection for the deliberately broken priority mask. The sealed
source/result/cleanup evidence is in docs/audits/priority-runtime-qualified-20260928/.
