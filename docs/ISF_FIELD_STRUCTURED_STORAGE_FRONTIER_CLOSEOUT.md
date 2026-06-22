# ISF Field-Structured Storage Frontier Closeout

- Date: `2026-06-22`
- Owner: `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.5`
- Status: closed after support-accounted scalar field metadata

## Context

`ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2` shipped the first bounded source
surface for declarative storage field maps: metadata-only `(fields (field NAME
(bits HI LO) ...))` on width-based scalar actor-owned `var` / `variable`
storage. The parser validates the accepted scalar metadata, the lowerer keeps
scheduled `.fsm` and HDL behavior unchanged by field metadata, and schedule
JSON exposes the public field-map payload through optional
`inferred_storage[].fields`.

`ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.4` then promoted that surface into the
public support-accounting path by adding `isf/storage_fields.isf` and
registering it as `feature.isf_storage_field_metadata`. Check JSON and
normalized semantic JSON report the matched source identity; normalized
semantic JSON remains the generated `.fsm` semantic-root view for `.isf`
inputs.

## Closeout Decision

Close this narrow field-structured-storage frontier after `.4`.

The original downstream request now has a shipped, checked, documented,
support-accounted scalar metadata surface. The remaining field-storage
directions are not incremental support-accounting or documentation cleanup;
they are behavior, layout, or semantic-payload expansions and should each get a
fresh exact task-tree owner before any code changes.

## Deferred Future Owners

Future exact leaves may pick up:

- parent reset derivation from complete field maps;
- actor `(enums ...)` references from field metadata;
- access-policy behavior such as read-clear, write-one-to-clear, WARL, WPRI,
  or reserved-bit enforcement;
- generated assertions, register models, UVM/VHDL verification artifacts,
  scoreboards, or coverage;
- typed storage fields, aggregate carriers, banks, packet/flit layouts, and
  transaction payload structures; and
- direct normalized semantic JSON projection of ISF field maps.

Until such leaves exist, schedule JSON remains the public field-map payload,
and support accounting is the public check/semantic JSON discovery surface for
`isf/storage_fields.isf`.

## Handoff

The active PNT pointer can return to the broader roadmap frontier:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.240`, which owns dynamic runtime
beat-count/RLAST validation over generated dynamic last-beat read-data.
