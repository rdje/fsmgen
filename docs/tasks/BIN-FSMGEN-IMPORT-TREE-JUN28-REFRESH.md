# BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH: Refresh import-tree measurements after APB register-set timing

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH`
- Status: `done`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-06-28`
- Last updated: `2026-06-28`
- Owner: repo-local workflow

## Goal

Refresh stale measured line counts in the live `bin/fsmgen` import-tree
architecture note after `IAL2-FEATURE-COMPLETENESS-FRONTIER.660` grew the APB
generalized register-set timing implementation while leaving the
project-owned import topology unchanged.

## Ground Truth

- The live static trace from `bin/fsmgen` still reaches `213` project files
  total, including `212` `FSM::...` `.pm` packages plus `bin/fsmgen`.
- The stale values are line-count measurements only.
- The largest visible drift is in
  `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`,
  `perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`,
  `perl/FSM/Adapter/IAL2/PPIF.pm`, and
  `perl/FSM/Support/RegressionCorpus.pm` after the recent APB sideband and
  generalized register-set slices.

## Non-Goals

- Do not change parser, scheduler, backend, generated `.fsm`, HDL, public API,
  manifests, tests, samples, support-accounting behavior, or runtime behavior.
- Do not edit frozen legacy blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`).
- Do not select the next IAL2 APB timing/register-set residue owner; that
  remains owned by `IAL2-FEATURE-COMPLETENESS-FRONTIER.661`.

## Acceptance Criteria

- `docs/BIN_FSMGEN_IMPORT_TREE.md` records the unchanged import-closure counts
  and current measured line counts after the `.660` implementation.
- The Knowledge Map import-tree fact points to the current baseline and this
  refresh owner.
- `MEMORY.md` records the completed bootstrap-maintenance slice and returns the
  active work pointer to `IAL2-FEATURE-COMPLETENESS-FRONTIER.661`.
- Focused documentation, Knowledge Map, memory, mdBook, diff, and doctrine
  gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH`
  Status: `done`
  Goal: `Refresh stale live import-tree measurements after the June 28 bootstrap audit.`
  Children: `BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH.1`
  Status: `done`
  Goal: `Update docs/BIN_FSMGEN_IMPORT_TREE.md with current measured line counts while preserving unchanged closure counts.`
  Acceptance: `The import-tree note records total=213, pm=212, unchanged topology, and refreshed measured line counts for the CLI/IAL2/APB/support owners that drifted; no behavior-bearing files change.`
  Verification: `perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\// && /\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm); my %seen=map { $_=>1 } @pm; for my $m (qw(FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm FSM/IAL2/ProtocolIntent/ApbCompleter.pm FSM/IAL2/ProtocolIntent/ApbComposition.pm)) { die "missing $m\n" unless $seen{$m}; } say "import tree APB owners ok";'`; `wc -l` measured files; `perl -Iperl -c bin/fsmgen`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git --no-pager diff --check`; `scripts/check_doctrines.sh`
  Commit: `BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH.1: refresh import tree after APB register-set timing`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH.1` | `done` | Bootstrap audit found stale measured line counts after `.660` while the import closure remains structurally current. |

## Decisions

- `2026-06-28`: Treat stale import-tree measurements as bootstrap
  architecture-maintenance documentation drift, not as an IAL2 behavior slice.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-28` | `BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH.1` | `perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\// && /\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm); my %seen=map { $_=>1 } @pm; for my $m (qw(FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm FSM/IAL2/ProtocolIntent/ApbCompleter.pm FSM/IAL2/ProtocolIntent/ApbComposition.pm)) { die "missing $m\n" unless $seen{$m}; } say "import tree APB owners ok";'`; `wc -l` measured files; `perl -Iperl -c bin/fsmgen`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git --no-pager diff --check`; `scripts/check_doctrines.sh` | `passed`; import closure `total=213`, `.pm=212`; APB owners reachable; stale measured line counts refreshed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH.1` | `BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH.1: refresh import tree after APB register-set timing` | Documentation-only bootstrap maintenance slice. |

## Changelog

- `2026-06-28`: Created after the session bootstrap audit reverified unchanged
  import closure counts but found stale measured line counts after `.660`.
- `2026-06-28`: Completed by refreshing the import-tree note, current baseline
  fact card, generated Knowledge Map, task index, and memory pointer while
  preserving unchanged closure counts.
