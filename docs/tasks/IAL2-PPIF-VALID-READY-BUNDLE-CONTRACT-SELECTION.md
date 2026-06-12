# IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION: Select PPIF Bundle Contract

## Metadata

- Tree ID: `IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Select the future `.ppif` multi Valid-Ready bundle contract that must exist
before parser/generator/CLI behavior can accept more than one
`valid-ready-channel` object in a file.

## Non-Goals

- Do not change parser, generator, CLI, report, HDL, or test behavior.
- Do not implement multi-object `.ppif` support.
- Do not implement AXI manager transactions, transaction IDs, ordering rules,
  bursts, response matching, or channel dependency enforcement.
- Do not select protocol-profile suffix aliases such as `.axi`.

## Acceptance Criteria

- The selected bundle contract identifies the authored source shape, source
  attribution model, aggregate report schema, generated IAL1/IAL0 artifact
  shape, and CLI-mode behavior required for a future implementation owner.
- The selection explicitly preserves the current one-object `.ppif` behavior
  until a future code leaf changes it.
- The mdBook backlog points at the selected contract without implying shipped
  multi-object behavior.
- A Knowledge Map fact captures the durable contract choice.
- Focused docs, Knowledge Map, memory, path, and diff gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION`
  Status: `done`
  Goal: `Select the future multi Valid-Ready .ppif bundle contract.`
  Children: `IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.1`

- ID: `IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.1`
  Status: `done`
  Goal: `Document the selected future bundle source/report/artifact/CLI contract.`
  Acceptance: `The contract selection note, task tree, mdBook backlog, Knowledge Map fact, generated map, and MEMORY pointer agree on the selected future bundle contract and current unshipped behavior.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.1: select PPIF bundle contract`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.1` | `done` | Future multi-channel `.ppif` support now has a selected aggregate bundle source/report/artifact/CLI contract. |

## Decisions

- `2026-06-12`: Start with a contract-selection leaf before any behavior
  owner. This turns the readiness prerequisite into a reviewable future
  implementation target.

## Open Questions

- None for this selection slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.1` | `IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.1: select PPIF bundle contract` | `completed` |

## Changelog

- `2026-06-12`: Created task tree and selected the future PPIF Valid-Ready
  bundle contract-selection leaf.
- `2026-06-12`: Completed the bundle source/report/artifact/CLI contract
  selection, ADR 0017, mdBook sync, Knowledge Map fact, generated map update,
  and validation.
