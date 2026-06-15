# CI-PERL-FSM-REGRESSION-JUN15-REPAIR: Perl FSM Regression CI Repair

## Metadata

- Tree ID: `CI-PERL-FSM-REGRESSION-JUN15-REPAIR`
- Status: `done`
- Roadmap lane: `CI / regression integrity`
- Created: `2026-06-15`
- Last updated: `2026-06-15`
- Owner: repo-local workflow

## Goal

Repair the failed GitHub `Perl FSM Regression` run `27531373582` without
mixing the fix into the active IAL2 feature-completeness implementation owner.

## Non-Goals

- Do not widen IAL2 queue-head behavior in this tree.
- Do not push unless explicitly requested.
- Do not edit frozen legacy prose logs.
- Do not hide real product defects by loosening tests; align tests only when
  the shipped behavior or public contract already changed deliberately.

## Acceptance Criteria

- Reproduce and classify the failing GitHub run locally.
- Fix the smallest coherent set of source/test/support-contract drift needed
  for the failed CI surface.
- Preserve current IAL2 `.124` ownership for future queue-head implementation
  work.
- Run focused tests for each reproduced failure plus the standard
  documentation/continuity gates.
- Update Memory, task tree, Knowledge Map, and user-facing docs if behavior or
  public contract text changes.
- Commit through `COMMIT.md` with this work-unit id.

## Task Tree

- ID: `CI-PERL-FSM-REGRESSION-JUN15-REPAIR`
  Status: `done`
  Goal: `Repair the June 15 Perl FSM Regression CI failure.`
  Children: `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1`

- ID: `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1`
  Status: `done`
  Goal: `Repair reproduced Perl FSM Regression failures from GitHub run 27531373582.`
  Acceptance: `Inspect GitHub run 27531373582 and reproduce the failing local tests; repair the HDLGenerator public source-path guard so the pipeline accepts supported .fsm/.isf/.ppif public source roots without weakening scalar/path validation; repair stale direct-root StructuralRTLIR expected source metadata alignment; repair stale language_surface capability-manifest discovery keys; repair stale repeat-body diagnostic expectation; repair IAL2 PPIF/corpus failures that cascade from the source-path guard; run focused tests t/193-forward-structural-rtl-ir-builder-direct-root.t, t/370-capability-manifest-section-discovery-audit.t, t/1215-isf-spawn-parameter-binding.t, t/1436-ial2-ppif-parser-cli.t, t/296-regression-corpus-supported-behavior.t, and a focused t/248-regression-corpus-accounting.t gate or documented narrower substitute if full t/248 remains too long; run Knowledge Map generation/check, mdBook build, docs path audit, memory architecture check, diff hygiene, README numbering if README changes, stale/positive task-tree scans, and commit.`
  Verification: `focused gates plus full ./bin/ci-regression PASS`
  Commit: `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1: repair Perl regression CI`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | `done` | Repaired the reproduced CI failure cluster and verified the full shared regression workflow. |

## Findings

- `2026-06-15`: GitHub run `27531373582` failed `Perl FSM Regression` on
  commit `dfc30b69` (`IAL2-FEATURE-COMPLETENESS-FRONTIER.121`).
- Local reproduction on current `HEAD` after `.123` still fails:
  - `t/193-forward-structural-rtl-ir-builder-direct-root.t` because rebuilt
    `StructuralRTLIR` port entries lack the pipeline `source` metadata.
  - `t/370-capability-manifest-section-discovery-audit.t` because
    `language_surface` section presence keys are stale for `file_surfaces`.
  - `t/1215-isf-spawn-parameter-binding.t` because the expected unsupported
    repeat-body diagnostic text is stale.
  - `t/296-regression-corpus-supported-behavior.t` because
    `FSM::Pipeline::HDLGenerator::generate_hdl_from_file` rejects supported
    `.isf` public source roots under a `.fsm`-only guard.
  - `t/1436-ial2-ppif-parser-cli.t` is under reproduction and is expected to
    include the same `.ppif` source-root guard failure plus any independent
    IAL2 drift.
- Repair result:
  - `FSM::Pipeline::HDLGenerator::generate_hdl_from_file` now accepts scalar
    supported `.fsm`, `.isf`, and `.ppif` public source roots. `.isf` and
    `.ppif` roots lower through reviewable generated `.fsm` artifacts before
    calling the existing source-generation orchestrator, while result
    `source_info.kind` preserves the public source kind.
  - The HDLGenerator facade capability contract now advertises the widened
    supported-source value shape without weakening exact-one-argument or scalar
    path validation.
  - `t/193`, `t/370`, `t/1215`, `t/248`, `t/296`, `t/409`, and `t/416` were
    aligned with already-shipped behavior or the widened public contract.
  - A clean local `./bin/ci-regression` rerun matched the hosted workflow and
    passed.

