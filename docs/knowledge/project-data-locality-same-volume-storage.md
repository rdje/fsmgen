---
id: project-data-locality-same-volume-storage
title: FSMGen project-owned data stays on the repository filesystem volume
answers:
  - "where must FSMGen store generated project data?"
  - "where should FSMGen temporary files and test fixtures live?"
  - "may FSMGen use the operating-system temporary directory?"
  - "may FSMGen use a user-home dependency cache?"
  - "how should off-volume FSMGen data be migrated?"
  - "what is the project data locality policy?"
date: 2026-07-29
status: current
tags: [artifacts, storage, temporary-files, caches, portability, doctrine]
evidence: PROJECT_DATA_LOCALITY.md; docs/decisions/0022-project-data-locality-and-same-volume-storage.md; docs/tasks/PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.md; scripts/check_project_data_locality.sh; README.md; TOOLBOX.md; docs/book/src/09-generated-hdl-debugging-and-inspection.md
reverify: scripts/check_project_data_locality.sh
---

FSMGen stores all project-owned generated output, build state, caches, logs,
test fixtures, and temporary workspaces on the repository filesystem volume.
Runtime tools derive absolute locations from the current repository root while
persisted project paths remain repository-relative.

The general generated-state root is `.artifacts/`; exact subdirectories and
the external-input exception boundary are defined in
`PROJECT_DATA_LOCALITY.md`. Existing exact off-volume project data follows
copy/verify/use/delete. Ambiguous shared caches are not deleted.

The adoption is complete. `scripts/check_project_data_locality.sh` now requires
zero operating-system temporary paths in live runtime, test, configuration,
README, toolbox, mdBook, fact-card, and generated Knowledge Map surfaces; the
check also verifies the shared repository-local runtime and launcher controls.
