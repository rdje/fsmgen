# ISF Field-Structured Storage Next Residual Selection

- Date: `2026-06-22`
- Owner: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.3`
- Status: selected follow-up support-accounting slice

## Context

`ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2` shipped the first bounded
declarative field-structured storage surface: metadata-only `(fields (field
NAME (bits HI LO) ...))` on width-based scalar actor-owned storage variables.
The parser validates names, ranges, overlaps, access tokens, field reset
metadata against explicit parent reset values, and inline enum metadata. The
lowerer keeps generated `.fsm` and HDL behavior unchanged, and schedule JSON
projects the accepted field map through optional `inferred_storage[].fields`.

The remaining field-structured-storage directions should not be widened until
the shipped scalar metadata slice is easier for downstream users and tools to
discover through the public support-accounting path.

## Audit Result

The current implementation has focused parser/report coverage in
`t/1453-isf-storage-field-metadata.t` and schedule-report contract coverage in
`t/1255-isf-schedule-report-golden-matrix.t`. The mdBook, ISF spec,
downstream handoff, public contract code, and Knowledge Map already describe
the first slice as report-only.

The missing downstream-facing residual is a file-backed, support-accounted
sample. Today, a consumer can learn the feature from docs or unit tests, but
the support-accounting catalog does not yet advertise one public `.isf` source
whose check JSON and normalized semantic JSON report a matched supported entry
for the field-storage surface.

One public-contract prose summary still listed `inferred_storage` optional keys
without `fields`; the machine contract and downstream handoff already include
it. This selector synchronizes that summary as documentation only.

## Selected Next Slice

Select `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.4`: add a file-backed,
support-accounted scalar storage-field sample and keep the contract summaries
aligned.

The slice should:

- add one representative `.isf` fixture using width-based scalar storage
  fields with access, reset, and inline enum metadata;
- register the fixture in support accounting so supported check JSON and
  normalized semantic JSON match a stable public source identity;
- keep the generated `.fsm`, HDL, parser, scheduler, lowerer, and schedule
  JSON behavior unchanged except for the new sample path;
- prove the sample's schedule JSON exposes `inferred_storage[].fields`;
- keep normalized semantic JSON as the generated `.fsm` semantic-root view,
  with the field-storage support claim coming from support accounting rather
  than a new semantic payload projection; and
- update the downstream/book/support-accounting docs that point users to
  representative file-backed ISF fixtures.

## Explicit Deferrals

- Parent reset derivation from a complete field map remains deferred. It would
  change hardware reset behavior and needs a separate complete-map/default-gap
  policy before implementation.
- Actor `(enums ...)` references from field metadata remain deferred until a
  source syntax and report shape are selected.
- Access-policy behavior remains deferred. Current access tokens are metadata
  only and do not imply write-one-to-clear, read-clear, WARL, or reserved-bit
  logic.
- Generated assertions, register-model output, UVM/VHDL verification
  artifacts, and scoreboard/coverage generation remain deferred behind the
  verification-output frontier.
- Typed storage fields, aggregate carriers, banks, packet/flit layouts, and
  transaction payload structures remain deferred because each requires a
  broader storage/type/layout contract than the scalar report metadata slice.
- Normalized semantic JSON projection of ISF field metadata remains deferred.
  The current normalized semantic payload intentionally describes the generated
  `.fsm` root for `.isf` sources; schedule JSON remains the public field-map
  payload for this slice.

## Rollback Boundary

If the support-accounting slice proves too broad, roll back by leaving the
shipped parser/report behavior intact and closing the field-structured-storage
frontier after recording the sample/support-accounting gap as deferred. No
runtime behavior or source syntax needs to change for this selector.