## Verification Log

| Date | Leaf | Commands / Evidence | Result |
| --- | --- | --- | --- |
| `2026-06-15` | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | GitHub run `27531373582`; local `env -u PERL5LIB prove -Iperl t/193-forward-structural-rtl-ir-builder-direct-root.t`; `env -u PERL5LIB prove -Iperl t/370-capability-manifest-section-discovery-audit.t`; `env -u PERL5LIB prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `env -u PERL5LIB prove -Iperl t/296-regression-corpus-supported-behavior.t` | Reproduced before repair. |
| `2026-06-15` | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | `env -u PERL5LIB perl -Iperl -c perl/FSM/Pipeline/HDLGenerator.pm`; `env -u PERL5LIB perl -Iperl -c perl/FSM/Support/CapabilityManifestContract.pm`; `.isf` and `.ppif` direct HDLGenerator probes | `PASS`; `.isf` probe returned `source_info.kind=isf`, generated entry `apb_requester.fsm`, module `apb_requester`; `.ppif` probe returned `source_info.kind=ppif`, generated entry `axi_aw_valid_ready_monitor.fsm`, module `axi_aw_valid_ready_monitor`. |
| `2026-06-15` | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | `env -u PERL5LIB prove -Iperl t/193-forward-structural-rtl-ir-builder-direct-root.t`; `env -u PERL5LIB prove -Iperl t/370-capability-manifest-section-discovery-audit.t`; `env -u PERL5LIB prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `env -u PERL5LIB prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `env -u PERL5LIB prove -Iperl t/296-regression-corpus-supported-behavior.t`; `env -u PERL5LIB prove -Iperl t/248-regression-corpus-accounting.t` | `PASS`; focused reproduced CI surfaces pass. |
| `2026-06-15` | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | First `./bin/ci-regression` after the core repair | `FAIL`; remaining failures were stale `.fsm`-only HDLGenerator facade wording in `t/409-hdl-generator-facade-generation-argument-shape-boundary-audit.t` and `t/416-hdl-generator-facade-generation-argument-list-shape-boundary-audit.t`; all other 1,435 test files passed. |
| `2026-06-15` | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | `env -u PERL5LIB perl -Iperl -c perl/FSM/Support/HDLGeneratorFacadeContract.pm`; `env -u PERL5LIB prove -Iperl t/375-hdl-generator-facade-contract.t t/399-hdl-generator-facade-stateful-reuse-boundary-audit.t t/409-hdl-generator-facade-generation-argument-shape-boundary-audit.t t/416-hdl-generator-facade-generation-argument-list-shape-boundary-audit.t t/370-capability-manifest-section-discovery-audit.t` | `PASS`; facade contract wording and manifests align with supported `.fsm`/`.isf`/`.ppif` source roots. |
| `2026-06-15` | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | `./bin/ci-regression` | `PASS`; `Files=1437, Tests=11200, 3821 wallclock secs`; trailing `mdbook build` completed successfully. |
| `2026-06-15` | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | Post-full-regression temp-artifact cleanup follow-up: `env -u PERL5LIB perl -Iperl -c perl/FSM/Pipeline/HDLGenerator.pm`; direct `.isf` and `.ppif` HDLGenerator probes; `env -u PERL5LIB prove -Iperl t/296-regression-corpus-supported-behavior.t` | `PASS`; direct probes preserved `source_info.kind` and generated entry artifacts; `t/296` `Files=1, Tests=6, 930 wallclock secs`. |
| `2026-06-15` | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; README documentation-index numbering check | `PASS` before final task closure; rerun after task/fact/memory closure recorded below. |
| `2026-06-15` | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | Final closure: `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; README documentation-index numbering check; stale and positive task-tree scans | `PASS`; Knowledge Map has `208` facts / `1193` question keys; README numbering is `15` through `170`; no stale active/pending CI repair marker remains; positive done marker and restored IAL2 `.124` frontier are present. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` | `CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1: repair Perl regression CI` | Repair complete; committed through `COMMIT.md` workflow. |

## Changelog

- `2026-06-15`: Opened `.1` after reproducing the latest GitHub `Perl FSM
  Regression` failure locally.
- `2026-06-15`: Closed `.1` after repairing the HDLGenerator public source
  facade, stale contract/test drift, support accounting, and focused CI
  failures; full `./bin/ci-regression` passed locally.
