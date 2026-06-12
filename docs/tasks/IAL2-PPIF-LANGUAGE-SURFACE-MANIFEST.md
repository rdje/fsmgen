# IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST: Advertise PPIF In Language Surface Manifest

## Metadata

- Tree ID: `IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Advertise the shipped `.ppif` public IAL2 file surface through the bounded
capability-manifest language-surface contract so downstream consumers can
discover the `IAL2 -> IAL1 -> IAL0` file-layer stack without reading the
source tree.

## Non-Goals

- Do not add new `.ppif` syntax.
- Do not support `.pif`, `.ppi`, `.axi`, or any other alias.
- Do not change parser, lowering, HDL generation, or report behavior.
- Do not claim multiple `.ppif` objects, platform clauses, protocol-profile
  aliases, or full AXI manager behavior.

## Acceptance Criteria

- `--capability-manifest` exposes a bounded `language_surface.file_surfaces`
  section that lists shipped `.fsm`, `.isf`, and `.ppif` file suffixes.
- The `.ppif` manifest entry states that `.ppif` is IAL2, lowers through
  generated `.isf` before generated `.fsm`, and currently supports only the
  first Valid-Ready PPIF slice.
- Contract helpers and focused manifest tests cover the new bounded key
  family without freezing the entire language-surface object.
- The mdBook, PPIF docs, README/Knowledge Map as needed, task tree, and MEMORY
  are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST`
  Status: `done`
  Goal: `Advertise shipped file suffixes, including .ppif, in the capability manifest.`
  Children: `IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST.1`

- ID: `IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST.1`
  Status: `done`
  Goal: `Add bounded language_surface.file_surfaces manifest metadata and focused coverage.`
  Acceptance: `Downstream consumers can discover .fsm, .isf, and .ppif file-layer roles from --capability-manifest.`
  Verification: `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceContract.pm`; `prove -Iperl t/297-capability-manifest.t t/446-language-surface-contract-defensive-copy-boundary-audit.t t/957-capability-manifest-language-surface-contract-top-level-keys-json-roundtrip-audit.t t/958-capability-manifest-language-surface-contract-language-family-keys-json-roundtrip-audit.t t/959-capability-manifest-language-surface-contract-nested-map-guidance-json-roundtrip-audit.t t/962-capability-manifest-language-surface-contract-top-level-keys-defensive-copy-audit.t t/963-capability-manifest-language-surface-contract-language-family-keys-defensive-copy-audit.t t/1066-language-surface-contract-full-surface-defensive-copy-audit.t t/1436-ial2-ppif-parser-cli.t t/1435-axi-ial2-valid-ready-generator.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1376-isf-book-example-lowering-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST.1: advertise PPIF file surface`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST.1` | `done` | The capability manifest now advertises `.fsm`, `.isf`, and `.ppif` file surfaces. |

## Decisions

- `2026-06-12`: Keep this as manifest/documentation alignment only. The
  parser/CLI behavior shipped in earlier PPIF slices remains unchanged.

## Open Questions

- None for this slice. Future aliases or richer `.ppif` objects need separate
  exact owners.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceContract.pm`; focused manifest/PPIF `prove` cluster; `mdbook build docs/book`; mdBook/path audit `prove` cluster; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `IAL2-PPIF-LANGUAGE-SURFACE-MANIFEST.1: advertise PPIF file surface` | `pending commit workflow` |

## Changelog

- `2026-06-12`: Created active task tree for PPIF language-surface manifest
  discoverability.
- `2026-06-12`: Added bounded `language_surface.file_surfaces` manifest
  metadata, contract helpers, focused tests, and user-facing docs for the
  shipped `.fsm`/`.isf`/`.ppif` file suffix stack.
