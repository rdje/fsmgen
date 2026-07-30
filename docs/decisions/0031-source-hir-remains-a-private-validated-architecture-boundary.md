# 0031 — SourceHIR remains a private validated architecture boundary

- Date: 2026-07-30
- Type: architecture
- Status: accepted by `FSMGEN-HIR-ROADMAP-FRONTIER.8`
- Refines: `0029`, `0030`

## Context

Decisions `0029` and `0030` required a second private route before
reconsidering SourceHIR promotion. T1547 now proves protocol/platform intent
through canonical PPIF/IAL2, and t1548 proves concrete control through
canonical ISF/IAL1. Both preserve the same immutable object, closed validation,
provenance, source-map, existing-parser re-entry, and exact downstream-
equivalence principles.

Repository usage still has only test producers. No supported host language,
public construction package/schema, serialization, versioning, compatibility,
CLI, report/manifest, or support-accounting surface has been selected.

## Decision

Retain SourceHIR as a validated private architecture boundary. Stop adding
architecture-only private routes. Do not publish the current Perl object/input
shapes, narrow or rename the boundary, or retire it.

The two routes validate the shared semantic seam but do not validate a public
product. `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` remains the separate owner of
any supported producer and public projection; this decision does not activate
that proposed tree.

## Consequences

- `FSMGEN-HIR-ROADMAP-FRONTIER` closes with both private routes proved.
- Existing SourceHIR packages and t1547/t1548 remain private and supported by
  their focused regression evidence.
- No third private fixture/schema is selected without a real producer or
  product requirement and a new task-tree owner.
- A future public builder must explicitly select its language, ergonomic API,
  wrapper/projection boundary, versioning, compatibility, diagnostics,
  packaging, serialization, golden workflow, and any public accounting.
- Existing `.fsm`, `.isf`, `.ppif`, CLI, reports, manifests, capability and
  support accounting, HDL/runtime, and public behavior remain unchanged.
