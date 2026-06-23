# BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH: Refresh import-tree measurements after mixed dynamic/static write demux

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH`
- Status: `done`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-06-23`
- Last updated: `2026-06-23`
- Owner: repo-local workflow

## Goal

Refresh stale measured line counts in the live `bin/fsmgen` import-tree
architecture note after `IAL2-FEATURE-COMPLETENESS-FRONTIER.272` grew the AXI
manager capacity/status implementation, support catalog, and related ISF
surface measurements while leaving the project-owned import topology
unchanged.

## Ground Truth

- The live static trace from `bin/fsmgen` still reaches `206` project files
  total, including `205` `FSM::...` `.pm` packages plus `bin/fsmgen`.
- The stale values are line-count measurements only.
- The largest drift is in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`; smaller drift is
  visible in `perl/FSM/Support/RegressionCorpus.pm` and already-growing ISF
  owners.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL, public API,
  manifests, tests, samples, support-accounting behavior, or runtime behavior.
- Do not edit frozen legacy blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`).
- Do not select the next IAL2 feature-completeness behavior owner; that
  remains owned by `IAL2-FEATURE-COMPLETENESS-FRONTIER.273`.

## Acceptance Criteria

- `docs/BIN_FSMGEN_IMPORT_TREE.md` records the unchanged import-closure counts
  and current measured line counts after the `.272` implementation.
- The Knowledge Map import-tree fact points to the current baseline and this
  refresh owner.
- `MEMORY.md` records the completed bootstrap-maintenance slice and returns the
  active work pointer to `IAL2-FEATURE-COMPLETENESS-FRONTIER.273`.
- Focused documentation, Knowledge Map, memory, mdBook, diff, and doctrine
  gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH`
  Status: `done`
  Goal: `Refresh stale live import-tree measurements after the June 23 bootstrap audit.`
  Children: `BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.1`
  Status: `done`
  Goal: `Update docs/BIN_FSMGEN_IMPORT_TREE.md with current measured line counts while preserving unchanged closure counts.`
  Acceptance: `The import-tree note records total=206, pm=205, unchanged topology, and refreshed measured line counts for the CLI/IAL2/ISF/support owners that drifted; no behavior-bearing files change.`
  Verification: `perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\// && /\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm);'`; `wc -l` measured files; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git --no-pager diff --check`; `scripts/check_doctrines.sh`
  Commit: `BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.1: refresh import tree after mixed demux`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.1` | `done` | Bootstrap audit found stale measured line counts after `.272` while the import closure remains structurally current. |

## Decisions

- `2026-06-23`: Treat stale import-tree measurements as bootstrap
  architecture-maintenance documentation drift, not as an IAL2 behavior slice.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-23` | `BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.1` | `perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\// && /\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm);'`; `wc -l` measured files; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git --no-pager diff --check`; `scripts/check_doctrines.sh` | `passed`; import closure `total=206`, `.pm=205`; stale measured line counts refreshed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.1` | `BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.1: refresh import tree after mixed demux` | Documentation-only bootstrap maintenance slice. |

## Changelog

- `2026-06-23`: Created after the session bootstrap audit reverified unchanged
  import closure counts but found stale measured line counts after `.272`.
- `2026-06-23`: Completed by refreshing the import-tree note with unchanged
  closure counts and current measured line counts after mixed dynamic/static
  write demux growth.
