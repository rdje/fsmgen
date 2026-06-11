# AXI-SPEC-LOCAL-REFERENCE-IMPORT: AXI Spec Local Reference Import

## Metadata

- Tree ID: `AXI-SPEC-LOCAL-REFERENCE-IMPORT`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Import the provided Arm AMBA AXI Protocol Specification PDF into the repository
as a tracked local reference artifact for future task-tree-owned IAL2 protocol
intent probes.

## Non-Goals

- Do not extract protocol rules from the PDF in this slice.
- Do not implement IAL2 parser, scheduler, lowering, or HDL behavior.
- Do not claim automated PDF/spec-to-FSM capture as shipped behavior.
- Do not record the external machine-local source path in tracked docs.

## Acceptance Criteria

- The provided PDF is copied into a repo-local tracked path.
- Live docs identify the repo-local reference artifact with relative paths.
- The mdBook IAL2 backlog and AXI case-study note remain synchronized.
- Focused docs/path/memory gates pass.
- The completed slice is committed through `COMMIT.md`.

## Task Tree

- ID: `AXI-SPEC-LOCAL-REFERENCE-IMPORT`
  Status: `done`
  Goal: `Track the provided AXI specification PDF as a repo-local reference artifact.`
  Children: `AXI-SPEC-LOCAL-REFERENCE-IMPORT.1`

- ID: `AXI-SPEC-LOCAL-REFERENCE-IMPORT.1`
  Status: `done`
  Goal: `Copy and document the AXI spec PDF reference artifact.`
  Acceptance: `Copy the provided PDF into the repository, keep it git-trackable, update README/mdBook/AXI notes with repo-relative references, and leave future extraction/implementation to later exact task-tree leaves.`
  Verification: `source/copy SHA-256 match`; `git check-ignore`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `AXI-SPEC-LOCAL-REFERENCE-IMPORT.1: track AXI spec reference`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AXI-SPEC-LOCAL-REFERENCE-IMPORT.1` | `done` | The user provided the current AXI specification PDF and requested a repo-local tracked copy. |

## Decisions

- `2026-06-12`: Store the PDF under `docs/vendor/arm/amba/axi/` so protocol
  reference artifacts are local to the documentation/evidence tree and remain
  distinct from generated code or implementation fixtures.
- `2026-06-12`: Keep this slice as an artifact/docs import only. The prior
  IAL2 evaluation selected no implementation; any AXI extraction or
  valid/ready probe still needs a later exact task-tree leaf.
- `2026-06-12`: Imported
  `docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`.
  The copied artifact matches the provided source with SHA-256
  `20aa5f946df5fa97053689d705959b1ef6a90a88f845fa3b686a53311f680ac1`.

## Open Questions

- Whether the first AXI-based IAL2 probe should use the raw PDF directly or a
  normalized Markdown conversion remains open for a future task.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `source/copy SHA-256 match`; `git check-ignore` confirms the PDF is not ignored; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `AXI-SPEC-LOCAL-REFERENCE-IMPORT.1: track AXI spec reference` | Pending artifact-import commit. |

## Changelog

- `2026-06-12`: Created active task tree and activated `.1`.
- `2026-06-12`: Completed `.1`, copied and documented the repo-local AXI spec
  PDF reference artifact, and closed the tree.
