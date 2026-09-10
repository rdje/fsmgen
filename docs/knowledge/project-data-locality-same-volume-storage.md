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
  - "how is the mdbook destination output directory resolved?"
date: 2026-09-10
status: current
tags: [artifacts, storage, temporary-files, caches, portability, doctrine]
evidence: docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; PROJECT_DATA_LOCALITY.md; docs/decisions/0022-project-data-locality-and-same-volume-storage.md; docs/tasks/PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.md; scripts/check_project_data_locality.sh; README.md; TOOLBOX.md; docs/book/src/09-generated-hdl-debugging-and-inspection.md
reverify: scripts/check_project_data_locality.sh
---

All project-owned output, builds, caches, logs, fixtures and temporary workspaces
stay on the repository volume, normally in `.artifacts/`. Runtime tools derive
absolute locations from the current root; persisted paths remain root-relative.
`PROJECT_DATA_LOCALITY.md` defines subdirectories and external-input exceptions.
Off-volume data follows copy/verify/use/delete; ambiguous shared caches stay.

Adoption is complete. `scripts/check_project_data_locality.sh` rejects OS temporary
paths in runtime, tests, configuration, README, toolbox, mdBook, fact cards and
Knowledge Map, and verifies shared local runtime/launcher controls.

From repository cwd, use `mdbook build docs/book --dest-dir .artifacts/book`:
mdBook resolves the destination from cwd. Task `.3.2.15.7.3.9` retains a misplaced
build's same-volume copy, complete hash comparison, rendered inspection and
exact-directory deletion/residue evidence.
