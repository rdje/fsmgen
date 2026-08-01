# Intent Scheduling Format (`.isf`) Specification v0.6

The normative language reference: purpose, source model, timing, interfaces, transactions, composition, rules, reports, fixtures, and explicit deferrals.

This maintained reference is split at stable semantic boundaries so every
review unit stays bounded. The exact pre-partition source remains retrievable
from Git through the registered archive descriptor. Edit the relevant part and
keep this landing, the other contracts, tests, and mdBook synchronized.

## Parts

- [Purpose, source model, libraries, clocks, resets, and watchdogs](isf-spec/01-purpose-source-timing.md)
- [Interfaces, storage, drives, transactions, waits, control flow, and data movement](isf-spec/02-interface-transactions.md)
- [Transaction composition, spawned work, schedule projection, diagnostics, and rules](isf-spec/03-composition-rules.md)
- [Schedule reports, regression fixtures, and explicit deferrals](isf-spec/04-reports-fixtures-deferrals.md)

## Complete ISF reference set

- [ISF Downstream Integration Specification](ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
  - [Readiness, integration pipeline, APIs, and source file model](isf-spec/10-downstream-readiness-source.md)
  - [Actor root, timing, interfaces, libraries, drives, and transactions](isf-spec/11-downstream-actor-transactions.md)
  - [Rules, actor networks, scheduled artifacts, and schedule reports](isf-spec/12-downstream-rules-artifacts-reports.md)
  - [Diagnostics, conformance, discovery, deferrals, guidance, and evolution](isf-spec/13-downstream-diagnostics-conformance.md)
- [ISF Public Interface Contract](ISF_PUBLIC_INTERFACE_CONTRACT.md)
  - [Public facade and interface surface](isf-spec/20-public-interface-surface.md)
  - [Stabilized surface, lower result, and DT assignment operators](isf-spec/21-public-interface-stabilized-lowering.md)
  - [Schedule report, freeze readiness, non-public internals, and evolution](isf-spec/22-public-interface-reports-evolution.md)
