# 0105 — VIAL deep inspection is additive to frozen summaries

- Date: 2026-09-24
- Status: accepted
- Type: public API architecture
- Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.1`

## Context

The director requires current-feature deep semantic API/MCP coverage. Actual
native/MCP VIAL reports agree, but the existing contract deliberately omits
declaration/action bodies and reports lifecycle families as identities/counts.
The compiler retains the typed meaning; neither an adapter fix nor equal
summary outputs can establish the requested depth. The exact observation and
independent authored values are in
`docs/audits/mcp-feature-coverage-20260924/vial-summary-boundary.json`.

## Decision

Keep frozen tooling results, capability records, summaries and digests intact.
Add a separately versioned, JSON-safe public source-inspection projection with
explicit typed constructors and relative source provenance. Public portable
and bounded filesystem APIs precede native CLI and MCP exposure. Inspect the
same captured source bytes without DUT binding, planning, random evaluation,
backend execution or publication. Cover inherited base semantics as well as
implemented intent families; unknown projection shapes fail closed.

The selected interfaces and implementation ownership live in
[the source-inspection contract](../VIAL_SOURCE_INSPECTION_CONTRACT.md).
Private SemanticIR objects and arbitrary hash dumps remain private. Projection
fields are public compatibility obligations even if initially derived from
equivalent compiler fields. Source legality is distinct from runtime maturity.

## Consequences

Existing clients keep their summary contracts. Agents gain a separate route
for typed expressions/actions and lifecycle conditions, references and bounds.
Meaningful authored-value assertions accompany full native/API/MCP equality;
future family signoff must update the projector and its semantic oracle.
Selection alone does not advertise a callable interface or qualified runtime.
