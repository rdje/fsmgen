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
date: 2026-10-25
status: current
tags: [artifacts, storage, temporary-files, caches, portability, doctrine]
evidence: docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; PROJECT_DATA_LOCALITY.md; docs/decisions/0022-project-data-locality-and-same-volume-storage.md; docs/tasks/PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.md; scripts/check_project_data_locality.sh; README.md; TOOLBOX.md; docs/book/src/09-generated-hdl-debugging-and-inspection.md
reverify: scripts/check_project_data_locality.sh
---

Keep all project outputs/builds/caches/logs/fixtures/temp workspaces on the repo
volume, normally `.artifacts/`. Persist relative paths; derive absolute paths.
`PROJECT_DATA_LOCALITY.md` owns roots/external-input exceptions. Migration:
copy/verify/use/delete exact owned data; retain ambiguous shared caches.

Adopted guard: `scripts/check_project_data_locality.sh` rejects OS-temp paths in runtime/tests/config/README/toolbox/book/cards/Knowledge Map and checks shared runtime/launcher controls.

From repo cwd, `mdbook build docs/book --dest-dir .artifacts/book` resolves from
cwd. Task `.3.2.15.7.3.9`: misplaced build's local copy, complete hashes, rendered
inspection, exact deletion/residue.

`gh`: book-local XDG cache/state/temp, updates/telemetry off, config/keychain read-only auth. PUBLICATION-REGRESSION-REPAIRS.5 owns exact log-cache migration proof; other shared entries stay.
