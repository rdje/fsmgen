# ISF Downstream Integration

This chapter renders the canonical downstream integration contract. The
maintained sources are `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` and the four
parts below. Edit those files; this chapter includes them, so the published
book and the handoff cannot drift apart.

- [Readiness, integration pipeline, APIs, and source file model](#1-readiness-and-stability)
- [Actor root, timing, interfaces, libraries, drives, and transactions](#6-actor-root)
- [Rules, actor networks, scheduled artifacts, and schedule reports](#12-rules-priorities-resources)
- [Diagnostics, conformance, discovery, deferrals, guidance, and evolution](#15-diagnostics-and-fail-closed-policy)

The language reference is [Intent Scheduling](13-intent-scheduling.md). The
public interface contract is described under
[Public Interface Contract](13-intent-scheduling.md#public-interface-contract).
Issue reports follow
[Downstream Issue Reporting](10a-downstream-issue-reporting.md).

{{#include ../../isf-spec/10-downstream-readiness-source.md}}

{{#include ../../isf-spec/11-downstream-actor-transactions.md}}

{{#include ../../isf-spec/12-downstream-rules-artifacts-reports.md}}

{{#include ../../isf-spec/13-downstream-diagnostics-conformance.md}}
