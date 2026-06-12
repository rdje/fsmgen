# LANGUAGE-SURFACE-FILE-CLI-MODES: Advertise File-Surface CLI Modes

## Metadata

- Tree ID: `LANGUAGE-SURFACE-FILE-CLI-MODES`
- Status: `done`
- Roadmap lane: `Embedding And Public APIs`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Advertise the supported CLI modes for each shipped file suffix in the
capability manifest's `language_surface.file_surfaces.entries[]` metadata.

## Non-Goals

- Do not change parser, lowering, HDL, check JSON, semantic JSON, or schedule
  JSON behavior.
- Do not add new file suffixes or aliases.
- Do not promise full API stability for the broader language surface.

## Acceptance Criteria

- Each shipped file-surface entry advertises a bounded `supported_cli_modes[]`
  list.
- The `.ppif` entry explicitly includes `--emit-semantic-json` and
  `--emit-schedule-json`.
- The language-surface contract and capability manifest tests cover the new
  entry key.
- README, mdBook, Knowledge Map fact body, task tree, and `MEMORY.md` stay
  aligned.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `LANGUAGE-SURFACE-FILE-CLI-MODES`
  Status: `done`
  Goal: `Advertise per-file-suffix CLI modes in the language-surface manifest.`
  Children: `LANGUAGE-SURFACE-FILE-CLI-MODES.1`

- ID: `LANGUAGE-SURFACE-FILE-CLI-MODES.1`
  Status: `done`
  Goal: `Add supported_cli_modes metadata for shipped file surfaces.`
  Acceptance: `Capability manifest file-surface entries include supported_cli_modes and tests assert .ppif semantic/schedule JSON modes.`
  Verification: `perl -Iperl -c perl/FSM/Support/LanguageSurfaceContract.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; focused manifest/PPIF/docs/knowledge checks passed.
  Commit: `LANGUAGE-SURFACE-FILE-CLI-MODES.1: advertise file CLI modes`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `LANGUAGE-SURFACE-FILE-CLI-MODES.1` | `done` | File-surface entries now advertise bounded supported CLI modes per shipped suffix. |

## Decisions

- `2026-06-12`: Keep the field descriptive and bounded. It records supported
  CLI modes for shipped suffixes, not a full CLI option schema.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `LANGUAGE-SURFACE-FILE-CLI-MODES.1` | `perl -Iperl -c perl/FSM/Support/LanguageSurfaceContract.pm`; `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t`; `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/363-language-surface-section-runtime-contract-audit.t t/446-language-surface-contract-defensive-copy-boundary-audit.t t/483-language-surface-section-defensive-copy-boundary-audit.t t/957-capability-manifest-language-surface-contract-top-level-keys-json-roundtrip-audit.t t/958-capability-manifest-language-surface-contract-language-family-keys-json-roundtrip-audit.t t/962-capability-manifest-language-surface-contract-top-level-keys-defensive-copy-audit.t t/963-capability-manifest-language-surface-contract-language-family-keys-defensive-copy-audit.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1435-axi-ial2-valid-ready-generator.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `LANGUAGE-SURFACE-FILE-CLI-MODES.1` | `LANGUAGE-SURFACE-FILE-CLI-MODES.1: advertise file CLI modes` | `completed` |

## Changelog

- `2026-06-12`: Created task tree and selected the file-surface CLI mode manifest leaf.
- `2026-06-12`: Added `supported_cli_modes[]` to shipped file-surface manifest entries, covered `.ppif` CLI modes in tests, and synced README, mdBook, and the PPIF fact card.
