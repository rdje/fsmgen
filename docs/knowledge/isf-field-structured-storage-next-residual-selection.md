---
id: isf-field-structured-storage-next-residual-selection
title: ISF field-structured storage next residual is support-accounting promotion
answers:
  - "what is the next ISF field-structured storage residual after scalar metadata?"
  - "does field storage metadata need support accounting next?"
  - "does ISF field metadata belong in normalized semantic JSON today?"
  - "what remains deferred after ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.3?"
date: 2026-06-22
status: current
tags: [isf, storage, register-fields, support-accounting, schedule-report]
evidence: docs/ISF_FIELD_STRUCTURED_STORAGE_NEXT_RESIDUAL_SELECTION.md; docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/book/src/14-feature-backlog.md; isf/storage_fields.isf; perl/FSM/Support/RegressionCorpus.pm; t/1453-isf-storage-field-metadata.t; t/1255-isf-schedule-report-golden-matrix.t
reverify: rg -n 'ISF-FIELD-STRUCTURED-STORAGE-FRONTIER\\.3|ISF-FIELD-STRUCTURED-STORAGE-FRONTIER\\.4|feature\\.isf_storage_field_metadata|isf/storage_fields\\.isf|inferred_storage\\[\\]\\.fields|normalized semantic payload|NEXT_RESIDUAL' docs/ISF_FIELD_STRUCTURED_STORAGE_NEXT_RESIDUAL_SELECTION.md docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md docs/ISF_PUBLIC_INTERFACE_CONTRACT.md docs/book/src/14-feature-backlog.md perl/FSM/Support/RegressionCorpus.pm
---

`ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.3` selected support-accounting
promotion as the next bounded residual after the metadata-only scalar storage
field slice.

The selected implementation leaf was
`ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.4`. It added the file-backed public
fixture `isf/storage_fields.isf` for shipped scalar `(fields ...)` metadata
and registered it as `feature.isf_storage_field_metadata`, so check JSON and
normalized semantic JSON report a matched supported source identity.

Schedule JSON remains the public payload for the field map through
`inferred_storage[].fields`. Normalized semantic JSON still describes the
generated `.fsm` semantic root for `.isf` sources; adding a direct semantic
payload projection for field metadata remains deferred.

Parent reset derivation, actor `(enums ...)` references, access-policy
behavior, generated assertions or register models, typed storage fields,
aggregate carriers, banks, packet/flit layouts, and broader verification
artifacts also remain deferred behind future exact leaves.
