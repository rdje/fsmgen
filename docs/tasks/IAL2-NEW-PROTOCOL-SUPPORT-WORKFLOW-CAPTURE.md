# IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE: IAL2 New Protocol Support Workflow Capture

## Metadata

- Tree ID: `IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE`
- Status: `done`
- Roadmap lane: `IAL2 / protocol onboarding documentation`
- Created: `2026-06-28`
- Last updated: `2026-06-28`
- Owner: repo-local workflow

## Goal

Capture the reusable end-to-end process for adding a new protocol to IAL2,
using the AXI and APB implementation history as evidence, so future protocol
support can be selected, implemented, validated, documented, and maintained in
a systematic way.

## Non-Goals

- Do not implement any new protocol behavior in this tree.
- Do not select the next APB, AXI, AHB, VHDL, direct-backend, or
  verification-output behavior slice.
- Do not relax the task-tree, commit, mdBook, Knowledge Map, or doctrine
  requirements.
- Do not claim new-protocol support is one monolithic implementation task.

## Acceptance Criteria

- A canonical repository doc describes the protocol-onboarding workflow from
  evidence capture through public syntax, parser/generator/report support,
  samples, support accounting, tests, docs, mdBook, Knowledge Map, and commit
  workflow.
- The mdBook exposes the workflow as user-facing project guidance.
- README points to the workflow doc.
- The task tree, Memory, and Knowledge Map are aligned.
- Documentation gates and doctrine checks pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE`
  Status: `done`
  Goal: `Document the reusable IAL2 new-protocol support workflow.`
  Children: `IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE.1`

- ID: `IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE.1`
  Status: `done`
  Goal: `Capture the end-to-end IAL2 new-protocol support workflow from AXI/APB experience.`
  Acceptance: `Read representative AXI/APB protocol-intent docs, parser/generator/report/support-accounting surfaces, mdBook/README conventions, task-tree and memory doctrine. Add a canonical docs workflow and mdBook page that define ordered phases, required artifacts, validation gates, residue handling, rollback, and stop conditions for any future protocol. Update README, Memory, Knowledge Map, task tree, and docs index surfaces. No parser, generator, sample, support-accounting, schedule/check/semantic JSON, generated-artifact, HDL/runtime, suffix, direct-backend, verification-output, backend-language, APB, AXI, AHB, or VHDL behavior changes occur.`
  Verification: `mdbook build docs/book; knowledge-map/scripts/gen_knowledge_map.sh; knowledge-map/scripts/check_knowledge_map.sh; git diff --check; scripts/check_memory_architecture.sh; scripts/check_doctrines.sh`
  Commit: `IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE.1: capture IAL2 protocol workflow`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE.1` | `done` | Captured reusable protocol onboarding workflow before future protocol work depends on chat-only process knowledge. |

## Decisions

- `2026-06-28`: Treat the new-protocol process capture as documentation and
  continuity work only. Future protocol implementations still need their own
  exact behavior-bearing task-tree leaves.

## Open Questions

- None blocking this capture.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-28` | `IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE.1` | `mdbook build docs/book`; `knowledge-map/scripts/gen_knowledge_map.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`; `scripts/check_memory_architecture.sh`; `scripts/check_doctrines.sh` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE.1` | `IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE.1: capture IAL2 protocol workflow` | `Committed through the repo commit workflow.` |

## Changelog

- `2026-06-28`: Created task tree for the reusable IAL2 new-protocol support
  workflow capture.
- `2026-06-28`: Captured the canonical workflow in
  `docs/IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md`, exposed it in mdBook, and
  aligned README, ROADMAP_V2, Memory, and Knowledge Map continuity surfaces.
