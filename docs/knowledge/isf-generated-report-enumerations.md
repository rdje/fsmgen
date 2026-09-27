---
id: isf-generated-report-enumerations
title: Advertised schedule values include generated storage and completion products
answers:
  - "why were child completion roles missing from the schedule report contract?"
  - "which schedule kinds describe generated actor storage handoffs?"
  - "are generated completion storage roles advertised to API consumers?"
date: 2026-09-27
status: current
tags: [isf, reports, contract, storage, completion, mcp]
evidence: perl/FSM/Support/ISFPublicInterfaceContract.pm; t/1964-isf-generated-report-enumerations.t; t/1158-isf-public-report-dt-kind-metadata-audit.t; t/data/isf_schedule_generated_role_families.isf; docs/audits/local-rule-payload-scoped-baseline-20260927.json
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1964-isf-generated-report-enumerations.t t/1148-isf-public-storage-metadata-audit.t t/1158-isf-public-report-dt-kind-metadata-audit.t t/1255-isf-schedule-report-golden-matrix.t
---

Production ChildCompletion, ChildCompletionOutputs and ChildStorageOwnership
already emitted generated storage roles and DT kinds absent from the advertised
ISF public-interface enumerations. The older metadata fixtures did not exercise
those producers together, so their membership checks missed the drift. The
scoped local-payload baseline first reproduced completion_seen/view and the
completion DT omission through a native schedule query.

The canonical storage-role list now includes child_completion_seen,
child_completion_view, child_completion_output_handoff and local_completion_pulse.
The DT-kind list includes child_completion, child_completion_output,
actor_storage_read_handoff and actor_storage_write_handoff. These are actual
existing producer values; this repair changes descriptors, not lowering or the
public report key set. Generated report contents remain identical before/after.

The combined fixture uses separate generated storage writer and reader workers,
a completion join and a shared named completion with a parent contribution.
T1964 requires every observed role/kind to be advertised, requires every repaired
value to occur, and detects each deliberate descriptor omission against actual
production output. The fixture strict-checks; complete native/API/newline
schedule responses agree. T1158 adds this family to its all-advertised-DT-kind
coverage. T1148 now locates the actual private direct-formal identity while
preserving its register/role/width assertions.

The reference also retains the current monitor contract: immediate monitor
assertions do not populate the legacy temporal_contracts array. That array stays
empty after removal of the old contract clause; the book already stated this.

Re-derivation uses actual source producers and production reports; falsification
removes each repaired descriptor while retaining the report observations;
durability is the canonical enum, combined fixture and membership/coverage tests.
This is a metadata repair, not snapshot retention or independent execution.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.56.
