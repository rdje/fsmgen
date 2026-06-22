---
id: isf-field-structured-storage-frontier-closeout
title: ISF field-structured storage frontier closes after support-accounted scalar fields
answers:
  - "is the ISF field-structured storage frontier still active?"
  - "what happened after ISF storage fields were support-accounted?"
  - "what is deferred after ISF storage field frontier closeout?"
  - "what task resumes after ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.5?"
date: 2026-06-22
status: current
tags: [isf, storage, register-fields, task-tree, pnt]
evidence: docs/ISF_FIELD_STRUCTURED_STORAGE_FRONTIER_CLOSEOUT.md; docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'ISF-FIELD-STRUCTURED-STORAGE-FRONTIER\\.5|closed after support-accounted scalar field metadata|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.240|feature\\.isf_storage_field_metadata' docs/ISF_FIELD_STRUCTURED_STORAGE_FRONTIER_CLOSEOUT.md docs/tasks/ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.md docs/TASK_TREE.md MEMORY.md
---

`ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.5` closes the narrow ISF
field-structured-storage frontier after the scalar field metadata surface was
implemented and support-accounted.

The shipped public surface is `isf/storage_fields.isf` registered as
`feature.isf_storage_field_metadata`. Schedule JSON remains the field-map
payload through `inferred_storage[].fields`; check JSON and normalized semantic
JSON discover the feature through support accounting.

Parent reset derivation, actor enum references, access-policy behavior,
generated register/verification outputs, typed or aggregate carriers, banks,
packet/flit layouts, and direct normalized semantic JSON field-map projection
remain deferred behind future exact task-tree leaves.

After `.5`, the active PNT pointer returns to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.240`.
