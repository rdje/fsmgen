---
id: specforge-field-structured-storage-response
title: SPECFORGE field-structured storage request has a bounded metadata-first ISF slice
answers:
  - "what is the FSMGen answer to SPECFORGE's field-structured storage request?"
  - "does ISF currently support declarative register bit-fields?"
  - "should SPECFORGE use set-field or extract to represent static field maps?"
  - "what is the next owner for declarative field-structured storage?"
  - "can SPECFORGE emit field-structured storage today?"
date: 2026-06-22
status: current
tags: [isf, specforge, storage, register-fields, bit-fields, downstream]
evidence: docs/SPECFORGE_FEEDBACK_RESPONSE.md; docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.md; docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md; docs/book/src/13a-actor-interface.md; docs/book/src/14-feature-backlog.md; docs/ISF_SPEC.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/Emitter/JSON.pm; t/1453-isf-storage-field-metadata.t
reverify: rg -n 'Field-Structured Storage|ISF-FIELD-STRUCTURED-STORAGE|inferred_storage\\[\\]\\.fields|set-field|runtime field operations|static field-map|storage field metadata' docs/SPECFORGE_FEEDBACK_RESPONSE.md docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.md docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md docs/book/src/13a-actor-interface.md docs/book/src/14-feature-backlog.md docs/ISF_SPEC.md docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md perl/FSM/Adapter/ISF/Parser.pm perl/FSM/Scheduler/ISF/Emitter/JSON.pm t/1453-isf-storage-field-metadata.t
---

FSMGen's answer to SPECFORGE's 2026-06-22 request is: yes, declarative
field-structured storage is a valid ISF direction, and FSMGen now ships a
bounded metadata-first scalar storage slice for static register/CSR bit-field
maps.

Existing ISF runtime field operations such as `set-field`, `when-field`,
`extract`, and `assemble` must not be used to fake a static field map. Those
forms describe scheduled behavior or data movement over opaque storage, not a
declarative source-authored layout.

SPECFORGE may emit `(fields (field NAME (bits HI LO) ...))` metadata under
width-based scalar `(storage (var ...))` / `(variable ...)` entries when the
field map fits the shipped contract. FSMGen validates names, literal
non-overlapping ranges inside the resolved parent width, optional access
tokens, optional field reset metadata against an explicit parent reset, and
inline enum values, then reports the accepted map through
`inferred_storage[].fields`.

The shipped slice is metadata-only. It does not derive parent reset values,
enforce access policy, generate assertions/register models, or cover banks,
typed aggregate storage carriers, packet/flit layouts, actor `(enums ...)`
references, or runtime field/data operations.
