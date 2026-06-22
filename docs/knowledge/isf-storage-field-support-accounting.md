---
id: isf-storage-field-support-accounting
title: ISF scalar storage field metadata has a support-accounted public fixture
answers:
  - "which public fixture covers ISF scalar storage field metadata?"
  - "what is the support-accounting id for ISF storage fields?"
  - "does check JSON match ISF storage field metadata support accounting?"
  - "does normalized semantic JSON include ISF storage field maps?"
date: 2026-06-22
status: current
tags: [isf, storage, register-fields, support-accounting, schedule-report, semantic-json]
evidence: isf/storage_fields.isf; perl/FSM/Support/RegressionCorpus.pm; t/1453-isf-storage-field-metadata.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/ISF_SPEC.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; docs/book/src/13a-actor-interface.md; docs/book/src/13k-isf-feature-support-matrix.md
reverify: prove -Iperl t/1453-isf-storage-field-metadata.t t/248-regression-corpus-accounting.t
---

`isf/storage_fields.isf` is the public file-backed fixture for scalar ISF
storage field metadata. The support-accounting catalog registers it as
`feature.isf_storage_field_metadata` with `family:
language_feature_fixture`, `coverage: isf_pipeline_cli`, `source_kind: isf`,
and `strict_supported: true`.

Check JSON and normalized semantic JSON report that matched support-accounting
identity for the fixture. The field map itself remains a schedule JSON payload
through `inferred_storage[].fields`; normalized semantic JSON continues to
describe the generated `.fsm` semantic root for `.isf` inputs and does not add
a direct field-map projection in this slice.
