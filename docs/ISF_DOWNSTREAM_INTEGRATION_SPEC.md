# ISF Downstream Integration Specification

The downstream-facing IAL1 integration contract for source, lowering, diagnostics, reports, artifacts, conformance, discovery, and evolution.

This maintained reference is split at stable semantic boundaries so every
review unit stays bounded. The exact pre-partition source remains retrievable
from Git through the registered archive descriptor. Edit the relevant part and
keep this landing, the other contracts, tests, and mdBook synchronized.

## Parts

- [Readiness, integration pipeline, APIs, and source file model](isf-spec/10-downstream-readiness-source.md)
- [Actor root, timing, interfaces, libraries, drives, and transactions](isf-spec/11-downstream-actor-transactions.md)
- [Rules, actor networks, scheduled artifacts, and schedule reports](isf-spec/12-downstream-rules-artifacts-reports.md)
- [Diagnostics, conformance, discovery, deferrals, guidance, and evolution](isf-spec/13-downstream-diagnostics-conformance.md)

## Related maintained contracts

- [Intent Scheduling Format (`.isf`) Specification v0.6](ISF_SPEC.md)
- [ISF Public Interface Contract](ISF_PUBLIC_INTERFACE_CONTRACT.md)
