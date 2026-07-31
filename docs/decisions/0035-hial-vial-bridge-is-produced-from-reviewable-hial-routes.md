# 0035 — The HIAL/VIAL bridge is produced from reviewable HIAL routes

- Date: 2026-07-31
- Type: compiler boundary and public schema
- Status: accepted by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.4`
- Preserves: `0018`, `0031`, `0032`, `0033`, `0034`

## Context

VIAL must bind to stable HIAL meaning without reading raw parser arrays,
private IR, generated HDL, or target hierarchy. IAL0, IAL1, and IAL2 have
different available facts. In particular, protocol intent originates in IAL2,
but project doctrine requires those facts to remain reviewable through
generated IAL1 before any verification consumer uses them.

The first checked VIAL source already names exact bridge IDs for the AHB
subordinate: public outputs, one domain, one transaction and six events, and a
declared storage probe. Existing generated IAL1 contains the ports and storage
behavior but not a machine-readable protocol/event/probe annotation. Letting a
bridge builder read the PPIF report beside generated IAL1 would preserve data
but violate the review route and create a second protocol truth source.

Current IAL0/IAL1 parsers also do not preserve exact spans uniformly. A bridge
that claimed invented line/column precision would be less trustworthy than a
stable semantic-path map.

## Decision

Select `fsmgen.hial_vial_bridge_manifest.v1` and initial profile
`core_single_unit_v1` as specified by
`docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md`.

The only accepted production routes are direct IAL0, direct IAL1 through its
generated IAL0 review artifact, and IAL2 through generated IAL1 plus generated
IAL0. Direct PPIF-to-bridge consumption is forbidden.

Select one additive IAL1 actor metadata form, `(verification-bridge ...)`, for
protocol/domain/transaction/event/probe/residue facts not already represented
by existing IAL1 interface, transaction, system, and `(observe ...)` records.
The IAL2 generator renders this form into generated IAL1; the normal IAL1
parser validates it and the schedule report projects it. The bridge consumes
that parsed/report authority. The metadata never creates scheduled hardware or
HDL behavior by itself.

The manifest uses semantic IDs rather than target paths. Its first AHB records
match the checked VIAL source exactly: `unit/ahb_lite_subordinate`,
`domain/ahb_bus`, `endpoint/HREADYOUT`, `endpoint/HRESP`, `endpoint/HRDATA`,
`probe/reg_data_q`, `transaction/ahb_write`, and the requested/accepted/
captured/held/completed/error event family.

Public ports are portable access. Verification probes remain adapter-required
declarations and never expose raw hierarchy. Backend bindings record logical
module/entity/port names only and make no compile, simulation, methodology, or
parity claim.

Every semantic field has an RFC-6901 source-map record. The first
implementation records exact byte spans only where the owning parser supplies
them; otherwise it records an honest stable semantic path with null span
fields. Generated IAL2 facts cite both authored IAL2 and generated IAL1
annotation provenance.

The sanitized manifest is immutable internally and fully defensive at every
caller boundary. It is versioned public data, but `.5` exposes only private
in-process construction/report helpers and writes no file. Public CLI/API,
output paths, and artifact-manifest discovery remain owned by `.8`.

## Consequences

- Direct IAL0 can publish structural unit/endpoint/domain/type/configuration
  facts but cannot invent protocol semantics from names.
- Direct IAL1 can additionally publish transactions and passive observations;
  protocol roles/events/probes require explicit validated metadata.
- The first AHB IAL2 implementation must add deterministic generated-IAL1
  annotation text and prove generated IAL0 plus HDL behavior unchanged.
- The bridge remains language-neutral and backend-language-neutral. Perl is
  the reference implementation, not part of the semantic schema.
- The first profile is intentionally one-unit/one-domain/scalar-logic. The
  schema has arrays for future widening, but composition, aggregates, multiple
  domains, and other protocols fail closed until qualified.
- The storage probe used by the checked VIAL source cannot execute until a
  later backend profile supplies an equivalent adapter capability.
- Proposed `.5` owns implementation and focused t1551. Binding and execution
  remain with `.6`/`.7`; public tooling remains with `.8`.
