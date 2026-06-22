---
id: isf-field-structured-storage-contract-selection
title: ISF field-structured storage first slice ships metadata-only scalar storage fields
answers:
  - "what is the first ISF field-structured storage implementation contract?"
  - "how will FSMGen represent declarative register fields first?"
  - "are storage fields metadata-only in the first slice?"
  - "does field reset metadata derive storage reset values?"
  - "what owns implementation of declarative storage fields?"
date: 2026-06-22
status: current
tags: [isf, storage, register-fields, bit-fields, schedule-report]
evidence: docs/ISF_FIELD_STRUCTURED_STORAGE_CONTRACT_SELECTION.md; docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md; docs/ISF_SPEC.md; docs/book/src/13a-actor-interface.md; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/Emitter/JSON.pm; t/1453-isf-storage-field-metadata.t
reverify: rg -n 'metadata-only|inferred_storage\\[\\]\\.fields|ISF-FIELD-STRUCTURED-STORAGE-FRONTIER\\.2|field reset|storage field metadata|Declarative Storage Fields' docs/ISF_FIELD_STRUCTURED_STORAGE_CONTRACT_SELECTION.md docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md docs/ISF_SPEC.md docs/book/src/13a-actor-interface.md perl/FSM/Adapter/ISF/Parser.pm perl/FSM/Scheduler/ISF/Emitter/JSON.pm t/1453-isf-storage-field-metadata.t
---

The first declarative field-structured storage implementation shipped in
`ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.2`. It is limited to metadata-only
`fields` on width-based scalar actor-owned `(var ...)` / `(variable ...)`
storage entries.

The selected syntax uses `(fields (field NAME (bits HI LO) ...))` under a
storage variable. Validation must reject duplicate names, malformed or
overlapping bit ranges, ranges outside the resolved parent width, unsupported
access tokens, over-width field reset values, enum collisions, and enum values
that do not fit the field width.

Field reset metadata does not derive hardware reset behavior in the first
slice. If a field declares `(reset V)`, the parent storage variable must also
declare `(reset PARENT)`, and the field reset must match that parent bit slice.

The public report projection is optional `inferred_storage[].fields`; generated
`.fsm`, HDL, scheduler behavior, access-policy behavior, aggregate/bank/packet
layouts, and actor `(enums ...)` references remain deferred.
