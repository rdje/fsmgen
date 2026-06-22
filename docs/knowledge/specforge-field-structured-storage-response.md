---
id: specforge-field-structured-storage-response
title: SPECFORGE field-structured storage request is accepted as future ISF work
answers:
  - "what is the FSMGen answer to SPECFORGE's field-structured storage request?"
  - "does ISF currently support declarative register bit-fields?"
  - "should SPECFORGE use set-field or extract to represent static field maps?"
  - "what is the next owner for declarative field-structured storage?"
  - "can SPECFORGE emit field-structured storage today?"
date: 2026-06-22
status: current
tags: [isf, specforge, storage, register-fields, bit-fields, downstream]
evidence: docs/SPECFORGE_FEEDBACK_RESPONSE.md; docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.md; docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md; docs/book/src/14-feature-backlog.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md
reverify: rg -n 'Field-Structured Storage|ISF-FIELD-STRUCTURED-STORAGE|declarative field-structured storage|set-field|runtime field operations|static field-map' docs/SPECFORGE_FEEDBACK_RESPONSE.md docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-RESPONSE.md docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md docs/book/src/14-feature-backlog.md docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md
---

FSMGen's answer to SPECFORGE's 2026-06-22 request is: yes, declarative
field-structured storage is a valid future ISF direction, and it exposes a
real representational gap for static register/CSR bit-field maps and related
packed layouts. It is not shipped behavior yet.

Existing ISF runtime field operations such as `set-field`, `when-field`,
`extract`, and `assemble` must not be used to fake a static field map. Those
forms describe scheduled behavior or data movement over opaque storage, not a
declarative source-authored layout.

Until the feature ships, SPECFORGE should keep field maps in IntentIR
metadata/residuals and may continue emitting opaque `(storage (var ...))`
only when that preserves the supported storage contract honestly.

The next FSMGen owner is
`ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1`, a readiness/contract audit for the
first checked declarative field-structured storage slice.
