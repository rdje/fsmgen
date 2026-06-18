# GENERATED-HDL-ARTIFACT-PLACEMENT: Generated HDL Artifact Placement

## Metadata

- Tree ID: `GENERATED-HDL-ARTIFACT-PLACEMENT`
- Status: `done`
- Roadmap lane: `artifact hygiene / CLI generated HDL placement`
- Created: `2026-06-18`
- Last updated: `2026-06-18`
- Owner: repo-local workflow

## Goal

Stop implicit generated HDL from accumulating in the repository root by routing
default HDL outputs into hidden, git-ignored artifact directories.

## Non-Goals

- Do not change explicit `-o` / `--output` behavior.
- Do not change generated HDL contents, language lowering, parser behavior, or
  semantic/report JSON contracts.
- Do not move tracked source fixtures, public examples, or reference files that
  are not generated CLI outputs.
- Do not advance the active IAL2 feature-completeness frontier.

## Acceptance Criteria

- Implicit CLI-generated SystemVerilog lands under `.artifacts/sv/` instead of
  the repo root.
- Implicit CLI-generated VHDL lands under `.artifacts/vhd/` instead of the repo
  root.
- Implicit CLI-generated Verilog lands under `.artifacts/v/` instead of the
  repo root.
- `.artifacts/` is ignored by git.
- Explicit `-o` / `--output` paths continue to be honored exactly.
- Existing root generated `.sv` / `.vhd` artifacts are moved under the matching
  hidden artifact subdirectory when safe.
- User-facing docs and task-tree/memory records describe the default placement.
- Focused CLI checks plus documentation and memory gates pass.
- The completed slice is committed through `COMMIT.md`.

## Task Tree

- ID: `GENERATED-HDL-ARTIFACT-PLACEMENT`
  Status: `done`
  Goal: `Route implicit generated HDL outputs to hidden artifact directories.`
  Children: `GENERATED-HDL-ARTIFACT-PLACEMENT.1`

- ID: `GENERATED-HDL-ARTIFACT-PLACEMENT.1`
  Status: `done`
  Goal: `Move implicit generated HDL output defaults out of the repository root.`
  Acceptance: `Default HDL output uses hidden .artifacts/<language>/ directories, .artifacts/ is ignored, explicit output paths remain unchanged, existing root generated HDL artifacts are relocated when safe, docs and continuity records are synced, and focused checks pass.`
  Verification: `env -u PERL5LIB perl -Iperl -c bin/fsmgen`; `env -u PERL5LIB perl -c t/1463-cli-generated-hdl-artifact-placement.t`; `env -u PERL5LIB prove -Iperl t/1463-cli-generated-hdl-artifact-placement.t`; `env -u PERL5LIB ./bin/fsmgen --quiet fsm/trial_0.fsm`; `env -u PERL5LIB ./bin/fsmgen --quiet --language vhdl t/corpus/direct_assignment_pair_form.fsm`; root `.sv`/`.vhd` scan; `.artifacts/` git-ignore check; Knowledge Map, mdBook, docs-path, memory-architecture, README-numbering, and diff gates
  Commit: `GENERATED-HDL-ARTIFACT-PLACEMENT.1: route generated HDL artifacts`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `GENERATED-HDL-ARTIFACT-PLACEMENT.1` | `done` | Completed; implicit generated HDL defaults now use hidden git-ignored artifact directories, and root `.sv`/`.vhd` generated outputs were relocated. |

## Decisions

- `2026-06-18`: Prefer hidden `.artifacts/sv/` and `.artifacts/vhd/` over
  visible `artifacts/` so generated outputs stay out of root listings and out
  of git by default.
- `2026-06-18`: Preserve explicit output path behavior; this slice only changes
  implicit generated HDL placement.
- `2026-06-18`: Also route implicit Verilog output to `.artifacts/v/` for
  consistency with the hidden generated-HDL artifact policy.
- `2026-06-18`: Existing root `.sv` and `.vhd` files were ignored local
  generated outputs, not tracked source; they were moved into `.artifacts/sv/`
  and `.artifacts/vhd/`.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-18` | `.1` | `git ls-files -- '*.sv' '*.vhd'`; `find . -maxdepth 1 -type f \( -name '*.sv' -o -name '*.vhd' \) -print`; `git check-ignore -v .artifacts .artifacts/sv/trial_0.sv .artifacts/vhd/direct_assignment_pair_form.vhd`; `env -u PERL5LIB perl -Iperl -c bin/fsmgen`; `env -u PERL5LIB perl -c t/1463-cli-generated-hdl-artifact-placement.t`; `env -u PERL5LIB prove -Iperl t/1463-cli-generated-hdl-artifact-placement.t`; `env -u PERL5LIB ./bin/fsmgen --quiet fsm/trial_0.fsm`; `env -u PERL5LIB ./bin/fsmgen --quiet --language vhdl t/corpus/direct_assignment_pair_form.fsm`; `test -s .artifacts/sv/trial_0.sv`; `test -s .artifacts/vhd/direct_assignment_pair_form.vhd` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `GENERATED-HDL-ARTIFACT-PLACEMENT.1: route generated HDL artifacts` | Implementation commit for completed artifact-placement slice. |

## Changelog

- `2026-06-18`: Created active tree and selected `.1` for generated HDL
  artifact placement.
- `2026-06-18`: Completed `.1`; implicit generated HDL now routes to hidden
  git-ignored artifact directories, explicit output paths are preserved, root
  generated `.sv`/`.vhd` artifacts were moved, and focused checks passed.
