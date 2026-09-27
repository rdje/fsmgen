---
id: isf-formal-source-binding-reports
title: Formal preparation retains canonical authored binding report records
answers:
  - "how are authored binding names retained before formal physical projection?"
  - "can binding report provenance be prepared for a raw storage formal shadow?"
  - "does collecting binding report products switch production formal naming?"
date: 2026-09-27
status: current
tags: [isf, formals, reports, bindings, preparation, domains]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm; t/1961-isf-formal-source-binding-reports.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1961-isf-formal-source-binding-reports.t t/1243-isf-port-binding-schedule-report.t t/1959-isf-prepared-formal-reservations.t
---

prepare_formal_source retains transaction_binding_report_products from the
existing canonical _transaction_port_binding_metadata producer. It is a detached
copy of the same complete record array used by ordinary executable reports,
collected before any physical formal projection. The checked prepared inventory
requires this category explicitly and includes it in conservative provenance.
The former partial-producer comment is updated to point to the now-qualified
separate final declaration verifier.

The source records preserve caller scalar endpoints and formatted expressions,
callee port names, widths, authored/effective timing, local/generated/rule sites
and generated handoff/helper names. Each actual domain preparation retains only
its own binding sites through the existing domain source constructor. Collection
does not require a raw conflicting parent merge; source binding admission already
uses the caller formal's lexical width rather than shadowed actor storage.

T1961 compares complete records with ordinary public reports, demonstrates that
physical projection changes report caller/callee endpoints while the retained
source table stays unchanged, and verifies snapshot isolation. Raw actor-storage
shadows preserve source metadata while executable raw merges remain refused.
Actual domain producers agree with local preparation records. Complete native,
API and newline schedule reports agree for the admitted control, including
source expressions and explicit snapshot/live modes.

[Production formal lowering](isf-production-formal-scope.md) now consumes the
retained source table in a detached report view. Executable bindings remain
physical, the public binding key set is unchanged, and inferred storage names
identify actual private storage. Controller and local-call runtime work remains
separate.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.3.1.
