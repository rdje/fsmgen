# ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT: Accellera Standards Local Reference Import

## Metadata

- Tree ID: `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT`
- Status: `done`
- Roadmap lane: `standards reference artifacts`
- Created: `2026-06-16`
- Last updated: `2026-06-16`
- Owner: repo-local workflow

## Goal

Import the provided Accellera SystemRDL, Portable Stimulus, and UVM PDF
standards into the repository as tracked local reference artifacts, and keep
local-only untracked UVM 1.2 source/documentation plus SystemVerilog LRM
Markdown mirrors available for future task-tree-owned reference work.

## Non-Goals

- Do not extract standard rules from the PDFs in this slice.
- Do not implement parser, scheduler, lowering, HDL, UVM, PSS, or SystemRDL
  behavior.
- Do not claim automated standard-to-FSM capture as shipped behavior.
- Do not git-track the UVM 1.2 source/documentation directory mirror.
- Do not git-track the SystemVerilog LRM Markdown mirrors.
- Do not record external machine-local source paths in tracked docs.

## Acceptance Criteria

- The four provided Accellera PDF standards are copied into repo-local tracked
  paths under `docs/vendor/accellera/`.
- The copied PDFs are git-trackable and match their provided local sources by
  SHA-256.
- The UVM 1.2 source/documentation tree is copied into an ignored local-only
  reference path.
- The SystemVerilog 1800-2017 and 1800-2023 LRM Markdown trees are copied into
  ignored local-only reference paths.
- Live docs identify the repo-local tracked PDF artifacts with relative paths.
- Focused docs/path/memory gates pass.
- The completed slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT`
  Status: `done`
  Goal: `Track provided Accellera PDF standards and keep local-only UVM 1.2 and SV LRM mirrors.`
  Children: `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.1`

- ID: `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.1`
  Status: `done`
  Goal: `Copy and document the Accellera standards reference artifacts.`
  Acceptance: `Copy the provided PDFs into the repository, keep them git-trackable, copy the UVM 1.2 source/documentation directory and SystemVerilog LRM Markdown directories into ignored local-only reference paths, update README/mdBook with repo-relative tracked PDF references, and leave extraction/implementation to later exact task-tree leaves.`
  Verification: `source/copy SHA-256 match`; `git check-ignore`; `SV LRM mirror file-count match`; `knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.1: track standards references`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.1` | `done` | The provided Accellera SystemRDL, PSS, and UVM standards references were copied as tracked local PDF artifacts, and the UVM 1.2 plus SystemVerilog LRM Markdown mirrors were copied into ignored local-only paths. |

## Decisions

- `2026-06-16`: Store tracked PDF references under `docs/vendor/accellera/`
  so standards artifacts remain local to the documentation/evidence tree and
  distinct from generated code or implementation fixtures.
- `2026-06-16`: Keep the UVM 1.2 source/documentation mirror local-only under
  an ignored cache path because the user requested that directory not be
  tracked.
- `2026-06-16`: Keep this slice as artifact/docs import only. Any SystemRDL,
  PSS, or UVM extraction, design decision, or implementation work still needs a
  later exact task-tree leaf.
- `2026-06-16`: Imported the tracked PDF references:
  - `docs/vendor/accellera/systemrdl/SystemRDL_2.0_Jan2018.pdf`
    (`SHA-256 4b0838e93d03a4974c6e67832e2fca765610af213776cf8f61086dd23596b5d7`)
  - `docs/vendor/accellera/pss/Portable_Test_Stimulus_Standard_v3.0.pdf`
    (`SHA-256 e9d75e47d1f248b137540ed3ed7de8ae067b597e13f6e6909d12eb8d0e95243b`)
  - `docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf`
    (`SHA-256 87117e30e17701a13434f785687d3776e710e13c74475b6ada4e7823244ea87a`)
  - `docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf`
    (`SHA-256 6cddf735c3f7f700ef5f62b2954a28f7fb7e590a149314cbe5b0d342f99d131c`)
- `2026-06-16`: Copied the UVM 1.2 source/documentation mirror into
  `.cache/local-references/accellera/uvm/uvm-1.2`; `.cache/` is ignored and
  the mirror is intentionally not tracked.
- `2026-06-16`: Copied local-only SystemVerilog LRM Markdown mirrors into
  `.cache/local-references/sv/1800-2017` and
  `.cache/local-references/sv/1800-2023`; `.cache/` is ignored and the mirrors
  are intentionally not tracked.

## Open Questions

- Which future standard-derived probe, if any, should be selected first remains
  open for a future task-tree leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `.1` | `source/copy SHA-256 match`; `git check-ignore` confirms the tracked PDFs are not ignored and the UVM/SV local mirrors are ignored by `.cache/`; SV LRM mirror file counts match (`59` files for 1800-2017, `58` files for 1800-2023); `knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.1: track standards references` | Pending artifact-import commit. |

## Changelog

- `2026-06-16`: Created active task tree and activated `.1`.
- `2026-06-16`: Completed `.1`, copied and documented the tracked Accellera
  PDF references, copied the ignored local-only UVM 1.2 source/documentation
  and SystemVerilog LRM Markdown mirrors, and closed the tree.
